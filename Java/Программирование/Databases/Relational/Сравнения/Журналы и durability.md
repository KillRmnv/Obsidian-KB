# Журналы и durability

## Зачем это нужно

Durability — единственная причина, по которой БД вообще пишет на диск синхронно. Все СУБД используют **write-ahead logging** или его аналог, но структура журнала, единицы измерения и настройки различаются. От этого зависит latency коммита, скорость recovery и объём WAL/redo/binlog.

## Общая идея

```
1. Изменение → страница в памяти (грязная)
2. Изменение → запись в журнал
3. COMMIT → журнал сброшен на диск (fsync)
4. Позже — грязные страницы на диск (checkpoint)
```

Различия — в том, **что** пишется в журнал, **как** он организован и **когда** усекается.

## PostgreSQL: WAL

- Сегменты по 16 МБ в `pg_wal/`, LSN — 64-битная позиция.
- **Checkpoint** сбрасывает страницы и фиксирует позицию; после — старые сегменты можно удалять/архивировать.
- **Full-page writes** после checkpoint — защита от torn pages.
- `synchronous_commit = on|off|local|remote_write|remote_apply`.
- Архивация — `archive_command`/`archive_library` → PITR.

## MySQL/InnoDB: redo + undo + doublewrite + binlog

| Компонент | Назначение |
|---|---|
| **redo log** | crash recovery; циклический (`innodb_redo_log_capacity`) |
| **undo log** | MVCC и rollback |
| **doublewrite buffer** | защита от torn pages (аналог full_page_writes, но иначе) |
| **binlog** | репликация и PITR; отдельный от redo |

- Коммит: redo (fsync по `innodb_flush_log_at_trx_commit`) + binlog (fsync по `sync_binlog`).
- **Два fsync на коммит** при полной durability → latency выше, чем в PG с одним WAL.
- `innodb_flush_log_at_trx_commit=1` + `sync_binlog=1` — «как synchronous_commit=on».
- Recovery: redo + undo, затем применение binlog (если нужно).

## SQL Server: transaction log + VLF

- **Один файл** лога, разбитый на **VLF** (Virtual Log Files).
- Усечение зависит от модели восстановления: `SIMPLE` (после checkpoint), `FULL` (только после log backup), `BULK_LOGGED`.
- `log_reuse_wait_desc` — что мешает усечению.
- **Нет WAL-сегментов** как в PG: один растущий файл, который нужно бэкапить.
- `DELAYED_DURABILITY` — аналог `synchronous_commit=off`.

## Oracle: redo + undo + archive

- **Online redo logs** — циклические группы; **archive log** — архив для PITR.
- **Undo-сегменты** — для MVCC и rollback.
- **SCN** вместо LSN; checkpoint — CKPT.
- `COMMIT WRITE IMMEDIATE WAIT` (default) / `BATCH NOWAIT` (аналог `synchronous_commit=off`).
- RMAN — бэкап/restore/PITR.

## Db2: transaction log

- **Circular** (без PITR) или **archive/retain** (с PITR).
- `LOGFILSIZ`, `LOGPRIMARY`, `LOGSECOND`; `db2pd -logs`.
- Recovery — `RESTART DATABASE`, `ROLLFORWARD`.

## Firebird: страницы + journal

- Нет WAL в смысле PG; **`FORCE WRITE = ON`** — fsync на коммит.
- `nbackup` — инкрементальные бэкапы на уровне страниц; `gbak` — логический.
- При сбое — `gfix -mend`, автоrecovery.

## Распределённые: Raft log

- **CockroachDB / TiDB / Yugabyte / Spanner**: журнал — это **Raft log** (или Paxos log), реплицируемый на кворум.
- Нет отдельного «локального WAL» в смысле PG; durability = подтверждение кворума.
- PITR — через backup + log backup / `AS OF SYSTEM TIME`.

## Сравнение

| | PostgreSQL | InnoDB | SQL Server | Oracle |
|---|---|---|---|---|
| Журнал | WAL-сегменты 16 МБ | redo (циклический) | один файл + VLF | online redo + archive |
| Позиция | LSN | LSN | LSN | SCN |
| Undo | не нужен | undo log | версии в tempdb (RCSI) | undo-сегменты |
| Torn pages | full_page_writes | doublewrite | нет (страницы 8 КБ + checksum) | block checksums |
| Усечение | checkpoint + archive | checkpoint + purge | модель восстановления | checkpoint + archive |
| Гарантия коммита | `synchronous_commit` | `innodb_flush_log_at_trx_commit` | `DELAYED_DURABILITY` | `COMMIT WRITE` |
| PITR | WAL archive | binlog + redo | log backup | RMAN + archive |
| Репликация | WAL sender | binlog | AG/log shipping | Data Guard |

## Latency коммита: что влияет

1. **Число fsync на коммит**: PG — 1 (WAL), InnoDB — 2 (redo + binlog), SQL Server — 1 (log).
2. **Групповой коммит**: PG собирает пачку (`wal_writer_delay`); InnoDB — `binlog_group_commit_sync_delay`.
3. **Синхронная репликация**: добавляет RTT до реплики.
4. **Диск**: NVMe vs сетевой EBS; `fdatasync` vs `fsync`.

```sql
-- PostgreSQL: замерить стоимость коммита
\timing on
INSERT INTO t VALUES (1);   -- с synchronous_commit=on
SET synchronous_commit = off;
INSERT INTO t VALUES (2);   -- быстрее
```

## Диагностика

| Задача | PostgreSQL | MySQL | SQL Server | Oracle |
|---|---|---|---|---|
| Объём журнала | `pg_stat_wal`, `pg_wal_lsn_diff` | `SHOW ENGINE INNODB STATUS` (log) | `sys.dm_db_log_space_usage` | `V$LOG`, `V$ARCHIVED_LOG` |
| Checkpoint | `pg_stat_checkpointer` (17+) | `SHOW ENGINE INNODB STATUS` | `sys.dm_os_performance_counters` | `V$INSTANCE_RECOVERY` |
| Содержимое | `pg_waldump`, `pg_walinspect` | `mysqlbinlog` | `fn_dblog` (недокументировано) | `LogMiner` |
| Recovery | лог + `pg_controldata` | `SHOW ENGINE INNODB STATUS` | `sys.dm_exec_requests` (recovery) | alert log |

## Грабли и мифы

1. **`synchronous_commit=off` не уменьшает объём журнала** — только число fsync.
2. **`fsync=off` (PG) / `innodb_flush_log_at_trx_commit=0` (MySQL)** — это не тюнинг, а отказ от durability.
3. **`FULL` recovery model в SQL Server без log backup** = растущий лог до заполнения диска.
4. **`max_wal_size` — не лимит**, WAL может превысить его при нагрузке.
5. **Частые checkpoint'ы** увеличивают объём WAL из-за full-page images (PG) и doublewrite (InnoDB).
6. **Два журнала в MySQL** (redo + binlog) — двойной fsync; отсюда latency.
7. **Raft log — не WAL**: нельзя «подкрутить» checkpoint так же, как в PG.
8. **Реплика — не бэкап**: журнал реплицирует и ошибки; нужен PITR.

## Связанное

[[PostgreSQL]] · [[Внутрянка/WAL и durability]] · [[Другие/MySQL и InnoDB]] · [[Другие/SQL Server]] · [[Другие/Oracle Database]] · [[Сравнения/Репликация и HA]]

## Источники

- PostgreSQL Docs: *Write-Ahead Logging*, *Reliability*
- MySQL Docs: *InnoDB Redo Log*, *Binary Log*, *Doublewrite Buffer*
- SQL Server Docs: *Transaction Log*, *Recovery Models*
- Oracle Concepts: *Redo Log*, *Undo*
