-- Лабораторка 01: EXPLAIN, кластерный PK и вторичный индекс
-- Тема: [[Сравнения/Хранение — heap vs clustered index]], [[Сравнения/Планировщик и диагностика]]
--
--   mysql --raw --force -h 127.0.0.1 -P 3307 -u root -proot lab < labs/01-explain.sql
--
-- Главное отличие от PG: таблица InnoDB — это B-tree по PRIMARY KEY.
-- Вторичный индекс хранит не адрес строки, а значение PK, поэтому
-- любой lookup по вторичному индексу — это два похода по деревьям.

USE lab;
SET profiling = 0;

-- ---------------------------------------------------------------------------
-- 1. Три формы EXPLAIN
-- ---------------------------------------------------------------------------

-- Классическая таблица (в 8.0 по умолчанию TREE, но табличный вид ещё жив)
EXPLAIN FORMAT=TRADITIONAL
SELECT * FROM orders WHERE id = 42;
-- type=const, key=PRIMARY, rows=1 — кластерный индекс, сразу строка

-- Вторичный индекс: key=idx_orders_user, но Extra пустой.
-- В плане не видно второго шага (PK → кластерный индекс) — он внутри.
EXPLAIN
SELECT * FROM orders WHERE user_id = 42;

-- JSON показывает стоимость и оценку по индексу подробнее
EXPLAIN FORMAT=JSON
SELECT * FROM orders WHERE user_id = 42\G

-- Реальное выполнение (8.0.18+): actual time, loops, rows
EXPLAIN ANALYZE
SELECT * FROM orders WHERE user_id = 42;

-- ---------------------------------------------------------------------------
-- 2. Покрывающий индекс: PK уже внутри вторичного индекса
-- ---------------------------------------------------------------------------

-- Читаем только user_id, и он же — ключ индекса.
-- Extra: Using index → в кластерный индекс не ходим вообще.
EXPLAIN ANALYZE
SELECT user_id FROM orders WHERE user_id BETWEEN 100 AND 200;
-- В PostgreSQL это index-only scan при свежей visibility map;
-- в InnoDB — всегда, потому что PK лежит в листе вторичного индекса.

-- А теперь нужна вся строка → второй поход в кластерный индекс.
EXPLAIN ANALYZE
SELECT * FROM orders WHERE user_id BETWEEN 100 AND 200;

-- ---------------------------------------------------------------------------
-- 3. ORDER BY: где сортировка бесплатна
-- ---------------------------------------------------------------------------

-- По PK: данных не сортируем, лист кластерного индекса уже упорядочен.
EXPLAIN ANALYZE
SELECT * FROM orders ORDER BY id LIMIT 10;

-- По колонке с индексом: обратный проход по idx_orders_created, без filesort.
EXPLAIN ANALYZE
SELECT * FROM orders ORDER BY created_at DESC LIMIT 10;

-- По колонке без индекса: filesort. С LIMIT MySQL использует priority queue,
-- но всё равно читает много строк.
EXPLAIN ANALYZE
SELECT * FROM orders ORDER BY total DESC LIMIT 10;

-- То же в PG было бы Sort (top-N heapsort) — идея та же, но в InnoDB
-- «бесплатный» порядок есть только по PK.

-- ---------------------------------------------------------------------------
-- 4. Функция по колонке убивает индекс (как и в PG)
-- ---------------------------------------------------------------------------

EXPLAIN
SELECT * FROM orders WHERE created_at >= '2026-01-01';

EXPLAIN
SELECT * FROM orders WHERE DATE(created_at) = '2026-01-01';
-- type=ALL, possible_keys=NULL: индекс по created_at неприменим

-- ---------------------------------------------------------------------------
-- 5. JSON: индекс только через generated column
-- ---------------------------------------------------------------------------

-- По сгенерированной колонке status (есть в init) — индекс работает
EXPLAIN ANALYZE
SELECT id, status FROM events WHERE status = 'paid' LIMIT 20;

-- По выражению — полный скан
EXPLAIN ANALYZE
SELECT id FROM events
WHERE JSON_UNQUOTE(JSON_EXTRACT(data, '$.status')) = 'paid'
LIMIT 20;

-- ---------------------------------------------------------------------------
-- 6. Сколько строк реально просмотрено
-- ---------------------------------------------------------------------------
SHOW SESSION STATUS LIKE 'Handler_read%';
-- Handler_read_next — сколько записей прочитано по индексу,
-- Handler_read_rnd_next — полный скан. В PG аналог — Buffers в EXPLAIN.

SHOW SESSION STATUS LIKE 'Innodb_buffer_pool_read%';
-- Физические чтения страниц: аналог shared hit/read в PG

-- ---------------------------------------------------------------------------
-- Вопросы
-- ---------------------------------------------------------------------------
-- 1. Почему `SELECT *` по вторичному индексу дороже, чем `SELECT user_id`?
-- 2. Почему `ORDER BY id` бесплатен, а `ORDER BY created_at` — нет?
-- 3. Что покажет EXPLAIN ANALYZE, если статистика устарела (rows vs actual)?
-- 4. Почему в MySQL нельзя индексировать JSON-путь напрямую?
