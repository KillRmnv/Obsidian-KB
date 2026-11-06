# WAL и durability

## Зачем это нужно

WAL (Write-Ahead Log) — это одновременно: гарантия Durability из [[ACID]], механизм crash recovery, основа репликации и главный источник нагрузки на диск при записи. Понимание WAL объясняет, почему `synchronous_commit=off` ускоряет коммиты, почему checkpoint вызывает всплески I/O и почему реплика отстаёт.

## Как устроено

### Правило WAL

> Прежде чем изменить страницу данных на диске, изменение должно быть записано в журнал.

Порядок:

```
1. Изменение → страница в shared_buffers (грязная)
2. Изменение → WAL-запись в wal_buffers
3. COMMIT → WAL сбрасывается на диск (fsync), клиенту отвечают OK
4. Позже checkpointer/bgwriter пишет грязные страницы в файлы данных
```

Если сервер упал между 3 и 4 — при старте WAL «доигрывается» (redo) с последней контрольной точки, и данные восстанавливаются.

### LSN и сегменты

- **LSN** (Log Sequence Number) — позиция в WAL, 64-бит: `16/B374D848` = старшие 8 hex — номер сегмента, младшие — смещение.
- Сегмент — 16 МБ (`wal_segment_size`), имя вида `000000010000000000000001`.
- `pg_wal/` — активные сегменты; `pg_wal/archive_status/` — готовые к архивации.

```sql
SELECT pg_current_wal_lsn();                        -- 0/1A2B3C4
SELECT pg_walfile_name(pg_current_wal_lsn());
SELECT pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), '0/0'));
SELECT pg_switch_wal();                             -- принудительно закрыть сегмент
```

### Checkpoint

Контрольная точка:

1. записывает в WAL запись `CHECKPOINT`;
2. сбрасывает все грязные страницы из `shared_buffers` на диск;
3. обновляет `pg_control` (позиция, откуда начинать recovery);
4. после этого старые WAL-сегменты можно удалять/архивировать.

Всё, что было до checkpoint, при крахе восстанавливать не нужно — данные уже на диске. Recovery начинается с **последней контрольной точки** и до конца WAL.

Параметры:

| Параметр | Default | Смысл |
|---|---|---|
| `checkpoint_timeout` | `5min` | Максимальный интервал между checkpoint |
| `max_wal_size` | `1GB` | Сколько WAL можно накопить до принудительного checkpoint |
| `checkpoint_completion_target` | `0.9` | Растянуть запись на 90% интервала (сгладить I/O) |
| `checkpoint_flush_after` | `256kB` | Сброс после N байт, чтобы не копить грязную память ОС |

### full_page_writes и «write amplification»

После checkpoint первый изменённый блок пишется в WAL **целиком** (full-page image, FPI), а не только изменённые байты. Это защита от «рваной страницы» (torn page): 8 КБ могут записаться частично при сбое питания.

Следствия:

- чем чаще checkpoint — тем больше FPI и тем больше WAL;
- `wal_compression = pglz|lz4|zstd` (zstd — PG15+) сжимает FPI;
- `full_page_writes=off` — только если ФС/диск гарантируют атомарную запись 8 КБ (обычно нет; для тестов).

### synchronous_commit: чем платим за скорость

| Значение | Гарантия при крахе | Комментарий |
|---|---|---|
| `on` (default) | Коммит на диске → не потеряется | Один fsync на коммит (групповой) |
| `remote_write` | WAL ушёл на реплику, но не обязательно на её диск | |
| `on` + sync-реплика (`remote_apply`) | Применён на реплике | Максимальная гарантия, максимальная задержка |
| `local` | Только локальный диск | Для каскадных реплик |
| `off` | Коммит **может потеряться** (последние ~3×`wal_writer_delay`), но БД останется консистентной | Ускоряет мелкие коммиты в разы |

`synchronous_commit=off` — не «грязное» решение: база не побьётся, потеряются только последние транзакции. Для аналитики/логов часто приемлемо; для денег — нет.

### Групповой коммит

Даже при `synchronous_commit=on` PostgreSQL не делает fsync на каждый коммит по отдельности: `walwriter` собирает пачку и сбрасывает разом (`wal_writer_delay = 200ms`, `commit_delay`). Поэтому тысячи мелких коммитов в секунду могут давать всего десятки fsync.

### Архивация и репликация

- `archive_mode=on` + `archive_command` (или `archive_library`) — копирование сегментов в архив для PITR.
- `wal_level`: `minimal` (без репликации), `replica` (default), `logical` (для логической репликации, больше WAL).
- `max_wal_senders`, `wal_keep_size`.
- `pg_walinspect` (PG15+) позволяет читать содержимое WAL: `SELECT * FROM pg_get_wal_records_info('0/1A2B3C4', '0/1A2B3D0');`

### PG18: async I/O

В PG18 появился асинхронный ввод-вывод (`io_method = worker|io_uring`), который меняет профиль чтения с диска и виден в `pg_stat_io`. На логику WAL это не влияет, но на «диск греется» — влияет.

## Что видно в psql

```sql
-- Сколько WAL сгенерировал запрос
CREATE TABLE IF NOT EXISTS big_table (id int);
SELECT pg_current_wal_lsn() AS start \gset
INSERT INTO big_table SELECT generate_series(1, 1000000);
SELECT pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), :'start')) AS wal_written;

-- Статистика WAL (PG14+)
SELECT * FROM pg_stat_wal;

-- Активность checkpoint (PG17+: pg_stat_checkpointer; PG16-: pg_stat_bgwriter)
SELECT * FROM pg_stat_bgwriter;
```

```sql
-- Сколько WAL накопилось с последнего checkpoint
SELECT pg_size_pretty(
         pg_wal_lsn_diff(pg_current_wal_lsn(), checkpoint_lsn)
       ) AS since_checkpoint
FROM pg_control_checkpoint();
```

## Грабли и мифы

1. **`fsync=off` = быстрее и «нормально»?** Нет: при сбое питания вы получите **повреждённую** базу, а не «откат последних транзакций». Только для одноразовых тестовых стендов.
2. **`synchronous_commit=off` не уменьшает объём WAL** — только число fsync. И не защищает от потери последних коммитов.
3. **Частые checkpoint'ы вредны.** Они вызывают пики записи и раздувают WAL из-за FPI. Ориентир: checkpoint раз в 5–15 минут при стабильной нагрузке, а не «каждые 30 секунд».
4. **`max_wal_size` — не лимит диска.** WAL может превысить его при интенсивной записи; следи за свободным местом в `pg_wal`.
5. **Реплика — не бэкап.** `DROP TABLE` мгновенно уедет на реплику. Нужен PITR/архив.
6. **WAL пишется и на read-only запросы?** Только на изменения (включая hint bits — но они не логируются). Чистое чтение WAL не генерирует.

## Эксперимент

```sql
-- 1. Объём WAL от вставки, обновления и удаления
CREATE TABLE wal_demo (id int, v text);
SELECT pg_current_wal_lsn() AS start \gset

INSERT INTO wal_demo SELECT g, repeat('x', 100) FROM generate_series(1, 100000) g;
SELECT pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), :'start')) AS insert_wal;

SELECT pg_current_wal_lsn() AS start \gset
UPDATE wal_demo SET v = v || 'y';
SELECT pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), :'start')) AS update_wal;

-- 2. CHECKPOINT и последующий UPDATE: WAL вырастет из-за full-page images
CHECKPOINT;
SELECT pg_current_wal_lsn() AS start \gset
UPDATE wal_demo SET v = v || 'z' WHERE id <= 100;
SELECT pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), :'start')) AS wal_after_checkpoint;
```

В лаборатории на Docker ([[Практикум/Лаборатория на Docker]]) можно ещё и убить контейнер `docker kill -9` и посмотреть crash recovery в логах.

## Связанное

[[Внутрянка/Архитектура PostgreSQL]] · [[Внутрянка/MVCC и версии строк]] · [[Внутрянка/Репликация]] · [[Оптимизация/Тюнинг параметров сервера]] · [[ACID]]

## Источники

- PostgreSQL Docs: *Write-Ahead Logging (WAL)*, *Reliability*, `pg_control_checkpoint()`, `pg_walinspect`
- Егор Рогов, «PostgreSQL 14 Internals», гл. 6–7
- Hironobu Suzuki, «The Internals of PostgreSQL», ch. 9 (WAL)
