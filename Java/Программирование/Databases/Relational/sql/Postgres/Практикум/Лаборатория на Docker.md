# Лаборатория на Docker

Песочница для всех экспериментов ветки [[PostgreSQL]]: PostgreSQL 18, расширения диагностики, 1 млн заказов. Всё ломать можно и нужно.

---

## Что нужно

- Docker + Docker Compose
- `psql` (клиент) — есть в системе
- ~2 ГБ свободного места

## Структура

```
Практикум/
├── docker-compose.yml
├── init/
│   ├── 00-extensions.sql     расширения
│   └── 01-demo-data.sql      схема lab + данные
├── labs/
│   ├── 01-explain.sql
│   ├── 02-indexes.sql
│   ├── 03-cardinality.sql
│   ├── 04-joins.sql
│   ├── 05-locking.sql
│   ├── 06-pagination.sql
│   └── 07-bloat.sql
├── Лаборатория на Docker.md   ← эта заметка
└── Лабораторки.md             ← сценарии и вопросы
```

---

## Запуск

```bash
cd "…/sql/Postgres/Практикум"

docker compose up -d
docker compose ps            # ждём healthy
docker compose logs -f pg    # видно инициализацию и ошибки
```

Подключение:

```bash
psql -h localhost -p 5433 -U postgres -d lab
# пароль: postgres
```

Порт **5433**, чтобы не конфликтовать с локальным сервером на 5432.

### Проверка, что всё на месте

```sql
SELECT version();
SHOW shared_preload_libraries;      -- pg_stat_statements,auto_explain
SHOW track_io_timing;               -- on
SHOW random_page_cost;              -- 1.1

SELECT count(*) FROM lab.orders;    -- 1 000 000
SELECT count(*) FROM lab.users;     -- 100 000
SELECT count(*) FROM lab.events;    -- 200 000

\dx                                  -- список расширений
```

---

## Управление

```bash
docker compose stop          # остановить (данные живы)
docker compose start         # запустить снова
docker compose down          # удалить контейнер (том с данными жив)
docker compose down -v       # ПОЛНЫЙ СБРОС: удаляет том и данные
docker compose logs -f pg    # логи
```

### Сброс только данных (без пересоздания тома)

```sql
DROP SCHEMA lab CASCADE;
-- затем заново выполнить init/01-demo-data.sql
\i /docker-entrypoint-initdb.d/01-demo-data.sql
```

### Изменить параметр

```sql
-- сессионно
SET work_mem = '128MB';

-- глобально (без рестарта, если context = sighup/user)
ALTER SYSTEM SET work_mem = '16MB';
SELECT pg_reload_conf();

-- глобально, но требует рестарта (shared_buffers, max_connections, wal_level)
ALTER SYSTEM SET shared_buffers = '512MB';
-- затем: docker compose restart pg
```

Посмотреть, что требует рестарта:

```sql
SELECT name, setting, context
FROM pg_settings
WHERE name IN ('shared_buffers','work_mem','max_connections','shared_preload_libraries');
-- context = postmaster → только рестарт
```

---

## Эксперимент: crash recovery

Отличный способ увидеть WAL в действии:

```bash
# 1. Записать данные
psql -h localhost -p 5433 -U postgres -d lab -c \
  "INSERT INTO lab.orders (user_id,status,total,created_at) VALUES (1,'new',10,now());"

# 2. Убить контейнер без graceful shutdown
docker kill -9 pg-lab

# 3. Запустить снова
docker compose up -d

# 4. В логах — recovery
docker compose logs pg | grep -i recover
# LOG: database system was not properly shut down; automatic recovery in progress
# LOG: redo starts at ...
# LOG: database system is ready to accept connections
```

Данные на месте — WAL доигран с последней контрольной точки.

Сравни с `docker compose stop` (graceful): recovery не будет.

---

## Полезные мелочи

```sql
-- Текущее время выполнения
\timing on

-- Вертикальный вывод для широких строк
\x auto

-- Выполнить файл
\i labs/01-explain.sql

-- Кто я
SELECT current_database(), current_user, pg_backend_pid();

-- Размеры
\dt+ lab.*
\di+ lab.*
```

Выполнить лабораторку одной командой:

```bash
psql -h localhost -p 5433 -U postgres -d lab -f labs/01-explain.sql
```

---

## Если что-то пошло не так

| Проблема | Решение |
|---|---|
| `port is already allocated` | занят 5433 → поменяй в `docker-compose.yml` (`"5434:5432"`) |
| `psql: connection refused` | контейнер ещё стартует: `docker compose ps`, `docker compose logs pg` |
| init-скрипты не выполнились | они запускаются **только при пустом томе**: `docker compose down -v` и заново |
| `permission denied` на томе | проверь права на каталог, либо `docker compose down -v` |
| не хватает памяти | уменьши `shared_buffers`/`work_mem` в compose |
| в PG18 «пропали» данные после рестарта | том должен быть смонтирован в `/var/lib/postgresql` (в 18 изменился `PGDATA`) |

---

## Ограничения песочницы

- Один инстанс, без реплики. Для репликации нужен отдельный compose-профиль (не входит в базовый).
- `hypopg`, `pg_repack`, `pg_cron` в официальный образ не входят — ставятся отдельным образом/пакетом.
- Данные генерируются случайно: планы и цифры будут немного отличаться от заметок — это нормально, важны порядки величин.

---

## Связанное

[[Практикум/Лабораторки]] · [[Шпаргалки/Конфиг на старте]] · [[Внутрянка/WAL и durability]] · [[Оптимизация/Методика разбора медленного запроса]]
