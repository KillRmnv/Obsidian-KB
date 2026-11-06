# VACUUM и autovacuum

## Зачем это нужно

`VACUUM` — самая недооценённая операция в PostgreSQL. Он не «чистит мусор для красоты», а: освобождает место под новые версии строк, обновляет карты FSM/VM (без него не работает index-only scan), замораживает XID (без него сервер встанет), обновляет статистику планировщика. Неправильный autovacuum — причина половины «загадочных» деградаций.

## Как устроено

### Что делает обычный VACUUM

1. Проходит по страницам и находит **мёртвые** кортежи — те, чьи `xmax` закоммичены и которые не видны ни одному снапшоту.
2. Убирает item pointers и дефрагментирует страницы (line pointers переиспользуются).
3. Обновляет **FSM** (свободное место) и **VM** (all-visible / all-frozen).
4. Очищает индексные записи, указывающие на мёртвые версии (через index vacuum).
5. **Замораживает** очень старые XID.
6. **Не возвращает место ОС** (кроме «хвостовых» пустых страниц, которые можно отрезать).

Без `VACUUM`:

- файл растёт (bloat), потому что новые версии строк ищут место в конце;
- index-only scan не включается (VM не обновлена);
- `age(relfrozenxid)` растёт → wraparound.

### VACUUM FULL vs pg_repack

| | `VACUUM` | `VACUUM FULL` | `pg_repack` |
|---|---|---|---|
| Блокировка | `SHARE UPDATE EXCLUSIVE` | `ACCESS EXCLUSIVE` | короткая, в конце |
| Возврат места ОС | только хвост | да (полная перезапись) | да |
| Нужно свободное место | нет | ≈ размер таблицы | ≈ размер таблицы |
| Длительность | минуты | часы | часы, но без простоя |
| Онлайн | да | нет | да |

`VACUUM FULL` = `CLUSTER` без сортировки: создаёт новый файл, копирует живые строки, пересоздаёт индексы. На проде почти всегда лучше `pg_repack`.

### Autovacuum: когда запускается

Для каждой таблицы:

```
порог vacuum = autovacuum_vacuum_threshold (50)
             + autovacuum_vacuum_scale_factor (0.2) * reltuples
порог analyze = autovacuum_analyze_threshold (50)
             + autovacuum_analyze_scale_factor (0.1) * reltuples
```

То есть для таблицы в 1 млн строк vacuum начнётся после ~200 050 мёртвых строк. Для 100 млн — после 20 млн. **Масштаб-фактор 0.2 — главная причина, почему большие таблицы «не успевают» очищаться.** Лечится per-table настройкой:

```sql
ALTER TABLE big_table SET (
  autovacuum_vacuum_scale_factor = 0.02,
  autovacuum_vacuum_threshold = 5000,
  autovacuum_analyze_scale_factor = 0.01
);
```

`autovacuum_vacuum_insert_threshold` / `autovacuum_vacuum_insert_scale_factor` (PG13+) — vacuum по вставкам (нужен для VM и freeze).

### Стоимость и троттлинг

Autovacuum не «жадный»: он ограничен cost-based delay.

| Параметр | Default | Смысл |
|---|---|---|
| `vacuum_cost_page_hit` | 1 | стоимость страницы из shared_buffers |
| `vacuum_cost_page_dirty` | 20 | стоимость испачканной страницы |
| `vacuum_cost_page_miss` | 10 | стоимость чтения с диска |
| `vacuum_cost_limit` | 200 | бюджет «кредита» |
| `autovacuum_vacuum_cost_delay` | 2 ms | пауза при исчерпании (PG12+; раньше 20 ms) |
| `autovacuum_max_workers` | 3 | параллельные воркеры |

Если autovacuum «не успевает» — либо таблица слишком большая (scale factor), либо воркеров мало, либо delay слишком большой, либо мешает долгая транзакция.

### Freeze и wraparound

`VACUUM` замораживает версии с `xmin` старше `vacuum_freeze_min_age` (50 млн). «Агрессивный» vacuum (проход по всей таблице, не только по страницам с мусором) запускается при `relfrozenxid` старше `vacuum_freeze_table_age` (150 млн).

Защита от wraparound: `autovacuum_freeze_max_age` (200 млн) — после этого возраста autovacuum **обязан** запуститься, даже если `autovacuum=off` (это может удивить). При `age(datfrozenxid)` близком к 2^31 сервер отказывается принимать команды.

```sql
SELECT relname, age(relfrozenxid) AS xid_age, pg_size_pretty(pg_total_relation_size(oid))
FROM pg_class WHERE relkind = 'r' ORDER BY xid_age DESC LIMIT 10;

SELECT datname, age(datfrozenxid) FROM pg_database ORDER BY 2 DESC;
```

### Что мешает vacuum

- **Долгая транзакция** (даже `idle in transaction`) — держит `backend_xmin`, и vacuum не может убрать версии, созданные после её снапшота.
- **Реплика с `hot_standby_feedback=on`** — передаёт свой `xmin` на primary.
- **Логический слот репликации**, который никто не читает (`pg_replication_slots.active = false` с `restart_lsn` далеко в прошлом) — WAL и каталог не чистятся.
- **`prepared transactions`**, забытые в `pg_prepared_xacts`.

Проверка:

```sql
SELECT pid, state, backend_xmin, now() - xact_start AS age
FROM pg_stat_activity
WHERE backend_xmin IS NOT NULL
ORDER BY age DESC;

SELECT slot_name, active, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn))
FROM pg_replication_slots;
```

## Что видно в psql

```sql
-- Прогресс vacuum (PG12+)
SELECT * FROM pg_stat_progress_vacuum;

-- Что думает статистика о мусоре
SELECT relname, n_live_tup, n_dead_tup, n_tup_upd, n_tup_hot_upd,
       last_vacuum, last_autovacuum, last_analyze, last_autoanalyze
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC
LIMIT 10;

-- Точный размер bloat (pgstattuple)
CREATE EXTENSION IF NOT EXISTS pgstattuple;
SELECT * FROM pgstattuple_approx('big_table');
-- table_len, dead_tuple_count, dead_tuple_len, free_percent
```

Ручной запуск:

```sql
VACUUM (VERBOSE, ANALYZE) big_table;
VACUUM (FREEZE, VERBOSE) big_table;
-- на всю базу:
VACUUM (ANALYZE, VERBOSE);
```

## Грабли и мифы

1. **`VACUUM` не уменьшает файл.** Он делает место переиспользуемым. Уменьшает — `VACUUM FULL`/`pg_repack`.
2. **`VACUUM FULL` на большой таблице = простой.** И требует столько же места, сколько таблица.
3. **Autovacuum не «сломался» — он ждёт.** Проверь `pg_stat_activity` на долгие транзакции и `pg_stat_progress_vacuum`.
4. **`autovacuum=off` не спасает от freeze-vacuum.** Anti-wraparound запускается принудительно.
5. **Массовый `DELETE` не освобождает место** — нужен vacuum, а лучше партиционирование + `DROP PARTITION` ([[Партиции]]).
6. **`ANALYZE` — часть autovacuum, но не часть `VACUUM`.** `VACUUM` без `ANALYZE` не обновляет статистику; autovacuum делает их вместе, но по разным порогам.
7. **Таблицы с `fillfactor=100` и частым `UPDATE`** плодят новые страницы быстрее, чем vacuum успевает; ставь `fillfactor=80..90` для HOT.

## Эксперимент

```sql
CREATE TABLE bloat_demo (id int primary key, payload text);
INSERT INTO bloat_demo SELECT g, repeat('x', 200) FROM generate_series(1, 200000) g;

SELECT pg_size_pretty(pg_total_relation_size('bloat_demo')) AS before;

UPDATE bloat_demo SET payload = payload || 'y';   -- 200k мёртвых версий
UPDATE bloat_demo SET payload = payload || 'z';

SELECT n_dead_tup, pg_size_pretty(pg_total_relation_size('bloat_demo'))
FROM pg_stat_user_tables WHERE relname = 'bloat_demo';

VACUUM (VERBOSE, ANALYZE) bloat_demo;
-- размер файла почти не изменился, n_dead_tup → 0, место переиспользуемо

-- А теперь вернуть место ОС
VACUUM FULL bloat_demo;
SELECT pg_size_pretty(pg_total_relation_size('bloat_demo')) AS after_full;
```

## Связанное

[[Внутрянка/MVCC и версии строк]] · [[Внутрянка/Физическое хранение]] · [[Внутрянка/Мониторинг и метрики]] · [[Оптимизация/Тюнинг параметров сервера]] · [[Партиции]]

## Источники

- PostgreSQL Docs: *Routine Vacuuming*, *VACUUM*, *autovacuum*
- Расширения `pgstattuple`, `pg_repack`
- Егор Рогов, «PostgreSQL 14 Internals», гл. 5
