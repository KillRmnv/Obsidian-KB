# Oracle Database

## Если знаешь PostgreSQL (TL;DR)

1. **Старые версии строк — в undo-сегментах**, а не в таблице. Отсюда: нет bloat в привычном смысле, но есть `undo retention` и `ORA-01555: snapshot too old`.
2. **Время — не LSN, а SCN** (System Change Number): монотонный счётчик изменений. `AS OF SCN` даёт «машину времени» из коробки (Flashback).
3. **Читатель никогда не ждёт писателя и не блокируется им**, даже в `SERIALIZABLE`; при конфликте записи — `ORA-08177`.
4. **Планировщик управляется hints и plan baselines**, а не только статистикой. `DBMS_XPLAN` вместо `EXPLAIN`.
5. **Пустая строка — это NULL** (`'' IS NULL` = TRUE), а `NULL` в `NOT IN` ведёт себя так же болезненно.
6. **Архитектура — instance + database**: память (SGA) и процессы отделены от файлов; RAC — несколько instance на одну БД.

## Ниша

Банки, телеком, госсектор, крупный ERP, legacy. Oracle Database 19c (LTS), 21c, 23ai. Дорого, сложно, но «умеет всё»: RAC, Data Guard, partitioning, Advanced Queuing, Spatial, In-Memory.

## Хранение

| | PostgreSQL | Oracle |
|---|---|---|
| Блок | 8 КБ | 2–32 КБ (`DB_BLOCK_SIZE`, задаётся при создании БД) |
| Таблица | heap + TOAST | сегмент из экстентов; строки в блоках, `PCTFREE`/`PCTUSED` |
| Адрес строки | `ctid` | `ROWID` (object, file, block, row) — стабильный |
| Индекс | отдельная структура | отдельный сегмент; B-tree, bitmap, function-based |
| Длинные значения | TOAST | `LOB`-сегменты (`BASICFILE`/`SECUREFILE`), `CLOB`/`BLOB` |
| Мусор | `VACUUM` | нет: место переиспользуется, `PCTFREE` резервирует под updates |
| Сжатие | TOAST pglz/lz4 | Advanced Compression (OLTP/Query), HCC |

Ключевое отличие: **`PCTFREE`** — процент блока, зарезервированный под будущие `UPDATE` этой же строки. Аналог `fillfactor` в PG, но на уровне блока и с `PCTUSED`.

**`ROWID`** — физический адрес, но, в отличие от `ctid`, **не меняется при обновлении строки** (строка мигрирует, а ROWID остаётся с указанием на новое место). Использовать как идентификатор всё равно нельзя: `ALTER TABLE ... MOVE` меняет.

**Кластеры таблиц** (не путать с RAC): несколько таблиц с общим ключом хранятся в одном сегменте; `IOT` (index-organized table) — таблица как B-tree по PK, прямой аналог clustered index в MySQL.

## Транзакции и MVCC

- Каждая транзакция получает **SCN** при коммите.
- В блоке хранится **ITL** (Interested Transaction List) — слоты активных транзакций; если слотов не хватило → `ITL waits`.
- Читатель видит данные на момент SCN, при необходимости откатывая изменения через undo.
- **Undo-сегменты** — циклические, размер `UNDO_TABLESPACE` + `UNDO_RETENTION`. Долгий запрос → `ORA-01555: snapshot too old` (undo перезаписан).
- **Нет freeze и wraparound** — SCN 48 бит и растёт, «заморозка» не нужна.
- Rollback — тоже через undo (`ROLLBACK` может быть долгим).

Уровни изоляции:

| Уровень | Что видит | Конфликт записи |
|---|---|---|
| `READ COMMITTED` (default) | на момент начала **оператора** | ждёт, потом видит новую версию |
| `SERIALIZABLE` | на момент начала **транзакции** | `ORA-08177: can't serialize access` |
| `READ ONLY` | снапшот на всю транзакцию | запрет записи |

В отличие от PG, `SERIALIZABLE` в Oracle — это snapshot isolation без SSI: не ловит write skew, но и не откатывает «на всякий случай».

## Журналы и durability

| | PostgreSQL | Oracle |
|---|---|---|
| Журнал | WAL-сегменты | **redo log** (online redo logs, циклические) + archive log |
| Позиция | LSN | SCN + RBA |
| Checkpoint | checkpointer | CKPT + DBWR |
| Запись страниц | bgwriter/checkpointer | **DBWR** (database writer) |
| Отмена | не нужна (версии в heap) | undo-сегменты |
| PITR | WAL archive | RMAN + archive log |
| Гарантия коммита | `synchronous_commit` | `COMMIT WRITE IMMEDIATE WAIT` (default) |

`COMMIT WRITE BATCH NOWAIT` — аналог `synchronous_commit=off`: быстрее, но последние коммиты можно потерять.

## Блокировки и конкурентность

- **Блокировки строк** хранятся в самом блоке (ITL), а не в общей таблице локов.
- **Нет эскалации блокировок** (в отличие от SQL Server) и нет «таблицы локов» как в PG.
- **Читатели не блокируются никогда** — даже в SERIALIZABLE.
- `SELECT ... FOR UPDATE` блокирует строку; `FOR UPDATE NOWAIT` / `SKIP LOCKED` — есть.
- **Deadlock** → `ORA-00060`, одна транзакция откатывается; `deadlock_timeout`-аналога нет, detection мгновенный.
- **DDL** в Oracle неявно коммитит транзакцию (в PG — транзакционный DDL). Это частая ловушка при миграции.
- **`LOCK TABLE ... IN EXCLUSIVE MODE`** — явная табличная блокировка; `NOWAIT`/`WAIT n`.

Диагностика:

```sql
SELECT sid, serial#, username, status, blocking_session, event, seconds_in_wait
FROM v$session WHERE blocking_session IS NOT NULL;

SELECT * FROM v$lock;
SELECT * FROM dba_blockers;
SELECT * FROM dba_waiters;
```

Убить сессию: `ALTER SYSTEM KILL SESSION 'sid,serial#' IMMEDIATE;`

## Диагностика запросов

| Задача | PostgreSQL | Oracle |
|---|---|---|
| План | `EXPLAIN (ANALYZE, BUFFERS)` | `EXPLAIN PLAN FOR` + `DBMS_XPLAN.DISPLAY`, `DISPLAY_CURSOR` |
| Реальное выполнение | `ANALYZE, BUFFERS` | `DBMS_XPLAN.DISPLAY_CURSOR(..., 'ALLSTATS LAST')` |
| Топ запросов | `pg_stat_statements` | **AWR** (`DBA_HIST_SQLSTAT`), **ASH** (`V$ACTIVE_SESSION_HISTORY`) |
| Кто работает | `pg_stat_activity` | `V$SESSION`, `V$SQL` |
| Ожидания | `wait_event` | `V$SESSION.event`, `V$SYSTEM_EVENT`, ASH |
| Блокировки | `pg_locks` | `V$LOCK`, `DBA_BLOCKERS`, `DBA_WAITERS` |
| Статистика | `pg_stats` | `DBMS_STATS`, `DBA_TAB_COL_STATISTICS` |

```sql
-- План последнего запроса
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(NULL, NULL, 'ALLSTATS LAST'));

-- Собрать статистику (аналог ANALYZE)
EXEC DBMS_STATS.GATHER_TABLE_STATS('APP', 'ORDERS', CASCADE => TRUE);

-- SQL с наибольшим elapsed time из AWR
SELECT sql_id, elapsed_time_delta/1e6 AS sec, executions_delta, sql_text
FROM dba_hist_sqlstat s JOIN dba_hist_sqltext t USING (sql_id)
ORDER BY elapsed_time_delta DESC FETCH FIRST 10 ROWS ONLY;
```

### Hints и plan management

```sql
SELECT /*+ INDEX(orders idx_orders_user) LEADING(u o) USE_NL(o) */ ...
```

- hints — не «совет», а **директива** (кроме случаев, когда невозможна);
- **SQL Plan Management (SPM)**: baseline фиксирует план, optimizer выбирает только из проверенных;
- **SQL Profiles**, **SQL patches**, **outline** — управление планами без правки запроса;
- `OPTIMIZER_FEATURES_ENABLE` — «откатить» оптимизатор к версии.

В PG аналог — `pg_hint_plan` (расширение), но идеология другая: в Oracle hints — часть культуры, в PG — крайняя мера.

## Индексы и DDL

- B-tree, **bitmap** (для низкой кардинальности и DWH), function-based, **reverse key** (против hot spots), **IOT**, **index compression**.
- Нет partial index; есть **function-based index с `CASE`** как эмуляция.
- **Invisible indexes**: `ALTER INDEX idx INVISIBLE;` — проверить, используется ли.
- `CREATE INDEX ... ONLINE` — без блокировки DML (аналог `CONCURRENTLY`).
- **Partitioning** — отдельная опция (в 12c+ доступна без EE? — только базовые схемы; интервальное/референсное — EE).
- `ALTER TABLE ... MOVE` / `SHRINK SPACE` — дефрагментация (аналог `VACUUM FULL`/`pg_repack`), `SHRINK SPACE` — онлайн.

## Репликация и HA

- **Data Guard**: физический standby (redo apply), `MAXIMUM PERFORMANCE` / `MAXIMUM AVAILABILITY` / `MAXIMUM PROTECTION`.
- **Active Data Guard** — чтение со standby.
- **GoldenGate** — логическая репликация (как PG logical replication, но промышленного уровня).
- **RAC** — несколько instance на общую БД (shared disk); не репликация, а масштабирование и HA на уровне instance.
- **Flashback** (query/table/database) — откат во времени через undo/archive log.

## SQL-диалект: перевод с PG

| PostgreSQL | Oracle |
|---|---|
| `LIMIT n OFFSET m` | `FETCH FIRST n ROWS ONLY` / `OFFSET m ROWS FETCH NEXT n ROWS ONLY` (12c+) |
| `SERIAL` / identity | `GENERATED ALWAYS AS IDENTITY` (12c+) или sequence + trigger |
| `ON CONFLICT` | `MERGE` |
| `RETURNING` | `RETURNING ... INTO :bind` (PL/SQL) |
| `boolean` | нет boolean в таблицах — `NUMBER(1)` или `CHAR(1)` |
| `text` | `VARCHAR2(n)` (до 32767 с `MAX_STRING_SIZE=EXTENDED`), `CLOB` |
| `timestamptz` | `TIMESTAMP WITH TIME ZONE` |
| `uuid` | `RAW(16)` или `VARCHAR2(36)` |
| `jsonb` | `JSON` (21c+) / `CLOB` + `IS JSON`; индексы — function-based |
| `LATERAL` | `CROSS APPLY` / `OUTER APPLY` (12c+) |
| `string_agg` | `LISTAGG` |
| `::type` | `CAST` |
| `ILIKE` | `UPPER(x) LIKE ...` или `NLS_COMP`/`NLS_SORT` |
| схемы | user = schema; `CREATE USER` = схема |
| `"identifier"` | `"IDENTIFIER"` (по умолчанию uppercase) |

## Грабли для приходящего с PG

1. **`''` — это NULL.** `INSERT INTO t VALUES ('')` вставит NULL и упадёт на `NOT NULL`.
2. **`NULL` в `NOT IN`** — та же ловушка, что в PG, но усугубляется пустыми строками.
3. **DDL автокоммитит.** `CREATE TABLE` внутри транзакции зафиксирует всё, что было до.
4. **`SERIALIZABLE` не ловит write skew** и даёт `ORA-08177` — retry обязателен.
5. **`UNDO_RETENTION` и долгие отчёты** → `ORA-01555`. Лечится увеличением undo или `AS OF` + Flashback.
6. **`ROWID` не вечен**: `MOVE`, `SHRINK`, partition maintenance меняют его.
7. **Идентификаторы в верхнем регистре** по умолчанию; `"users"` и `users` — разные объекты.
8. **`VARCHAR2` пустая строка = NULL** (см. п.1) — миграция из PG ломается на `NOT NULL` + `''`.
9. **Hints легко «протухают»** при изменении данных; SPM baseline надёжнее.
10. **RAC — не шардирование**: общий диск, один образ данных, масштабируется не линейно.

## Что проверить руками

```sql
SELECT * FROM v$version;
SELECT name, value FROM v$parameter WHERE name IN ('db_block_size','sga_target','undo_retention');

-- Пустая строка = NULL
SELECT CASE WHEN '' IS NULL THEN 'NULL!' ELSE 'not null' END FROM dual;

EXPLAIN PLAN FOR SELECT * FROM orders WHERE user_id = 42;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

SELECT sid, event, blocking_session, sql_id FROM v$session WHERE status = 'ACTIVE';
```

## Связанное

[[PostgreSQL]] · [[Сравнения/Хранение — heap vs clustered index]] · [[Сравнения/MVCC и очистка мусора]] · [[Сравнения/Изоляция и блокировки]] · [[Сравнения/SQL-диалекты и миграция]] · [[Сравнения/Планировщик и диагностика]]

## Источники

- Oracle Database Concepts 19c/23ai (главы про storage, undo, redo, optimisation)
- Oracle Base (Tim Hall), «Oracle Database 19c: New Features»
- «Expert Oracle Database Architecture» (Thomas Kyte)
