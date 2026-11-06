-- Лабораторка 03: кардинальность и расширенная статистика
-- Тема: [[Оптимизация/Оценка кардинальности]]
--
--   psql -h localhost -p 5433 -U postgres -d lab -f labs/03-cardinality.sql

SET search_path = lab, public;
\timing on

\echo ''
\echo '=== 1. Что знает статистика о country и locale ==='
SELECT attname, n_distinct, null_frac, correlation,
       most_common_vals, most_common_freqs
FROM pg_stats
WHERE schemaname = 'lab' AND tablename = 'users'
  AND attname IN ('country', 'locale');

\echo ''
\echo '=== 2. Реальная корреляция country → locale ==='
SELECT country, locale, count(*) AS users,
       round(100.0 * count(*) / sum(count(*)) OVER (), 1) AS pct
FROM users
GROUP BY country, locale
ORDER BY country;

\echo ''
\echo '=== 3. Ошибка независимости ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM users WHERE country = 'RU' AND locale = 'ru-RU';
-- Оценка ≈ 0.2 * 0.2 = 4% (4000), реально 20% (20000)

\echo ''
\echo '=== 4. Создаём расширенную статистику ==='
CREATE STATISTICS IF NOT EXISTS st_users_country_locale (dependencies, mcv)
ON country, locale FROM users;

ANALYZE users;

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM users WHERE country = 'RU' AND locale = 'ru-RU';
-- Оценка должна приблизиться к реальности

SELECT e.stxname, e.stxkind,
       d.stxddependencies IS NOT NULL AS has_deps,
       d.stxdmcv          IS NOT NULL AS has_mcv
FROM pg_statistic_ext e
JOIN pg_statistic_ext_data d ON d.stxoid = e.oid
WHERE e.stxname = 'st_users_country_locale';

\echo ''
\echo '=== 5. Детализация гистограммы ==='
SELECT attname, array_length(histogram_bounds::text::text[], 1) AS buckets
FROM pg_stats
WHERE schemaname = 'lab' AND tablename = 'orders' AND attname = 'total';

ALTER TABLE orders ALTER COLUMN total SET STATISTICS 1000;
ANALYZE orders;

SELECT attname, array_length(histogram_bounds::text::text[], 1) AS buckets_after
FROM pg_stats
WHERE schemaname = 'lab' AND tablename = 'orders' AND attname = 'total';

\echo ''
\echo '=== 6. Устаревшая статистика: reltuples ==='
SELECT relname, reltuples, relpages
FROM pg_class WHERE relname IN ('orders','users','events');
-- reltuples = -1 означает «никогда не анализировали»

\echo ''
\echo '=== 7. Проверка на перекошенной колонке status ==='
SELECT attname, n_distinct, most_common_vals, most_common_freqs
FROM pg_stats
WHERE schemaname = 'lab' AND tablename = 'orders' AND attname = 'status';

EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders WHERE status = 'cancelled';   -- 5%
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders WHERE status = 'paid';        -- 80%

\echo ''
\echo '--- Вопросы ---'
\echo '1. Почему PostgreSQL умножает селективности при AND?'
\echo '2. В каких случаях CREATE STATISTICS не поможет?'
\echo '3. Как понять, что планировщик ошибся, а не просто выбрал «плохой» план?'
