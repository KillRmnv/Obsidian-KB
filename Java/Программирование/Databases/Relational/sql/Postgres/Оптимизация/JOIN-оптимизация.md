# JOIN-оптимизация

## Зачем это нужно

JOIN — место, где планы ломаются чаще всего: nested loop с миллионом итераций, hash join, не влезший в `work_mem`, сортировка на 2 ГБ перед merge join. Здесь — как понять, какой метод выбран и почему, и что с этим делать.

## Как устроено

### Три метода соединения

#### Nested Loop

```
для каждой строки внешнего набора:
    найти совпадения во внутреннем (обычно по индексу)
```

Стоимость ≈ `rows_outer × (index_lookup + fetch)`.

- **Хорош**: внешних строк мало (десятки–тысячи), на внутренней стороне есть индекс.
- **Плох**: внешних строк много (сотни тысяч) → миллионы random I/O.
- Признак в плане: `Nested Loop`, внутренний узел — `Index Scan`, `loops` = числу внешних строк.

#### Hash Join

```
1. Прочитать меньшую таблицу → построить хэш-таблицу по ключу
2. Прочитать большую → для каждой строки найти совпадение в хэше
```

Стоимость ≈ `scan_small + build_hash + scan_big + probe`.

- **Хорош**: большие таблицы без подходящих индексов, равенство.
- **Плох**: ключи с перекосом (один хэш-бакет на 80% строк), не хватило `work_mem`.
- Признак проблемы: `Batches: 4`, `Memory Usage: 2048kB` при `work_mem` меньше — хэш пишется во временные файлы.

#### Merge Join

```
1. Отсортировать обе стороны по ключу (или взять готовый порядок из индекса)
2. Слить два потока
```

- **Хорош**: обе стороны уже отсортированы (индексы `(join_key)`), большие объёмы.
- **Плох**: если нужна сортировка — она может стоить дороже самого join'а.
- Признак: `Merge Join` + `Sort` под ним; `Sort Method: external merge` — плохо.

### Как планировщик выбирает

Он перебирает комбинации:

- порядок соединения таблиц (для `N` таблиц);
- метод для каждого соединения;
- способы сканирования.

Ограничения перебора:

| Параметр | Default | Смысл |
|---|---|---|
| `join_collapse_limit` | 8 | сколько `JOIN` разворачивать в общий перебор |
| `from_collapse_limit` | 8 | сколько подзапросов в `FROM` «схлопывать» |
| `geqo_threshold` | 12 | после скольких таблиц включается генетический алгоритм |
| `geqo_effort` | 5 | его «усердие» |

Если таблиц больше лимита, планировщик **фиксирует порядок** как написано — и это может быть плохо. Иногда помогает переписать `FROM` в нужном порядке или повысить лимит (осторожно: время планирования растёт экспоненциально).

### Оценка размера join'а

```
rows(join) ≈ rows_a × rows_b / max(n_distinct(a.key), n_distinct(b.key))
```

Ошибки:

- **перекос**: 80% заказов у 1% клиентов;
- **несколько условий** и корреляция;
- **join по выражению** — статистика не применяется.

Смотреть: `rows` (оценка) vs `actual rows`, `Buckets`/`Batches` у Hash.

### LATERAL: top-N на группу

Классическая задача «последние 3 заказа каждого клиента». Без LATERAL — окно или коррелированный подзапрос, часто с полным сканом.

```sql
SELECT u.id, u.email, o.id, o.created_at
FROM users u
CROSS JOIN LATERAL (
  SELECT id, created_at
  FROM orders
  WHERE user_id = u.id
  ORDER BY created_at DESC
  LIMIT 3
) o
WHERE u.active;
```

С индексом `orders (user_id, created_at DESC)` это `Nested Loop` + `Index Scan` с `LIMIT` — по 3 строки на клиента вместо сортировки всей таблицы.

### N+1 из ORM

```java
// Плохо: 1 + N запросов
for (User u : users) { u.getOrders().size(); }

// Хорошо: 1 запрос с JOIN / IN
SELECT * FROM orders WHERE user_id IN (…);
```

Признак в `pg_stat_statements`: один и тот же нормализованный запрос с `calls` в тысячах и `rows=1`. Лечение — `JOIN FETCH`, batch-size, `IN`-загрузка.

### Semi/anti join

```sql
-- EXISTS → Semi Join (hash или nested loop)
SELECT * FROM users u
WHERE EXISTS (SELECT 1 FROM orders o WHERE o.user_id = u.id);

-- NOT EXISTS → Anti Join; безопаснее, чем NOT IN (NULL!)
SELECT * FROM users u
WHERE NOT EXISTS (SELECT 1 FROM orders o WHERE o.user_id = u.id);
```

`NOT IN (SELECT …)` при наличии NULL в подзапросе вернёт **пустой результат** — классическая ловушка, а не проблема производительности.

## Что видно в psql

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT u.email, count(o.id) AS orders
FROM users u
JOIN orders o ON o.user_id = u.id
WHERE u.active AND o.created_at > now() - interval '90 days'
GROUP BY u.email;
```

Что искать:

| Признак | Диагноз |
|---|---|
| `Nested Loop`, `loops=500000` | внешних строк слишком много |
| `Hash ... Batches: 8`, `Memory Usage` маленький | не хватает `work_mem` |
| `Sort Method: external merge` под `Merge Join` | сортировка на диск |
| `rows=10` vs `actual rows=100000` | ошибка оценки → неверный метод |
| `Rows Removed by Join Filter` | join-условие не используется как ключ (например, `OR`) |
| `Materialize` | внутренняя сторона пересчитывается, кэшируется — иногда признак плохого порядка |

Проверка гипотез:

```sql
SET enable_nestloop = off;   -- только для проверки!
EXPLAIN (ANALYZE, BUFFERS) SELECT …;
RESET enable_nestloop;

SET work_mem = '256MB';      -- локально
EXPLAIN (ANALYZE, BUFFERS) SELECT …;
RESET work_mem;
```

`enable_memoize` (PG14+): кэширует результаты внутренней стороны nested loop при повторяющихся ключах — может резко ускорить join без изменения запроса.

`incremental sort` (PG13+): если данные уже частично отсортированы, сортировка дешевле полной.

## Грабли и мифы

1. **«JOIN всегда медленный»** — нет. Медленный join = неверный метод или неверная оценка.
2. **Nested Loop не «плохой»** — он лучший, когда внешних строк мало. Плохой — когда `loops` в сотнях тысяч.
3. **Hash Join требует памяти**, но `work_mem` — на узел, а не на запрос. 3 hash join'а × 64 МБ = 192 МБ.
4. **`enable_hashjoin=off` не «ускоряет»** — он искажает cost model, а не отключает метод.
5. **Порядок таблиц в `FROM` важен**, если превышен `join_collapse_limit`. Обычно планировщик сам переставляет, но не всегда.
6. **`NOT IN` с NULL** — не про скорость, а про корректность. Используй `NOT EXISTS`.
7. **`LEFT JOIN` + условие в `WHERE`** превращает его в `INNER JOIN` (если фильтр по правой таблице) — и это меняет план.
8. **Индекс на FK обязателен**, если по нему join'ят или удаляют родителя: без него `DELETE` из родительской таблицы делает seq scan дочерней.

## Эксперимент

```sql
CREATE TABLE j_users AS
SELECT g AS id, 'user' || g AS email, (g % 10 = 0) AS active
FROM generate_series(1, 50_000) g;

CREATE TABLE j_orders AS
SELECT g AS id,
       (1 + (random() * 49999)::int) AS user_id,
       now() - (random() * interval '365 days') AS created_at,
       (random() * 1000)::numeric(10,2) AS total
FROM generate_series(1, 2_000_000) g;

ANALYZE j_users;
ANALYZE j_orders;

-- 1. Без индекса на user_id: hash join или nested loop?
EXPLAIN (ANALYZE, BUFFERS)
SELECT u.email, count(*) FROM j_users u JOIN j_orders o ON o.user_id = u.id GROUP BY u.email;

-- 2. С индексом
CREATE INDEX ON j_orders (user_id);
ANALYZE j_orders;

EXPLAIN (ANALYZE, BUFFERS)
SELECT u.email, count(*) FROM j_users u JOIN j_orders o ON o.user_id = u.id GROUP BY u.email;

-- 3. Top-N per group через LATERAL
CREATE INDEX ON j_orders (user_id, created_at DESC);
EXPLAIN (ANALYZE, BUFFERS)
SELECT u.id, o.id, o.created_at
FROM j_users u
CROSS JOIN LATERAL (
  SELECT id, created_at FROM j_orders WHERE user_id = u.id ORDER BY created_at DESC LIMIT 3
) o
WHERE u.id <= 100;

-- 4. Проверка гипотезы «мешает nested loop»
SET enable_nestloop = off;
EXPLAIN (ANALYZE, BUFFERS) SELECT …;
RESET enable_nestloop;
```

## Связанное

[[Внутрянка/Планировщик и исполнитель]] · [[Оптимизация/Оценка кардинальности]] · [[Оптимизация/Подзапросы, CTE и оконные функции]] · [[Оптимизация/Антипаттерны запросов]]

## Источники

- PostgreSQL Docs: *Join Methods*, *Planner/Optimizer*, `enable_memoize`, `incremental sort`
- Use The Index, Luke: «Nested Loops», «Hash Joins», «Merge Joins»
- Егор Рогов, «PostgreSQL 14 Internals», гл. 9
