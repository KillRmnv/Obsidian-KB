-- Лабораторка 01: как читать EXPLAIN
-- Тема: [[Оптимизация/EXPLAIN и EXPLAIN ANALYZE]]
--
-- Запуск:
--   psql -h localhost -p 5433 -U postgres -d lab -f labs/01-explain.sql

SET search_path = lab, public;
\timing on

\echo ''
\echo '=== 1. EXPLAIN без ANALYZE: только оценка планировщика ==='
EXPLAIN
SELECT * FROM orders WHERE status = 'paid';

\echo ''
\echo '=== 2. То же с ANALYZE + BUFFERS: реальные строки, время, страницы ==='
EXPLAIN (ANALYZE, BUFFERS, SETTINGS)
SELECT * FROM orders WHERE status = 'paid';
-- 80% строк → Seq Scan. Это нормально: индекс по status бесполезен.

\echo ''
\echo '=== 3. Селективный фильтр: оценка vs реальность ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders WHERE user_id = 500 AND status = 'paid';
-- Смотрим rows (оценка) и actual rows. Если расходятся >10x — проблема статистики.

\echo ''
\echo '=== 4. Rows Removed by Filter: работа вхолостую ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders WHERE payload LIKE '%abc%';
-- Seq Scan + много Rows Removed by Filter. Так выглядит отсутствие индекса.

\echo ''
\echo '=== 5. loops: время узла = actual time * loops ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT count(*)
FROM users u
JOIN orders o ON o.user_id = u.id
WHERE u.country = 'RU';
-- Если Nested Loop — смотрим loops у внутреннего узла.

\echo ''
\echo '=== 6. work_mem и внешняя сортировка ==='
SET work_mem = '64kB';
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders ORDER BY payload LIMIT 10;
-- Sort Method: external merge  Disk: …kB

SET work_mem = '64MB';
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders ORDER BY payload LIMIT 10;
-- Sort Method: quicksort  Memory: …kB
RESET work_mem;

\echo ''
\echo '=== 7. JIT: помогает или мешает? ==='
SET jit = off;
EXPLAIN (ANALYZE, BUFFERS) SELECT count(*) FROM orders;
RESET jit;
EXPLAIN (ANALYZE, BUFFERS) SELECT count(*) FROM orders;

\echo ''
\echo '--- Вопросы ---'
\echo '1. Почему cost нельзя сравнивать между разными запросами?'
\echo '2. Где в плане видно, что не хватило work_mem?'
\echo '3. Почему actual time у узла с loops=1000 надо умножать на 1000?'
