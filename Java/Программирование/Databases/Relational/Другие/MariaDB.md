# MariaDB

## Если знаешь PostgreSQL (TL;DR)

1. **Это форк MySQL 5.5**, ушедший своей дорогой: другие движки (Aria, MyRocks, ColumnStore), другой оптимизатор, свои фичи.
2. **Совместимость с MySQL частичная**: SQL и протокол в основном совпадают, но 8.0-фичи (CTE с 10.2, оконные с 10.2, `JSON_TABLE` позже, `CHECK` с 10.2) появились в разное время.
3. **`system-versioned tables`** — встроенная темпоральность (`WITH SYSTEM VERSIONING`), которой нет ни в PG, ни в MySQL.
4. **`SEQUENCE`** есть (10.3+), в отличие от MySQL.
5. **Galera Cluster** — синхронная multi-master репликация на уровне плагина.

## Ниша

Хостинги (Wikipedia, WordPress-парки), замена MySQL без лицензионных и версионных сюрпризов, проекты, которым нужны Galera/ColumnStore. Версии: 10.6 LTS, 10.11 LTS, 11.4 LTS.

## Чем отличается от MySQL

| | MySQL 8.0/8.4 | MariaDB 11.x |
|---|---|---|
| Владелец | Oracle | MariaDB Foundation/Plc |
| Default engine | InnoDB | InnoDB |
| Другие движки | MyISAM, MEMORY | + **Aria**, **MyRocks**, **ColumnStore**, **Spider** |
| JSON | бинарный тип `JSON` | алиас `LONGTEXT` + `JSON_VALID` CHECK |
| CTE / окна | 8.0 | 10.2 |
| `CHECK` constraints | 8.0.16 | 10.2 |
| Sequences | нет | **есть** (10.3) |
| System-versioned | нет | **есть** (10.3) |
| Invisible columns | 8.0.23 | 10.3 |
| `RETURNING` | нет | **есть** для `INSERT`/`DELETE` (10.5) |
| Репликация | GTID, Group Replication | GTID, **Galera** |
| Аутентификация | caching_sha2 | unix_socket, ed25519, PAM |
| Оптимизатор | Hypergraph (8.0.20+) | свой, с 11.x переписан |

Для приложения разница чаще проявляется в мелочах: `JSON` ведёт себя иначе (в MariaDB это текст), `utf8mb4` collations другие, `information_schema` отличается набором таблиц.

## Хранение

InnoDB — тот же, что в MySQL (см. [[Другие/MySQL и InnoDB]]): clustered PK, 16 КБ страницы, undo + purge, redo + doublewrite + binlog.

Специфика MariaDB:

- **Aria** — «MyISAM с краш-безопасностью»: нет транзакций, но есть журнал для восстановления после сбоя. Для внутренних таблиц (`mysql.*` в старых версиях) и временных данных.
- **MyRocks** — LSM-дерево на RocksDB: лучше сжатие и запись, хуже точечное чтение. Аналог того, чего в PG нет «из коробки».
- **ColumnStore** — колоночный движок для OLAP внутри MariaDB (аналог Citus/ClickHouse-подхода, но в одном сервере).
- **Spider** — шардирование на уровне движка (федерация таблиц по разным серверам).

Смена движка у таблицы: `ALTER TABLE t ENGINE=MyRocks;` — переписывает таблицу (аналог `VACUUM FULL` по стоимости).

## Транзакции и MVCC

Как в InnoDB: undo-цепочки, read view, purge thread. Отличия MariaDB:

- **`innodb_snapshot_isolation`** — можно включить snapshot isolation, приблизив поведение к PG.
- **`innodb_instant_alter_column`** — `ALTER TABLE` меняет тип без перестройки (осторожно: старые строки конвертируются на лету).
- **`innodb_version`** расходится с MySQL: MariaDB-ветка InnoDB своя.

## Темпоральные таблицы (уникальная фича)

```sql
CREATE TABLE prices (
  id      INT PRIMARY KEY,
  price   DECIMAL(10,2),
  valid_from TIMESTAMP(6) GENERATED ALWAYS AS ROW START,
  valid_to   TIMESTAMP(6) GENERATED ALWAYS AS ROW END,
  PERIOD FOR SYSTEM_TIME (valid_from, valid_to)
) WITH SYSTEM VERSIONING;
```

- Каждое изменение создаёт строку в скрытой истории;
- запрос «как было»: `SELECT * FROM prices FOR SYSTEM_TIME AS OF '2026-01-01';`
- история чистится `DELETE HISTORY FROM prices BEFORE SYSTEM_TIME ...;`
- В PG аналог — расширение `temporal_tables` или ручные `valid_from/valid_to` + триггеры.

## Журналы и репликация

- redo + undo + doublewrite + binlog — как в MySQL.
- **GTID** для репликации (`gtid_strict_mode`).
- **Galera Cluster**: синхронная multi-master репликация; транзакции применяются на всех узлах через certification-based replication. Требует quorum; при split-brain узел переходит в `non-Primary`.
- **MaxScale** — прокси/роутер с read/write splitting, failover, фильтрами.
- **Binlog** можно читать как поток изменений (CDC) — аналог logical replication в PG.

## Диагностика

```sql
SHOW ENGINE INNODB STATUS\G
EXPLAIN ANALYZE SELECT ...;              -- 10.1+
ANALYZE FORMAT=JSON SELECT ...;          -- детальный план
SHOW EXPLAIN FOR <thread_id>;            -- план чужого запроса (удобно!)
SELECT * FROM information_schema.INNODB_TRX;
SELECT * FROM information_schema.INNODB_LOCK_WAITS;
SHOW STATUS LIKE 'Innodb_row_lock%';
```

`ANALYZE FORMAT=JSON` и `SHOW EXPLAIN FOR` — то, чего в MySQL нет и что очень помогает в проде.

## Грабли для приходящего с PG

1. **`JSON` — это `LONGTEXT`**: нет бинарного формата, индексы только через generated columns.
2. **Различия с MySQL 8.0** ломают миграцию в обе стороны: `utf8mb4_0900_ai_ci` в MariaDB нет, `CHECK` и `RETURNING` работают иначе.
3. **Aria/MyISAM не транзакционные** — не смешивай в одной транзакции с InnoDB.
4. **Galera — это не «просто реплика»**: нет `SELECT ... FOR UPDATE` между узлами без сертификации, есть ограничения на `XA`, `LOCK TABLES`.
5. **`sql_mode` по умолчанию мягче MySQL** — данные могут «тихо» обрезаться (`STRICT_TRANS_TABLES` проверь).
6. **`TIMESTAMP` 2038** — как в MySQL.
7. **Разные версии InnoDB** — поведение `innodb_flush_method`, `innodb_undo` отличается от MySQL-документации.

## Что проверить руками

```sql
SELECT VERSION();
SELECT @@sql_mode;
SHOW ENGINES;                        -- какие движки доступны
SHOW VARIABLES LIKE 'innodb_version';
SHOW VARIABLES LIKE 'transaction_isolation';

ANALYZE FORMAT=JSON SELECT * FROM orders WHERE user_id = 42;
```

## Связанное

[[PostgreSQL]] · [[Другие/MySQL и InnoDB]] · [[Сравнения/MVCC и очистка мусора]] · [[Сравнения/Репликация и HA]] · [[Сравнения/SQL-диалекты и миграция]]

## Источники

- MariaDB Knowledge Base (mariadb.com/kb)
- «MariaDB Crash Course» / документация Galera Cluster
- Percona/MariaDB Foundation блоги о различиях с MySQL
