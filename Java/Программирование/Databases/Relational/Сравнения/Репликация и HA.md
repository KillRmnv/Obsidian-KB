# Репликация и HA

## Зачем это нужно

Репликация выглядит одинаково («копия данных на другом сервере»), но **что именно** передаётся и **как** выбирается новый лидер — определяет лаг, потерю данных при failover и сложность эксплуатации.

## Три способа репликации

| Способ | Что передаётся | Примеры |
|---|---|---|
| **Физическая** | байты журнала (WAL/redo) | PG streaming, Oracle Data Guard, SQL Server AG, MySQL (через binlog, но физически) |
| **Логическая** | изменения строк (INSERT/UPDATE/DELETE) | PG logical, MySQL binlog ROW, Oracle GoldenGate, SQL Server replication |
| **Консенсус** | журнал Raft/Paxos | CockroachDB, TiDB, Yugabyte, Spanner |

## PostgreSQL

- **Streaming replication**: `walsender` → `walreceiver`; standby применяет WAL.
- **Синхронная**: `synchronous_standby_names`, `synchronous_commit = remote_write|on|remote_apply`.
- **Логическая**: `CREATE PUBLICATION` / `CREATE SUBSCRIPTION`; `wal_level = logical`.
- **Слоты репликации**: держат WAL; `max_slot_wal_keep_size` защищает диск.
- **Failover**: Patroni/repmgr/облако; `pg_rewind` для возврата старого primary.
- **`hot_standby_feedback`**: реплика сообщает `xmin`, чтобы vacuum не удалил нужные версии (ценой bloat на primary).

## MySQL/InnoDB

- **binlog** (ROW) + GTID; асинхронная по умолчанию.
- **semi-sync**: master ждёт подтверждения хотя бы одной реплики (не полная синхронность).
- **Group Replication / InnoDB Cluster**: синхронная группа на Paxos-подобном протоколе, автоматический failover.
- **Clone plugin**: физическая копия инстанса.
- **Multi-source replication**: одна реплика от нескольких master'ов.

## SQL Server

- **Always On Availability Groups**: синхронные/асинхронные реплики, автоматический failover, читаемые secondary, listener.
- **Log shipping**: асинхронная, ручной/полуавтоматический failover.
- **Replication**: snapshot/transactional/merge — логическая.
- **Azure SQL**: geo-replication, auto-failover groups.

## Oracle

- **Data Guard**: физический standby (redo apply); режимы `MAXIMUM PERFORMANCE` / `MAXIMUM AVAILABILITY` / `MAXIMUM PROTECTION`.
- **Active Data Guard**: чтение со standby.
- **GoldenGate**: логическая репликация (гетерогенная).
- **RAC**: shared-disk кластер (не репликация, а HA/масштабирование instance).
- **Flashback**: откат во времени (query/table/database).

## Распределённые (Raft/Paxos)

- **CockroachDB/TiDB/Yugabyte**: каждый диапазон — Raft-группа; лидер на запись, кворум на коммит.
- **Spanner**: Paxos + TrueTime → внешняя согласованность.
- **Failover** = выборы лидера, секунды; данные не теряются (кворум).
- **Цена**: межрегиональная latency на запись; чтение — с ближайшей реплики (follower reads).

## Сравнение

| | PostgreSQL | MySQL | SQL Server | Oracle | CockroachDB |
|---|---|---|---|---|---|
| Физическая | streaming | binlog (по сути) | AG | Data Guard | Raft |
| Логическая | publication | binlog ROW | replication | GoldenGate | changefeeds |
| Sync | `synchronous_commit` | semi-sync | AG synchronous | Max Availability/Protection | кворум Raft |
| Failover | Patroni/repmgr | InnoDB Cluster/Orchestrator | AG (auto) | Data Guard broker | авто (Raft) |
| Читаемые реплики | да (hot standby) | да | да (AG) | да (Active DG) | да (follower reads) |
| Потеря при async failover | последние транзакции | последние транзакции | последние транзакции | последние транзакции | нет (кворум) |
| Лаг | `pg_stat_replication` | `SHOW REPLICA STATUS` | AG dashboard | `V$DATAGUARD_STATS` | метрики кластера |

## Лаг и чтение с реплики

| | PostgreSQL | MySQL | SQL Server | Oracle |
|---|---|---|---|---|
| Метрика | `pg_wal_lsn_diff`, `replay_lag` | `Seconds_Behind_Source` | `sys.dm_hadr_database_replica_states` | `V$DATAGUARD_STATS` |
| Read-your-writes | `remote_apply` / sticky | semi-sync + sticky | AG sync + listener | Max Availability |
| Конфликты с vacuum | `hot_standby_feedback` | нет (undo) | нет (версии в tempdb) | нет (undo) |
| Долгий запрос на реплике | может быть убит (`max_standby_*_delay`) | не блокирует purge | читает версии | не блокирует undo |

## Failover: чек-лист

1. **Кворум/менеджер**: Patroni, repmgr, Orchestrator, AG, Data Guard broker — без них split-brain.
2. **VIP/DNS/listener**: клиенты должны переключиться автоматически.
3. **`pg_rewind`/rebuild**: вернуть старый primary в строй.
4. **Проверка данных**: контрольные суммы/сверка после переключения.
5. **Реплики**: перенастроить `primary_conninfo`, слоты, каскады.

## Грабли и мифы

1. **«Реплика = бэкап»** — нет: `DROP TABLE` мгновенно уедет.
2. **Асинхронная реплика теряет данные** при failover — ровно те транзакции, что не доехали.
3. **Синхронная репликация увеличивает latency коммита** на RTT; `remote_apply` — ещё больше.
4. **Забытый слот репликации** съедает диск primary (PG).
5. **`hot_standby_feedback=on`** раздувает таблицы на primary (vacuum не убирает версии).
6. **MySQL semi-sync ≠ sync**: master может продолжить работу без реплики (таймаут).
7. **Group Replication/Galera** имеют ограничения на `XA`, `LOCK TABLES`, размер транзакции.
8. **Raft не «бесплатный»**: межрегиональная запись = latency; проектируй локальность.
9. **RAC — не шардирование**: общий диск, один образ данных.
10. **Failover без кворума** = split-brain = потеря данных; всегда нужен менеджер.

## Связанное

[[PostgreSQL]] · [[Внутрянка/Репликация]] · [[шардирование]] · [[CAP]] · [[Другие/MySQL и InnoDB]] · [[Другие/SQL Server]] · [[Другие/Oracle Database]] · [[Другие/CockroachDB, TiDB и YugabyteDB]]

## Источники

- PostgreSQL Docs: *High Availability, Load Balancing, and Replication*, *Logical Replication*
- MySQL Docs: *Replication*, *Group Replication*
- SQL Server Docs: *Always On Availability Groups*
- Oracle Docs: *Data Guard Concepts and Administration*
