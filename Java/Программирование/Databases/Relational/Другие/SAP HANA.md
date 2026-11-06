# SAP HANA

## Если знаешь PostgreSQL (TL;DR)

1. **Всё в памяти**, данные на диске — это персистентная копия (snapshot + redo log). Диск нужен для durability и восстановления, а не для чтения.
2. **Колоночное хранение по умолчанию** (column store) + row store для маленьких/OLTP-таблиц. Индексы почти не нужны — сканирование колонки и так быстрое.
3. **Delta store + merge**: вставки идут в дельта-структуру, периодически сливаются с основной колонкой. Аналог LSM, но внутри одной таблицы.
4. **Нет `VACUUM`**: версии строк для MVCC ограничены и чистятся автоматически; undo — в памяти.
5. **Расчёт выполняется в колоночном движке** (vectorized, parallel); SQL компилируется в план, но идеология — «данные рядом с CPU».

## Ниша

SAP S/4HANA, BW/4HANA, ритейл-аналитика, отчёты в реальном времени по огромным объёмам, где нужны и транзакции, и OLAP в одной системе (HTAP). Версии: HANA 2.0 SPS06+, HANA Cloud.

## Хранение

| | PostgreSQL | SAP HANA |
|---|---|---|
| Основное хранилище | диск (heap) | **RAM** + персистентность на диске |
| Организация | heap (row) | **column store** по умолчанию, row store — опция |
| Единица | 8 КБ страница | колонки, векторы, delta-структуры |
| Индекс | B-tree/GIN/GiST | обычно **не нужен**; inverted index, B-tree для row store |
| Адрес строки | `ctid` | rowid внутри колонки |
| Длинные значения | TOAST | LOB, отдельное хранение |
| Мусор | `VACUUM` | автоочистка MVCC-версий + merge delta |

Следствия:

- **`SELECT *` по широкой таблице** в колоночном движке читает только нужные колонки — это принципиально дешевле, чем в PG.
- **Точечные `UPDATE`/`DELETE`** дороже, чем в row-store: они идут в delta и требуют merge.
- **`ORDER BY` по колонке** может быть дешёвым, если колонка уже отсортирована/сжата с словарём.
- **Память — главный ресурс**: размер БД ≈ объём данных в RAM (со сжатием). Не влезло — swap/диск, деградация.

## Транзакции и MVCC

- MVCC через **версии в delta/undo**, но старые версии живут недолго — блокируются долгими транзакциями.
- Уровни: `READ COMMITTED` (default), `REPEATABLE READ`, `SERIALIZABLE`.
- **`SERIALIZABLE`** — через блокировки/конфликты, не SSI.
- **Statement snapshot** — читатель видит состояние на начало запроса; долгие запросы могут упираться в `snapshot too old` (как Oracle).
- **`LOCK TABLE` / `SELECT FOR UPDATE`** — есть, но в колоночном движке дороже.

## Журналы и durability

- **Redo log** (в памяти буферизуется, пишется на диск) + **savepoints** (периодический snapshot состояния).
- **`data snapshot`** — консистентная копия на диск; при рестарте загружается snapshot + доигрывается redo.
- `log_mode = normal|overwrite`; для PITR — `log_mode=normal` + backup.
- **`RECOVER DATABASE`**, `hdbbackupdiag`, `hdbnsutil`.
- **Persistence**: после рестарта вся БД должна снова влезть в память — иначе старт долгий.

## Блокировки и конкурентность

- Блокировки строк/таблиц, как в обычной СУБД, но в колоночном движке — дороже.
- **`M_SESSION`, `M_LOCKS`, `M_BLOCKED_TRANSACTIONS`** — мониторинг (аналог `pg_stat_activity`/`pg_locks`).
- **Deadlock detection** встроен.

```sql
SELECT * FROM M_SESSIONS WHERE STATE = 'ACTIVE';
SELECT * FROM M_BLOCKED_TRANSACTIONS;
SELECT * FROM M_LOCKS;
```

## Диагностика

```sql
EXPLAIN PLAN FOR SELECT * FROM orders WHERE user_id = 42;
SELECT * FROM EXPLAINED_PLANS;
-- или в HANA Studio: Visual Explain

SELECT * FROM M_SQL_PLAN_CACHE ORDER BY TOTAL_EXECUTION_TIME DESC;
SELECT * FROM M_EXPENSIVE_STATEMENTS ORDER BY DURATION_MICROSEC DESC;
```

- **Plan cache** (`M_SQL_PLAN_CACHE`) — аналог `pg_stat_statements`.
- **Expensive statements trace** — запись медленных запросов в файл.
- **HANA Studio / Cockpit** — графика, но SQL-доступ тоже есть.

## Индексы и DDL

- В column store индексы обычно **не нужны**; для точечного поиска — **inverted index** (аналог GIN) и **B-tree** (для row store).
- **`CREATE INDEX ... INVERTED`** — по колонке, для `=`/`IN`.
- **Partitioning** по диапазону/хэшу — есть, важно для больших таблиц.
- **`ALTER TABLE`** в column store — перестройка колонки; на больших объёмах — долго.
- **`MERGE DELTA`** — ручной/автоматический merge; смотреть `M_DELTA_MERGE_STATISTICS`.

## Репликация и HA

- **System Replication** — синхронная/асинхронная реплика на уровне БД; `hdbnsutil -sr_enable`.
- **Active/Active (read-enabled)** — чтение со secondary.
- **Scale-out** — несколько узлов, данные шардируются по таблицам (аналог MPP).
- **HANA Cloud** — managed, с автомасштабированием.

## SQL-диалект: перевод с PG

| PostgreSQL | SAP HANA |
|---|---|
| `LIMIT n OFFSET m` | `LIMIT n OFFSET m` (совпадает) |
| `SERIAL` | `GENERATED ALWAYS AS IDENTITY` / sequence |
| `ON CONFLICT` | `UPSERT` (HANA-специфичный) / `MERGE` |
| `RETURNING` | нет (через `SELECT` после) |
| `boolean` | `BOOLEAN` |
| `text` | `NVARCHAR(n)`, `NCLOB` |
| `timestamptz` | `TIMESTAMP` (без TZ), `SECONDDATE` |
| `jsonb` | нет; `NCLOB` + функции |
| `LATERAL` | `LATERAL` (есть, ограниченно) |
| `string_agg` | `STRING_AGG` |
| `::type` | `CAST` |
| `ILIKE` | нет; `LIKE`/`UPPER()` |
| схемы | schema есть |

## Грабли для приходящего с PG

1. **Память = размер БД.** Планируй RAM, а не диск; сжатие колонок помогает, но не бесконечно.
2. **Точечные `UPDATE`/`DELETE`** медленнее, чем в PG: delta store и merge.
3. **`SELECT *`** в колоночном движке не так страшен, но `INSERT ... SELECT *` — да.
4. **Долгая транзакция** → `snapshot too old` и рост delta.
5. **`MERGE DELTA`** может не успевать при массовой загрузке — смотреть `M_DELTA_MERGE_STATISTICS`.
6. **Индексы почти не нужны** — не переноси привычку «добавить индекс».
7. **DDL в column store** — перестройка колонки; планируй окно.
8. **Рестарт долгий** — вся БД загружается в память.
9. **SQL-диалект** не совпадает с PG в `UPSERT`, `LIMIT` и работе с датами.

## Что проверить руками

```sql
SELECT * FROM M_DATABASE;
SELECT * FROM M_SQL_PLAN_CACHE ORDER BY TOTAL_EXECUTION_TIME DESC LIMIT 10;
SELECT * FROM M_DELTA_MERGE_STATISTICS;
SELECT * FROM M_MEMORY WHERE CATEGORY = 'MAIN';
```

## Связанное

[[PostgreSQL]] · [[Сравнения/Хранение — heap vs clustered index]] · [[Сравнения/MVCC и очистка мусора]] · [[Другие/Аналитические MPP]] · [[Другие/Snowflake, BigQuery и DuckDB]]

## Источники

- SAP HANA Administration Guide, «Performance Analysis», «Persistence»
- SAP HANA SQL Reference
- SAP Community блоги по delta merge и plan cache
