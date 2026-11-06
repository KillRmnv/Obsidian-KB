-- Лабораторка 07: bloat, VACUUM, pgstattuple
-- Тема: [[Внутрянка/VACUUM и autovacuum]], [[Внутрянка/MVCC и версии строк]]
--
--   psql -h localhost -p 5433 -U postgres -d lab -f labs/07-bloat.sql

SET search_path = lab, public;
\timing on

\echo ''
\echo '=== 1. Создаём таблицу на 200 000 строк ==='
DROP TABLE IF EXISTS bloat_demo;
CREATE TABLE bloat_demo AS
SELECT id, user_id, status, total, created_at, payload
FROM orders
LIMIT 200000;

SELECT pg_size_pretty(pg_total_relation_size('bloat_demo')) AS size_before,
       (SELECT count(*) FROM bloat_demo) AS rows_before;

\echo ''
\echo '=== 2. Обновляем ВСЕ строки дважды: MVCC создаёт мёртвые версии ==='
UPDATE bloat_demo SET total = total + 1;
UPDATE bloat_demo SET payload = payload || 'x';

SELECT n_live_tup, n_dead_tup, n_tup_upd, n_tup_hot_upd
FROM pg_stat_user_tables WHERE relname = 'bloat_demo';

SELECT pg_size_pretty(pg_total_relation_size('bloat_demo')) AS size_after_updates;

\echo ''
\echo '=== 3. VACUUM: мусор убран, файл НЕ уменьшился ==='
VACUUM (VERBOSE, ANALYZE) bloat_demo;

SELECT n_live_tup, n_dead_tup
FROM pg_stat_user_tables WHERE relname = 'bloat_demo';

SELECT pg_size_pretty(pg_total_relation_size('bloat_demo')) AS size_after_vacuum;

\echo ''
\echo '=== 4. Точный bloat через pgstattuple ==='
SELECT table_len,
       dead_tuple_count,
       round(dead_tuple_percent::numeric, 2) AS dead_pct,
       round(approx_free_percent::numeric, 2) AS free_pct
FROM pgstattuple_approx('bloat_demo');

\echo ''
\echo '=== 5. VACUUM FULL: перезапись и возврат места ОС (ACCESS EXCLUSIVE) ==='
VACUUM FULL bloat_demo;
SELECT pg_size_pretty(pg_total_relation_size('bloat_demo')) AS size_after_full;

\echo ''
\echo '=== 6. fillfactor и HOT-обновления ==='
DROP TABLE IF EXISTS hot_upd;
CREATE TABLE hot_upd (
  id  int PRIMARY KEY,
  v   text NOT NULL,
  pad text NOT NULL
) WITH (fillfactor = 80);

INSERT INTO hot_upd
SELECT g, 'v' || g, repeat('x', 100)
FROM generate_series(1, 100000) g;

UPDATE hot_upd SET v = v || '+';        -- индексируемая колонка → не HOT
UPDATE hot_upd SET pad = pad || 'y';    -- неиндексируемая → HOT при наличии места

SELECT n_tup_upd, n_tup_hot_upd,
       round(100.0 * n_tup_hot_upd / nullif(n_tup_upd, 0), 1) AS hot_pct
FROM pg_stat_user_tables WHERE relname = 'hot_upd';

\echo ''
\echo '=== 7. Долгая транзакция мешает vacuum ==='
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT count(*) FROM bloat_demo;
-- В другом окне: VACUUM (VERBOSE) bloat_demo;  → мусор не убирается
ROLLBACK;

\echo ''
\echo '--- Вопросы ---'
\echo '1. Почему разметка файла не уменьшилась после VACUUM?'
\echo '2. Что делает fillfactor=80 и почему это включает HOT?'
\echo '3. Почему VACUUM FULL нельзя делать в рабочие часы?'
\echo '4. Как долгая транзакция связана с backend_xmin?'
