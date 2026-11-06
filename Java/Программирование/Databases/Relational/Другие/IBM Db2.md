# IBM Db2

## Если знаешь PostgreSQL (TL;DR)

1. **Tablespace + buffer pool** вместо `shared_buffers` и файлов: объекты кладутся в табличные пространства, кэш задаётся на каждое пространство.
2. **MVCC «по требованию»**: по умолчанию — блокировки; версии строк (`currently committed`, `CS`) включаются настройкой.
3. **CLI-инструменты, а не SQL-каталог**: `db2look`, `db2explain`, `db2advis`, `MON_GET_*` — основная диагностика.
4. **Изоляция по умолчанию — Cursor Stability (CS)**, а не Read Committed: курсор видит только текущую строку.
5. **`REORG` и `RUNSTATS`** — обязательные регулярные операции (аналоги `VACUUM`/`pg_repack` и `ANALYZE`).

## Ниша

Банки (особенно в Европе и Азии), страхование, крупный retail, ERP (SAP), legacy на мейнфреймах (z/OS) и Linux/Unix/Windows (LUW). Db2 LUW 11.5 — актуальная версия.

## Хранение

| | PostgreSQL | Db2 LUW |
|---|---|---|
| Единица | 8 КБ страница | страница 4/8/16/32 КБ (задаётся при создании БД) |
| Контейнер | каталог PGDATA | **tablespace** (SMS/DMS/automatic) |
| Кэш | `shared_buffers` | **buffer pool** на tablespace |
| Таблица | heap | heap/MDC (multi-dimensional clustering)/range-partitioned |
| Адрес строки | `ctid` | RID (page, slot) |
| Индекс | отдельная структура | B-tree; **MDC** и **cluster indexes** для порядка |
| Длинные значения | TOAST | `LOB` в отдельном tablespace |
| Мусор | `VACUUM` | переиспользование + `REORG` (дефрагментация) |

- **`REORG TABLE` / `REORG INDEXES`** — аналог `VACUUM FULL`/`REINDEX`, но чаще нужен: после массовых `DELETE`/`UPDATE` таблица фрагментируется.
- **`RUNSTATS`** — аналог `ANALYZE`; без него оптимизатор слеп.
- **MDC** (Multi-Dimensional Clustering) — таблица физически кластеризуется по нескольким измерениям (аналог `CLUSTER` в PG, но поддерживается автоматически).

## Транзакции и MVCC

- По умолчанию — **locking-based concurrency**: читатель ставит shared-lock, писатель — exclusive.
- **`CURRENTLY COMMITTED`** (DB2 9.7+) — читатель видит последнюю закоммиченную версию, не дожидаясь писателя. Это ближайший аналог MVCC.
- Уровни изоляции: `UR` (uncommitted read), `CS` (default), `RS` (read stability), `RR` (repeatable read).
- **`CS` и `RS`** работают через блокировки + «commit LSN»; версии строк не хранятся в таблице, как в PG.
- `RR` блокирует прочитанные строки до конца транзакции → конфликты и deadlock'и.
- Deadlock detection — `LOCKTIMEOUT`, `DEADLOCK` монитор.

Аналогия с PG:

| Db2 | PostgreSQL |
|---|---|
| `UR` | грязное чтение (в PG нет) |
| `CS` (default) | ближе к `READ COMMITTED`, но на локах |
| `RS` | похоже на `REPEATABLE READ` (стабильность прочитанного) |
| `RR` | `REPEATABLE READ` + блокировки |

## Журналы и durability

- **Transaction log** — циклический (`circular`) или архивный (`archive`/`retain`).
- `LOGRETAIN ON` + `USEREXIT` — включить архивацию для PITR.
- `db2pd -logs`, `db2 get db cfg for <db>` (`LOGFILSIZ`, `LOGPRIMARY`, `LOGSECOND`).
- **`db2Backup` / `db2Restore` / `db2Rollforward`** — бэкап и PITR.
- High Availability: **HADR** (аналог streaming replication), **pureScale** (shared disk, аналог RAC).

## Диагностика

```bash
db2 connect to SAMPLE
db2 "SELECT * FROM orders WHERE user_id = 42"

db2explain -d SAMPLE -t orders -i idx_orders_user   # план
db2advis -d SAMPLE -s "SELECT ..."                  # советы по индексам

db2 "CALL MON_GET_PKG_CACHE_STMT(NULL, NULL, NULL, -2)"  # топ по времени
db2 "SELECT * FROM TABLE(MON_GET_ACTIVITY(NULL, -2))"     # активность
db2pd -d SAMPLE -locks -transactions -applications        # блокировки
db2top                                                    # live-мониторинг
```

| Задача | PostgreSQL | Db2 |
|---|---|---|
| План | `EXPLAIN (ANALYZE)` | `db2explain`, `EXPLAIN PLAN FOR` + `db2exfmt` |
| Топ запросов | `pg_stat_statements` | package cache (`MON_GET_PKG_CACHE_STMT`) |
| Кто работает | `pg_stat_activity` | `MON_GET_ACTIVITY`, `LIST APPLICATIONS` |
| Блокировки | `pg_locks` | `db2pd -locks`, `MON_GET_LOCKS` |
| Статистика | `ANALYZE` / `pg_stats` | `RUNSTATS`, `SYSCAT.TABLES` |

## Индексы и DDL

- B-tree, **MDC**, **cluster index**, **partitioned index**, **compression** (row и value).
- **`INCLUDE`** для покрывающих индексов есть.
- **Expression/functional index** — через generated columns (как в SQL Server).
- **`CREATE INDEX ... ALLOW REVERSE SCANS`** и `GENERATE KEY USING` — специфика.
- Online-операции: `REORG TABLE ... INPLACE`, `REORG INDEXES ... ALLOW WRITE ACCESS`.
- **BLU Acceleration** — колоночный движок внутри Db2 (column-organized tables), аналог Oracle In-Memory/ClickHouse, но в одной СУБД.

## Репликация и HA

- **HADR** — физическая репликация через transaction log (sync/near-sync/async).
- **pureScale** — shared-disk кластер (аналог Oracle RAC).
- **Q Replication / SQL Replication** — логическая репликация.
- **Db2 Warehouse / Db2 on Cloud** — MPP-варианты.
- **Federation** — доступ к внешним источникам через nicknames (аналог `postgres_fdw`).

## SQL-диалект: перевод с PG

| PostgreSQL | Db2 |
|---|---|
| `LIMIT n OFFSET m` | `FETCH FIRST n ROWS ONLY` / `OFFSET m ROWS FETCH NEXT n ROWS ONLY` |
| `SERIAL` | `GENERATED ALWAYS AS IDENTITY` |
| `ON CONFLICT` | `MERGE` |
| `RETURNING` | `SELECT FROM FINAL TABLE (INSERT ...)` (data-change table) |
| `boolean` | `SMALLINT` 0/1 (нет boolean) |
| `text` | `VARCHAR(n)`, `CLOB` |
| `timestamptz` | `TIMESTAMP` (без TZ) |
| `jsonb` | `JSON`/`BLOB` + `JSON_VAL` |
| `LATERAL` | `LATERAL` (есть), `TABLE(...)` |
| `string_agg` | `LISTAGG` |
| `::type` | `CAST` |
| `ILIKE` | `UPPER() LIKE` |
| схемы | schema есть, но user ≠ schema |
| `"identifier"` | `"IDENTIFIER"` (uppercase по умолчанию) |

## Грабли для приходящего с PG

1. **Нет MVCC по умолчанию**: читатель может ждать писателя. Проверь `CURRENTLY COMMITTED` / `CS`.
2. **`REORG` и `RUNSTATS` — обязательны**, иначе фрагментация и плохие планы.
3. **`RUNSTATS` не автоматический** (в отличие от autovacuum/autoanalyze) — нужен scheduler.
4. **`VARCHAR` без длины** — только `VARCHAR(n)`.
5. **Идентификаторы в upper case** по умолчанию.
6. **Табличные пространства нужно создавать заранее** и раскладывать по ним индексы/LOB.
7. **`LOCKTIMEOUT` по умолчанию `-1`** (ждать вечно) — выставляй.
8. **Пустая строка ≠ NULL** (в отличие от Oracle), но ведёт себя как обычная строка.
9. **Типы данных и collation** зависят от `territory`/`codeset` при создании БД — менять потом нельзя.

## Что проверить руками

```bash
db2 get db cfg for SAMPLE | grep -iE "log|lock|isolation"
db2 "VALUES CURRENT ISOLATION"
db2 "SELECT TABSCHEMA, TABNAME, CARD, NPAGES FROM SYSCAT.TABLES WHERE TABSCHEMA='APP'"
db2pd -d SAMPLE -locks
```

## Связанное

[[PostgreSQL]] · [[Сравнения/Хранение — heap vs clustered index]] · [[Сравнения/Изоляция и блокировки]] · [[Сравнения/Репликация и HA]] · [[Другие/SQL Server]] · [[Другие/Oracle Database]]

## Источники

- IBM Db2 Documentation (11.5): «Database fundamentals», «Performance», «HADR»
- «Db2 Developer's Guide» (Craig Mullins)
- IBM Redbooks по pureScale и BLU
