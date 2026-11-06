# Лаборатория MySQL и SQLite

Песочница для ветки [[Реляционные СУБД]]: MySQL 8.4 в Docker (тот же датасет, что в PG-лаборатории) и SQLite локальным файлом. Цель — потрогать руками то, чем эти СУБД отличаются от PostgreSQL: кластерный PK, gap locks, undo/purge, диалект, отсутствие сервера.

---

## Что нужно

- Docker + Docker Compose
- клиент `mysql` (или `docker exec -it mysql-lab mysql ...`)
- `sqlite3` для второй части — есть в системе
- ~1 ГБ свободного места (образ + том)

## Структура

```
Другие/Практикум/
├── docker-compose.yml
├── init/
│   └── 01-demo.sql           схема lab + 100k users / 1M orders / 200k events
├── labs/
│   ├── 01-explain.sql        планы, кластерный PK, covering index, JSON
│   ├── 02-clustered-pk.sql   AUTO_INCREMENT vs UUID, размеры, OPTIMIZE
│   ├── 03-gap-locks.sql      REPEATABLE READ, next-key locks, deadlock
│   ├── 04-pagination.sql     OFFSET, keyset, антипаттерны, NOT IN + NULL
│   ├── 05-mvcc-undo.sql      undo/purge, фрагментация, стоимость fsync
│   └── 06-sqlite.sql         PRAGMA, WAL, EXPLAIN QUERY PLAN, STRICT
└── Лаборатория MySQL и SQLite.md   ← эта заметка
```

---

## Запуск

```bash
cd "…/Relational/Другие/Практикум"

docker compose up -d
docker compose ps            # ждём healthy
docker compose logs -f mysql # видно инициализацию и ошибки
```

Первый запуск: образ ~150 МБ + генерация 1,3 млн строк — **1–3 минуты**. Данные создаются один раз и лежат в томе `mysqldata`.

Подключение:

```bash
mysql -h 127.0.0.1 -P 3307 -u root -proot lab
```

Порт **3307**, чтобы не конфликтовать с локальным MySQL (3306) и с PG-лабораторией (5433).

### Проверка, что всё на месте

```sql
SELECT VERSION();                    -- 8.4.x
SELECT @@transaction_isolation;      -- REPEATABLE-READ
SELECT @@character_set_database, @@collation_database;
SELECT @@sql_mode;                   -- ONLY_FULL_GROUP_BY, STRICT_TRANS_TABLES...

SELECT COUNT(*) FROM users;          -- 100 000
SELECT COUNT(*) FROM orders;         -- 1 000 000
SELECT COUNT(*) FROM events;         -- 200 000

SHOW VARIABLES LIKE 'innodb_buffer_pool_size';   -- 256M
SHOW VARIABLES LIKE 'innodb_flush_log_at_trx_commit';  -- 1
```

---

## Управление

```bash
docker compose stop          # остановить (данные живы)
docker compose start         # запустить снова
docker compose down          # удалить контейнер (том с данными жив)
docker compose down -v       # ПОЛНЫЙ СБРОС: удаляет том и данные
docker compose logs -f mysql # логи
```

### Сброс только данных (без пересоздания тома)

```bash
mysql -h 127.0.0.1 -P 3307 -u root -proot \
  -e "DROP DATABASE lab; CREATE DATABASE lab CHARACTER SET utf8mb4;"

mysql -h 127.0.0.1 -P 3307 -u root -proot lab < init/01-demo.sql
```

Init-скрипты из `./init` выполняются **только при пустом томе** — это поведение официального образа, а не этого compose.

### Изменить параметр

```sql
-- сессионно
SET SESSION innodb_lock_wait_timeout = 2;
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;

-- глобально, без рестарта (для динамических параметров)
SET GLOBAL innodb_lock_wait_timeout = 10;

-- требует рестарта: innodb_page_size, innodb_flush_method, innodb_dedicated_server
-- → правь docker-compose.yml и `docker compose up -d`
```

Проверить, динамический ли параметр, проще всего попыткой:

```sql
SET GLOBAL innodb_page_size = 16384;
-- ERROR 1238: Variable 'innodb_page_size' is a read only variable

SET GLOBAL innodb_lock_wait_timeout = 10;   -- работает
```

Учти: `innodb_buffer_pool_size` и `innodb_redo_log_capacity` в 8.x **динамические** —
их можно менять без рестарта (в отличие от старых версий и от `shared_buffers` в PG).

---

## Лабораторки

Все файлы лежат в `labs/` и запускаются с хоста:

```bash
mysql --raw --force -h 127.0.0.1 -P 3307 -u root -proot lab \
  < labs/01-explain.sql
```

`--raw` не экранирует переводы строк (иначе `EXPLAIN ANALYZE` печатает `\n`),
`--force` продолжает после намеренных ошибок (например, `ONLY_FULL_GROUP_BY`
в лабораторке 04).

Если клиента `mysql` на хосте нет — тот же файл через контейнер:

```bash
docker exec -i mysql-lab mysql --raw --force -uroot -proot lab \
  < labs/01-explain.sql
```

| Файл | Тема | Что увидеть |
|---|---|---|
| `01-explain.sql` | [[Сравнения/Планировщик и диагностика]] | `EXPLAIN` vs `EXPLAIN ANALYZE`, `const` по PK, covering index, filesort, JSON-индекс |
| `02-clustered-pk.sql` | [[Сравнения/Хранение — heap vs clustered index]] | размер таблицы и индексов при AUTO_INCREMENT и UUID PK, `data_free`, `OPTIMIZE` |
| `03-gap-locks.sql` | [[Сравнения/Изоляция и блокировки]] | next-key locks в `performance_schema.data_locks`, разница RR и RC |
| `04-pagination.sql` | [[Сравнения/SQL-диалекты и миграция]] | keyset-пагинация, `LIMIT m,n`, `ORDER BY RAND()`, `NOT IN` + NULL |
| `05-mvcc-undo.sql` | [[Сравнения/MVCC и очистка мусора]], [[Сравнения/Журналы и durability]] | history list length, фрагментация, цена `innodb_flush_log_at_trx_commit=1` |
| `06-sqlite.sql` | [[Другие/SQLite]] | PRAGMA, WAL, `EXPLAIN QUERY PLAN`, `STRICT`, `WITHOUT ROWID` |

Полезные команды клиента (аналоги `\d`, `\timing`):

```sql
SHOW TABLES;
SHOW CREATE TABLE orders\G
SHOW INDEX FROM orders;
SHOW ENGINE INNODB STATUS\G
SHOW PROCESSLIST;
SELECT @@profiling;
```

### Лабораторка 03: два окна

Часть шагов требует второго подключения — открой второй терминал:

```bash
mysql -h 127.0.0.1 -P 3307 -u root -proot lab
```

Сценарий: первое окно держит `START TRANSACTION; SELECT ... FOR UPDATE;` по пустому диапазону `gap_demo` (11–19), второе пробует `INSERT INTO gap_demo VALUES (15, 1);` и получает `ERROR 1205 Lock wait timeout exceeded`. Это gap lock — промежуток между строками 10 и 20, которого в PostgreSQL нет. Вставка `id = 35` при этом проходит.

---

## Эксперимент: crash recovery

MySQL пишет redo log и binlog; после `kill -9` он должен восстановиться сам:

```bash
# 1. Записать данные
mysql -h 127.0.0.1 -P 3307 -u root -proot lab -e \
  "INSERT INTO orders (user_id,status,total,created_at) VALUES (1,'new',10,UTC_TIMESTAMP(6));"

# 2. Убить контейнер без graceful shutdown
docker kill -9 mysql-lab

# 3. Запустить снова
docker compose up -d

# 4. В логах — recovery
docker compose logs mysql | grep -iE "recover|redo"
```

Данные на месте: redo доигран с последней контрольной точки. Сравни с `docker compose stop` — там recovery не будет.

Важно: **binlog и redo — разные журналы**. `SHOW BINARY LOG STATUS;` показывает позицию binlog (репликация/PITR), redo в SQL не виден — только через `SHOW ENGINE INNODB STATUS`.

---

## SQLite: без сервера

SQLite не нужен Docker — это файл и библиотека. Упражнения:

```bash
rm -f /tmp/sqlite-lab.db
sqlite3 /tmp/sqlite-lab.db < labs/06-sqlite.sql
```

Что важно увидеть:

| Наблюдение | Смысл |
|---|---|
| `PRAGMA journal_mode = WAL` | читатели не блокируют писателя; на сетевой ФС WAL нельзя |
| `PRAGMA foreign_keys` = 0 | FK объявлены, но **не проверяются**, пока не включишь в соединении |
| `EXPLAIN QUERY PLAN` | `SCAN` / `SEARCH ... USING INDEX` — аналог `EXPLAIN`, но без стоимости |
| `STRICT` | включает проверку типов; без неё `INTEGER` принимает `'abc'` |
| `WITHOUT ROWID` | таблица как B-tree по явному PK (аналог кластерного индекса) |
| `freelist_count` + `VACUUM` | DELETE не уменьшает файл; `VACUUM` перестраивает |
| `PRAGMA optimize` | собирает статистику (`sqlite_stat1`), аналог `ANALYZE` |

Проверить ограничение «один писатель» можно двумя терминалами:

```bash
# окно A
sqlite3 /tmp/sqlite-lab.db
sqlite> BEGIN IMMEDIATE; UPDATE orders SET total = total + 1 WHERE id = 1;

# окно B
sqlite3 /tmp/sqlite-lab.db
sqlite> PRAGMA busy_timeout = 2000;
sqlite> UPDATE orders SET total = total + 1 WHERE id = 1;
# database is locked — через 2 секунды, а не сразу
```

Без `busy_timeout` второе соединение получит `SQLITE_BUSY` мгновенно.

---

## Соответствие командам PostgreSQL

| Задача | PostgreSQL | MySQL |
|---|---|---|
| Подключиться | `psql -p 5433 -U postgres -d lab` | `mysql -P 3307 -u root -p lab` |
| Список таблиц | `\dt` | `SHOW TABLES;` |
| Описание таблицы | `\d orders` | `SHOW CREATE TABLE orders\G` |
| Индексы | `\di` | `SHOW INDEX FROM orders;` |
| Выполнить файл | `\i labs/01.sql` | `SOURCE labs/01.sql;` (или `<` в shell) |
| Тайминг | `\timing on` | `EXPLAIN ANALYZE` / `SET profiling = 1` |
| Кто работает | `pg_stat_activity` | `SHOW PROCESSLIST;` / `performance_schema.threads` |
| Блокировки | `pg_locks` | `performance_schema.data_locks`, `sys.innodb_lock_waits` |
| План | `EXPLAIN (ANALYZE, BUFFERS)` | `EXPLAIN ANALYZE` |
| Размер таблиц | `pg_total_relation_size` | `information_schema.TABLES.data_length` |
| Убить сессию | `pg_terminate_backend(pid)` | `KILL <id>;` |

---

## Если что-то пошло не так

| Проблема | Решение |
|---|---|
| `port is already allocated` | занят 3307 → поменяй в `docker-compose.yml` (`"3308:3306"`) |
| `Can't connect to MySQL server` | контейнер ещё инициализируется: `docker compose ps`, `docker compose logs mysql` |
| init-скрипт упал | смотри лог, затем `docker compose down -v` и повтори (том должен быть пустым) |
| `ERROR 1045 Access denied` | пароль `root`; если менял — правь `MYSQL_ROOT_PASSWORD` |
| клиента `mysql` нет | `docker exec -it mysql-lab mysql -uroot -proot lab` |
| в логах `Disk full` | освободи место; том MySQL растёт от undo и binlog |
| `ERROR 1205 Lock wait timeout` в лабораторке | это ожидаемый результат gap lock, а не поломка |
| данные «пропали» после `down -v` | том удалён — запусти `up -d` заново и подожди инициализацию |

---

## Ограничения песочницы

- Один инстанс: нет реплики, Group Replication и failover. Для них нужен отдельный compose на 3 узла.
- `performance_schema` включён, но `sys`-вьюхи неполные по сравнению с полноценным сервером.
- Дампы/бэкапы не настроены: `mysqldump` есть в образе, PITR требует `log_bin` + архивации binlog (в лаборатории не включена).
- Данные случайны: конкретные цифры планов будут отличаться от заметок — важны порядки величин.
- SQLite-часть не в контейнере: версия CLI зависит от системы (здесь 3.54).

---

## Связанное

[[Реляционные СУБД]] · [[Другие/MySQL и InnoDB]] · [[Другие/MariaDB]] · [[Другие/SQLite]] · [[Сравнения/Хранение — heap vs clustered index]] · [[Сравнения/Изоляция и блокировки]] · [[Сравнения/MVCC и очистка мусора]] · [[Сравнения/Журналы и durability]] · [[Сравнения/SQL-диалекты и миграция]] · [[Лаборатория на Docker]]

## Источники

- MySQL 8.4 Reference Manual: «InnoDB Locking», «InnoDB Multi-Versioning», «Optimizing SQL Statements»
- MySQL Docs: «Server Administration», «Performance Schema»
- SQLite Documentation: «PRAGMA Statements», «EXPLAIN QUERY PLAN», «Write-Ahead Logging»
- Docker Official Image: `mysql` (entrypoint и init-скрипты)
