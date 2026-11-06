# Legacy СУБД

## Если знаешь PostgreSQL (TL;DR)

1. **Странично-ориентированные движки с блокировками**, а не MVCC: читатель ждёт писателя, эскалация блокировок — норма.
2. **SQL-диалект «почти как у всех», но с историческими сюрпризами**: `NULL`-семантика, даты, идентификаторы, `TOP`/`ROWS`.
3. **Нет `pg_catalog`-удобств**: диагностика через системные таблицы/procedure, часто закрытая.
4. **Миграция — это не «поменять драйвер»**, а переписать часть запросов, триггеров, хранимых процедур.
5. **Главный риск — не производительность, а знание**: документации мало, специалистов ещё меньше.

## Кто попадает в «legacy»

| СУБД | Где встречается | Статус |
|---|---|---|
| **Informix** | банки, телеком, retail (СНГ, Азия) | IBM поддерживает (14.10), но развитие медленное |
| **Sybase ASE** | банки, биллинг, legacy enterprise | SAP поддерживает (16.0), новых внедрений почти нет |
| **Microsoft Access** | внутренние инструменты, малый бизнес | в составе Office; Jet/ACE — файловая БД |
| **Visual FoxPro / dBase** | legacy desktop | сняты с поддержки |
| **R:BASE, Paradox** | совсем старые | музей |
| **Adabas/Natural, IMS/DB** | мейнфреймы | не реляционные (иерархические/сетевые) |

## Informix

- **Dynamic Server (IDS)** — основной движок; **extents** вместо таблиц, **dbspaces** вместо tablespace.
- **B-tree, bitmap, functional indexes**; **fragmentation** (партиционирование) по выражению/round-robin.
- **Изоляция**: `DIRTY READ`, `COMMITTED READ`, `CURSOR STABILITY`, `REPEATABLE READ`; по умолчанию — `COMMITTED READ` с блокировками.
- **MVCC нет** (в классическом IDS): читатели и писатели конкурируют за блокировки.
- **Logical log** + **physical log**; `onstat`, `oncheck`, `onbar` — диагностика/бэкап.
- **SQL-диалект**: `SELECT SKIP n FIRST m`, `MATCHES`, `TODAY`, `CURRENT`.
- **4GL** — язык приложений (аналог PL/SQL), много legacy-кода.

```sql
-- Informix: первые 10 строк, пропустив 20
SELECT SKIP 20 FIRST 10 * FROM orders;

-- Уровень изоляции
SET ISOLATION TO COMMITTED READ;
```

## Sybase ASE

- **Pages 2/4/8/16 КБ**, **extents**, **segments**; clustered/nonclustered индексы (как SQL Server, но старше).
- **Блокировки**: page-level по умолчанию, row-level при `alter table ... lock datarows`; **эскалация** — норма.
- **Изоляция**: `READ UNCOMMITTED` (0), `READ COMMITTED` (1), `REPEATABLE READ` (2), `SERIALIZABLE` (3); по умолчанию — 1.
- **Transaction log** в отдельном сегменте; `dump tran` — усечение/бэкап.
- **Диагностика**: `sp_who`, `sp_lock`, `set showplan on`, `dbcc`.
- **SQL-диалект**: `SELECT TOP n`, `HOLDLOCK`, `UPDATE ... FROM`, `COMPUTE BY`.

```sql
SET SHOWPLAN ON;
GO
SELECT * FROM orders WHERE user_id = 42;
GO

sp_lock;
sp_who;
```

## Microsoft Access (Jet/ACE)

- **Файловая БД**: `.accdb`/`.mdb`, движок Jet (ныне ACE) внутри процесса.
- **Нет сервера**, блокировки на уровне страниц/файла; конкурентность ограничена.
- **SQL-подмножество** (Access SQL) + VBA; формы/отчёты — часть продукта.
- **`NULL` и типы** ведут себя иначе (как в старых VB-движках); `Date/Time` — OLE Automation.
- **Лимит 2 ГБ** на файл; при росте — миграция на SQL Server (upsizing wizard).
- **Диагностика**: `Database Documenter`, `Compact & Repair` (аналог `VACUUM`), Performance Analyzer.

## Общие грабли при миграции с legacy на PostgreSQL

| Проблема | Что делать |
|---|---|
| **Блокировки вместо MVCC** | нагрузка на чтение вырастет; проверь, что приложение не полагается на «грязное чтение» |
| **`NULL`-семантика** | Oracle/ASE/Access трактуют `''`/`NULL` по-разному; тесты на пустые строки |
| **Типы дат** | `datetime`/`smalldatetime` → `timestamptz`; проверить precision и TZ |
| **Идентификаторы** | upper-case/lower-case, кавычки, зарезервированные слова |
| **Хранимые процедуры** | PL/SQL, T-SQL, 4GL → PL/pgSQL; переписывать, а не конвертировать |
| **Триггеры** | в legacy часто бизнес-логика; переносить в приложение или PL/pgSQL |
| **`TOP`/`SKIP`/`ROWS`** | `LIMIT/OFFSET` |
| **`MERGE`/upsert** | `ON CONFLICT` |
| **Пустые строки vs NULL** | `CHECK (col <> '')` или `NULLIF` |
| **Collation** | регистрозависимость/независимость — проверить на данных |
| **Драйверы/ORM** | диалект Hibernate, JDBC-URL, пул соединений |

## Стратегия миграции

1. **Инвентаризация**: какие объекты, какие запросы, какие процедуры, кто вызывает.
2. **Пилот на чтение**: реплика legacy → PG, сравнить результаты запросов.
3. **Двойная запись (CDC)**: миграция без простоя; сверка контрольных сумм.
4. **Переключение чтения**, потом записи; обратный путь на время стабилизации.
5. **Откат**: держать legacy в hot standby до подтверждения.

## Грабли для приходящего с PG (обратное направление)

1. **В legacy нет `VACUUM`** — не ищи bloat; но есть фрагментация и `REORG`-аналоги.
2. **`EXPLAIN` может отсутствовать** — `set showplan`, trace, и только.
3. **Блокировки эскалируют** — «нормальный» запрос может заблокировать таблицу.
4. **`SERIAL`/identity** — через sequence/trigger, не «просто колонка».
5. **Регистр имён** — часто upper-case и без кавычек.
6. **Пустая строка = NULL** (Oracle/Access) — ломает `NOT NULL` и `UNIQUE`.
7. **`DATETIME` точность** — 1/300 секунды в ASE, 3.33 мс в SQL Server, секунды в старых Access.
8. **`COUNT(*)`** может быть медленным или наоборот «мгновенным» из статистики — проверяй.
9. **Репликация** — log shipping/ASA-подобное, не streaming; лаг и ручной failover.
10. **Навыки**: документация и специалисты — главный дефицит; фиксируй знания в заметках.

## Что проверить руками (если есть доступ)

```sql
-- Informix
SELECT SKIP 0 FIRST 5 * FROM systables;
SET EXPLAIN ON;

-- Sybase ASE
SELECT @@version;
SET SHOWPLAN ON;
sp_helpdb;
```

## Связанное

[[PostgreSQL]] · [[Сравнения/Изоляция и блокировки]] · [[Сравнения/SQL-диалекты и миграция]] · [[Сравнения/Хранение — heap vs clustered index]] · [[Другие/IBM Db2]]

## Источники

- IBM Informix Documentation (14.10)
- SAP Sybase ASE Documentation (16.0)
- Microsoft Access SQL Reference
- «Refactoring Legacy Databases» / материалы по миграции
