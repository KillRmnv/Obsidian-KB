-- Лабораторка 04: пагинация и антипаттерны запросов
-- Тема: [[Сравнения/Планировщик и диагностика]], [[Оптимизация/Антипаттерны запросов]]
--
--   mysql --raw --force -h 127.0.0.1 -P 3307 -u root -proot lab < labs/04-pagination.sql
--
-- --force нужен, потому что часть шагов намеренно заканчивается ошибкой.

USE lab;

-- ---------------------------------------------------------------------------
-- 1. OFFSET деградирует линейно (как в PG, но синтаксис легче перепутать)
-- ---------------------------------------------------------------------------

EXPLAIN ANALYZE
SELECT * FROM orders ORDER BY id LIMIT 20 OFFSET 900000;
-- Читает и выбрасывает 900 000 строк. Время растёт вместе с OFFSET.

-- MySQL-специфичная запись: LIMIT <offset>, <count>
-- Это НЕ «limit 900000 строк», а «пропустить 900000, взять 20».
EXPLAIN ANALYZE
SELECT * FROM orders ORDER BY id LIMIT 900000, 20;

-- Keyset-пагинация: клиент помнит последний id
EXPLAIN ANALYZE
SELECT * FROM orders WHERE id > 900000 ORDER BY id LIMIT 20;
-- Один диапазонный проход по кластерному индексу — время константное.
-- Требование: стабильный уникальный порядок (id), а не created_at.

-- ---------------------------------------------------------------------------
-- 2. Составной индекс под фильтр + сортировку
-- ---------------------------------------------------------------------------

EXPLAIN ANALYZE
SELECT id, total FROM orders
WHERE status = 'new'
ORDER BY created_at DESC
LIMIT 20;

-- idx_orders_status_created(status, created_at) закрывает и WHERE, и ORDER BY:
-- MySQL идёт по индексу и не делает filesort. В PG для этого тоже нужен
-- индекс с тем же порядком колонок.

-- Но если сортировать по другой колонке — filesort неизбежен:
EXPLAIN ANALYZE
SELECT id, total FROM orders
WHERE status = 'new'
ORDER BY total DESC
LIMIT 20;

-- ---------------------------------------------------------------------------
-- 3. Индекс есть — но помогает ли он?
-- ---------------------------------------------------------------------------

-- COUNT(*) не требует колонок строки: индекс (status, created_at) покрывает,
-- второй поход в кластерный индекс не нужен.
EXPLAIN ANALYZE
SELECT COUNT(*) FROM orders WHERE status = 'paid';

-- А SUM(total) требует total, которого в индексе нет:
-- 800 000 lookup'ов по кластерному индексу, ~2.5 секунды.
EXPLAIN ANALYZE
SELECT SUM(total) FROM orders WHERE status = 'paid';

-- Полный скан той же таблицы — быстрее. Проверяем принудительно:
EXPLAIN ANALYZE
SELECT SUM(total) FROM orders IGNORE INDEX (idx_orders_status_created)
WHERE status = 'paid';
-- Мораль: «есть индекс» ≠ «индекс полезен». MySQL недооценивает
-- стоимость сотен тысяч lookup'ов по PK; в PostgreSQL cost-модель
-- с random_page_cost обычно выбирает скан раньше.

-- Редкое значение — индексу действительно место в плане
EXPLAIN ANALYZE
SELECT COUNT(*) FROM orders WHERE status = 'cancelled';

SELECT status, COUNT(*) AS cnt, ROUND(100 * COUNT(*) / (SELECT COUNT(*) FROM orders), 1) AS pct
FROM orders GROUP BY status ORDER BY cnt DESC;

-- ---------------------------------------------------------------------------
-- 4. ORDER BY RAND(): классика, которая убивает базу
-- ---------------------------------------------------------------------------

EXPLAIN ANALYZE
SELECT * FROM orders ORDER BY RAND() LIMIT 10;
-- Полный скан + сортировка 1M случайных значений на каждый запрос.

-- Дешёвая альтернатива: случайная точка входа + диапазон
SELECT * FROM orders
WHERE id >= (SELECT FLOOR(RAND() * (SELECT MAX(id) FROM orders)))
ORDER BY id
LIMIT 10;

-- ---------------------------------------------------------------------------
-- 5. Неявное приведение типов отключает индекс
-- ---------------------------------------------------------------------------

EXPLAIN
SELECT * FROM users WHERE email = 'user42@example.com';   -- key=uq_users_email

EXPLAIN
SELECT * FROM users WHERE email = 42;
-- type=ALL: MySQL приводит строку к числу (42 → '42'), индекс бесполезен.
-- В PostgreSQL такой запрос просто упал бы с ошибкой типа — это безопаснее.

-- ---------------------------------------------------------------------------
-- 6. NOT IN и NULL — та же ловушка, что в PG
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS t_null;
CREATE TABLE t_null (id INT PRIMARY KEY, v INT NULL);
INSERT INTO t_null VALUES (1, 10), (2, NULL), (3, 30);

SELECT * FROM t_null WHERE id NOT IN (SELECT v FROM t_null);
-- 0 строк: NULL в подзапросе делает сравнение UNKNOWN для всех строк.

SELECT * FROM t_null t
WHERE NOT EXISTS (SELECT 1 FROM t_null x WHERE x.v = t.id);
-- 2 строки — правильный ответ

-- ---------------------------------------------------------------------------
-- 7. Полу-соединение: IN против JOIN
-- ---------------------------------------------------------------------------
EXPLAIN ANALYZE
SELECT COUNT(*) FROM orders
WHERE user_id IN (SELECT id FROM users WHERE country = 'RU');
-- MySQL 8 переписывает в semi-join (semijoin materialization / first-match)

EXPLAIN ANALYZE
SELECT COUNT(*) FROM orders o
JOIN users u ON u.id = o.user_id
WHERE u.country = 'RU';
-- результат тот же, но с JOIN легко случайно размножить строки

-- ---------------------------------------------------------------------------
-- 8. ONLY_FULL_GROUP_BY: MySQL строже PG в одном месте
-- ---------------------------------------------------------------------------
SELECT @@sql_mode;

SELECT user_id, status, COUNT(*) FROM orders GROUP BY user_id;
-- ERROR 1055: Expression #2 of SELECT list is not in GROUP BY clause...
-- В PostgreSQL такого запроса тоже не будет (кроме функциональных зависимостей
-- от PK), но сообщение и поведение исторически различались.

SELECT user_id, COUNT(*) FROM orders GROUP BY user_id ORDER BY COUNT(*) DESC LIMIT 5;

-- ---------------------------------------------------------------------------
-- Вопросы
-- ---------------------------------------------------------------------------
-- 1. Почему keyset-пагинация требует уникального стабильного порядка?
-- 2. Когда индекс по status='paid' всё-таки сработает?
-- 3. Чем `LIMIT 20 OFFSET 900000` отличается от `LIMIT 900000, 20`?
-- 4. Почему `WHERE email = 42` в MySQL опаснее, чем в PostgreSQL?
