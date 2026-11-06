# EXPLAIN и EXPLAIN ANALYZE

## Зачем это нужно

`EXPLAIN` — основной инструмент оптимизации. Но 90% людей читают только «стоимость» и не смотрят на `rows vs actual rows`, `Buffers` и `loops`. Здесь — как читать план целиком и какие опции включать.

## Как устроено

### Разница между EXPLAIN и EXPLAIN ANALYZE

| | `EXPLAIN` | `EXPLAIN ANALYZE` |
|---|---|---|
| Выполняет запрос | нет | **да** |
| Показывает оценку | да | да |
| Показывает реальное время/строки | нет | да |
| Безопасно для `UPDATE`/`DELETE` | да | только в транзакции с `ROLLBACK` |

```sql
BEGIN;
EXPLAIN (ANALYZE, BUFFERS) DELETE FROM orders WHERE created_at < '2020-01-01';
ROLLBACK;
```

### Опции

| Опция | Что даёт |
|---|---|
| `ANALYZE` | реальное выполнение: `actual time`, `rows`, `loops` |
| `BUFFERS` | `shared hit/read/dirtied/written`, `temp read/written` |
| `SETTINGS` | нестандартные GUC, повлиявшие на план (PG12+) |
| `WAL` | объём WAL, сгенерированный запросом (PG13+) |
| `VERBOSE` | полный список колонок, схема, alias |
| `COSTS off` | убрать cost/rows — удобно для сравнения структуры |
| `TIMING off` | убрать замеры времени (снижает overhead на больших планах) |
| `SUMMARY` | итог в конце (по умолчанию on при ANALYZE) |
| `FORMAT JSON/YAML/XML` | для инструментов визуализации |

Разумный минимум для диагностики:

```sql
EXPLAIN (ANALYZE, BUFFERS, SETTINGS) SELECT …;
```

### Как читать план

План — дерево, напечатанное с отступами. **Выполнение идёт снизу вверх и слева направо**; узел с большим отступом — источник данных для узла выше.

```
Limit                                   ← верхний узел, отдаёт клиенту
  ->  Sort                              ← сортировка
        Sort Key: created_at DESC
        Sort Method: top-N heapsort  Memory: 27kB
        ->  Hash Join                    ← соединение
              Hash Cond: (o.user_id = u.id)
              ->  Seq Scan on orders o    ← левый источник
                    Filter: (status = 'paid')
                    Rows Removed by Filter: 900000
              ->  Hash
                    Buckets: 16384  Batches: 1  Memory Usage: 1024kB
                    ->  Seq Scan on users u
```

Ключевые поля строки:

| Поле | Смысл |
|---|---|
| `cost=startup..total` | оценка стоимости до первой строки и до последней |
| `rows=N` | **оценка** числа строк на выходе узла |
| `width=N` | средняя ширина строки в байтах |
| `actual time=start..end` | реальное время **на один цикл** до первой/последней строки |
| `rows=N` (в actual) | реальное среднее число строк **на цикл** |
| `loops=N` | сколько раз узел выполнялся |
| `Buffers: shared hit=… read=…` | страницы из кэша / с диска |
| `Rows Removed by Filter` | сколько строк отброшено после чтения |
| `Heap Fetches` | походы в heap у Index Only Scan |

**Реальное время узла** = `actual time` (второе число) × `loops`. Именно так ищется «дорогой» узел.

### Что означает расхождение оценок

```
Seq Scan on orders  (cost=0.00..35000.00 rows=100 width=200)
                    (actual time=0.02..850.30 rows=50000 loops=1)
```

Оценка 100, реально 50 000 — ошибка в 500 раз. Дальше планировщик строит весь план на этом вранье: выбирает nested loop вместо hash join, недооценивает `work_mem`, ставит не тот порядок соединений.

Причины (подробно — [[Оптимизация/Оценка кардинальности]]):

- устаревшая/отсутствующая статистика → `ANALYZE`;
- коррелированные колонки → `CREATE STATISTICS`;
- функции/выражения в `WHERE` → expression index или переписывание;
- `LIKE '%…%'`, `OR`, `NOT IN` — плохо оцениваются;
- данные сильно неравномерны, а `default_statistics_target` мал.

### Буферы: кэш vs диск

```
Buffers: shared hit=1200 read=3400
```

- `hit` — страница уже в `shared_buffers` (быстро);
- `read` — пришлось читать с диска (или из page cache ОС);
- `dirtied`/`written` — изменения (для DML).

Если `read` большой, а запрос «должен быть быстрым» — либо холодный кэш, либо не хватает `shared_buffers`, либо индекс не покрывает нужные страницы.

### Визуализация

Текстовый план читать тяжело. Скопируй `EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)` в:

- **pev2** — explain.dalibo.com (лучший визуализатор);
- **explain.depesz.com** — подсветка расхождений;
- **pgMustard** — платная аналитика с советами.

## Что видно в psql

```sql
-- Базовая диагностика
EXPLAIN (ANALYZE, BUFFERS, SETTINGS)
SELECT o.id, o.total, u.email
FROM orders o
JOIN users u ON u.id = o.user_id
WHERE o.status = 'paid' AND o.created_at > now() - interval '30 days';

-- Сравнение планов: отключить seq scan (только для проверки гипотезы!)
SET enable_seqscan = off;
EXPLAIN (ANALYZE, BUFFERS) SELECT …;
RESET enable_seqscan;

-- Планы в JSON для визуализатора
EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON) SELECT …;

-- Проверить, не мешает ли JIT
SET jit = off;
EXPLAIN (ANALYZE) SELECT …;
```

## Грабли и мифы

1. **`EXPLAIN` без `ANALYZE` не показывает реальность** — только предположения планировщика.
2. **`cost` нельзя сравнивать между запросами.** Это внутренние единицы, зависящие от настроек.
3. **`actual time` — на цикл, а не на узел.** Забыть про `loops` — классическая ошибка.
4. **`EXPLAIN ANALYZE` меняет нагрузку**: включает таймеры на каждый узел. Для очень больших планов используй `TIMING off`.
5. **Кэш искажает картину.** Первый запуск — холодный (`read`), второй — горячий (`hit`). Для честного сравнения смотри `Buffers`.
6. **`Rows Removed by Filter` у Seq Scan** — нормально, если фильтр селективный, но плохо, если строк «удалено» в 1000 раз больше, чем вернулось.
7. **`Sort Method: external merge`** — почти всегда сигнал поднять `work_mem` (локально!) или добавить индекс под `ORDER BY`.
8. **План может измениться после `ANALYZE`** — не делай выводов по данным, которые только что массово залили без анализа.

## Эксперимент

```sql
CREATE TABLE exp_demo AS
SELECT g AS id, (g % 50) AS grp, md5(g::text) AS payload
FROM generate_series(1, 500000) g;
ANALYZE exp_demo;

-- 1. Плохая оценка → Seq Scan с большим Rows Removed
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM exp_demo WHERE grp = 7;

-- 2. Что меняется с индексом
CREATE INDEX ON exp_demo (grp);
ANALYZE exp_demo;
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM exp_demo WHERE grp = 7;

-- 3. Heap Fetches и VM
EXPLAIN (ANALYZE, BUFFERS) SELECT grp FROM exp_demo WHERE grp = 7;
VACUUM exp_demo;
EXPLAIN (ANALYZE, BUFFERS) SELECT grp FROM exp_demo WHERE grp = 7;

-- 4. work_mem и сортировка
SET work_mem = '64kB';
EXPLAIN (ANALYZE, BUFFERS) SELECT * FROM exp_demo ORDER BY payload;
RESET work_mem;
```

## Связанное

[[Внутрянка/Планировщик и исполнитель]] · [[Оптимизация/Оценка кардинальности]] · [[Оптимизация/Индексы на практике]] · [[Оптимизация/JOIN-оптимизация]] · [[Шпаргалки/Медленный запрос — 10 шагов]]

## Источники

- PostgreSQL Docs: *Using EXPLAIN*
- pev2 / explain.dalibo.com, explain.depesz.com
- Егор Рогов, «PostgreSQL 14 Internals», гл. 9
