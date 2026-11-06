-- Лабораторка 04: JOIN и work_mem
-- Тема: [[Оптимизация/JOIN-оптимизация]]
--
--   psql -h localhost -p 5433 -U postgres -d lab -f labs/04-joins.sql

SET search_path = lab, public;
\timing on

\echo ''
\echo '=== 1. Таблица без индекса на user_id: hash join ==='
DROP TABLE IF EXISTS j_orders;
CREATE TABLE j_orders AS
SELECT id, user_id, status, total, created_at FROM orders;

ANALYZE j_orders;

EXPLAIN (ANALYZE, BUFFERS)
SELECT u.country, count(*), sum(o.total)
FROM users u
JOIN j_orders o ON o.user_id = u.id
WHERE u.country = 'RU'
GROUP BY u.country;

\echo ''
\echo '=== 2. Индекс на user_id: план может стать nested loop ==='
CREATE INDEX j_orders_user_idx ON j_orders (user_id);
ANALYZE j_orders;

EXPLAIN (ANALYZE, BUFFERS)
SELECT u.country, count(*), sum(o.total)
FROM users u
JOIN j_orders o ON o.user_id = u.id
WHERE u.country = 'RU'
GROUP BY u.country;
-- Сравни: метод join, loops, Buffers

\echo ''
\echo '=== 3. Мало work_mem: hash join уходит на диск ==='
SET work_mem = '64kB';
EXPLAIN (ANALYZE, BUFFERS)
SELECT u.country, count(*)
FROM users u
JOIN j_orders o ON o.user_id = u.id
GROUP BY u.country;
-- Batches > 1, temp read/written

\echo ''
\echo '=== 4. Достаточно work_mem ==='
SET work_mem = '64MB';
EXPLAIN (ANALYZE, BUFFERS)
SELECT u.country, count(*)
FROM users u
JOIN j_orders o ON o.user_id = u.id
GROUP BY u.country;
-- Batches: 1, Memory Usage
RESET work_mem;

\echo ''
\echo '=== 5. Top-3 заказа на пользователя через LATERAL ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT u.id, o.id AS order_id, o.created_at
FROM users u
CROSS JOIN LATERAL (
  SELECT id, created_at
  FROM orders
  WHERE user_id = u.id
  ORDER BY created_at DESC
  LIMIT 3
) o
WHERE u.id <= 500;
-- Nested Loop + Index Scan по (user_id, created_at DESC), без сортировки всей таблицы

\echo ''
\echo '=== 6. Проверка гипотезы: «а если без nested loop?» ==='
SET enable_nestloop = off;
EXPLAIN (ANALYZE, BUFFERS)
SELECT u.country, count(*)
FROM users u
JOIN j_orders o ON o.user_id = u.id
GROUP BY u.country;
RESET enable_nestloop;
-- Это только диагностика. В проде enable_* не трогают.

\echo ''
\echo '=== 7. NOT IN vs NOT EXISTS ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*) FROM users u
WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.user_id = u.id);

\echo ''
\echo '--- Вопросы ---'
\echo '1. Когда nested loop лучше hash join?'
\echo '2. Что означает Batches: 4 и чем это плохо?'
\echo '3. Почему LATERAL с LIMIT быстрее оконной функции?'
