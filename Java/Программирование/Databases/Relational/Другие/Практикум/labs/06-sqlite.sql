-- Лабораторка 06: SQLite — типы, WAL, план запроса
-- Тема: [[Другие/SQLite]], [[Сравнения/SQL-диалекты и миграция]]
--
-- Запуск (sqlite3 CLI, не MySQL):
--   rm -f /tmp/sqlite-lab.db
--   sqlite3 /tmp/sqlite-lab.db < labs/06-sqlite.sql
--
-- SQLite не нужен сервер: файл и есть база. Все PRAGMA — настройки
-- конкретного соединения/файла, а не глобального сервера.

.bail off
.timer on

-- ---------------------------------------------------------------------------
-- 1. Режим журнала и durability
-- ---------------------------------------------------------------------------
PRAGMA journal_mode;          -- delete (rollback journal) по умолчанию
PRAGMA journal_mode = WAL;    -- читатели не блокируют писателя
PRAGMA journal_mode;          -- wal
PRAGMA synchronous;           -- 2 = FULL
PRAGMA synchronous = NORMAL;  -- в WAL: fsync на checkpoint, не на коммит
PRAGMA busy_timeout = 5000;   -- ждать вместо мгновенного SQLITE_BUSY
PRAGMA foreign_keys;          -- 0 — ВЫКЛЮЧЕНЫ по умолчанию

-- ---------------------------------------------------------------------------
-- 2. Внешние ключи по умолчанию не проверяются
-- ---------------------------------------------------------------------------
CREATE TABLE parent (id INTEGER PRIMARY KEY);
CREATE TABLE child (
  id        INTEGER PRIMARY KEY,
  parent_id INTEGER REFERENCES parent(id)
);

INSERT INTO child (id, parent_id) VALUES (1, 999);   -- проходит!
SELECT COUNT(*) AS orphans FROM child;

PRAGMA foreign_keys = ON;
INSERT INTO child (id, parent_id) VALUES (2, 999);   -- FOREIGN KEY constraint failed
DELETE FROM child;

-- ---------------------------------------------------------------------------
-- 3. 200 000 строк и план запроса
-- ---------------------------------------------------------------------------
CREATE TABLE orders (
  id         INTEGER PRIMARY KEY,
  user_id    INTEGER NOT NULL,
  status     TEXT    NOT NULL,
  total      NUMERIC NOT NULL,
  created_at TEXT    NOT NULL
);

WITH RECURSIVE c(n) AS (
  SELECT 1
  UNION ALL
  SELECT n + 1 FROM c WHERE n < 200000
)
INSERT INTO orders (id, user_id, status, total, created_at)
SELECT n,
       1 + (abs(random()) % 1000),
       CASE WHEN abs(random()) % 100 < 80 THEN 'paid'
            WHEN abs(random()) % 100 < 95 THEN 'new'
            ELSE 'cancelled' END,
       round(abs(random()) % 100000 / 100.0, 2),
       datetime('2025-01-01', '+' || (abs(random()) % 31536000) || ' seconds')
FROM c;

ANALYZE;

-- Полный скан: индекса по user_id нет
EXPLAIN QUERY PLAN
SELECT * FROM orders WHERE user_id = 42;
-- SCAN orders

CREATE INDEX idx_orders_user ON orders(user_id);

EXPLAIN QUERY PLAN
SELECT * FROM orders WHERE user_id = 42;
-- SEARCH orders USING INDEX idx_orders_user (user_id=?)

-- Покрывающий индекс: строка таблицы не нужна
CREATE INDEX idx_orders_user_created ON orders(user_id, created_at);

EXPLAIN QUERY PLAN
SELECT created_at FROM orders WHERE user_id = 42;
-- SEARCH orders USING COVERING INDEX idx_orders_user_created (user_id=?)

-- Порядок в SQLite: таблица — B-tree по rowid, поэтому ORDER BY id бесплатен
EXPLAIN QUERY PLAN
SELECT * FROM orders ORDER BY id LIMIT 10;
-- SCAN orders — rowid и так упорядочен, сортировки нет

EXPLAIN QUERY PLAN
SELECT * FROM orders ORDER BY total DESC LIMIT 10;
-- SCAN orders USING INDEX ... + USE TEMP B-TREE FOR ORDER BY (при отсутствии индекса)

-- Partial index — редкость среди СУБД, в PG тоже есть
CREATE INDEX idx_orders_new ON orders(created_at) WHERE status = 'new';

EXPLAIN QUERY PLAN
SELECT * FROM orders WHERE status = 'new' ORDER BY created_at DESC LIMIT 10;
-- SCAN orders USING INDEX idx_orders_new — партиальный индекс и фильтрует,
-- и даёт порядок, без TEMP B-TREE

-- ---------------------------------------------------------------------------
-- 4. WITHOUT ROWID: таблица как B-tree по явному PK
-- ---------------------------------------------------------------------------
CREATE TABLE kv (
  k TEXT PRIMARY KEY,
  v TEXT
) WITHOUT ROWID;

INSERT INTO kv VALUES ('a', '1'), ('b', '2');

EXPLAIN QUERY PLAN SELECT v FROM kv WHERE k = 'a';
-- SEARCH kv USING PRIMARY KEY (k=?) — без скрытого rowid и без второго шага

-- ---------------------------------------------------------------------------
-- 5. Типы: динамическая типизация и STRICT
-- ---------------------------------------------------------------------------
CREATE TABLE t_loose (
  id      INTEGER,
  int_col INTEGER,
  text_col TEXT
);

INSERT INTO t_loose VALUES (1, 'abc', 123);

SELECT typeof(id) AS t_id,
       typeof(int_col) AS t_int,
       typeof(text_col) AS t_text,
       int_col, text_col
FROM t_loose;
-- INTEGER affinity не смог привести 'abc' → хранится TEXT.
-- VARCHAR(10) в SQLite длину НЕ ограничивает.

CREATE TABLE t_strict (
  id      INTEGER PRIMARY KEY,
  int_col INTEGER,
  text_col TEXT
) STRICT;

INSERT INTO t_strict VALUES (1, 'abc', 'ok');
-- Runtime error: cannot store TEXT value in INTEGER column t_strict.int_col

-- ---------------------------------------------------------------------------
-- 6. Даты — это строки
-- ---------------------------------------------------------------------------
SELECT created_at FROM orders LIMIT 3;

SELECT COUNT(*) AS in_january
FROM orders
WHERE created_at >= '2025-01-01' AND created_at < '2025-02-01';
-- Работает только потому, что ISO-8601 сравнивается лексикографически.
-- Хранить дату как '01.02.2025' — значит потерять и индекс, и сравнения.

EXPLAIN QUERY PLAN
SELECT COUNT(*) FROM orders
WHERE created_at >= '2025-01-01' AND created_at < '2025-02-01';

-- ---------------------------------------------------------------------------
-- 7. DELETE не возвращает место
-- ---------------------------------------------------------------------------
PRAGMA page_count;
PRAGMA freelist_count;

DELETE FROM orders WHERE id % 10 <> 0;

PRAGMA freelist_count;    -- свободные страницы выросли
PRAGMA page_count;        -- файл не уменьшился

VACUUM;                   -- перестройка файла (нужно ~столько же места)
PRAGMA freelist_count;

PRAGMA integrity_check;
PRAGMA quick_check;
PRAGMA optimize;

-- ---------------------------------------------------------------------------
-- Вопросы
-- ---------------------------------------------------------------------------
-- 1. Почему `PRAGMA foreign_keys` нужно включать в каждом соединении?
-- 2. Чем WAL в SQLite отличается от WAL в PostgreSQL?
-- 3. Почему один писатель — это архитектурное решение, а не баг?
-- 4. Что произойдёт, если положить файл SQLite на NFS?
