# Архитектура PostgreSQL

## Зачем это нужно

Почти все «странности» PostgreSQL объясняются процессной моделью: почему `max_connections` стоит дорого, почему `work_mem` может съесть всю память, почему нельзя «просто включить многопоточность», почему реплика отстаёт и почему `pg_stat_activity` — главный инструмент диагностики.

## Как устроено

### Процессная модель: один процесс на соединение

```
                   ┌──────────────────────────────┐
   клиенты         │          postmaster          │  слушает порт 5432,
   (psql, JDBC) ──►│  fork() на каждое соединение │  принимает сигналы, перезапускает
                   └───────────┬──────────────────┘  упавшие процессы
                               │
        ┌──────────────────────┼───────────────────────┐
        ▼                      ▼                       ▼
  backend 1              backend 2               backend N
  (один клиент)          (один клиент)           (один клиент)
        │                      │                       │
        └──────────────────────┴───────────────────────┘
                               │
                     ┌─────────▼──────────┐
                     │   shared memory    │
                     │ shared_buffers     │
                     │ WAL buffers        │
                     │ lock table         │
                     │ proc array, stats  │
                     └─────────┬──────────┘
                               │
        ┌──────────────────────┼───────────────────────┐
        ▼                      ▼                       ▼
   checkpointer          background writer          walwriter
   autovacuum launcher   archiver                   walsender / walreceiver
```

Ключевое:

- **Нет общего пула потоков.** Каждое соединение — отдельный ОС-процесс (`fork`). Он занимает память (несколько МБ + `work_mem` при сортировках) и CPU на переключение контекста.
- **Параллелизм внутри запроса** — тоже процессы: `parallel workers` форкаются на время запроса.
- **Общая память** — единственное место, где процессы видят одно и то же. Всё остальное — своя память бэкенда.

### Кто чем занят

| Процесс | Роль |
|---|---|
| `postmaster` | Слушает порт, форкает бэкенды, перезапускает вспомогательные процессы, обрабатывает сигналы |
| `checkpointer` | Пишет контрольные точки: сбрасывает грязные страницы на диск, фиксирует позицию в WAL |
| `background writer` | Постепенно сбрасывает грязные страницы, чтобы бэкендам не приходилось ждать записи |
| `walwriter` | Сбрасывает WAL-буферы на диск |
| `autovacuum launcher` + workers | Запускает `VACUUM`/`ANALYZE` по расписанию |
| `archiver` | Копирует заполненные WAL-сегменты в архив (если `archive_mode=on`) |
| `walsender` / `walreceiver` | Отдают/принимают WAL для репликации |
| `logical replication launcher` + apply workers | Логическая репликация |
| `stats collector` | **Удалён в PG15** — статистика теперь в shared memory |

Посмотреть живьём:

```sql
SELECT pid, backend_type, usename, state, wait_event_type, wait_event
FROM pg_stat_activity
ORDER BY backend_type, pid;
```

`backend_type` в PG10+ показывает и вспомогательные процессы, а не только клиентские.

### Память: shared vs local

```
shared_buffers          кэш страниц данных (свой у PG, поверх page cache ОС)
wal_buffers             буфер WAL (по умолчанию 1/32 shared_buffers, до 16 МБ)
lock table, proc array  состояние транзакций, блокировок, снапшотов
статистика (PG15+)      pg_stat_* в общей памяти

work_mem                НА КАЖДЫЙ узел сортировки/хэша в запросе, локально
maintenance_work_mem    VACUUM, CREATE INDEX, ALTER TABLE, локально
temp_buffers            временные таблицы, локально
catalog cache           кэш системного каталога, локально
```

**Главная ловушка памяти:** `work_mem` умножается на число узлов плана и на число одновременных соединений. Запрос с 3 сортировками при `work_mem=256MB` и 100 соединениях — это потенциальные десятки гигабайт. Поэтому `work_mem` поднимают точечно (`SET LOCAL work_mem`), а не глобально.

### Файлы на диске (PGDATA)

```
$PGDATA/
├── base/<dboid>/<relfilenode>          сами данные: таблицы и индексы
├── base/<dboid>/<relfilenode>_fsm      free space map
├── base/<dboid>/<relfilenode>_vm       visibility map
├── global/                             общий каталог (pg_database, pg_authid)
├── pg_wal/                             WAL-сегменты по 16 МБ
├── pg_xact/                            статусы транзакций (2 бита на xid)
├── pg_multixact/                       статусы мультитранзакций (блокировки строк)
├── pg_stat/                            персистентная статистика (PG15+)
├── pg_logical/                         логическая репликация
├── postgresql.conf / pg_hba.conf       конфиг и доступ
└── postmaster.pid                      pid + адрес shared memory
```

```sql
SELECT pg_relation_filepath('orders');   -- base/16384/24576
SELECT relfilenode, reltablespace FROM pg_class WHERE relname = 'orders';
```

При `TRUNCATE`, `VACUUM FULL`, `REINDEX` меняется `relfilenode` — файл пересоздаётся. Это важно для бэкапов «по файлам»: копировать PGDATA на живой системе нельзя.

### Сигналы управления

| Сигнал | Что делает |
|---|---|
| `SIGTERM` (`pg_ctl stop -m smart`) | Ждёт отключения клиентов, потом останавливается |
| `SIGINT` (`-m fast`) | Откатывает активные транзакции и выключается — обычный вариант |
| `SIGQUIT` (`-m immediate`) | Аварийное завершение, при старте будет crash recovery |

## Что видно в psql

```sql
-- Кто я и какой у меня процесс
SELECT pg_backend_pid();

-- Все процессы сервера
SELECT pid, backend_type, state, query
FROM pg_stat_activity
WHERE backend_type = 'client backend';
```

Процесс бэкенда в ОС (из терминала):

```bash
ps -eo pid,rss,cmd | grep "[p]ostgres"
```

## Грабли и мифы

1. **«PostgreSQL многопоточный»** — нет. Один процесс на соединение; параллелизм — через форк процессов и разделяемую память.
2. **`max_connections=1000` — плохая идея.** 1000 процессов × (несколько МБ + `work_mem`) + переключения контекста. Правильно — PgBouncer в transaction-режиме и `max_connections` 100–200.
3. **`shared_buffers` — не «кэш всей БД».** Он дублирует page cache ОС; данные читаются из page cache, если нет в shared_buffers. Отсюда `effective_cache_size` — это подсказка планировщику, а не выделение памяти.
4. **`work_mem` — не общий лимит.** Это лимит на один узел плана в одном запросе. `EXPLAIN (ANALYZE)` покажет `Sort Method: external merge Disk: …kB`, если не хватило.
5. **Падение бэкенда ≠ падение сервера.** postmaster убивает всех и делает crash recovery от последней контрольной точки.

## Эксперимент

1. Открой две сессии `psql`.
2. В первой: `SELECT pg_backend_pid();` — запомни PID.
3. Во второй: `SELECT pid, state, query FROM pg_stat_activity WHERE pid = <PID>;`
4. Выполни в первой `SELECT pg_sleep(10);` и во второй посмотри `state = 'active'`, `wait_event = 'PgSleep'`.
5. В терминале: `ps -o pid,ppid,rss,cmd -p <PID>` — увидишь `postgres: <user> <db> [local] idle/active`, родитель — postmaster.

## Связанное

[[Внутрянка/Физическое хранение]] · [[Внутрянка/WAL и durability]] · [[Оптимизация/Тюнинг параметров сервера]] · [[Внутрянка/Мониторинг и метрики]]

## Источники

- PostgreSQL Docs: *Architectural Fundamentals*, *Server Processes*, *Memory*
- Егор Рогов, «PostgreSQL 14 Internals», гл. 1
- `pg_stat_activity` в документации (колонка `backend_type`)
