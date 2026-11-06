# MVCC и очистка мусора

## Зачем это нужно

Все «взрослые» СУБД дают читателю не блокировать писателя. Но делают это по-разному, и от этого зависит **всё**: где живёт мусор, кто его чистит, какие настройки крутить, как выглядит деградация.

## Четыре подхода

### 1. Версии в heap (PostgreSQL)

```
строка: [v1 xmin=100 xmax=105] [v2 xmin=105 xmax=0]
                                 ↑ актуальная
```

- `UPDATE` = новая версия + пометка старой.
- Старые версии лежат **в той же таблице** → bloat.
- Чистит **`VACUUM`** (autovacuum).
- Долгая транзакция держит `xmin` → мусор не убирается.
- Нужен **freeze** (32-битные XID).

### 2. Undo-сегменты (MySQL/InnoDB, Oracle)

```
строка: [v2, roll_ptr → undo]
undo:   [v1] ← откат для читателей и rollback
```

- `UPDATE` меняет строку **на месте**, старую версию кладёт в undo.
- Читатель идёт по `roll_ptr`, пока не найдёт видимую версию.
- Чистит **purge thread** (InnoDB) / **undo retention** (Oracle).
- Таблица не пухнет от старых версий, но пухнут **undo-таблицы**.
- Нет freeze; в InnoDB — 6-байтовый trx id.

### 3. Версии в tempdb (SQL Server RCSI/SNAPSHOT)

- По умолчанию — **блокировки**, не MVCC.
- При `READ_COMMITTED_SNAPSHOT`/`SNAPSHOT` старые версии пишутся в **tempdb**.
- Чистит **ghost cleanup** (для ghost records) и version store (для snapshot).
- Долгая транзакция → рост tempdb.

### 4. MGA — версии в файле (Firebird)

- Как PG: старая версия остаётся, новая пишется рядом.
- Чистит **`SWEEP`** (ручной/фоновый) + ленивая сборка при чтении.
- Долгая транзакция → OAT не двигается → garbage растёт.

## Сравнение

| | PostgreSQL | InnoDB | Oracle | SQL Server | Firebird |
|---|---|---|---|---|---|
| Где старые версии | heap | undo | undo | tempdb (если RCSI) | файл БД |
| Чистит | `VACUUM`/autovacuum | purge thread | undo retention | ghost cleanup / version store | `SWEEP` |
| Видимый симптом | bloat таблиц/индексов | history list length | undo tablespace, ORA-01555 | рост tempdb | garbage, рост файла |
| Долгая транзакция | блокирует vacuum | блокирует purge | блокирует undo reuse | блокирует cleanup | блокирует sweep |
| Freeze/wraparound | **есть** (32-бит XID) | нет (6 байт) | нет (SCN 48 бит) | нет | ограничение транзакций |
| Читатель блокирует писателя | нет | нет | нет | **да** (по умолчанию) | нет |

## Как выглядит деградация

**PostgreSQL**:

```
1. Много UPDATE → n_dead_tup растёт → таблица и индексы растут
2. Autovacuum не успевает (scale factor 0.2) → bloat
3. Index-only scan перестаёт работать (VM не обновлена)
4. Долгая транзакция → vacuum не может убрать → ещё больше bloat
5. Приближение XID к 2^31 → anti-wraparound vacuum
```

**InnoDB**:

```
1. Много UPDATE → undo растёт, history list length увеличивается
2. Purge thread не успевает / долгая транзакция → undo tablespace растёт
3. Запросы к старым версиям идут по длинной цепочке undo → медленнее
4. В крайнем случае — "history list length" в сотнях тысяч и деградация
```

**Oracle**:

```
1. Долгий запрос → undo перезаписан → ORA-01555: snapshot too old
2. Undo tablespace растёт → автоextend → место на диске
3. Лечение: UNDO_RETENTION, размер undo, разбиение отчётов
```

**SQL Server**:

```
1. RCSI включён → версии в tempdb
2. Долгая транзакция → version store растёт → tempdb пухнет
3. Ghost records от DELETE → ghost cleanup
```

## Диагностика: перевод команд

| Задача | PostgreSQL | MySQL | Oracle | SQL Server |
|---|---|---|---|---|
| Мусор | `pg_stat_user_tables.n_dead_tup` | `History list length` в `SHOW ENGINE INNODB STATUS` | `V$UNDOSTAT`, `DBA_UNDO_EXTENTS` | `sys.dm_db_index_physical_stats` (ghost) |
| Точный bloat | `pgstattuple_approx` | `information_schema.INNODB_TABLESTATS` | `DBMS_SPACE` | `sys.dm_db_index_physical_stats` |
| Долгая транзакция | `pg_stat_activity.backend_xmin` | `INNODB_TRX.trx_started` | `V$TRANSACTION.start_time` | `sys.dm_tran_active_transactions` |
| Очистка | `VACUUM` | `purge` (авто) | `undo retention` | `ghost cleanup` (авто) |
| «Полная» очистка | `VACUUM FULL` / `pg_repack` | `OPTIMIZE TABLE` (перестройка) | `SHRINK SPACE` | `ALTER INDEX REBUILD` |
| XID-возраст | `age(relfrozenxid)` | — | — | — |

## Что общего

1. **Читатель не блокирует писателя** (кроме SQL Server по умолчанию).
2. **Старые версии нужно кому-то убирать** — всегда есть фоновый процесс.
3. **Долгая транзакция — враг очистки** во всех моделях.
4. **`UPDATE` дороже `INSERT`** везде, просто по разным причинам.

## Грабли и мифы

1. **«В MySQL нет bloat»** — есть undo bloat и фрагментация таблиц; просто выглядит иначе.
2. **«Oracle не пухнет»** — пухнет undo tablespace и сегменты; `SHRINK SPACE` существует не просто так.
3. **`VACUUM` в PG не освобождает место ОС** — только переиспользует; в InnoDB purge тоже не уменьшает файл.
4. **`VACUUM FULL` — не «оптимизация»**, а перестройка с `ACCESS EXCLUSIVE`.
5. **SQL Server по умолчанию не MVCC** — читатель ждёт писателя, если не включён RCSI.
6. **`freeze` — уникальная проблема PG** (32-битные XID); в других СУБД её нет.
7. **Версии в undo дороже для чтения старых снапшотов** (цепочка), версии в heap дороже для места.

## Связанное

[[PostgreSQL]] · [[Внутрянка/MVCC и версии строк]] · [[Внутрянка/VACUUM и autovacuum]] · [[Другие/MySQL и InnoDB]] · [[Другие/Oracle Database]] · [[Другие/Firebird]] · [[Сравнения/Хранение — heap vs clustered index]]

## Источники

- PostgreSQL Docs: *Concurrency Control*, *Routine Vacuuming*
- MySQL Docs: *InnoDB Multi-Versioning*, *Purge*
- Oracle Concepts: *Data Concurrency and Consistency*, *Undo*
- SQL Server Docs: *Row Versioning*, *Ghost Cleanup*
- Firebird Docs: *MVCC*, *Sweep*
