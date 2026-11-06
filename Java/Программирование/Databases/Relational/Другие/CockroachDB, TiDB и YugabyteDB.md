# CockroachDB, TiDB и YugabyteDB

## Если знаешь PostgreSQL (TL;DR)

1. **Данные разбиты на диапазоны (ranges/regions)**, каждый реплицируется через **Raft**. Нет одного файла PGDATA — есть распределённое key-value хранилище.
2. **Ключ включает `tenant_id`/префикс таблицы**, поэтому `ORDER BY` по PK почти бесплатен, а вот `JOIN` между диапазонами может ходить по сети.
3. **MVCC по таймстампам** (Hybrid Logical Clock) и **GC вместо vacuum**: старые версии удаляются по TTL, а не `VACUUM`-проходом.
4. **Serializable по умолчанию** у CockroachDB/Spanner-подобных; TiDB — `Repeatable Read` (snapshot) по умолчанию, но с `pessimistic`/`optimistic` транзакциями.
5. **`EXPLAIN` показывает распределение**: какие ranges задействованы, сколько узлов, есть ли network exchange. Локальный cost model не работает — стоимость сети другая.

## Ниша

Глобальные сервисы, мультирегион, шардирование «из коробки», замена ручного шардинга PostgreSQL. CockroachDB и YugabyteDB — PostgreSQL-wire-совместимые; TiDB — MySQL-совместимый.

## Общая архитектура

```
SQL-слой (stateless)  →  распределённое KV-хранилище (Raft-группы)
       ↑                        ↑
   планировщик            диапазоны (ranges) по ключу
```

| | CockroachDB | TiDB | YugabyteDB |
|---|---|---|---|
| SQL-совместимость | PostgreSQL (wire) | MySQL (wire) | PostgreSQL (wire) |
| Хранилище | собственное (Pebble) | TiKV (RocksDB) | DocDB (RocksDB) |
| Консенсус | Raft | Raft (Multi-Raft) | Raft |
| Транзакции | Serializable (по умолчанию) | Snapshot (RR) + pessimistic/optimistic | Serializable / Snapshot |
| Часы | HLC | TSO (центральный) | HLC |
| Аналитика | отдельный слой/CDC | **TiFlash** (колоночный) | — |
| Шардирование | ranges, auto-split | regions, auto-split | tablets/shards |

## Хранение

- Ключ = `(tenant, table_id, index_id, indexed_cols, primary_key)`. Значение — строка.
- Диапазон ключей = **range** (CockroachDB, ~512 МБ) / **region** (TiDB, ~96 МБ) / **tablet** (Yugabyte).
- Каждый диапазон — Raft-группа с лидером; запись идёт на лидера, реплицируется на followers.
- **Нет heap и TOAST**: всё — KV; большие значения — тоже KV-чанки.
- **MVCC**: версии хранятся рядом (`key@timestamp`), GC удаляет версии старше `gc.ttlseconds` (Cockroach) / `gc.life_time` (TiDB).

Следствие: **вторичный индекс — отдельный диапазон**, поэтому `JOIN` по индексу — это сетевой поход в другой диапазон.

## Транзакции и MVCC

**CockroachDB**:

- Транзакция получает HLC-таймстамп; при конфликте — **retry** (`40001`).
- **Serializable по умолчанию**; `READ COMMITTED` появился в 23.1 (опция).
- **`AS OF SYSTEM TIME`** — чтение на прошлый таймстамп (аналог Flashback).
- **Contention**: горячие ключи → `RETRY_SERIALIZABLE`; помогает `SELECT ... FOR UPDATE` и разбиение ключа.

**TiDB**:

- **Percolator**-модель: primary lock + secondary locks; commit через 2PC.
- `pessimistic` (по умолчанию с 3.0) и `optimistic` транзакции.
- TSO — центральный сервис времени (единая точка, но с батчингом).
- `SET TRANSACTION ISOLATION LEVEL` — RC/RR (snapshot).

**YugabyteDB**:

- DocDB: MVCC + Raft; транзакции через распределённый 2PC.
- Поддержка `SERIALIZABLE` и `SNAPSHOT` (как PG).

## Журналы и durability

- **Raft log** — журнал консенсуса; заменил WAL в привычном смысле.
- Каждый узел пишет свой Raft log на диск (RocksDB WAL + SST).
- **Checkpoint** — компакция SST; в CockroachDB — Pebble compaction.
- **PITR**: CockroachDB — `BACKUP ... AS OF SYSTEM TIME` (внешнее хранилище: S3/GCS); TiDB — BR (Backup & Restore) + log backup; Yugabyte — `yb_backup`.

## Блокировки и конкурентность

- **Нет глобального `pg_locks`**; блокировки — на уровне KV-ключей и диапазонов.
- CockroachDB: `crdb_internal.cluster_locks`, `crdb_internal.cluster_queries`, `crdb_internal.cluster_sessions`.
- TiDB: `information_schema.cluster_processlist`, `tidb_lock_resolver`, `DATA_LOCK_WAITS` (в TiKV).
- Deadlock: detection через графы ожиданий в SQL-слое; в CockroachDB — частые `40001` вместо ожидания.

## Диагностика

```sql
-- CockroachDB
EXPLAIN (VERBOSE) SELECT * FROM orders WHERE user_id = 42;
SHOW TRACE FOR SELECT ...;                 -- распределённая трассировка!
SELECT * FROM crdb_internal.cluster_queries;
SELECT * FROM crdb_internal.node_statement_statistics;

-- TiDB
EXPLAIN ANALYZE SELECT ...;
SHOW PROCESSLIST;
SELECT * FROM information_schema.slow_query;
SELECT * FROM information_schema.statements_summary;

-- YugabyteDB
EXPLAIN (ANALYZE, DIST, DEBUG) SELECT ...;
SELECT * FROM yb_servers();
```

`EXPLAIN (DIST)` в Yugabyte и `SHOW TRACE` в Cockroach — то, что показывает **сетевую** стоимость, которой нет в PG.

## Индексы и DDL

- **Индексы — глобальные диапазоны**; `CREATE INDEX` перестраивает данные по всей таблице, но **online** (не блокирует запись).
- **`CREATE INDEX ... STORING (...)`** (Cockroach) / `INCLUDE` — покрывающие индексы.
- **`PARTITION BY` / `REGIONAL BY ROW`** (Cockroach) — управление локальностью данных (мультирегион).
- **`ALTER TABLE`** — online, но может быть долгим; в TiDB — `ADMIN SHOW DDL JOBS`.

## Репликация и HA

- **Raft**: потеря лидера → выборы за секунды; консенсус на запись.
- **Мультирегион**: `REGIONAL BY ROW` / `GLOBAL` таблицы; latency зависит от географии.
- **CDC**: CockroachDB changefeeds, TiDB CDC (TiCDC), Yugabyte CDC — в Kafka/DWH.
- **Follower reads** (Cockroach `AS OF SYSTEM TIME` + `follower_read_timestamp()`) — чтение с ближайшей реплики.

## Грабли для приходящего с PG

1. **`VACUUM` нет** — GC по TTL; `pg_stat_user_tables` не существует.
2. **`EXPLAIN` показывает ranges и network** — локальная cost-модель обманывает.
3. **`SERIAL`/sequence в распределённой среде** — не монотонны и не гарантируют порядок; используй `UUID`/`HLC`.
4. **Транзакции с retry**: `40001` — не баг, а контракт; retry-loop обязателен.
5. **Горячие ключи** (например, счётчик) убивают производительность; шардируй.
6. **`JOIN` между большими таблицами** может быть сетевым; денормализация и `INTERLEAVE`/`REGIONAL` важнее, чем в PG.
7. **`pg_stat_statements` нет** — свои `crdb_internal`/`statements_summary`.
8. **DDL online, но долгий** — на большой таблице `ADD COLUMN`/`CREATE INDEX` занимает минуты.
9. **Совместимость неполная**: часть PG-функций/расширений отсутствует (Cockroach), часть MySQL-синтаксиса — в TiDB.
10. **Цена**: межрегиональная репликация = latency и трафик; считай заранее.

## Что проверить руками

```sql
-- CockroachDB (single-node demo)
cockroach demo
EXPLAIN (VERBOSE) SELECT * FROM orders WHERE user_id = 42;
SHOW TRACE FOR SELECT count(*) FROM orders;
SELECT * FROM crdb_internal.cluster_locks;
```

```bash
# TiDB (tiup playground)
tiup playground
mysql -h 127.0.0.1 -P 4000 -u root
```

## Связанное

[[PostgreSQL]] · [[Google Spanner]] · [[шардирование]] · [[Сравнения/Репликация и HA]] · [[Сравнения/MVCC и очистка мусора]] · [[CAP]]

## Источники

- CockroachDB Docs: «Architecture», «Transactions», «Performance Tuning»
- TiDB Docs: «Architecture», «Transaction Overview», «TiFlash»
- YugabyteDB Docs: «Architecture», «DocDB»
- «Designing Data-Intensive Applications», главы про консенсус
