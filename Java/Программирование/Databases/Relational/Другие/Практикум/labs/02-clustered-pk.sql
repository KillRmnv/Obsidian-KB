-- Лабораторка 02: кластерный PK, размер строки и цена случайного ключа
-- Тема: [[Сравнения/Хранение — heap vs clustered index]], [[Другие/MySQL и InnoDB]]
--
--   mysql --raw --force -h 127.0.0.1 -P 3307 -u root -proot lab < labs/02-clustered-pk.sql
--
-- Проверяем на цифрах: автоинкремент vs UUID в качестве PK,
-- сколько занимает таблица, сколько — вторичный индекс, что делает OPTIMIZE.

USE lab;

-- information_schema.TABLES в MySQL 8 кэширует статистику на 24 часа.
-- Без этого «размер таблицы» после DELETE/OPTIMIZE будет старым.
SET SESSION information_schema_stats_expiry = 0;
-- ---------------------------------------------------------------------------
-- 1. Таблица — это B-tree по PK
-- ---------------------------------------------------------------------------

-- Строки физически упорядочены по id: диапазон читается последовательно
EXPLAIN ANALYZE
SELECT * FROM orders WHERE id BETWEEN 100000 AND 100100;

-- А по user_id порядок другой → индекс + россыпь страниц
EXPLAIN ANALYZE
SELECT * FROM orders WHERE user_id = 777 LIMIT 100;

-- Посмотреть, что PRIMARY — кластерный (index_type=BTREE, без «heap»)
SHOW INDEX FROM orders;

-- ---------------------------------------------------------------------------
-- 2. Автоинкремент vs UUID: тот же объём данных, разный размер
-- ---------------------------------------------------------------------------
DROP TABLE IF EXISTS pk_auto;
DROP TABLE IF EXISTS pk_uuid;

CREATE TABLE pk_auto (
  id      BIGINT      NOT NULL AUTO_INCREMENT,
  payload VARCHAR(64) NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB;

CREATE TABLE pk_uuid (
  id      CHAR(36)    NOT NULL,
  payload VARCHAR(64) NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB;

INSERT INTO pk_auto (payload)
SELECT payload FROM orders WHERE id <= 200000;

-- UUID() случаен → вставки идут в середину дерева, страницы расщепляются
INSERT INTO pk_uuid (id, payload)
SELECT UUID(), payload FROM orders WHERE id <= 200000;

ANALYZE TABLE pk_auto, pk_uuid;

SELECT table_name,
       table_rows,
       data_length        AS clustered_bytes,
       index_length       AS secondary_bytes,
       data_free          AS free_bytes,
       ROUND(data_length / NULLIF(table_rows,0)) AS bytes_per_row
FROM information_schema.TABLES
WHERE table_schema = 'lab' AND table_name IN ('pk_auto','pk_uuid')
ORDER BY table_name;

-- Точнее по страницам: size = сколько страниц по 16 КБ занимает индекс
SELECT table_name, index_name, stat_name, stat_value
FROM mysql.innodb_index_stats
WHERE database_name = 'lab'
  AND table_name IN ('pk_auto','pk_uuid')
  AND index_name = 'PRIMARY'
  AND stat_name IN ('size', 'n_leaf_pages')
ORDER BY table_name, stat_name;

-- ---------------------------------------------------------------------------
-- 3. Длинный PK раздувает ВСЕ вторичные индексы
-- ---------------------------------------------------------------------------
ALTER TABLE pk_auto ADD COLUMN note VARCHAR(20) NULL, ADD KEY idx_note (note);
ALTER TABLE pk_uuid ADD COLUMN note VARCHAR(20) NULL, ADD KEY idx_note (note);

UPDATE pk_auto SET note = CONCAT('n', id % 100);
UPDATE pk_uuid SET note = CONCAT('n', CRC32(id) % 100);

ANALYZE TABLE pk_auto, pk_uuid;

SELECT table_name,
       index_name,
       ROUND(stat_value * 16 / 1024) AS size_kb
FROM mysql.innodb_index_stats
WHERE database_name = 'lab'
  AND table_name IN ('pk_auto','pk_uuid')
  AND index_name = 'idx_note'
  AND stat_name = 'size'
ORDER BY table_name;
-- В листе idx_note лежит ключ (note) + PK. У pk_uuid это 36 байт вместо 8,
-- поэтому индекс заметно больше — ровно та же проблема, что в SQL Server.

-- ---------------------------------------------------------------------------
-- 4. Фрагментация и OPTIMIZE (аналог VACUUM FULL / pg_repack)
-- ---------------------------------------------------------------------------
DELETE FROM pk_auto WHERE id % 2 = 0;
DELETE FROM pk_uuid WHERE CRC32(id) % 2 = 0;

-- После массового DELETE размеры в information_schema — оценки,
-- поэтому обновляем статистику перед замером.
ANALYZE TABLE pk_auto, pk_uuid;

SELECT table_name, table_rows, data_length, data_free
FROM information_schema.TABLES
WHERE table_schema = 'lab' AND table_name IN ('pk_auto','pk_uuid');

-- OPTIMIZE TABLE = ALTER TABLE ... FORCE: перестройка, дефрагментация.
-- В MySQL 8.0+ для InnoDB это ONLINE (с оговорками), но всё равно долго
-- и требует свободного места ≈ размер таблицы.
-- Сообщение "Table does not support optimize, doing recreate + analyze instead"
-- для InnoDB — норма, а не ошибка.
OPTIMIZE TABLE pk_auto, pk_uuid;

SELECT table_name, table_rows, data_length, data_free
FROM information_schema.TABLES
WHERE table_schema = 'lab' AND table_name IN ('pk_auto','pk_uuid');

-- ---------------------------------------------------------------------------
-- 5. Вывод в одну строку
-- ---------------------------------------------------------------------------
SELECT 'auto-increment PK: вставка в хвост, компактно, но ключ предсказуем' AS auto_pk
UNION ALL
SELECT 'UUID PK: случайные вставки → split, фрагментация, толстые вторичные индексы';

DROP TABLE IF EXISTS pk_auto;
DROP TABLE IF EXISTS pk_uuid;

-- ---------------------------------------------------------------------------
-- Вопросы
-- ---------------------------------------------------------------------------
-- 1. Почему в InnoDB UUID v4 в роли PK хуже, чем в PostgreSQL?
-- 2. Что произойдёт со вторичными индексами, если PK — varchar(200)?
-- 3. Чем OPTIMIZE TABLE отличается от VACUUM в PG по блокировкам?
-- 4. Какой PK выбрать для таблицы событий: AUTO_INCREMENT, UUID v7 или составной?
