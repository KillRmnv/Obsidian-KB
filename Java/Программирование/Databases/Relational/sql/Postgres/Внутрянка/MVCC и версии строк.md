# MVCC и версии строк

## Зачем это нужно

MVCC — причина №1, почему PostgreSQL ведёт себя «не как MySQL»: чтение не блокирует запись, `UPDATE` создаёт новую версию строки, появляется bloat, а старые снапшоты мешают vacuum. Без этого не понять ни `pg_stat_activity.backend_xmin`, ни «почему таблица растёт без роста данных».

## Как устроено

### Одна строка — много версий

`UPDATE` в PostgreSQL **не меняет строку на месте**. Он:

1. помечает старую версию удалённой (`xmax = мой xid`);
2. вставляет новую версию с `xmin = мой xid`.

`DELETE` только ставит `xmax`. Место физически освобождается позже — при `VACUUM`.

```
После INSERT:      [xmin=100, xmax=0]            ctid=(0,1)
После UPDATE:      [xmin=100, xmax=105]  ──►     [xmin=105, xmax=0]   ctid=(0,2)
                   старая версия (dead)          новая версия (live)
```

Старые версии нужны, пока их «видит» хоть один снапшот: читатель, начавший транзакцию до коммита обновления, обязан увидеть старую версию.

### Снапшот: что видно

Снапшот (snapshot) — это:

```
xmin  = минимальный XID среди активных транзакций
xmax  = следующий XID, который ещё не выдан (всё ≥ него — «будущее»)
xip   = список активных (незакоммиченных) XID между xmin и xmax
```

Правило видимости для версии строки (упрощённо):

1. `xmin` не закоммичен или попадает в `xip` → версия **невидима**;
2. `xmin` закоммичен → версия видима;
3. `xmax == 0` → версия живая;
4. `xmax` закоммичен и не в `xip` → версия удалена;
5. `xmax` не закоммичен / в `xip` → версия ещё живая (удаление не подтверждено).

Снапшот берётся:

- **Read Committed** — на каждый оператор;
- **Repeatable Read / Serializable** — на первый оператор транзакции.

```sql
SELECT pg_current_snapshot();          -- PG13+: xmin:xmax:xip_list
SELECT txid_current();                 -- выдаёт XID текущей транзакции
SELECT pg_current_xact_id();           -- PG13+
SELECT pg_current_xact_id_if_assigned(); -- не выдаёт XID, если его ещё нет
```

### Статусы транзакций и hint-биты

Статус (committed/aborted/in-progress/subcommitted) хранится в `pg_xact` — **2 бита на XID**, отдельно от данных. Чтобы не читать его на каждый кортеж, статус кэшируется в `t_infomask` (hint bits). Запись hint-бита пачкает страницу, но не WAL — при потере пересчитается.

### HOT-обновления

Если `UPDATE` **не меняет индексируемые колонки** и на странице есть свободное место, новая версия кладётся **на ту же страницу**, а индексные записи не трогаются. Это **HOT** (Heap-Only Tuples).

```
страница:  [v1, ctid→v2] [v2, ctid→v3] [v3, xmax=0]
индекс:    одна запись → v1, дальше цепочка ctid
```

Плюсы: нет новых индексных записей, меньше WAL, дешевле `UPDATE`. Условия: не менять индексируемые поля + место на странице (`fillfactor < 100`).

Счётчик: `pg_stat_user_tables.n_tup_hot_upd`.

### Мультитранзакции (multixact)

Если одну строку одновременно блокируют несколько транзакций (`SELECT FOR UPDATE`), в `xmax` не влезает список. Тогда пишется ссылка на `pg_multixact`. Раздувание `pg_multixact` — отдельная headache (настройки `vacuum_multixact_freeze_*`).

### Заморозка (freeze) и wraparound

XID — 32 бита, то есть ~4.3 млрд значений, но сравнивать можно только в пределах 2^31 (~2.1 млрд). Чтобы старые XID не «завернулись» и не стали выглядеть будущими, `VACUUM` **замораживает** старые версии: `xmin` заменяется на специальный `FrozenXID`.

- `pg_class.relfrozenxid` — самый старый незамороженный XID таблицы;
- `age(relfrozenxid)` — сколько транзакций прошло с тех пор;
- `pg_database.datfrozenxid` — по базе;
- при приближении к 2^31 включается **anti-wraparound autovacuum** (принудительный, игнорирует `autovacuum=off`).

```sql
SELECT relname, age(relfrozenxid) AS xid_age
FROM pg_class
WHERE relkind = 'r'
ORDER BY xid_age DESC
LIMIT 10;

SELECT datname, age(datfrozenxid) FROM pg_database;
```

Опасный порог — 2 000 000 000. Ошибка `database is not accepting commands to avoid wraparound data loss` означает, что сервер встал на защиту.

## Что видно в psql

```sql
CREATE TABLE t_mvcc (id int primary key, val text);
INSERT INTO t_mvcc VALUES (1, 'v1');

SELECT ctid, xmin, xmax, * FROM t_mvcc;
-- (0,1) | 7xx | 0 | 1 | v1

BEGIN;
UPDATE t_mvcc SET val = 'v2' WHERE id = 1;
-- из ДРУГОЙ сессии:
--   SELECT * FROM t_mvcc;  → всё ещё v1 (снапшот не видит незакоммиченное)
COMMIT;
-- теперь видно v2, а старая версия — dead
```

```sql
-- Кто мешает vacuum: самый старый снапшот
SELECT pid, state, xact_start,
       backend_xmin, backend_xid,
       now() - xact_start AS xact_age
FROM pg_stat_activity
WHERE backend_xmin IS NOT NULL
ORDER BY backend_xmin;
```

## Грабли и мифы

1. **«MVCC = нет блокировок»** — нет. MVCC убирает блокировки *чтения*, но `UPDATE`/`DELETE` одной и той же строки конфликтуют: вторая транзакция ждёт первую.
2. **`UPDATE` дороже `INSERT`.** Он делает insert новой версии + правку старой + WAL + иногда обновление индексов.
3. **Долгая транзакция = bloat.** Пока она жива, vacuum не может убрать ни одну версию, созданную после её снапшота. `idle in transaction` особенно опасен.
4. **`SELECT count(*)` не «дешёвый».** Он читает все версии, проходя visibility-проверки; в PG нет счётчика строк в таблице.
5. **`VACUUM` не «освобождает место на диске»** — он делает его переиспользуемым. См. [[Внутрянка/VACUUM и autovacuum]].
6. **`xmin`/`xmax` из `SELECT` — не пользовательские колонки.** Это системные поля, их можно смотреть, но не надо на них завязываться.

## Эксперимент

```sql
-- 1. Сколько версий накопилось
CREATE TABLE t_ver (id int primary key, v text);
INSERT INTO t_ver SELECT g, 'v0' FROM generate_series(1, 10000) g;

UPDATE t_ver SET v = v || '+';   -- 10 000 update
SELECT n_tup_upd, n_tup_hot_upd, n_dead_tup
FROM pg_stat_user_tables WHERE relname = 't_ver';

-- 2. Без индекса на v часть апдейтов станет HOT
SELECT ctid, xmin, xmax FROM t_ver LIMIT 5;

-- 3. Пока транзакция открыта, vacuum не уберёт мусор
BEGIN ISOLATION LEVEL REPEATABLE READ;
SELECT count(*) FROM t_ver;
-- в другой сессии:
--   VACUUM t_ver;  → n_dead_tup не уменьшится
COMMIT;
```

## Связанное

[[Внутрянка/Физическое хранение]] · [[Внутрянка/Транзакции и блокировки]] · [[Внутрянка/VACUUM и autovacuum]] · [[изоляция транзакций]] · [[ACID]]

## Источники

- PostgreSQL Docs: *Concurrency Control*, *MVCC*, *Routine Vacuuming*
- Егор Рогов, «PostgreSQL 14 Internals», гл. 4–5
- Hironobu Suzuki, «The Internals of PostgreSQL», ch. 5 (HOT), ch. 6 (Vacuum)
