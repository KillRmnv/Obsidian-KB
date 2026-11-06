# SQL-диалекты и миграция

## Зачем это нужно

Перенос приложения с PostgreSQL на другую СУБД (или наоборот) ломается не на «SELECT», а на мелочах: `NULL` vs `''`, upsert, пагинация, типы дат, идентификаторы, `RETURNING`, JSON. Здесь — таблица перевода и список мест, где миграция обычно рвётся.

## Шпаргалка по конструкциям

| Задача | PostgreSQL | MySQL | SQL Server | Oracle | SQLite |
|---|---|---|---|---|---|
| Автоинкремент | `GENERATED … AS IDENTITY`, `serial` | `AUTO_INCREMENT` | `IDENTITY(1,1)` | `GENERATED … AS IDENTITY` (12c+) | `INTEGER PRIMARY KEY` |
| Upsert | `ON CONFLICT DO UPDATE` | `ON DUPLICATE KEY UPDATE` | `MERGE` | `MERGE` | `ON CONFLICT DO UPDATE` |
| Вернуть вставленное | `RETURNING` | `LAST_INSERT_ID()` | `OUTPUT INSERTED.*` | `RETURNING … INTO` | `RETURNING` (3.35+) |
| Пагинация | `LIMIT n OFFSET m` | `LIMIT m, n` / `LIMIT n OFFSET m` | `OFFSET m ROWS FETCH NEXT n ROWS ONLY`, `TOP n` | `FETCH FIRST n ROWS ONLY`, `OFFSET … FETCH` | `LIMIT n OFFSET m` |
| Boolean | `boolean` | `TINYINT(1)` | `bit` | нет — `NUMBER(1)`/`CHAR(1)` | `INTEGER` 0/1 |
| Деньги | `numeric(12,2)` | `DECIMAL(12,2)` | `decimal(12,2)` / `money` | `NUMBER(12,2)` | `NUMERIC` |
| Дата+время с TZ | `timestamptz` | `TIMESTAMP` (UTC, до 2038) / `DATETIME` | `datetimeoffset` | `TIMESTAMP WITH TIME ZONE` | `TEXT` ISO / `INTEGER` epoch |
| UUID | `uuid` (нативно) | `BINARY(16)` / `CHAR(36)` | `uniqueidentifier` | `RAW(16)` / `VARCHAR2(36)` | `TEXT`/`BLOB` |
| JSON | `jsonb` + GIN | `JSON` + generated column | `nvarchar(max)` + `JSON_VALUE` | `JSON` (21c) / `CLOB` | `TEXT` + JSON1 |
| Массив | `int[]`, `text[]` | нет (JSON) | нет (JSON/таблица) | нет (nested table/JSON) | нет |
| Строковая агрегация | `string_agg(x, ',')` | `GROUP_CONCAT` | `STRING_AGG` | `LISTAGG` | `group_concat` |
| Приведение типа | `x::int`, `CAST` | `CAST` | `CAST`/`TRY_CAST` | `CAST` | `CAST` |
| ILIKE | `ILIKE` | `LIKE` (ci collation) | `LIKE` (ci collation) | `UPPER() LIKE` | `LIKE` (ASCII ci) |
| Схемы | есть (`public`) | database = schema | есть (`dbo`) | user = schema | нет (ATTACH) |
| Кавычки идентификатора | `"x"` | `` `x` `` | `[x]` | `"x"` (upper-case) | `"x"` |

## NULL и пустая строка

| | `''` | `NULL` |
|---|---|---|
| PostgreSQL | пустая строка | NULL |
| MySQL | пустая строка | NULL |
| SQL Server | пустая строка (но `'a' = 'a '` — TRUE!) | NULL |
| Oracle | **NULL** | NULL |
| SQLite | пустая строка | NULL |

Следствия:

```sql
-- Oracle: вставит NULL и упадёт на NOT NULL
INSERT INTO users (name) VALUES ('');

-- PostgreSQL: NOT IN + NULL = пустой результат (везде, кроме...)
SELECT * FROM users WHERE id NOT IN (SELECT user_id FROM orders);
-- если в orders.user_id есть NULL → 0 строк
```

**Правило:** всегда используй `NOT EXISTS` вместо `NOT IN`, если есть шанс NULL.

## Строки и сравнение

- **SQL Server** игнорирует хвостовые пробелы при сравнении: `'a' = 'a   '` → TRUE. В PG — FALSE.
- **SQL Server/MySQL** часто регистронезависимы по collation; в PG — зависит от collation (`C` → регистрозависимо).
- **MySQL `utf8` = `utf8mb3`**; полный UTF-8 — `utf8mb4`.
- **Oracle** пустая строка = NULL (см. выше).
- **PostgreSQL** `LIKE` чувствителен к регистру; `ILIKE` — нет.

## Пагинация

```sql
-- PostgreSQL / SQLite
SELECT * FROM orders ORDER BY created_at DESC LIMIT 20 OFFSET 100000;

-- MySQL: сначала offset, потом limit (легко перепутать!)
SELECT * FROM orders ORDER BY created_at DESC LIMIT 100000, 20;

-- SQL Server
SELECT * FROM orders ORDER BY created_at DESC
OFFSET 100000 ROWS FETCH NEXT 20 ROWS ONLY;

-- Oracle
SELECT * FROM orders ORDER BY created_at DESC
OFFSET 100000 ROWS FETCH NEXT 20 ROWS ONLY;
```

Во всех случаях `OFFSET` деградирует линейно — используй keyset (см. [[Оптимизация/Антипаттерны запросов]]).

## Upsert

```sql
-- PostgreSQL / SQLite
INSERT INTO users (email, name) VALUES ($1, $2)
ON CONFLICT (email) DO UPDATE SET name = EXCLUDED.name;

-- MySQL
INSERT INTO users (email, name) VALUES (?, ?)
ON DUPLICATE KEY UPDATE name = VALUES(name);
-- MySQL 8.0.20+: ... AS new ON DUPLICATE KEY UPDATE name = new.name

-- SQL Server / Oracle
MERGE INTO users u
USING (SELECT ? AS email, ? AS name FROM dual) s
ON (u.email = s.email)
WHEN MATCHED THEN UPDATE SET u.name = s.name
WHEN NOT MATCHED THEN INSERT (email, name) VALUES (s.email, s.name);
```

`MERGE` в SQL Server имеет известные баги при конкурентности; в PG `ON CONFLICT` надёжнее.

## Типы: на что менять

| PG | MySQL | SQL Server | Oracle |
|---|---|---|---|
| `text` | `TEXT` (`utf8mb4`) | `nvarchar(max)` | `VARCHAR2(4000)` / `CLOB` |
| `varchar(n)` | `VARCHAR(n)` | `nvarchar(n)` | `VARCHAR2(n CHAR)` |
| `int` | `INT` | `int` | `NUMBER(10)` |
| `bigint` | `BIGINT` | `bigint` | `NUMBER(19)` |
| `numeric(p,s)` | `DECIMAL(p,s)` | `decimal(p,s)` | `NUMBER(p,s)` |
| `boolean` | `TINYINT(1)` | `bit` | `NUMBER(1)` |
| `timestamptz` | `TIMESTAMP` (2038!) | `datetimeoffset` | `TIMESTAMP WITH TIME ZONE` |
| `date` | `DATE` | `date` | `DATE` |
| `uuid` | `BINARY(16)` | `uniqueidentifier` | `RAW(16)` |
| `jsonb` | `JSON` | `nvarchar(max)` | `JSON`/`CLOB` |
| `bytea` | `BLOB` | `varbinary(max)` | `BLOB` |
| `serial` | `AUTO_INCREMENT` | `IDENTITY` | `IDENTITY`/sequence |

## Идентификаторы и регистр

| | По умолчанию | `"Quoted"` |
|---|---|---|
| PostgreSQL | lower_case | сохраняет регистр |
| MySQL | как в ОС (часто lower) | сохраняет |
| SQL Server | сохраняет, сравнение ci | сохраняет |
| Oracle | **UPPER_CASE** | сохраняет |
| SQLite | сохраняет, сравнение ci | сохраняет |

Миграция из Oracle: `"users"` и `users` — **разные** объекты (второй станет `USERS`).

## Транзакции и DDL

| | DDL в транзакции | Откат DDL |
|---|---|---|
| PostgreSQL | да | да |
| MySQL | нет (неявный commit) | нет |
| SQL Server | да | да |
| Oracle | нет (неявный commit) | нет |
| SQLite | да | да |

Миграции, написанные для PG, на MySQL/Oracle нужно разбивать на отдельные шаги с проверками.

## Что проверить при миграции

1. **`NULL`/`''`** — тесты на пустые строки и `NOT IN`.
2. **Регистр и collation** — сравнения строк, `ORDER BY`, уникальные индексы.
3. **Даты и TZ** — `timestamp` vs `timestamptz`, precision, диапазон.
4. **`RETURNING`** — переписать на `LAST_INSERT_ID`/`OUTPUT`.
5. **`ON CONFLICT`** — на `MERGE`/`ON DUPLICATE KEY`.
6. **Пагинация** — `LIMIT/OFFSET` vs `TOP`/`FETCH`.
7. **JSON** — `jsonb`-операторы (`@>`, `->>`) не переносятся 1:1.
8. **Массивы и enum** — в других СУБД их нет.
9. **Оконные функции** — есть везде, но `FILTER (WHERE)` — только PG/SQLite.
10. **`DISTINCT ON`** — только PG; в остальных — `ROW_NUMBER()`.
11. **Триггеры и процедуры** — переписывать (PL/pgSQL ≠ T-SQL ≠ PL/SQL).
12. **Права/роли** — синтаксис `GRANT` различается.

## Инструменты

- **ora2pg** (Oracle → PG), **pgloader** (MySQL/SQLite → PG), **AWS SCT/DMS**, **Azure DMS**.
- **Hibernate/JPA**: диалекты (`PostgreSQLDialect`, `MySQLDialect`), но native-запросы всё равно проверять.
- **Testcontainers**: тестировать на целевой СУБД, а не на H2.

## Связанное

[[PostgreSQL]] · [[Другие/MySQL и InnoDB]] · [[Другие/SQL Server]] · [[Другие/Oracle Database]] · [[Другие/SQLite]] · [[Оптимизация/Антипаттерны запросов]]

## Источники

- PostgreSQL Docs: *Functions and Operators*, *Data Types*
- MySQL Docs: *Differences from Other DBMS*
- Oracle Docs: *SQL Language Reference*
- ora2pg, pgloader documentation
