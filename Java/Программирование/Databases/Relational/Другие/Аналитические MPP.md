# Аналитические MPP

## Если знаешь PostgreSQL (TL;DR)

1. **Данные хранятся по колонкам**, а не по строкам: запрос читает только нужные колонки, сжатие в 5–20 раз.
2. **Таблица распределена по узлам** (distribution key); `JOIN` требует **перемещения данных по сети** (broadcast/shuffle) — это главная стоимость плана.
3. **Индексы почти не нужны**: вместо них — **zone maps / min-max** по блокам, партиционирование, сортировка.
4. **OLTP-транзакций нет**: `UPDATE`/`DELETE` дорогие, `INSERT` — батчами; MVCC либо нет, либо упрощённый.
5. **`EXPLAIN` показывает distribution/slice**: какой узел что делает и сколько строк передаётся по сети.

## Ниша

DWH, BI, отчёты по миллиардам строк, ETL. Redshift, Greenplum, Vertica, Teradata, Snowflake, BigQuery, ClickHouse, SingleStore.

## Общая модель

```
        координатор (leader)
       /        |         \
   сегмент 1  сегмент 2  сегмент 3    ← каждый хранит свою часть строк
      │          │          │
   колонки    колонки    колонки
```

- **Distribution key** определяет, на каком сегменте лежит строка: `DISTKEY(user_id)`.
- **`JOIN` по distribution key** — локальный; иначе **broadcast** (маленькая таблица копируется на все) или **redistribute** (shuffle обеих сторон).
- **Sort key / zone map** — данные физически отсортированы, min/max по блокам отсекают чтение.
- **Column store** + dictionary/RLE/Delta compression.

## Сравнение

| | Redshift | Greenplum | Vertica | Teradata | ClickHouse |
|---|---|---|---|---|---|
| Основа | PostgreSQL-форк | PostgreSQL-форк | своя | своя | своя (C++) |
| Хранение | колоночное, блочное | row/column (append-optimized) | колоночное | колоночное | колоночное (MergeTree) |
| Распределение | DISTKEY/DISTSTYLE | distribution policy | segmentation | AMP | shard + replica |
| Индексы | sortkey, zone maps | btree/bitmap (AO) | projections | PI (primary index) | primary key = sort key |
| MVCC | да (упрощённый) | да | да | да | нет (частично) |
| Обновления | дорогие | дорогие | дорогие | дорогие | `ALTER UPDATE` (мутации) |
| Репликация | внутри кластера | mirror segments | K-safety | fallback | реплики шардов |

## Как думать о плане

В PG вы смотрите `Seq Scan` vs `Index Scan` и `Buffers`. В MPP добавляется третий вопрос: **сколько данных едет по сети**.

```
Gather Motion (slice 1 → slice 0)
  -> Hash Join
       -> Redistribute Motion (по user_id)
       -> Seq Scan on orders
       -> Broadcast Motion
       -> Seq Scan on users
```

Что искать:

- **`Broadcast`** большой таблицы — катастрофа; фильтруй заранее.
- **`Redistribute`** на миллиардах строк — тоже дорого; проверь distribution key.
- **`Slice`/`Segment`** — сколько узлов реально работают; перекос (skew) убивает.
- **`rows` vs `actual rows`** — та же проблема статистики, но цена ошибки выше.

## Хранение и сжатие

- **Колоночное**: `SELECT sum(amount)` читает только `amount`, а не всю строку.
- **Сжатие**: dictionary (низкая кардинальность), RLE (повторы), delta (sorted), LZO/ZSTD/LZ4.
- **Zone maps**: min/max на блок (1 МБ в Redshift) — `WHERE created_at > ...` отсекает блоки без индексов.
- **Сортировка (sortkey)** — физический порядок, усиливает zone maps; `VACUUM SORT`/`OPTIMIZE` пересортировывает.
- **Партиционирование** — по дате/региону; в Redshift — `PARTITION BY`, в ClickHouse — `PARTITION BY toYYYYMM(date)`.

## Транзакции и конкурентность

- **MVCC есть, но дорогой**: `UPDATE` = delete + insert; массовые обновления — через `CREATE TABLE AS` + swap.
- **Изоляция**: обычно `SNAPSHOT`/`SERIALIZABLE` с блокировками на таблицу; в ClickHouse — атомарность на партицию, без полноценных транзакций.
- **Конкурентность**: очереди (Redshift WLM), resource groups, квоты; одновременные тяжёлые запросы душат друг друга.
- **`VACUUM`/`OPTIMIZE`** — обязательны: удалённые строки физически не исчезают, пока не пройдёт merge/vacuum.

## Диагностика

**Redshift**:

```sql
SELECT query, userid, starttime, substring(query,1,80) AS q, cpu_time, elapsed
FROM stl_query ORDER BY starttime DESC LIMIT 10;

SELECT * FROM svl_query_summary WHERE query = <id>;   -- по шагам
SELECT * FROM svv_table_info;                          -- размеры, skew
```

**Greenplum**:

```sql
SELECT * FROM gp_toolkit.gp_skew_coefficients;
EXPLAIN ANALYZE SELECT ...;
```

**Vertica**:

```sql
SELECT * FROM query_profiles WHERE query = '<id>';    -- профиль
SELECT * FROM projection_storage;
```

**ClickHouse**:

```sql
EXPLAIN PIPELINE SELECT ...;
SELECT * FROM system.query_log ORDER BY query_duration_ms DESC LIMIT 10;
SELECT * FROM system.parts WHERE active;
```

## Грабли для приходящего с PG

1. **Индексы не решают**: распределение и сортировка важнее.
2. **`JOIN` не по distribution key** — сеть; перепроектируй ключ или денормализуй.
3. **Перекос (skew)**: один сегмент в 10 раз больше — все ждут его.
4. **`UPDATE`/`DELETE` дорогие**: батчи, `MERGE`, перезапись партиции.
5. **`COUNT(DISTINCT)`** на миллиардах — дорого; approximate (`APPROXIMATE COUNT DISTINCT`, `uniq()`).
6. **`SELECT *`** убивает колоночное преимущество.
7. **Статистика** (`ANALYZE`) критична; без неё plan выбирает broadcast.
8. **`VACUUM`/`OPTIMIZE`** — регулярно, иначе деградация.
9. **Колоночное сжатие** плохо работает на случайных UUID/текстах — сортировка помогает.
10. **OLTP-нагрузка** на MPP — антипаттерн; для неё есть отдельная БД.

## Что проверить руками

```sql
-- Redshift
EXPLAIN SELECT ...;
SELECT * FROM svv_table_info ORDER BY size DESC LIMIT 10;

-- ClickHouse
EXPLAIN PIPELINE SELECT ...;
SELECT database, table, sum(bytes_on_disk) FROM system.parts WHERE active GROUP BY 1,2;
```

## Связанное

[[PostgreSQL]] · [[Другие/Snowflake, BigQuery и DuckDB]] · [[Другие/SAP HANA]] · [[Партиции]] · [[Сравнения/Хранение — heap vs clustered index]]

## Источники

- Amazon Redshift: «Optimizing Query Performance», «Distribution styles»
- Greenplum Documentation: «Distribution», «gp_toolkit»
- Vertica Documentation: «Query plans», «Projections»
- ClickHouse Documentation: «MergeTree», «Query analysis»
