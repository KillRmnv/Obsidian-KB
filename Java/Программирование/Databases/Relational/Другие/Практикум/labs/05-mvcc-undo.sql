-- Лабораторка 05: undo, purge, фрагментация и durability
-- Тема: [[Сравнения/MVCC и очистка мусора]], [[Сравнения/Журналы и durability]]
--
--   mysql --raw --force -h 127.0.0.1 -P 3307 -u root -proot lab < labs/05-mvcc-undo.sql
--
-- Часть шагов меняет ГЛОБАЛЬНЫЕ параметры (durability). В конце они
-- возвращаются в исходное состояние, но если скрипт прервался — проверь:
--   SELECT @@innodb_flush_log_at_trx_commit, @@sync_binlog;   -- 1, 1

USE lab;

-- Размеры в information_schema.TABLES кэшируются на 24 часа
SET SESSION information_schema_stats_expiry = 0;

-- ---------------------------------------------------------------------------
-- 1. Где живут старые версии строк
-- ---------------------------------------------------------------------------
SHOW VARIABLES LIKE 'innodb_undo%';
SHOW VARIABLES LIKE 'innodb_redo_log_capacity';
SHOW VARIABLES LIKE 'innodb_flush_log_at_trx_commit';
SHOW VARIABLES LIKE 'sync_binlog';

-- InnoDB не хранит старые версии в таблице (в отличие от PG):
-- UPDATE меняет строку на месте, а прежний образ уходит в undo.
-- Читатель идёт по roll_ptr, пока не найдёт видимую версию.

SELECT name, space_type, ROUND(file_size / 1024 / 1024) AS size_mb
FROM information_schema.INNODB_TABLESPACES
WHERE space_type = 'Undo';
-- Два undo-табличных пространства; они растут при нагрузке на запись
-- и не обязаны уменьшаться после коммита.

-- ---------------------------------------------------------------------------
-- 2. History list length — индикатор «undo не чистится»
-- ---------------------------------------------------------------------------
SELECT NAME, COUNT AS value
FROM information_schema.INNODB_METRICS
WHERE NAME = 'trx_rseg_history_len';

START TRANSACTION;

UPDATE orders SET total = total + 1 WHERE id <= 100000;
UPDATE orders SET total = total + 1 WHERE id <= 100000;

-- Своя транзакция видна в INNODB_TRX; пока она открыта, purge
-- не может выбросить её undo.
SELECT trx_id, trx_state, trx_started,
       TIMESTAMPDIFF(SECOND, trx_started, NOW()) AS age_sec,
       trx_rows_modified, trx_isolation_level
FROM information_schema.INNODB_TRX\G

SELECT NAME, COUNT AS value
FROM information_schema.INNODB_METRICS
WHERE NAME = 'trx_rseg_history_len';

SELECT name, ROUND(file_size / 1024 / 1024) AS size_mb
FROM information_schema.INNODB_TABLESPACES
WHERE space_type = 'Undo';

-- [окно B] в это время:
--   UPDATE orders SET total = total + 1 WHERE id = 5;   -- id <= 100000
--   → будет ждать на строке (X-лок)

COMMIT;

-- После коммита purge догоняет: history list length остаётся маленьким,
-- пока фоновый purge успевает за нагрузкой.
-- Файлы undo при этом не уменьшаются — они переиспользуются.
SELECT NAME, COUNT AS value
FROM information_schema.INNODB_METRICS
WHERE NAME = 'trx_rseg_history_len';

-- Аналог в PG: n_dead_tup и backend_xmin. Симптом другой:
-- в PG пухнет таблица, в InnoDB — undo и история версий.

-- ---------------------------------------------------------------------------
-- 3. Долгая транзакция «держит» purge
-- ---------------------------------------------------------------------------
-- [окно B]
--   BEGIN;
--   SELECT * FROM orders WHERE id = 1;     -- даже обычный SELECT
--   -- ... и не коммитим 10 минут
--   -- параллельно в окне C: UPDATE orders SET total = total + 1 WHERE id BETWEEN 1000 AND 2000;
--
-- Пока B жива, undo от изменений C не может быть выброшен.
-- Смотрим:
SELECT trx_id, trx_started,
       TIMESTAMPDIFF(SECOND, trx_started, NOW()) AS age_sec,
       trx_mysql_thread_id, trx_query
FROM information_schema.INNODB_TRX
ORDER BY trx_started;

-- Правило: `idle in transaction` опасен и в PG, и здесь, но лечится по-разному.

-- ---------------------------------------------------------------------------
-- 4. Фрагментация: DELETE не возвращает место
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS bloat_demo;
CREATE TABLE bloat_demo (id BIGINT PRIMARY KEY, pad CHAR(200) NOT NULL) ENGINE=InnoDB;

INSERT INTO bloat_demo
SELECT id, REPEAT('x', 200) FROM orders WHERE id <= 200000;

ANALYZE TABLE bloat_demo;

SELECT table_rows, data_length, data_free
FROM information_schema.TABLES
WHERE table_schema = 'lab' AND table_name = 'bloat_demo';
-- ~50 МБ на 200k строк по 200 байт

DELETE FROM bloat_demo WHERE id % 10 <> 0;         -- удалили 90%

ANALYZE TABLE bloat_demo;

SELECT table_rows, data_length, data_free
FROM information_schema.TABLES
WHERE table_schema = 'lab' AND table_name = 'bloat_demo';
-- data_length почти не изменился: файл остался выделенным.
-- Освободившиеся страницы лежат внутри tablespace и переиспользуются,
-- но ОС место не возвращается (data_free — грубая оценка экстентов).

OPTIMIZE TABLE bloat_demo;

SELECT table_rows, data_length, data_free
FROM information_schema.TABLES
WHERE table_schema = 'lab' AND table_name = 'bloat_demo';
-- После перестройки data_length падает в разы.
-- Это аналог VACUUM FULL / pg_repack, а не VACUUM.

DROP TABLE bloat_demo;

-- ---------------------------------------------------------------------------
-- 5. Цена durability: два fsync на коммит
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS fsync_demo;
CREATE TABLE fsync_demo (id BIGINT AUTO_INCREMENT PRIMARY KEY, v INT NOT NULL) ENGINE=InnoDB;

DELIMITER $$
CREATE PROCEDURE bench_commits(IN n INT, OUT us BIGINT)
BEGIN
  DECLARE i INT DEFAULT 0;
  DECLARE t0 DATETIME(6);
  SET t0 = NOW(6);
  WHILE i < n DO
    INSERT INTO fsync_demo (v) VALUES (i);
    SET i = i + 1;
  END WHILE;
  SET us = TIMESTAMPDIFF(MICROSECOND, t0, NOW(6));
END$$
DELIMITER ;

-- Параметры durability — ГЛОБАЛЬНЫЕ (SET GLOBAL), не сессионные.
SET GLOBAL innodb_flush_log_at_trx_commit = 1;    -- как synchronous_commit=on
SET GLOBAL sync_binlog = 1;
CALL bench_commits(300, @us_full);
SELECT @us_full AS full_us, ROUND(@us_full / 300 / 1000, 3) AS ms_per_commit;

SET GLOBAL innodb_flush_log_at_trx_commit = 0;    -- без fsync вообще
SET GLOBAL sync_binlog = 0;
CALL bench_commits(300, @us_fast);
SELECT @us_fast AS fast_us, ROUND(@us_fast / 300 / 1000, 3) AS ms_per_commit;

SELECT ROUND(@us_full / NULLIF(@us_fast, 0), 1) AS slowdown_x;
-- На локальном SSD разница в десятки раз: каждый коммит с durability
-- ждёт fsync redo + fsync binlog, без неё — только память.

SET GLOBAL innodb_flush_log_at_trx_commit = 1;
SET GLOBAL sync_binlog = 1;

DROP PROCEDURE bench_commits;

-- В MySQL два журнала (redo + binlog) → два fsync на коммит.
-- В PostgreSQL WAL один, поэтому та же нагрузка обычно даёт меньший latency.

-- ---------------------------------------------------------------------------
-- 6. Buffer pool: попадания и промахи
-- ---------------------------------------------------------------------------
SELECT VARIABLE_VALUE AS read_requests
FROM performance_schema.global_status
WHERE VARIABLE_NAME = 'Innodb_buffer_pool_read_requests';

SELECT
  ROUND(100 * (1 - (
    (SELECT VARIABLE_VALUE FROM performance_schema.global_status WHERE VARIABLE_NAME='Innodb_buffer_pool_reads')
    /
    NULLIF((SELECT VARIABLE_VALUE FROM performance_schema.global_status WHERE VARIABLE_NAME='Innodb_buffer_pool_read_requests'),0)
  )), 2) AS buffer_pool_hit_pct;

-- Это аналог shared hit ratio в PG, но считается иначе:
-- в InnoDB буфер управляет и таблицами, и индексами, и undo.

-- ---------------------------------------------------------------------------
-- 7. Статистика и гистограммы (8.0+)
-- ---------------------------------------------------------------------------
ANALYZE TABLE orders;

SELECT table_name, index_name, stat_name, stat_value
FROM mysql.innodb_index_stats
WHERE database_name = 'lab' AND table_name = 'orders' AND stat_name = 'n_diff_pfx01';

-- Гистограмма по перекошенному status
ANALYZE TABLE orders UPDATE HISTOGRAM ON status WITH 16 BUCKETS;

SELECT column_name, histogram
FROM information_schema.COLUMN_STATISTICS
WHERE schema_name = 'lab' AND table_name = 'orders'\G

EXPLAIN
SELECT * FROM orders WHERE status = 'cancelled';
-- С гистограммой оценка rows ближе к реальным 5%, а не к «треть таблицы».

-- ---------------------------------------------------------------------------
-- Вопросы
-- ---------------------------------------------------------------------------
-- 1. Почему в InnoDB не бывает bloat таблицы в том же смысле, что в PG?
-- 2. Что именно держит history list length и как это увидеть?
-- 3. Почему коммит в MySQL дороже, чем в PostgreSQL, при полной durability?
-- 4. Зачем гистограмма, если есть индекс с cardinality?
