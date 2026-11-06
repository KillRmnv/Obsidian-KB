# Подзапросы, CTE и оконные функции

## Зачем это нужно

Подзапросы, CTE и оконные функции — там, где запрос «выглядит логично», но выполняется в 100 раз дольше. Причина обычно в том, что планировщик не может «схлопнуть» конструкцию, или в сортировке, которая незаметна в тексте запроса.

## Как устроено

### Подзапросы: планировщик старается их «развернуть»

| Конструкция | Что делает планировщик |
|---|---|
| `FROM (SELECT …) s` | **flattening**: подзапрос вливается в общий план (если нет `LIMIT`/`DISTINCT`/агрегата) |
| `WHERE x IN (SELECT …)` | может превратить в **semi join** |
| `WHERE EXISTS (SELECT …)` | semi join; коррелированный — часто nested loop |
| `WHERE x NOT IN (SELECT …)` | **anti join**, но с NULL — ловушка |
| `SELECT (SELECT max(…) FROM b)` | коррелированный подзапрос → выполняется на каждую строку |

```sql
-- Плохо: подзапрос на каждую строку
SELECT u.id, (SELECT count(*) FROM orders o WHERE o.user_id = u.id) AS cnt
FROM users u;

-- Лучше: один join + группировка
SELECT u.id, count(o.id) AS cnt
FROM users u LEFT JOIN orders o ON o.user_id = u.id
GROUP BY u.id;
```

Но не всегда: если нужен top-1 на группу, коррелированный `LATERAL` — самый быстрый вариант ([[Оптимизация/JOIN-оптимизация]]).

### `IN` vs `EXISTS` vs `JOIN`

```sql
-- Семантически эквивалентны при отсутствии дублей:
SELECT * FROM users u WHERE u.id IN (SELECT user_id FROM orders);
SELECT * FROM users u WHERE EXISTS (SELECT 1 FROM orders o WHERE o.user_id = u.id);
SELECT DISTINCT u.* FROM users u JOIN orders o ON o.user_id = u.id;
```

- `IN`/`EXISTS` не размножают строки, `JOIN` — размножает (нужен `DISTINCT`, а это сортировка/хэш).
- `EXISTS` обычно лучший выбор для «есть ли связанные».
- `NOT IN` **опасен**: если подзапрос вернёт NULL, результат будет пустым.

```sql
-- Вернёт 0 строк, если в orders есть user_id IS NULL
SELECT * FROM users WHERE id NOT IN (SELECT user_id FROM orders);
-- Правильно:
SELECT * FROM users u WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.user_id = u.id);
```

### CTE: `MATERIALIZED` и инлайнинг

До PG12 CTE был «оптимизационным барьером»: всегда материализовался. С PG12 обычный (нерекурсивный) CTE, на который ссылаются один раз, **инлайнится** в основной запрос.

```sql
WITH recent AS (
  SELECT * FROM orders WHERE created_at > now() - interval '7 days'
)
SELECT * FROM recent WHERE status = 'paid';
-- PG12+: предикат status может «протолкнуться» внутрь → индекс работает
```

Управление:

```sql
WITH recent AS MATERIALIZED (…)      -- принудительно материализовать
WITH recent AS NOT MATERIALIZED (…)  -- принудительно инлайнить
```

Когда материализация полезна:

- CTE используется **несколько раз** (иначе пересчитается);
- нужен «барьер» для стабильной оценки (редко);
- в CTE дорогой подзапрос, результат маленький.

Когда вредна: фильтр снаружи не проталкивается внутрь → CTE читает всю таблицу.

Классическая ошибка:

```sql
-- Медленно: CTE материализует 10 млн строк, а нужно 10
WITH all_orders AS (SELECT * FROM orders)
SELECT * FROM all_orders WHERE user_id = 42 LIMIT 10;
```

### Оконные функции

```sql
SELECT user_id, created_at, total,
       row_number() OVER (PARTITION BY user_id ORDER BY created_at DESC) AS rn,
       sum(total)   OVER (PARTITION BY user_id) AS user_total
FROM orders;
```

Стоимость:

- требуется **сортировка** по `(PARTITION BY, ORDER BY)`, если нет подходящего индекса;
- окно считается по всему набору строк **до** `LIMIT` (кроме случаев, когда planner может остановиться);
- несколько окон с разными `ORDER BY` = несколько сортировок;
- `WINDOW w AS (…)` позволяет переиспользовать одно окно.

Типичные задачи и альтернативы:

| Задача | Окно | Альтернатива |
|---|---|---|
| top-N на группу | `row_number() … = 1` | `LATERAL` + индекс, `DISTINCT ON` |
| последняя запись | `row_number() OVER (PARTITION BY … ORDER BY … DESC)` | `DISTINCT ON (user_id) … ORDER BY user_id, created_at DESC` |
| running total | `sum() OVER (ORDER BY …)` | `GROUP BY` + join, если возможно |
| дедупликация | `row_number() = 1` | `DISTINCT ON` / `GROUP BY` |

`DISTINCT ON` часто быстрее окна, потому что умеет использовать индекс и не сортирует весь набор:

```sql
SELECT DISTINCT ON (user_id) user_id, created_at, total
FROM orders
ORDER BY user_id, created_at DESC;
```

### Рекурсивные CTE

```sql
WITH RECURSIVE tree AS (
  SELECT id, parent_id, name, 0 AS depth
  FROM categories WHERE parent_id IS NULL
  UNION ALL
  SELECT c.id, c.parent_id, c.name, t.depth + 1
  FROM categories c JOIN tree t ON c.parent_id = t.id
)
SELECT * FROM tree;
```

- `UNION ALL` быстрее `UNION` (нет дедупликации);
- глубина ограничена только памятью/временем — добавь `WHERE depth < N`;
- `CYCLE … SET is_cycle` (PG14+) защищает от бесконечных циклов;
- `SEARCH DEPTH FIRST / BREADTH FIRST` (PG14+) — порядок обхода без ручной сортировки.

### Группировки и множества

- `GROUP BY` → `HashAggregate` (нужен `work_mem`) или `GroupAggregate` (по сортировке).
- `GROUPING SETS`, `ROLLUP`, `CUBE` — несколько агрегатов за один проход; полезно для отчётов.
- `count(DISTINCT x)` — дорого (сортировка/хэш всех значений). Иногда дешевле `COUNT(*)` по подзапросу с `DISTINCT`.
- `FILTER (WHERE …)` дешевле, чем `CASE WHEN` внутри агрегата (и читаемее).

## Что видно в psql

```sql
-- 1. CTE инлайнится?
EXPLAIN (ANALYZE, BUFFERS)
WITH recent AS (SELECT * FROM orders WHERE created_at > now() - interval '7 days')
SELECT * FROM recent WHERE user_id = 42;

-- 2. Сравнить с MATERIALIZED
EXPLAIN (ANALYZE, BUFFERS)
WITH recent AS MATERIALIZED (SELECT * FROM orders WHERE created_at > now() - interval '7 days')
SELECT * FROM recent WHERE user_id = 42;

-- 3. Окно: где сортировка
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM (
  SELECT *, row_number() OVER (PARTITION BY user_id ORDER BY created_at DESC) rn
  FROM orders
) s WHERE rn = 1;

-- 4. DISTINCT ON vs окно
EXPLAIN (ANALYZE, BUFFERS)
SELECT DISTINCT ON (user_id) user_id, created_at FROM orders ORDER BY user_id, created_at DESC;
```

Ищи в плане: `Sort`, `Incremental Sort`, `WindowAgg` (дорогой при больших партициях), `CTE Scan` (материализация), `SubPlan` (коррелированный подзапрос в цикле).

## Грабли и мифы

1. **«CTE всегда быстрее подзапроса»** — с PG12 наоборот, по умолчанию инлайнится. Материализация — осознанное решение.
2. **`NOT IN` с NULL** — не про скорость, а про **неверный результат**.
3. **`row_number() = 1` по большой таблице** сортирует всё → лучше `DISTINCT ON` или `LATERAL`.
4. **`LIMIT` не спасает окно**: окно считается до применения `LIMIT` (в подзапросе).
5. **`UNION` = дедупликация** (сортировка/хэш). Если дубликаты невозможны — `UNION ALL`.
6. **`count(DISTINCT)` на большой таблице** может быть дороже самого join'а.
7. **Коррелированный подзапрос в `SELECT`** выполняется на каждую строку, даже если кажется «одним запросом».

## Эксперимент

```sql
CREATE TABLE q_orders AS
SELECT g AS id, (1 + (random()*9999)::int) AS user_id,
       now() - (random() * interval '365 days') AS created_at,
       (random()*1000)::numeric(10,2) AS total
FROM generate_series(1, 1_000_000) g;
ANALYZE q_orders;

-- 1. Три способа «последний заказ на пользователя»
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM (
  SELECT *, row_number() OVER (PARTITION BY user_id ORDER BY created_at DESC) rn
  FROM q_orders
) s WHERE rn = 1;

EXPLAIN (ANALYZE, BUFFERS)
SELECT DISTINCT ON (user_id) user_id, created_at, total
FROM q_orders ORDER BY user_id, created_at DESC;

-- 2. CTE: инлайн vs материал
EXPLAIN (ANALYZE, BUFFERS)
WITH c AS (SELECT * FROM q_orders) SELECT * FROM c WHERE user_id = 10 LIMIT 5;

EXPLAIN (ANALYZE, BUFFERS)
WITH c AS MATERIALIZED (SELECT * FROM q_orders) SELECT * FROM c WHERE user_id = 10 LIMIT 5;

-- 3. IN vs EXISTS vs JOIN
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM q_orders WHERE user_id IN (SELECT user_id FROM q_orders WHERE total > 999);
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM q_orders o WHERE EXISTS (SELECT 1 FROM q_orders x WHERE x.user_id = o.user_id AND x.total > 999);
```

## Связанное

[[Оптимизация/JOIN-оптимизация]] · [[Оптимизация/Антипаттерны запросов]] · [[Внутрянка/Планировщик и исполнитель]] · [[Оптимизация/EXPLAIN и EXPLAIN ANALYZE]]

## Источники

- PostgreSQL Docs: *WITH Queries (CTE)*, *Window Functions*, *Subquery Expressions*
- Use The Index, Luke: «Window functions», «DISTINCT ON»
- CYBERTEC: «CTE materialization in PostgreSQL 12+»
