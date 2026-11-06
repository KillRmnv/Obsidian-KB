-- Лабораторка 05: блокировки, lock_timeout, deadlock
-- Тема: [[Внутрянка/Транзакции и блокировки]], [[Внутрянка/Конкурентность на практике]]
--
--   psql -h localhost -p 5433 -U postgres -d lab -f labs/05-locking.sql
--
-- ВАЖНО: скрипт использует dblink, чтобы из одной сессии
-- сымитировать вторую. В реальной жизни это два окна psql.

SET search_path = lab, public;
\set ON_ERROR_STOP off
\timing on

CREATE EXTENSION IF NOT EXISTS dblink;

DROP TABLE IF EXISTS hot;
CREATE TABLE hot (id int PRIMARY KEY, v int NOT NULL DEFAULT 0);
INSERT INTO hot (id) VALUES (1), (2);

\echo ''
\echo '=== 1. Вторая сессия держит строку 10 секунд ==='
SELECT dblink_connect('lab2',
  'host=127.0.0.1 port=5432 dbname=lab user=postgres password=postgres');

SELECT dblink_send_query('lab2',
  'BEGIN; UPDATE lab.hot SET v = v + 1 WHERE id = 1; SELECT pg_sleep(10); COMMIT;');

SELECT pg_sleep(1);

\echo '--- Кто кого блокирует ---'
SELECT pid, pg_blocking_pids(pid) AS blocked_by,
       wait_event_type, wait_event, left(query, 60)
FROM pg_stat_activity
WHERE cardinality(pg_blocking_pids(pid)) > 0;

-- Отменяем «вторую сессию», иначе она будет держать строку ещё 9 секунд
SELECT dblink_cancel_query('lab2');
SELECT dblink_disconnect('lab2');
SELECT pg_sleep(1);

\echo ''
\echo '=== 2. lock_timeout: не ждать вечно ==='
SELECT dblink_connect('lab3',
  'host=127.0.0.1 port=5432 dbname=lab user=postgres password=postgres');
SELECT dblink_send_query('lab3',
  'BEGIN; UPDATE lab.hot SET v = v + 1 WHERE id = 1; SELECT pg_sleep(8); COMMIT;');
SELECT pg_sleep(1);

SET lock_timeout = '2s';
UPDATE hot SET v = v + 1 WHERE id = 1;
-- ERROR: canceling statement due to lock timeout
RESET lock_timeout;

SELECT dblink_cancel_query('lab3');
SELECT dblink_disconnect('lab3');
SELECT pg_sleep(1);

\echo ''
\echo '=== 3. Deadlock: разный порядок строк ==='
SELECT dblink_connect('a',
  'host=127.0.0.1 port=5432 dbname=lab user=postgres password=postgres');
SELECT dblink_connect('b',
  'host=127.0.0.1 port=5432 dbname=lab user=postgres password=postgres');

SELECT dblink_send_query('a',
  'BEGIN; UPDATE lab.hot SET v=v+1 WHERE id=1; SELECT pg_sleep(3); UPDATE lab.hot SET v=v+1 WHERE id=2; COMMIT;');
SELECT dblink_send_query('b',
  'BEGIN; UPDATE lab.hot SET v=v+1 WHERE id=2; SELECT pg_sleep(3); UPDATE lab.hot SET v=v+1 WHERE id=1; COMMIT;');

SELECT pg_sleep(8);
-- Одна из транзакций получит: ERROR: deadlock detected
SELECT pid, state, wait_event_type, wait_event, left(query, 60)
FROM pg_stat_activity
WHERE query LIKE '%lab.hot%';

SELECT dblink_disconnect('a');
SELECT dblink_disconnect('b');

\echo ''
\echo '=== 4. Очередь задач: FOR UPDATE SKIP LOCKED ==='
DROP TABLE IF EXISTS jobs;
CREATE TABLE jobs (
  id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  status     text NOT NULL DEFAULT 'pending',
  created_at timestamptz NOT NULL DEFAULT now()
);
INSERT INTO jobs (status) SELECT 'pending' FROM generate_series(1, 100);

BEGIN;
SELECT id FROM jobs
WHERE status = 'pending'
ORDER BY id
LIMIT 5
FOR UPDATE SKIP LOCKED;
ROLLBACK;
-- Воркеры не ждут друг друга и не берут одну задачу дважды

\echo ''
\echo '=== 5. Блокировки по объектам ==='
SELECT locktype, mode, granted, count(*)
FROM pg_locks
GROUP BY 1, 2, 3
ORDER BY 4 DESC;

\echo ''
\echo '--- Вопросы ---'
\echo '1. Чем Lock отличается от LWLock?'
\echo '2. Почему очередь локов FIFO опасна для DDL?'
\echo '3. Когда приложение должно повторять транзакцию после ошибки сериализации?'
