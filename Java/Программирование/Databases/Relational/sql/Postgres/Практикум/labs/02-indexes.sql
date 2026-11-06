-- Лабораторка 02: индексы
-- Тема: [[Оптимизация/Индексы на практике]], [[Внутрянка/Индексы изнутри]]
--
--   psql -h localhost -p 5433 -U postgres -d lab -f labs/02-indexes.sql

SET search_path = lab, public;
\timing on

\echo ''
\echo '=== 1. До индекса: Seq Scan по user_id ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, status, total FROM orders WHERE user_id = 4242;

\echo ''
\echo '=== 2. Создаём индекс (в лаборатории можно без CONCURRENTLY) ==='
CREATE INDEX IF NOT EXISTS orders_user_idx ON orders (user_id);
ANALYZE orders;

EXPLAIN (ANALYZE, BUFFERS)
SELECT id, status, total FROM orders WHERE user_id = 4242;
-- Index Scan: стоимость чтения упала, Buffers read меньше

\echo ''
\echo '=== 3. Индекс по status не используется (80% строк) ==='
CREATE INDEX IF NOT EXISTS orders_status_bad_idx ON orders (status);
ANALYZE orders;
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders WHERE status = 'paid';
-- Seq Scan: индекс дороже, чем прочитать всё

\echo ''
\echo '=== 4. Partial index для редкого значения ==='
DROP INDEX IF EXISTS orders_status_bad_idx;
CREATE INDEX IF NOT EXISTS orders_new_idx ON orders (created_at) WHERE status = 'new';
ANALYZE orders;

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders
WHERE status = 'new' AND created_at > now() - interval '30 days';
-- Index Scan по маленькому частичному индексу

\echo ''
\echo '=== 5. Покрывающий индекс и index-only scan ==='
CREATE INDEX IF NOT EXISTS orders_covering_idx ON orders (user_id) INCLUDE (status, total);
ANALYZE orders;

-- VM ещё не обновлена — будут Heap Fetches
EXPLAIN (ANALYZE, BUFFERS)
SELECT user_id, status, total FROM orders WHERE user_id = 4242;

VACUUM orders;

-- после VACUUM: Heap Fetches: 0 (если страницы all-visible)
EXPLAIN (ANALYZE, BUFFERS)
SELECT user_id, status, total FROM orders WHERE user_id = 4242;

\echo ''
\echo '=== 6. Expression index ==='
CREATE INDEX IF NOT EXISTS users_lower_email_idx ON users (lower(email));
ANALYZE users;

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM users WHERE lower(email) = 'user123@example.com';

\echo ''
\echo '=== 7. GIN по jsonb: @> использует индекс, ->> нет ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM events WHERE data @> '{"status":"paid"}';

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM events WHERE data->>'status' = 'paid';

\echo ''
\echo '=== 8. Что мы только что создали ==='
SELECT indexrelname, idx_scan,
       pg_size_pretty(pg_relation_size(indexrelid)) AS size
FROM pg_stat_user_indexes
WHERE relname IN ('orders', 'users')
ORDER BY pg_relation_size(indexrelid) DESC;

\echo ''
\echo '--- Вопросы ---'
\echo '1. Почему index-only scan не работает сразу после создания индекса?'
\echo '2. Почему partial index по status="new" эффективнее полного?'
\echo '3. Чем отличается ключ индекса от INCLUDE?'
