-- Лабораторка 06: пагинация OFFSET vs keyset
-- Тема: [[Оптимизация/Антипаттерны запросов]]
--
--   psql -h localhost -p 5433 -U postgres -d lab -f labs/06-pagination.sql

SET search_path = lab, public;
\timing on

\echo ''
\echo '=== 1. Индекс под keyset ==='
CREATE INDEX IF NOT EXISTS orders_created_id_idx
  ON orders (created_at DESC, id DESC);
ANALYZE orders;

\echo ''
\echo '=== 2. OFFSET 500000: читаем и выбрасываем полмиллиона строк ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, user_id, created_at
FROM orders
ORDER BY created_at DESC, id DESC
LIMIT 20 OFFSET 500000;

\echo ''
\echo '=== 3. Keyset: запомнили последнюю строку — идём по индексу ==='
SELECT created_at AS ts, id AS last_id
FROM orders
ORDER BY created_at DESC, id DESC
OFFSET 500000 LIMIT 1
\gset

EXPLAIN (ANALYZE, BUFFERS)
SELECT id, user_id, created_at
FROM orders
WHERE (created_at, id) < (:'ts', :last_id)
ORDER BY created_at DESC, id DESC
LIMIT 20;
-- Index Scan с Limit: читает только 20 строк, а не 500020

\echo ''
\echo '=== 4. Замер «в лоб» ==='
\timing on
SELECT count(*) FROM (
  SELECT id FROM orders ORDER BY created_at DESC, id DESC LIMIT 20 OFFSET 500000
) s;

SELECT count(*) FROM (
  SELECT id FROM orders
  WHERE (created_at, id) < (:'ts', :last_id)
  ORDER BY created_at DESC, id DESC LIMIT 20
) s;

\echo ''
\echo '=== 5. Почему ORDER BY должен совпадать с индексом ==='
EXPLAIN (ANALYZE, BUFFERS)
SELECT id FROM orders ORDER BY created_at ASC LIMIT 20;
-- Для ASC индекс (created_at DESC, id DESC) не подходит → Sort

\echo ''
\echo '--- Вопросы ---'
\echo '1. Почему OFFSET деградирует линейно?'
\echo '2. Зачем уникальный tie-breaker (id) в keyset-пагинации?'
\echo '3. Когда OFFSET всё-таки допустим?'
