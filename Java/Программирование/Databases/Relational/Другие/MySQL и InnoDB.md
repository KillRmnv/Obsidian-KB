# MySQL и InnoDB

## Если знаешь PostgreSQL (TL;DR)

1. **Таблица — это B-tree по первичному ключу** (clustered index), а не heap + отдельные индексы. Нет `ctid` — строка живёт в листе дерева.
2. **Вторичный индекс хранит PK**, поэтому lookup идёт «индекс → PK → кластерный индекс». Длинный PK раздувает все индексы.
3. **Старые версии строк — в undo-log**, а не в таблице. Мусор чистит **purge thread**, а не `VACUUM`; bloat выглядит иначе (history list).
4. **Изоляция по умолчанию — Repeatable Read** (в PG — Read Committed), причём с **gap locks**.
5. **Два журнала:** redo (crash recovery) + binlog (репликация). Плюс doublewrite buffer против torn pages.

## Ниша

Веб-приложения, SaaS, high-traffic чтение, экосистема WordPress/Java/PHP. MySQL 8.0/8.4 LTS; InnoDB — единственный реальный движок для OLTP (MyISAM — legacy, без транзакций).

## Хранение

| | PostgreSQL | MySQL/InnoDB |
|---|---|---|
| Страница | 8 КБ | 16 КБ (`innodb_page_size`, задаётся при init) |
| Таблица | heap (неупорядоченный) | clustered B-tree по PK |
| Адрес строки | `ctid` (page, offset) | PK (или скрытый 6-байтовый row ID) |
| Вторичный индекс | `ctid` → heap | значение PK → clustered |
| Длинные значения | TOAST (отдельная таблица) | off-page overflow pages (20-байтовый указатель) |
| Мусор | dead tuples + `VACUUM` | undo + purge, history list |
| Сжатие | TOAST (pglz/lz4) | row format `COMPRESSED`, page compression |

Следствия:

- **`ORDER BY id` почти бесплатен** (данные уже отсортированы по PK), а `ORDER BY created_at` требует индекса.
- **Секвенциальный доступ по диапазону PK быстрый**, но вставка случайного UUID — это вставка в середину дерева (page split).
- **Вторичный индекс содержит PK**, поэтому `PRIMARY KEY (id)` на 8 байт лучше, чем UUID на 16.
- **`SELECT *` без PK-фильтра** всё равно читает кластерный индекс (в PG — heap).

## Транзакции и MVCC

- Скрытые колонки: `DB_TRX_ID` (6 байт), `DB_ROLL_PTR` (7 байт) → цепочка undo.
- Читатель строит **read view** (список активных транзакций) и идёт по undo, пока не найдёт видимую версию.
- **Purge thread** удаляет undo, когда версия больше никому не видна. Долгая транзакция → **history list length** растёт, undo-таблицы пухнут.
- Нет `VACUUM`, нет freeze и wraparound: trx id 6 байт, «заморозка» не нужна.
- `SHOW ENGINE INNODB STATUS` → `History list length`; при тысячах — ищите долгую транзакцию (`information_schema.INNODB_TRX`).

## Журналы и durability

| Что | Зачем | Настройка |
|---|---|---|
| **redo log** | crash recovery, циклический | `innodb_redo_log_capacity` (8.0.30+), `innodb_flush_log_at_trx_commit` |
| **undo log** | MVCC и rollback | undo tablespaces, `innodb_undo_tablespaces` |
| **doublewrite** | защита от torn pages | `innodb_doublewrite` |
| **binlog** | репликация и PITR | `binlog_format=ROW`, `sync_binlog=1` |

`innodb_flush_log_at_trx_commit`:

- `1` (default) — fsync на каждый коммит, как `synchronous_commit=on`;
- `2` — в page cache ОС, fsync раз в секунду (потеря при падении ОС);
- `0` — fsync раз в секунду (потеря при падении mysqld).

## Блокировки и изоляция

| | PostgreSQL | MySQL/InnoDB |
|---|---|---|
| Default | Read Committed | **Repeatable Read** |
| Snapshot | на каждый оператор (RC) | на первую читающую транзакцию |
| Phantom | SSI только в Serializable | **gap locks** (в RR) |
| Чтение vs запись | не блокируются | не блокируются |
| Deadlock | detection через 1 с | `innodb_deadlock_detect`, `innodb_lock_wait_timeout` (50 с) |
| `FOR UPDATE` | блокирует строку | блокирует строку + gap (в RR) |

`gap lock` — блокировка «промежутка» в индексе, чтобы другая транзакция не вставила строку в диапазон. В `READ COMMITTED` gap locks почти отключены (остаются для FK/unique).

Диагностика:

```sql
SHOW ENGINE INNODB STATUS;                       -- deadlock, history list
SELECT * FROM information_schema.INNODB_TRX;     -- активные транзакции
SELECT * FROM performance_schema.data_locks;     -- 8.0: блокировки
SELECT * FROM performance_schema.data_lock_waits;
SELECT * FROM sys.innodb_lock_waits;             -- удобное представление
```

## Диагностика запросов

```sql
EXPLAIN SELECT ...;                    -- план
EXPLAIN ANALYZE SELECT ...;            -- 8.0.18+: реальное выполнение
EXPLAIN FORMAT=JSON SELECT ...;        -- детали стоимости
SHOW WARNINGS;                         -- переписанный запрос
SET optimizer_trace='enabled=on';      -- трассировка оптимизатора
```

| Задача | PostgreSQL | MySQL |
|---|---|---|
| Топ запросов | `pg_stat_statements` | `performance_schema.events_statements_summary_by_digest`, slow log |
| Кто работает | `pg_stat_activity` | `SHOW PROCESSLIST`, `performance_schema.threads` |
| Блокировки | `pg_locks` | `performance_schema.data_locks` |
| Таблицы | `pg_stat_user_tables` | `information_schema.tables`, `INNODB_TABLESTATS` |
| Индексы | `pg_stat_user_indexes` | `sys.schema_unused_indexes` |
| Размер | `pg_total_relation_size` | `information_schema.tables.data_length + index_length` |

Статистика: `ANALYZE TABLE t;` (аналог `ANALYZE`), гистограммы 8.0:

```sql
ANALYZE TABLE orders UPDATE HISTOGRAM ON status WITH 100 BUCKETS;
SELECT * FROM information_schema.column_statistics;
```

## Индексы и DDL

- B-tree, FULLTEXT, SPATIAL; hash только для MEMORY.
- **Нет partial index** — эмуляция через generated column + индекс.
- **Функциональные индексы** с 8.0.13: `CREATE INDEX ON t ((lower(email)));`
- **Invisible index** 8.0: `ALTER TABLE t ALTER INDEX idx INVISIBLE;` — проверить, нужен ли индекс, не удаляя.
- **Multi-valued index** 8.0.17 для JSON-массивов.
- Online DDL: `ALTER TABLE ... ALGORITHM=INPLACE, LOCK=NONE`; `INSTANT` для `ADD COLUMN` (8.0.12+) и `DROP COLUMN` (8.0.29+).
- Аналог `CREATE INDEX CONCURRENTLY` — `ALGORITHM=INPLACE, LOCK=NONE`; при недоступности — `pt-online-schema-change` или `gh-ost`.

## Репликация и HA

- **binlog** (ROW по умолчанию) + GTID; асинхронная по умолчанию.
- **semi-sync**: master ждёт подтверждения хотя бы одной реплики.
- **Group Replication / InnoDB Cluster**: синхронная multi-master группа (Paxos-подобная), автоматический failover.
- **Clone plugin** — физическая копия инстанса.
- Читающие реплики — только чтение; лаг смотреть `SHOW REPLICA STATUS` (`Seconds_Behind_Source` в 8.0.22+).

## SQL-диалект: перевод с PG

| PostgreSQL | MySQL |
|---|---|
| `SERIAL` / `GENERATED … AS IDENTITY` | `AUTO_INCREMENT` |
| `INSERT … ON CONFLICT DO UPDATE` | `INSERT … ON DUPLICATE KEY UPDATE` |
| `INSERT … RETURNING` | нет (только `LAST_INSERT_ID()`) |
| `LIMIT n OFFSET m` | `LIMIT m, n` (или `LIMIT n OFFSET m`) |
| `boolean` | `TINYINT(1)` |
| `text`, `varchar(n)` | `TEXT`, `VARCHAR(n)`; `utf8mb4` |
| `timestamptz` | `TIMESTAMP` (UTC, 1970–2038) или `DATETIME` (без TZ, 1000–9999) |
| `jsonb` + GIN | `JSON` (бинарь с 5.7) + functional/multi-valued index |
| `NULLS FIRST/LAST` | нет; эмуляция через `ISNULL()` |
| `ILIKE` | `LIKE` с `utf8mb4_0900_ai_ci` (регистронезависимо по collation) |
| `::type` | `CAST(x AS type)` |
| `string_agg` | `GROUP_CONCAT` |
| `DISTINCT ON` | нет; `ROW_NUMBER()` |
| `FILTER (WHERE …)` | `COUNT(IF(cond,1,NULL))` |
| schemas | database = schema (нет отдельной схемы внутри БД) |
| `"identifier"` | `` `identifier` `` |

## Грабли для приходящего с PG

1. **Ждёшь `VACUUM`** — его нет; смотри history list и purge.
2. **Ставишь `READ COMMITTED` «как в PG»** — теряешь защиту от phantom, но получаешь меньше gap locks. Понимай, что меняешь.
3. **Таблица без PK** — InnoDB создаст скрытый row ID, и это хуже для репликации и вторичных индексов.
4. **UUID v4 как PK** — page splits и раздувание; используй `BINARY(16)`, `UUID_TO_BIN(uuid, 1)` (перестановка времени) или auto-increment.
5. **`utf8` — это `utf8mb3`**, не полный UTF-8. Только `utf8mb4`.
6. **`TIMESTAMP` конвертирует в UTC и имеет предел 2038**; для дат вне диапазона — `DATETIME`.
7. **`CHECK` не работал до 8.0.16** — старые схемы могут содержать мусор.
8. **`COUNT(*)` по InnoDB** — такой же скан индекса, как в PG, не «мгновенный».
9. **`ORDER BY` без индекса** на кластерной таблице может быть дороже, чем в PG (нет heap-сканов).
10. **`SELECT … FOR UPDATE` в RR берёт gap locks** — неожиданные блокировки вставок.

## Что проверить руками

```sql
SHOW VARIABLES LIKE 'innodb_page_size';
SHOW VARIABLES LIKE 'transaction_isolation';
SHOW ENGINE INNODB STATUS\G

EXPLAIN ANALYZE SELECT * FROM orders WHERE user_id = 42;
SELECT * FROM sys.schema_unused_indexes;
SELECT * FROM sys.innodb_lock_waits;
```

## Связанное

[[PostgreSQL]] · [[Сравнения/Хранение — heap vs clustered index]] · [[Сравнения/MVCC и очистка мусора]] · [[Сравнения/Изоляция и блокировки]] · [[Другие/MariaDB]] · [[Другие/Практикум/Лаборатория MySQL и SQLite]]

## Источники

- MySQL 8.0/8.4 Reference Manual: InnoDB Storage Engine, Optimization, Replication
- Jeremy Cole, «innodb-diagram» (устройство страниц)
- Percona Blog, «MySQL Performance Blog»
