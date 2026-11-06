-- Демо-данные для лабораторок по MySQL 8.4.
--
-- Схема повторяет PG-лабораторию (users / orders / events), чтобы результаты
-- можно было сравнивать глазами: те же 100k / 1M / 200k строк, тот же перекос
-- status 80/15/5.
--
-- Отличия намеренные:
--   * DATETIME(6) вместо TIMESTAMP — TIMESTAMP в MySQL упирается в 2038 год;
--   * utf8mb4 везде;
--   * JSON — нативный тип (в MariaDB это был бы LONGTEXT);
--   * внешние ключи не ставим: на 1M строк загрузка дольше, а для лабораторок
--     по планам и блокировкам они не нужны.
--
-- Скрипт выполняется автоматически при первом `docker compose up`
-- (каталог ./init смонтирован в /docker-entrypoint-initdb.d).
-- Первый запуск: 1–3 минуты, дальше данные лежат в volume mysqldata.

USE lab;

SET NAMES utf8mb4;

-- ---------------------------------------------------------------------------
-- nums: 1..1 000 000 — генератор строк вместо generate_series
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS nums;
CREATE TABLE nums (n BIGINT NOT NULL PRIMARY KEY);

DELIMITER $$
CREATE PROCEDURE fill_nums(IN target BIGINT)
BEGIN
  TRUNCATE TABLE nums;
  INSERT INTO nums VALUES (1);
  WHILE (SELECT COUNT(*) FROM nums) < target DO
    SET @half = (SELECT COUNT(*) FROM nums);
    INSERT INTO nums SELECT n + @half FROM nums;
  END WHILE;
  DELETE FROM nums WHERE n > target;
END$$
DELIMITER ;

CALL fill_nums(1000000);
DROP PROCEDURE fill_nums;

-- ---------------------------------------------------------------------------
-- users: 100 000 строк; country и locale коррелируют (для гистограмм)
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS users;
CREATE TABLE users (
  id         BIGINT       NOT NULL AUTO_INCREMENT,
  email      VARCHAR(120) NOT NULL,
  country    CHAR(2)      NOT NULL,
  locale     VARCHAR(10)  NOT NULL,
  is_active  TINYINT(1)   NOT NULL,
  created_at DATETIME(6)  NOT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_email (email),
  KEY idx_users_country_locale (country, locale)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO users (email, country, locale, is_active, created_at)
SELECT CONCAT('user', n, '@example.com'),
       ELT(1 + (n % 5), 'RU', 'US', 'DE', 'BR', 'IN'),
       ELT(1 + (n % 5), 'ru-RU', 'en-US', 'de-DE', 'pt-BR', 'en-IN'),
       (n % 10 <> 0),                                     -- 90% активных
       UTC_TIMESTAMP(6) - INTERVAL FLOOR(RAND() * 63072000) SECOND
FROM nums
WHERE n <= 100000;

-- ---------------------------------------------------------------------------
-- orders: 1 000 000 строк, перекошенный status (80/15/5)
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
  id         BIGINT        NOT NULL AUTO_INCREMENT,
  user_id    BIGINT        NOT NULL,
  status     VARCHAR(16)   NOT NULL,
  total      DECIMAL(12,2) NOT NULL,
  created_at DATETIME(6)   NOT NULL,
  payload    VARCHAR(64)   NULL,
  PRIMARY KEY (id),
  KEY idx_orders_user (user_id),
  KEY idx_orders_created (created_at),
  KEY idx_orders_status_created (status, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO orders (user_id, status, total, created_at, payload)
SELECT 1 + FLOOR(RAND() * 100000),
       CASE
         WHEN RAND() < 0.80 THEN 'paid'
         WHEN RAND() < 0.75 THEN 'new'
         ELSE 'cancelled'
       END,
       ROUND(RAND() * 1000, 2),
       UTC_TIMESTAMP(6) - INTERVAL FLOOR(RAND() * 31536000) SECOND,
       MD5(RAND())
FROM nums;

-- ---------------------------------------------------------------------------
-- events: 200 000 строк с JSON
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS events;
CREATE TABLE events (
  id         BIGINT      NOT NULL AUTO_INCREMENT,
  user_id    BIGINT      NOT NULL,
  kind       VARCHAR(16) NOT NULL,
  data       JSON        NOT NULL,
  created_at DATETIME(6) NOT NULL,
  -- Индексировать JSON напрямую нельзя: нужна generated column
  status     VARCHAR(16) GENERATED ALWAYS AS
               (JSON_UNQUOTE(JSON_EXTRACT(data, '$.status'))) STORED,
  PRIMARY KEY (id),
  KEY idx_events_kind (kind),
  KEY idx_events_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO events (user_id, kind, data, created_at)
SELECT 1 + FLOOR(RAND() * 100000),
       ELT(1 + FLOOR(RAND() * 4), 'click', 'view', 'purchase', 'signup'),
       JSON_OBJECT(
         'status', ELT(1 + FLOOR(RAND() * 3), 'new', 'paid', 'cancelled'),
         'amount', ROUND(RAND() * 500, 2),
         'source', ELT(1 + FLOOR(RAND() * 3), 'web', 'ios', 'android')
       ),
       UTC_TIMESTAMP(6) - INTERVAL FLOOR(RAND() * 15552000) SECOND
FROM nums
WHERE n <= 200000;

-- ---------------------------------------------------------------------------
-- Статистика: без ANALYZE гистограмм не будет, а планы будут «на глазок»
-- ---------------------------------------------------------------------------
ANALYZE TABLE users, orders, events;

DROP TABLE nums;

SELECT 'users' AS t, COUNT(*) AS rows_cnt FROM users
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'events', COUNT(*) FROM events;
