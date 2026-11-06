# Aurora и облачные Postgres

## Если знаешь PostgreSQL (TL;DR)

1. **PostgreSQL-совместимый SQL, но другое хранилище**: вычисления (compute) отделены от хранения (storage). WAL уходит в распределённый storage-слой с кворумом.
2. **Репликация — на уровне storage, а не WAL**: реплики читают те же страницы, лаг меньше, но есть свои ограничения.
3. **Нет доступа к файлам PGDATA**, нет `pg_ctl`, нет суперпользователя ОС — только параметры и SQL.
4. **`shared_buffers` и checkpoint ведут себя иначе**: storage сам решает, что и когда писать.
5. **Бэкап и PITR — управляемые**: continuous backup в S3, restore на любую секунду в пределах retention.

## Ниша

Облачный прод без DBA: RDS/Aurora (AWS), Cloud SQL/AlloyDB (GCP), Azure Database for PostgreSQL, Neon (serverless), Supabase. Плюс — управляемые «PG-совместимые» с другим движком под капотом.

## Кто есть кто

| Сервис | Движок | Ключевая идея |
|---|---|---|
| **Amazon RDS for PostgreSQL** | vanilla PG | управляемый PG, storage = EBS |
| **Amazon Aurora PostgreSQL** | форк PG | storage-слой с кворумом, 6 копий в 3 AZ |
| **Amazon Aurora MySQL** | форк MySQL | то же, но MySQL-совместимость |
| **Google Cloud SQL** | vanilla PG/MySQL/SQL Server | управляемый, региональный |
| **Google AlloyDB** | форк PG | колоночный движок + умный storage |
| **Azure Database for PostgreSQL** | vanilla PG (Flexible Server) | управляемый, зоны |
| **Neon** | форк PG | разделение compute/storage, ветвление (copy-on-write) |
| **Supabase** | vanilla PG | BaaS поверх PG |
| **YugabyteDB Aeon / CockroachDB Cloud** | NewSQL | распределённые (см. [[Другие/CockroachDB, TiDB и YugabyteDB]]) |

## Aurora: чем отличается от PG

### Хранение

- **Storage-слой** — распределённая система: 6 копий данных в 3 AZ, кворум 4/6 на запись, 3/6 на чтение.
- Запись идёт **только в storage**, а не в локальные файлы; WAL-сегменты тоже уходят в storage.
- **Нет `fsync` на каждом коммите в привычном смысле** — durability обеспечивает storage-слой.
- **Checkpoint** менее болезненный: грязные страницы не нужно массово сбрасывать на диск.
- **Реплики** читают те же страницы из storage, а не применяют WAL → лаг меньше, но `hot_standby_feedback`-проблемы остаются.

### Параметры и ограничения

- Нет доступа к ОС: нельзя `pg_repack` без расширения, нельзя `pg_ctl`, нельзя менять `wal_level` произвольно.
- `shared_buffers` — на instance; storage-кэш отдельный.
- **Нет `VACUUM FULL`-эффекта на storage** в том же смысле — но bloat всё равно есть.
- **`pg_stat_statements`** есть, `auto_explain` — через parameter group.
- **Logical replication** поддерживается (PG10+ на Aurora).
- **Extensions**: список ограничен; `pg_repack` есть, `pg_cron` есть (ограниченно), `hypopg` — нет.

### Репликация и HA

- **Aurora Replicas** — до 15, читают storage; failover — повышение реплики.
- **Global Database** — межрегиональная репликация на уровне storage (латентность ~1 с).
- **Backtrack** (MySQL) — откат во времени без restore; для PG — PITR.
- **RDS Proxy** — пул соединений (аналог PgBouncer).

### Диагностика

```sql
-- Как в PG, но с оговорками
SELECT * FROM pg_stat_activity;
SELECT * FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 10;
SELECT * FROM aurora_stat_*;   -- свои вьюхи (Aurora)
```

- **Performance Insights** — управляемый мониторинг (wait events, top SQL) — аналог `pg_stat_activity` + `pg_stat_statements` + графики.
- **Enhanced Monitoring** — метрики ОС.
- **`aurora_stat_plans`**, `aurora_stat_statements` — расширения Aurora.

## AlloyDB (GCP)

- **Форк PostgreSQL** + колоночный движок (columnar engine) для аналитики.
- **Умный storage**: кэш, pre-fetch, разделение compute/storage.
- **`google_columnar_engine`** — ускорение аналитических запросов без изменения SQL.
- **`pg_stat_statements`**, **`auto_explain`**, **`pg_hint_plan`** — есть.
- **Read pool** — отдельные ноды для чтения.

## Neon

- **Compute/storage separation**: PostgreSQL в compute-ноде, storage — собственный (pageserver + safekeepers).
- **Branching**: копия БД на любой момент — copy-on-write, секунды (аналог git-ветки).
- **Autoscaling compute**: scale to zero, холодный старт.
- **Ограничения**: не все расширения, нет суперпользователя, latency на холодном старте.

## Cloud SQL / Azure / RDS

- Vanilla PG, управляемые: бэкапы, PITR, реплики, failover.
- **Ограничения**: нет ОС, ограниченный набор расширений, нельзя `shared_preload_libraries` произвольно.
- **`pg_stat_statements`** обычно включён; **`auto_explain`** — через флаги.
- **`pg_repack`/`pg_cron`** — зависят от провайдера.

## Грабли для приходящего с PG

1. **Нет файлов и ОС** — `pg_ctl`, `pg_waldump`, `pg_repack` без расширения недоступны.
2. **`shared_buffers` и checkpoint** ведут себя иначе; не переноси локальные тюнинги 1:1.
3. **Расширения ограничены** — проверь список до миграции.
4. **Superuser нет** — часть `ALTER SYSTEM`, `COPY FROM PROGRAM`, `pg_read_file` запрещены.
5. **Версии PG отстают** — Aurora/Cloud SQL обновляются не в день релиза.
6. **Storage-стоимость** — платишь за IOPS/throughput; «дешёвый» диск может стать узким местом.
7. **Лаг реплик** — меньше, чем в vanilla PG, но не нулевой; read-your-writes не гарантирован.
8. **`VACUUM` и bloat** остаются: управляемый ≠ без обслуживания.
9. **Параметры через parameter group** — не все применяются без рестарта.
10. **PITR ограничен retention** (обычно 7–35 дней) — не «бэкап навсегда».

## Что проверить руками

```sql
SELECT version();
SHOW shared_buffers;
SHOW shared_preload_libraries;

SELECT * FROM pg_stat_activity LIMIT 5;
SELECT * FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 5;

-- Aurora-специфичное (если есть)
SELECT * FROM aurora_stat_plans LIMIT 10;
```

## Связанное

[[PostgreSQL]] · [[Другие/CockroachDB, TiDB и YugabyteDB]] · [[Сравнения/Репликация и HA]] · [[Сравнения/Хранение — heap vs clustered index]] · [[Оптимизация/Тюнинг параметров сервера]]

## Источники

- AWS: «Amazon Aurora User Guide», «Performance Insights»
- Google Cloud: «AlloyDB for PostgreSQL», «Cloud SQL»
- Neon Docs: «Architecture», «Branching»
- Azure Database for PostgreSQL Flexible Server docs
