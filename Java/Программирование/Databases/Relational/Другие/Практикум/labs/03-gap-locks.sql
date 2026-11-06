-- Лабораторка 03: REPEATABLE READ, gap locks и конкурентность
-- Тема: [[Сравнения/Изоляция и блокировки]], [[Другие/MySQL и InnoDB]]
--
--   mysql --raw --force -h 127.0.0.1 -P 3307 -u root -proot lab < labs/03-gap-locks.sql
--
-- Часть шагов требует ВТОРОГО окна mysql — они помечены [окно B].
-- Первое окно (этот скрипт) держит транзакцию и печатает locks;
-- из второго окна видно, что происходит с чужими вставками.

USE lab;

-- ---------------------------------------------------------------------------
-- 0. Уровень изоляции по умолчанию
-- ---------------------------------------------------------------------------
SELECT @@transaction_isolation AS default_isolation;
-- REPEATABLE-READ — в отличие от READ COMMITTED в PostgreSQL.
-- Именно из-за этого в MySQL есть gap locks.

-- Маленькая таблица с «дырами» — на ней gap lock виден отчётливо
DROP TABLE IF EXISTS gap_demo;
CREATE TABLE gap_demo (id INT PRIMARY KEY, v INT NOT NULL DEFAULT 1) ENGINE=InnoDB;
INSERT INTO gap_demo VALUES (10, 1), (20, 1), (30, 1);

-- ---------------------------------------------------------------------------
-- 1. Gap lock: блокируется пустой промежуток
-- ---------------------------------------------------------------------------
START TRANSACTION;

-- Строк в диапазоне нет, но промежуток (10, 20) блокируется
SELECT * FROM gap_demo WHERE id BETWEEN 11 AND 19 FOR UPDATE;

SELECT ENGINE_TRANSACTION_ID AS trx,
       INDEX_NAME,
       LOCK_TYPE,
       LOCK_MODE,
       LOCK_STATUS,
       LOCK_DATA
FROM performance_schema.data_locks
WHERE OBJECT_SCHEMA = 'lab' AND OBJECT_NAME = 'gap_demo'
ORDER BY INDEX_NAME, LOCK_DATA;
-- LOCK_MODE='X,GAP' на LOCK_DATA=20 — заблокирован промежуток до строки 20.
-- LOCK_MODE='X' (next-key) — запись + промежуток перед ней.
-- LOCK_MODE='X,REC_NOT_GAP' — только сама запись.

-- [окно B] вставка внутрь промежутка:
--   INSERT INTO gap_demo VALUES (15, 1);
-- → ERROR 1205 (HY000): Lock wait timeout exceeded
--
-- [окно B] вставка вне промежутка:
--   INSERT INTO gap_demo VALUES (35, 1);
-- → проходит: промежуток после 30 не заблокирован

COMMIT;

-- ---------------------------------------------------------------------------
-- 2. То же на большой таблице: next-key locks на существующих строках
-- ---------------------------------------------------------------------------
START TRANSACTION;

SELECT id, user_id FROM orders WHERE id BETWEEN 200 AND 210 FOR UPDATE;

SELECT INDEX_NAME, LOCK_MODE, LOCK_DATA
FROM performance_schema.data_locks
WHERE OBJECT_SCHEMA = 'lab' AND OBJECT_NAME = 'orders'
ORDER BY LOCK_DATA LIMIT 15;
-- Первая строка диапазона обычно X,REC_NOT_GAP, дальше — X (next-key).
-- В PostgreSQL здесь были бы только блокировки самих строк, без промежутков.

ROLLBACK;

-- ---------------------------------------------------------------------------
-- 3. Отсутствующая строка → gap на supremum
-- ---------------------------------------------------------------------------
START TRANSACTION;

SELECT * FROM gap_demo WHERE id = 999 FOR UPDATE;

SELECT INDEX_NAME, LOCK_MODE, LOCK_DATA
FROM performance_schema.data_locks
WHERE OBJECT_SCHEMA = 'lab' AND OBJECT_NAME = 'gap_demo';
-- LOCK_MODE='X,GAP', LOCK_DATA='supremum pseudo-record' — заблокирован «хвост».
-- [окно B] INSERT INTO gap_demo VALUES (1000, 1);   → будет ждать.
-- В PostgreSQL `SELECT ... FOR UPDATE` по отсутствующей строке не блокирует
-- ничего: нет строки — нет лока. Фантомы ловит только SERIALIZABLE (SSI).

ROLLBACK;

-- ---------------------------------------------------------------------------
-- 4. READ COMMITTED: gap locks почти отключены
-- ---------------------------------------------------------------------------
SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
START TRANSACTION;

SELECT * FROM gap_demo WHERE id BETWEEN 11 AND 19 FOR UPDATE;

SELECT INDEX_NAME, LOCK_MODE, LOCK_DATA
FROM performance_schema.data_locks
WHERE OBJECT_SCHEMA = 'lab' AND OBJECT_NAME = 'gap_demo';
-- Пусто (кроме table IX): промежуток не заблокирован.
-- [окно B] INSERT INTO gap_demo VALUES (15, 1);   → пройдёт, фантом возможен.

ROLLBACK;

SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- ---------------------------------------------------------------------------
-- 5. Deadlock: два окна, разный порядок строк
-- ---------------------------------------------------------------------------
-- [окно A]                              [окно B]
-- BEGIN;                                BEGIN;
-- UPDATE orders SET total = total+1     UPDATE orders SET total = total+1
--  WHERE id = 1;                         WHERE id = 2;
--                                        UPDATE orders SET total = total+1
--                                         WHERE id = 1;   -- ждёт A
-- UPDATE orders SET total = total+1
--  WHERE id = 2;   -- ERROR 1213: Deadlock found
--
-- MySQL обнаруживает deadlock мгновенно (innodb_deadlock_detect=ON),
-- откатывает «дешёвую» транзакцию целиком. Приложение обязано повторить.

-- Что осталось в логе после deadlock:
SHOW ENGINE INNODB STATUS\G
-- смотри секции TRANSACTIONS и LATEST DETECTED DEADLOCK

-- ---------------------------------------------------------------------------
-- 6. Очередь задач: FOR UPDATE SKIP LOCKED (8.0+)
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS jobs;
CREATE TABLE jobs (
  id         BIGINT      NOT NULL AUTO_INCREMENT,
  status     VARCHAR(16) NOT NULL DEFAULT 'pending',
  created_at DATETIME(6) NOT NULL DEFAULT (UTC_TIMESTAMP(6)),
  PRIMARY KEY (id),
  KEY idx_jobs_status (status)
) ENGINE=InnoDB;

INSERT INTO jobs (status) SELECT 'pending' FROM orders WHERE id <= 100;

-- [окно A] забирает 5 задач и «работает» 30 секунд
--   BEGIN;
--   SELECT id FROM jobs WHERE status='pending'
--    ORDER BY id LIMIT 5 FOR UPDATE SKIP LOCKED;
--   SELECT SLEEP(30);
--   COMMIT;
--
-- [окно B] в это время получает СЛЕДУЮЩИЕ 5, а не ждёт
--   BEGIN;
--   SELECT id FROM jobs WHERE status='pending'
--    ORDER BY id LIMIT 5 FOR UPDATE SKIP LOCKED;
--   COMMIT;
--
-- В PostgreSQL механизм тот же (9.5+), но там нет gap locks,
-- поэтому очередь работает без сюрпризов с промежутками.

-- ---------------------------------------------------------------------------
-- 7. Кто кого ждёт (штатные вьюхи)
-- ---------------------------------------------------------------------------
SELECT * FROM sys.innodb_lock_waits\G
SELECT * FROM performance_schema.data_lock_waits\G

-- Таймаут ожидания лока: по умолчанию 50 секунд
SELECT @@innodb_lock_wait_timeout;
SET SESSION innodb_lock_wait_timeout = 2;
-- теперь `UPDATE` чужой строки упадёт через 2 секунды, а не через 50

DROP TABLE IF EXISTS gap_demo;

-- ---------------------------------------------------------------------------
-- Вопросы
-- ---------------------------------------------------------------------------
-- 1. Почему REPEATABLE READ в MySQL защищает от фантомов, а в PG — нет
--    (без SERIALIZABLE)?
-- 2. Чем gap lock хуже для конкурентной вставки, чем SSI в PostgreSQL?
-- 3. Когда `READ COMMITTED` в MySQL — правильный выбор?
-- 4. Почему `SKIP LOCKED` не спасает от deadlock в других запросах?
