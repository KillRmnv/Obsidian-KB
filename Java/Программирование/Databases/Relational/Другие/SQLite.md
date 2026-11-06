# SQLite

## Если знаешь PostgreSQL (TL;DR)

1. **Нет сервера.** База — один файл, который открывает библиотека внутри процесса. Нет процессов, `pg_stat_activity`, сокетов и сети (по умолчанию).
2. **Один писатель на всю базу.** Запись сериализуется, даже если приложение многопоточное. В WAL-режиме читатели не мешают писателю, но писатель по-прежнему один.
3. **Нет типов в привычном смысле** — динамическая типизация по «type affinity». `INSERT INTO t(int_col) VALUES ('abc')` работает, если нет `STRICT`-таблицы.
4. **Нет MVCC в смысле версий строк** — старые данные перезаписываются; стабильность чтения обеспечивают блокировки файла или WAL.
5. **Нет `VACUUM` в смысле PG** — но `VACUUM` есть и делает другое: перестраивает файл, убирая фрагментацию.

## Ниша

Мобильные приложения (Android/iOS), desktop (браузеры, мессенджеры), embedded, тесты, edge/IoT, локальный кэш. SQLite — **самая распространённая СУБД в мире** по числу установок. Версия 3.

Для серверного веба SQLite подходит, пока запись невысокая: блог, форум, аналитика на чтение.

## Хранение

| | PostgreSQL | SQLite |
|---|---|---|
| Единица | 8 КБ страница в файле | страница 512–65536 Б (обычно 4096) |
| Файлы | PGDATA: heap, индексы, WAL, каталог | **один `.db`-файл** (+ `-wal`, `-shm` при WAL) |
| Таблица | heap + отдельные индексы | **B-tree по `rowid`** (аналог clustered index) |
| Адрес строки | `ctid` | `rowid` (64-бит), `INTEGER PRIMARY KEY` = алиас rowid |
| Вторичный индекс | `ctid` → heap | `rowid` → таблица |
| Длинные значения | TOAST | overflow pages (как в MySQL) |
| Мусор | dead tuples + `VACUUM` | free pages + `VACUUM` (перестройка файла) |
| Сжатие | TOAST pglz/lz4 | нет |

- Таблица **всегда** кластерная по `rowid`. `WITHOUT ROWID` — таблица как B-tree по явному PK (аналог MySQL clustered index, но без скрытого rowid).
- `AUTOINCREMENT` — не «автоинкремент» в привычном смысле, а запрет переиспользования rowid; использует таблицу `sqlite_sequence` и медленнее, чем просто `INTEGER PRIMARY KEY`.
- `STRICT`-таблицы (3.37+) — включают проверку типов, приближая поведение к обычной СУБД.

## Транзакции и конкурентность

**Два режима журналирования:**

| | rollback journal (default) | WAL |
|---|---|---|
| Читатели во время записи | блокируются | **не блокируются** |
| Файлы | `-journal` | `-wal`, `-shm` |
| Одновременные читатели | да (shared lock) | да |
| Писателей | один | один |
| Сеть/сетевые ФС | работает | **не работает надёжно** |

- Уровни блокировок: `SHARED` → `RESERVED` → `EXCLUSIVE` (rollback journal); в WAL — через `-shm`.
- `BEGIN IMMEDIATE` сразу берёт write-lock (лучше для конкурентных писателей: не будет `SQLITE_BUSY` на коммите).
- `busy_timeout` — ждать вместо мгновенного `SQLITE_BUSY`.
- **Изоляция — фактически serializable**: один писатель + снапшот читателя.
- `PRAGMA journal_mode=WAL;` — обязательный первый шаг для веба.

```sql
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;     -- 0=OFF, 1=NORMAL, 2=FULL, 3=EXTRA
PRAGMA busy_timeout = 5000;
PRAGMA foreign_keys = ON;        -- по умолчанию ВЫКЛЮЧЕНЫ!
```

`synchronous`:

- `FULL` — fsync на каждый коммит (медленно, как `synchronous_commit=on`);
- `NORMAL` (в WAL) — fsync при checkpoint; при падении ОС можно потерять последние коммиты (аналог `synchronous_commit=off`);
- `OFF` — не безопасно.

## Журнал и durability

- **Rollback journal**: перед изменением страницы старая копия пишется в `-journal`; при откате — восстанавливается. Аналог undo, но на уровне страниц.
- **WAL**: изменения пишутся в `-wal`, checkpoint переносит их в основной файл. Читатели видят снапшот WAL.
- Нет отдельного процесса checkpoint — его делает кто угодно (по умолчанию при 1000 страниц WAL), либо `PRAGMA wal_checkpoint(TRUNCATE)`.
- Нет архивации WAL и PITR «из коробки» — бэкап это `VACUUM INTO` или `.backup` (SQLite Online Backup API).

## Диагностика

```sql
EXPLAIN QUERY PLAN SELECT * FROM orders WHERE user_id = 42;
-- SEARCH orders USING INDEX idx_orders_user (user_id=?)

EXPLAIN SELECT ...;              -- байткод VDBE, не план
PRAGMA index_list('orders');
PRAGMA index_info('idx_orders_user');
PRAGMA table_info('orders');
PRAGMA integrity_check;
PRAGMA quick_check;
PRAGMA page_count;
PRAGMA freelist_count;           -- свободные страницы (аналог bloat)
```

- **Нет `pg_stat_statements`** — статистику собирают из приложения или через `sqlite3_stmt_status`.
- `PRAGMA optimize` (3.18+) — собирает статистику для планировщика (`sqlite_stat1`), запускать периодически.
- `ANALYZE` есть, но статистика грубее, чем в PG.

`.timer on`, `.eqp on` в CLI.

## Индексы

- B-tree; **partial indexes** есть (`WHERE status='new'`) — редкость среди СУБД.
- **Expression indexes** есть (`CREATE INDEX ON t(lower(email))`).
- Нет GIN/GiST/BRIN; для поиска — **FTS5** (полнотекстовый виртуальный модуль) и **R-Tree** (геометрия).
- Нет `CREATE INDEX CONCURRENTLY` — индекс строится с блокировкой записи; для больших таблиц — в миграции/оффлайн.
- `INDEXED BY` — подсказка, какой индекс использовать (аналог hints).

## SQL-диалект: перевод с PG

| PostgreSQL | SQLite |
|---|---|
| `SERIAL` / identity | `INTEGER PRIMARY KEY` (= rowid) |
| `ON CONFLICT DO UPDATE` | `ON CONFLICT DO UPDATE` (3.24+) — синтаксис почти совпадает |
| `RETURNING` | `RETURNING` (3.35+) |
| `LIMIT n OFFSET m` | `LIMIT n OFFSET m` (совпадает) |
| `boolean` | `INTEGER` 0/1 (нет типа boolean) |
| `text`, `varchar(n)` | `TEXT` (длина не проверяется) |
| `timestamptz` | `TEXT` ISO-8601 / `INTEGER` unix epoch / `REAL` julian day |
| `jsonb` | `TEXT` + JSON1 (`json_extract`, `->>`, `json_each`) |
| `LATERAL` | нет (коррелированные подзапросы есть) |
| `string_agg` | `group_concat` |
| `::type` | `CAST(x AS type)` |
| `ILIKE` | `LIKE` (по умолчанию регистронезависим для ASCII) |
| схемы | `ATTACH DATABASE` вместо схем |
| `"identifier"` | `"identifier"` / `[identifier]` / `` `identifier` `` |

## Грабли для приходящего с PG

1. **`PRAGMA foreign_keys` выключен по умолчанию.** FK объявлены, но не проверяются, пока не включишь.
2. **`PRAGMA journal_mode=WAL` не персистентен для `:memory:`** и требует `busy_timeout`.
3. **Один писатель.** «Database is locked» — это не баг, а архитектура. Лечится `busy_timeout` + короткие транзакции + `BEGIN IMMEDIATE`.
4. **SQLite на сетевой ФС (NFS/SMB) — источник порчи данных.** Только локальный диск.
5. **Нет настоящих типов**: `VARCHAR(10)` не ограничивает длину, `INT` принимает `'abc'`. Нужен `STRICT`.
6. **`COUNT(*)` — полный скан**, как в PG; но таблицы обычно маленькие.
7. **`ALTER TABLE` ограничен**: `DROP COLUMN` (3.35+), `RENAME COLUMN`, `ADD COLUMN`; смена типа — только пересоздание таблицы.
8. **Даты — строки.** Сравнение работает лексикографически только для ISO-8601.
9. **`VACUUM` перестраивает весь файл** и требует свободного места ≈ размер БД; в WAL-режиме — не блокирует читателей.
10. **Нет пользователей и прав** — безопасность на уровне файловой системы.

## Что проверить руками

```sql
PRAGMA journal_mode;
PRAGMA foreign_keys;
PRAGMA page_size;
PRAGMA freelist_count;

EXPLAIN QUERY PLAN SELECT * FROM orders WHERE user_id = 42;

CREATE TABLE t (id INTEGER PRIMARY KEY, v TEXT) STRICT;
INSERT INTO t (v) VALUES ('abc');
INSERT INTO t (id) VALUES ('not a number');   -- ошибка только в STRICT
```

## Связанное

[[PostgreSQL]] · [[Сравнения/Хранение — heap vs clustered index]] · [[Сравнения/MVCC и очистка мусора]] · [[Сравнения/SQL-диалекты и миграция]] · [[Другие/Встраиваемые для JVM]] · [[Другие/Практикум/Лаборатория MySQL и SQLite]]

## Источники

- SQLite Documentation: «Distinctive Features», «Write-Ahead Logging», «Query Planner»
- «SQLite: Past, Present, and Future» (VLDB 2022)
- «Using SQLite» (Jay A. Kreibich)
