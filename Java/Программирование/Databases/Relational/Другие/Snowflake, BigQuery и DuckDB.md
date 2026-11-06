# Snowflake, BigQuery и DuckDB

## Если знаешь PostgreSQL (TL;DR)

1. **Нет индексов, нет `VACUUM`, нет `shared_buffers`** — вместо этого micro-partitions (Snowflake), Capacitor-колонки (BigQuery) или columnar segments (DuckDB).
2. **Compute отделён от storage**: платишь за время работы склада (Snowflake warehouse, BigQuery slots/on-demand), а не за инстанс.
3. **`ORDER BY`/`WHERE` ускоряются метаданными**: min/max по micro-partition; кластеризация таблицы — вместо индекса.
4. **Транзакции ограничены**: Snowflake — ACID на DML, но без `SELECT FOR UPDATE`-культуры; BigQuery — DML-батчи; DuckDB — один писатель.
5. **SQL-диалект свой**, хотя есть режимы совместимости (DuckDB → PostgreSQL, BigQuery → стандартный SQL).

## Snowflake

### Архитектура

- **Storage** — S3/GCS/Azure Blob, данные в **micro-partitions** (50–500 МБ, колоночные, сжатые).
- **Compute** — **virtual warehouses** (кластеры узлов), независимо масштабируются; можно несколько складов на одни данные.
- **Cloud Services** — метаданные, оптимизатор, транзакции.

### Хранение

| | PostgreSQL | Snowflake |
|---|---|---|
| Единица | страница 8 КБ | micro-partition (50–500 МБ) |
| Организация | heap | колоночная, по порядку загрузки |
| Индекс | B-tree | **нет**; clustering key + min/max метаданные |
| Адрес | `ctid` | нет (immutable partitions) |
| Мусор | `VACUUM` | Time Travel + fail-safe (хранение) |

- **Clustering key** — физическая сортировка (автоматическая или заданная); ускоряет `WHERE` за счёт pruning.
- **Time Travel** — `AT (TIMESTAMP => ...)` / `BEFORE (STATEMENT => ...)` до 90 дней; **Fail-safe** — 7 дней после.
- **Zero-copy clone** — `CREATE TABLE t2 CLONE t1` — мгновенно, copy-on-write (аналог Neon branching).

### Транзакции

- ACID, `READ COMMITTED` по умолчанию; `SERIALIZABLE` через `ALTER SESSION`.
- **Нет `SELECT FOR UPDATE`-конкуренции** в привычном смысле; конкурентные `UPDATE` — через `MERGE`.
- DML дорогой: micro-partition перезаписывается; массовые операции — `COPY INTO`.

### Диагностика

```sql
SELECT * FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
ORDER BY TOTAL_ELAPSED_TIME DESC LIMIT 10;

SELECT * FROM TABLE(INFORMATION_SCHEMA.QUERY_HISTORY_BY_SESSION());
```

- **Query Profile** в UI — граф с операторами, bytes scanned, partitions pruned.
- **`EXPLAIN`** — есть, но главное — Query Profile.

## BigQuery

### Архитектура

- **Serverless**: compute выделяется на запрос; storage — Colossus.
- **Capacitor** — колоночный формат; **Dremel** — движок выполнения (tree of slots).
- **Slot** — единица compute; on-demand (per TB scanned) или flat-rate (slots).
- **Партиционирование и кластеризация** — главные инструменты оптимизации.

### Хранение

| | PostgreSQL | BigQuery |
|---|---|---|
| Единица | страница | колоночный блок в Capacitor |
| Организация | heap | колоночная, immutable |
| Индекс | B-tree | **нет**; partitioning + clustering + search index |
| Мусор | `VACUUM` | time travel (7 дней) + snapshots |

- **Partitioning**: по дате/ingestion time/range; **`WHERE _PARTITIONDATE`** отсекает.
- **Clustering**: до 4 колонок, сортировка внутри партиции; `WHERE cluster_col = ...` ускоряет.
- **`SELECT *`** — самый дорогой запрос: платишь за просканированные колонки.
- **Materialized views** — автообновление, аналог PG matview + refresh.

### Транзакции

- DML (`INSERT/UPDATE/DELETE/MERGE`) — батчевый, с лимитами; **стриминговые вставки** — через Storage Write API.
- **`BEGIN TRANSACTION`** есть, но длинные транзакции не приветствуются.
- **`MERGE`** — основной способ upsert.

### Диагностика

- **Query Plan** в UI: `READ`, `COMPUTE`, `WRITE`, `shuffle`.
- `INFORMATION_SCHEMA.JOBS_BY_PROJECT` — история, bytes processed.
- `EXPLAIN` — есть с недавних пор, но основной инструмент — визуальный план.

## DuckDB

### Архитектура

- **In-process** OLAP: библиотека, а не сервер (аналог SQLite для аналитики).
- **Векторный движок**: обработка батчами (1024–2048 значений), columnar.
- **Читает напрямую** Parquet/CSV/JSON/Arrow без загрузки.
- Один писатель, много читателей (MVCC на уровне транзакций).

### Хранение

| | PostgreSQL | DuckDB |
|---|---|---|
| Формат | heap + WAL | columnar segments + WAL |
| Индексы | B-tree | **ART** (Adaptive Radix Tree) для PK/unique, zone maps |
| Организация | строки | колонки, сжатие |
| Мусор | `VACUUM` | `CHECKPOINT` + компакция |
| Внешние данные | FDW | **прямое чтение Parquet/CSV/Arrow** |

- **`SELECT * FROM 'data/*.parquet'`** — главный сценарий; данные не нужно импортировать.
- **`COPY ... TO 'out.parquet'`** — экспорт.
- **`EXPLAIN ANALYZE`** — с профилем по операторам.
- **`PRAGMA`** — настройки (`threads`, `memory_limit`).

### Транзакции

- ACID, один писатель; `SERIALIZABLE` (через MVCC).
- **`BEGIN`/`COMMIT`** есть, но OLTP-нагрузка — не сценарий.
- **`INSTALL`/`LOAD`** расширений (httpfs, parquet, json, iceberg, delta).

### Диагностика

```sql
EXPLAIN ANALYZE SELECT ...;
PRAGMA database_size;
SELECT * FROM duckdb_memory();
```

## Сравнение

| | Snowflake | BigQuery | DuckDB |
|---|---|---|---|
| Модель | managed warehouse | serverless | embedded |
| Единица хранения | micro-partition | Capacitor block | column segment |
| Индексы | нет | нет | ART + zone maps |
| Оплата | warehouse-time | bytes/slots | бесплатно (CPU) |
| Лучше всего | DWH, BI | DWH, ad-hoc | локальная аналитика, тесты |
| Транзакции | ACID DML | батч DML | ACID, один писатель |
| Внешние данные | stages, Iceberg | external tables, Iceberg | Parquet/CSV/Arrow |

## Грабли для приходящего с PG

1. **Нет индексов** — не ищи `CREATE INDEX`; работай партиционированием/кластеризацией.
2. **`SELECT *`** оплачивается по просканированным байтам (BigQuery) или времени (Snowflake).
3. **`UPDATE`/`DELETE`** дорогие и ограниченные; проектируй append-only + `MERGE`.
4. **`COUNT(DISTINCT)`** — дорого; используй approximate (`APPROX_COUNT_DISTINCT`, `HLL`).
5. **`JOIN` больших таблиц** — shuffle по сети; фильтруй до join.
6. **`ORDER BY` без `LIMIT`** на миллиардах — дорого; окна и top-N дешевле.
7. **Time Travel ≠ бэкап навсегда** — ограничен retention.
8. **DuckDB — один писатель**; для конкурентной записи не подходит.
9. **SQL-диалект**: `QUALIFY`, `STRUCT`, `UNNEST`, `PIVOT` — свои.
10. **Стоимость непредсказуема**, если не следить за `bytes processed`/`warehouse size`.

## Что проверить руками

```sql
-- DuckDB (локально, бесплатно)
INSTALL httpfs; LOAD httpfs;
SELECT count(*) FROM 'https://.../*.parquet';
EXPLAIN ANALYZE SELECT ...;

-- BigQuery
SELECT * FROM `region-us`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
ORDER BY total_bytes_processed DESC LIMIT 10;
```

## Связанное

[[PostgreSQL]] · [[Другие/Аналитические MPP]] · [[Другие/SAP HANA]] · [[Сравнения/Хранение — heap vs clustered index]] · [[Партиции]]

## Источники

- Snowflake Documentation: «Micro-partitions», «Clustering», «Time Travel»
- BigQuery Documentation: «Storage», «Partitioning», «Clustering»
- DuckDB Documentation: «Architecture», «Performance»
- «Dremel: Interactive Analysis of Web-Scale Datasets» (VLDB 2010)
