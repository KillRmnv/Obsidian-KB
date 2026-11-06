# Firebird

## Если знаешь PostgreSQL (TL;DR)

1. **MGA вместо MVCC-в-heap**: старые версии строк живут в самом файле БД, каждая запись — цепочка версий. Это ближе к PG, чем undo-подход, но без отдельного `VACUUM`.
2. **`SWEEP` вместо `VACUUM`**: фоновая очистка старых версий; может не успевать → «garbage» и рост файла.
3. **Нет отдельного WAL**: журналирование через **write-ahead на уровне страниц** и `FORCE WRITE`; для PITR — `nbackup` и archive.
4. **Нет схем** — только база; объекты в одном пространстве имён (как в MySQL, но без «database = schema»).
5. **Очень лёгкий**: один файл `.fdb`, без сервера (embedded) или с сервером; популярен в 1С-совместимых и legacy-системах.

## Ниша

1С-франчайзи (некоторые конфигурации), российский/восточноевропейский enterprise, embedded в десктоп, медицинские и бухгалтерские системы. Версии: 3.0, 4.0, 5.0.

## Хранение

| | PostgreSQL | Firebird |
|---|---|---|
| Единица | 8 КБ страница | страница 4/8/16 КБ (задаётся при создании) |
| Файл | каталог PGDATA | **один `.fdb`** (или несколько файлов) |
| Таблица | heap + TOAST | страницы данных + **цепочки версий** |
| Адрес строки | `ctid` | record number (внутренний) |
| Индекс | отдельная структура | B-tree |
| Длинные значения | TOAST | BLOB-страницы |
| Мусор | `VACUUM` | **`SWEEP`** + garbage collection при чтении |
| Сжатие | TOAST | нет (страницы пишутся как есть) |

**MGA (Multi-Generational Architecture)** — ключевое отличие: при `UPDATE` старая версия остаётся в странице, новая пишется рядом (или в новой странице), а заголовок содержит ссылку на предыдущую версию и `transaction id`. Читатель идёт по цепочке, пока не найдёт видимую. Мусор убирается, когда версия больше никому не видна — либо при чтении (лениво), либо `SWEEP`.

Это очень похоже на PG, но:

- **нет visibility map и freeze** — вместо этого «interesting transaction» и лимит транзакций;
- **нет autovacuum** — `SWEEP` запускается вручную/по расписанию или встроенным механизмом;
- **garbage collection может отставать** — файл растёт, производительность падает.

## Транзакции и MVCC

- Транзакции имеют 32-битный ID; для долгих транзакций — «interesting» список.
- Уровни изоляции: `READ COMMITTED` (default, с `RECORD_VERSION`/`NO RECORD_VERSION`), `SNAPSHOT`, `SNAPSHOT TABLE STABILITY`.
- **`SNAPSHOT`** — аналог `REPEATABLE READ` в PG.
- **`SNAPSHOT TABLE STABILITY`** — блокирует таблицу целиком (аналог `LOCK TABLE`).
- **Нет serializable через SSI**; конкурентность — через конфликты записи (`update conflicts with concurrent update`).
- **`WAIT` / `NO WAIT`** — ждать блокировку или сразу ошибка.
- Долгая транзакция → **OAT** (Oldest Active Transaction) не двигается → garbage не чистится → рост файла. Прямой аналог `backend_xmin` в PG.

## Журналы и durability

- **`FORCE WRITE = ON`** — fsync на коммит (аналог `synchronous_commit=on`), по умолчанию `ON` для сервера, `OFF` для embedded.
- Нет WAL в смысле PG: страницы пишутся на диск, журнал — для recovery (`.fbk`/`firebird.log`).
- **`nbackup`** — инкрементальные бэкапы на уровне страниц; `gbak` — логический бэкап/restore.
- **PITR** — через archive mode + `nbackup`; не так развит, как WAL-архивация PG.
- При аварийном завершении — `gfix -mend`, `gfix -sweep`.

## Блокировки и конкурентность

- Блокировки записей — на уровне версий; конфликт `UPDATE`/`DELETE` → `deadlock` или `update conflicts`.
- **Нет таблицы локов как в PG**; диагностика — `MON$`-таблицы:

```sql
SELECT MON$TRANSACTION_ID, MON$STATE, MON$TIMESTAMP, MON$ISOLATION_MODE
FROM MON$TRANSACTIONS;

SELECT MON$ATTACHMENT_ID, MON$USER, MON$REMOTE_ADDRESS, MON$STATE
FROM MON$ATTACHMENTS;

SELECT MON$LOCK_TYPE, MON$RELATION_NAME, MON$LOCK_MODE
FROM MON$LOCKS;
```

- `MON$` — встроенный мониторинг (аналог `pg_stat_activity` + `pg_locks`), доступен без расширений.

## Диагностика

```sql
SET PLAN ON;
SELECT * FROM orders WHERE user_id = 42;
-- PLAN (ORDERS INDEX (IDX_ORDERS_USER))

SET STATS ON;                  -- время, чтения, записи
SELECT ...;

SELECT * FROM MON$STATEMENTS;  -- активные запросы
SELECT * FROM MON$IO_STATS;    -- I/O по таблицам
SELECT * FROM MON$RECORD_STATS;
```

- **`SET PLANONLY`** — план без выполнения.
- Нет `pg_stat_statements`; статистика — через `MON$` и trace-API (`fb-trace`).
- `gstat -h database.fdb` — статистика страниц, индексов, версий (аналог `pgstattuple`).

## Индексы и DDL

- B-tree; **computed/expression indexes** через `COMPUTED BY`.
- **Partial index нет**; **covering index** нет (только ключевые колонки).
- **`INACTIVE` индексы** — можно отключить, не удаляя.
- `CREATE INDEX` блокирует запись; для больших таблиц — в окно обслуживания.
- **`ALTER TABLE` ограничен**: `ADD/ALTER/DROP COLUMN` есть, но перестройка таблицы — через `gbak`/`ALTER ... TYPE` (переписывает).

## Репликация и HA

- **Firebird 4+**: встроенная репликация (logical, на основе journal) — `firebird.conf`, `replication` секция.
- **`nbackup`** — инкрементальные бэкапы.
- **Кластеризация**: нет встроенной; через сторонние решения (IBProvider, коммерческие).
- **Embedded** — та же БД, но без сервера; один процесс.

## SQL-диалект: перевод с PG

| PostgreSQL | Firebird |
|---|---|
| `LIMIT n OFFSET m` | `ROWS n` / `ROWS m TO n` (1-based!) |
| `SERIAL` | `GENERATED BY DEFAULT AS IDENTITY` |
| `ON CONFLICT` | `UPDATE OR INSERT` / `MERGE` (3.0+) |
| `RETURNING` | `RETURNING` (есть!) |
| `boolean` | `BOOLEAN` (3.0+) |
| `text` | `VARCHAR(n)`, `BLOB SUB_TYPE TEXT` |
| `timestamptz` | `TIMESTAMP WITH TIME ZONE` (4.0+) |
| `jsonb` | нет; `BLOB SUB_TYPE TEXT` |
| `LATERAL` | нет |
| `string_agg` | `LIST` |
| `::type` | `CAST` |
| `ILIKE` | нет; `UPPER() LIKE` |
| схемы | **нет схем** |
| `"identifier"` | `"IDENTIFIER"` (uppercase по умолчанию) |

## Грабли для приходящего с PG

1. **`ROWS` 1-based и включительно**: `ROWS 1 TO 10` — первые 10 строк, а не `OFFSET 1`.
2. **Нет autovacuum** — `SWEEP` нужно запускать самому (или он идёт при backup); иначе garbage и рост файла.
3. **Долгая транзакция блокирует уборку мусора** — как `backend_xmin` в PG, но без мониторинга «из коробки».
4. **Нет схем** — все объекты в одном пространстве; конфликты имён.
5. **`FORCE WRITE = OFF` в embedded** — потеря данных при сбое питания (аналог `fsync=off`).
6. **`ALTER TABLE` переписывает таблицу** при смене типа; на большой таблице — простой.
7. **Нет partial/covering индексов** — планировщик беднее.
8. **Идентификаторы в upper case** по умолчанию.
9. **`gbak`/`restore` — обязательная часть обслуживания** (аналог `pg_dump` + `VACUUM FULL` в одном).
10. **Один файл ≠ один сервер**: несколько процессов могут открыть одну БД, но конкурентность ограничена.

## Что проверить руками

```sql
SELECT rdb$get_context('SYSTEM', 'ENGINE_VERSION') FROM rdb$database;
SELECT * FROM MON$TRANSACTIONS;
SELECT * FROM MON$ATTACHMENTS;

SET PLAN ON;
SELECT * FROM orders WHERE user_id = 42;
```

```bash
gstat -h database.fdb        # страницы, версии, индексы
gfix -validate database.fdb
```

## Связанное

[[PostgreSQL]] · [[Сравнения/MVCC и очистка мусора]] · [[Сравнения/Хранение — heap vs clustered index]] · [[Сравнения/SQL-диалекты и миграция]]

## Источники

- Firebird Documentation (3.0/4.0/5.0): «Language Reference», «Operations Guide»
- «Firebird: The Database» (Helen Borrie)
- ibphoenix.com, firebirdsql.org
