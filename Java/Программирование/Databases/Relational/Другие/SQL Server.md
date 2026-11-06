# SQL Server

## Если знаешь PostgreSQL (TL;DR)

1. **Таблица — либо heap, либо кластерный индекс**; некластерные индексы хранят ключ кластеризации (или RID), а не `ctid`.
2. **По умолчанию блокировки, а не MVCC.** RCSI (`READ_COMMITTED_SNAPSHOT`) включает версионирование — версии живут в **tempdb**.
3. **Журнал транзакций — один последовательный файл с VLF**; усечение зависит от модели восстановления (SIMPLE/FULL).
4. **Query Store** — встроенный «архив планов» с возможностью зафиксировать план; аналог `pg_stat_statements` + `auto_explain` + plan baselines.
5. **Нет `VACUUM`, нет freeze**: место переиспользуется, «мусор» — ghost records, которые чистит ghost cleanup.

## Ниша

Корпоративный сектор, .NET/Azure, банки, ERP/CRM (1С, Dynamics), BI. Версии: 2019/2022, Azure SQL. Работает и на Linux.

## Хранение

| | PostgreSQL | SQL Server |
|---|---|---|
| Страница | 8 КБ | 8 КБ (+ 96-байтовый заголовок) |
| Единица выделения | файл/сегменты | экстент = 8 страниц (64 КБ) |
| Таблица | heap | **heap** (без кластерного индекса) или **clustered index** |
| Адрес строки | `ctid` | RID (file:page:slot) или ключ кластера |
| Вторичный индекс | `ctid` → heap | ключ кластера → clustered; для heap — RID |
| Длинные значения | TOAST | `LOB`-страницы, `ROW_OVERFLOW` |
| Мусор | dead tuples + `VACUUM` | ghost records + ghost cleanup, forwarded records |

Особенности:

- **Heap + forwarded records**: `UPDATE`, увеличивающий строку, может оставить «forwarding pointer»; лечится `ALTER TABLE … REBUILD` или кластерным индексом.
- **Кластерный индекс = физический порядок**. Как MySQL, но можно жить и без него (heap).
- **`INCLUDE`** у некластерного индекса — листовые колонки, как в PG.
- **`%%physloc%%`** — недокументированный аналог `ctid`; не использовать в проде.

## Транзакции и MVCC

- **READ COMMITTED по умолчанию** — но на **блокировках**: читатель ждёт писателя (в отличие от PG).
- **RCSI** (`ALTER DATABASE … SET READ_COMMITTED_SNAPSHOT ON`) — читатели видят версию на момент начала оператора; версии в tempdb.
- **SNAPSHOT** (`ALLOW_SNAPSHOT_ISOLATION ON`) — версия на момент начала транзакции; конфликт обновления → ошибка 3960.
- **tempdb version store**: `sys.dm_tran_version_store_space_usage`; долгая транзакция раздувает tempdb.
- **`READ UNCOMMITTED` / `NOLOCK`** — грязное чтение, не блокирует; часто используют зря.

## Журнал и durability

| | PostgreSQL | SQL Server |
|---|---|---|
| Журнал | WAL-сегменты 16 МБ | один log-файл, разбитый на **VLF** |
| Усечение | checkpoint + `max_wal_size` | SIMPLE — на checkpoint; FULL — только после log backup |
| Проверка | `pg_waldump` | `DBCC LOGINFO`, `sys.dm_db_log_info` |
| Репликация | WAL sender | log shipping, AG, replication |
| Отложенная durability | `synchronous_commit=off` | `DELAYED_DURABILITY = FORCED/ALLOWED` |

Модели восстановления:

- **SIMPLE** — лог усечён после checkpoint, PITR нет;
- **FULL** — лог растёт, пока не сделаешь backup log; PITR есть;
- **BULK_LOGGED** — минимальное логирование массовых операций, компромисс.

`log_reuse_wait_desc` показывает, что мешает усечению (`LOG_BACKUP`, `REPLICATION`, `ACTIVE_TRANSACTION`…).

## Блокировки и изоляция

| Уровень | Как работает |
|---|---|
| `READ UNCOMMITTED` | грязное чтение, без shared-локов |
| `READ COMMITTED` (default) | shared-локи на время чтения строки |
| `REPEATABLE READ` | shared-локи до конца транзакции |
| `SERIALIZABLE` | range-локи (аналог gap locks) |
| `SNAPSHOT` | версии в tempdb, конфликт записи → ошибка |

- Эскалация блокировок: ~5000 локов на оператор → таблица (`LOCK_ESCALATION`).
- Deadlock: жертва получает ошибку 1205; приоритет — `SET DEADLOCK_PRIORITY`.
- `sys.dm_tran_locks`, `sys.dm_exec_requests` (`blocking_session_id`), `sys.dm_os_waiting_tasks`.

## Диагностика и оптимизация

| Задача | PostgreSQL | SQL Server |
|---|---|---|
| План | `EXPLAIN (ANALYZE, BUFFERS)` | actual execution plan, `SET STATISTICS IO, TIME ON` |
| Топ запросов | `pg_stat_statements` | **Query Store** (`sys.query_store_*`), `sys.dm_exec_query_stats` |
| Кто работает | `pg_stat_activity` | `sys.dm_exec_requests`, `sys.dm_exec_sessions` |
| Ожидания | `wait_event` | `sys.dm_os_wait_stats`, `sys.dm_os_waiting_tasks` |
| Блокировки | `pg_locks` | `sys.dm_tran_locks` |
| Индексы | `pg_stat_user_indexes` | `sys.dm_db_index_usage_stats`, missing index DMV |
| Размер | `pg_total_relation_size` | `sys.dm_db_partition_stats` |

Query Store (2016+): история планов, runtime-статистика, **forcing plan**, wait stats. В 2022 — Query Store hints.

Параметры и подсказки:

- `OPTION (RECOMPILE)`, `OPTIMIZE FOR`, `MAXDOP`, `USE HINT` — борьба с parameter sniffing;
- `AUTO_CREATE_STATISTICS`, `AUTO_UPDATE_STATISTICS` (асинхронно с 2017?);
- фильтрованные статистики и индексы.

## Индексы и DDL

- **Clustered / nonclustered**, `INCLUDE`, filtered index (аналог partial), indexed views, columnstore (CCI/NCCI).
- **Нет expression index** — computed column + индекс.
- `ONLINE=ON` для операций с индексами (Enterprise; в Standard — ограниченно), `RESUMABLE` (2017+).
- `CREATE INDEX` блокирует таблицу в зависимости от версии/edition; планировать в окно.

## Репликация и HA

- **Always On Availability Groups** — синхронные/асинхронные реплики, автоматический failover, listener, читаемые secondary.
- **Log shipping**, **mirroring** (legacy), **replication** (transactional/merge/snapshot).
- **Azure SQL** — управляемые AG, geo-replication, auto-failover groups.
- RPO/RTO зависят от режима синхронизации; synchronous commit увеличивает latency.

## SQL-диалект: перевод с PG

| PostgreSQL | SQL Server |
|---|---|
| `LIMIT n OFFSET m` | `OFFSET m ROWS FETCH NEXT n ROWS ONLY` или `TOP (n)` |
| `SERIAL` / identity | `IDENTITY(1,1)` / `SEQUENCE` |
| `ON CONFLICT` | `MERGE` (осторожно с конкурентностью) |
| `RETURNING` | `OUTPUT INSERTED.*` |
| `boolean` | `bit` |
| `text` | `nvarchar(max)` |
| `timestamptz` | `datetimeoffset` (или `datetime2`) |
| `uuid` | `uniqueidentifier` + `NEWID()`/`NEWSEQUENTIALID()` |
| `jsonb` | `nvarchar(max)` + `JSON_VALUE`/`OPENJSON`; индекс — computed column |
| `LATERAL` | `CROSS APPLY` / `OUTER APPLY` |
| `string_agg` | `STRING_AGG` |
| `::type` | `CAST` / `TRY_CAST` |
| `ILIKE` | `LIKE` (зависит от collation) |
| схемы | `dbo` по умолчанию, схемы есть |
| `"identifier"` | `[identifier]` |

## Грабли для приходящего с PG

1. **Читатель блокирует писателя** в дефолтном RC — включи RCSI или используй snapshot.
2. **`NOLOCK` — не «ускорение»**, а грязное чтение и пропущенные/дублированные строки.
3. **`SELECT *` и `ORDER BY` без индекса** — сортировка в tempdb, как в PG, но tempdb общая для всех.
4. **`MERGE` имеет известные баги** с конкурентностью; в PG `ON CONFLICT` надёжнее.
5. **Пустая строка ≠ NULL**, но **хвостовые пробелы игнорируются** при сравнении (`'a' = 'a '`), в отличие от PG.
6. **Регистронезависимая collation по умолчанию** — `WHERE name = 'ivan'` найдёт `Ivan`.
7. **`datetime` точность 3.33 мс и округление**; для точности — `datetime2`.
8. **Журнал в FULL растёт без log backup** — диск кончится молча.
9. **`COUNT(*)`** — скан индекса, но `sys.dm_db_partition_stats` даёт оценку.
10. **Кластерный индекс на случайном UUID** — те же page splits, что в MySQL.

## Что проверить руками

```sql
SELECT @@VERSION;
SELECT SERVERPROPERTY('Edition');

SET STATISTICS IO, TIME ON;
SELECT * FROM orders WHERE user_id = 42;

SELECT * FROM sys.dm_exec_requests WHERE blocking_session_id <> 0;
SELECT * FROM sys.dm_tran_locks;

SELECT * FROM sys.dm_db_index_usage_stats WHERE database_id = DB_ID();
SELECT * FROM sys.query_store_runtime_stats ORDER BY avg_duration DESC;
```

## Связанное

[[PostgreSQL]] · [[Сравнения/Хранение — heap vs clustered index]] · [[Сравнения/Изоляция и блокировки]] · [[Сравнения/Планировщик и диагностика]] · [[Сравнения/Репликация и HA]]

## Источники

- Microsoft Docs: Database Engine, Query Processing, Query Store, Always On
- SQL Shack, Brent Ozar (диагностика и waits)
- «Pro SQL Server Internals» (Dmitri Korotkevitch)
