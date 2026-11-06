# Хранение — heap vs clustered index

## Зачем это нужно

Это **главное** различие между PostgreSQL и остальными: в PG таблица — неупорядоченный heap, а все индексы отдельные. В MySQL и SQL Server (при кластерном индексе) таблица — это и есть B-tree. Отсюда различия в `ORDER BY`, вставках, bloat, вторичных индексах и в том, насколько дорог `SELECT *`.

## Три модели

### 1. Heap + отдельные индексы (PostgreSQL)

```
heap:     [стр.0] [стр.1] [стр.2] ...   ← строки в порядке вставки
индексы:  B-tree(key → ctid)             ← отдельные структуры
```

- Строка имеет `ctid` (page, offset); `UPDATE` **создаёт новую версию** в heap (MVCC).
- Индекс ссылается на `ctid`; при обновлении индексы обновляются только если изменились индексируемые колонки (HOT).
- `ORDER BY` требует индекса или сортировки.
- Плюс: вторичные индексы не зависят от PK; дешёвая вставка в любое место.
- Минус: bloat, необходимость `VACUUM`, двойной поход (index → heap).

### 2. Clustered index (MySQL/InnoDB, SQL Server)

```
clustered B-tree(PK):  лист = строка целиком, отсортированы по PK
вторичный индекс:      B-tree(key → PK) → поиск в кластерном
```

- Таблица физически отсортирована по PK.
- Вторичный индекс хранит **значение PK**, а не адрес строки → lookup из двух шагов.
- Длинный PK раздувает **все** индексы.
- `ORDER BY pk` бесплатен; `ORDER BY other` — сортировка или индекс.
- Вставка случайного ключа (UUID) → page split.

### 3. Column store (MPP, HANA, DuckDB)

```
колонка A: [1,2,3,4,...]  сжатая
колонка B: ['a','b',...]
```

- Читаются только нужные колонки; сжатие в 5–20 раз.
- Нет «строки» как единицы чтения; `SELECT *` дорог.
- `UPDATE`/`DELETE` — через delta/merge или перезапись блока.

## Сравнительная таблица

| | PostgreSQL | MySQL/InnoDB | SQL Server | Oracle |
|---|---|---|---|---|
| Таблица | heap | clustered PK | heap или clustered | heap или IOT |
| Адрес строки | `ctid` | PK | ключ кластера / RID | ROWID |
| Вторичный индекс | `ctid` → heap | PK → clustered | ключ кластера → clustered | ROWID → block |
| `ORDER BY pk` | нужен индекс | бесплатен | бесплатен (clustered) | нужен индекс (heap) |
| Случайный PK | нет split (heap) | split | split | split (IOT) |
| Длинный PK | не влияет на индексы | раздувает все | раздувает все | раздувает IOT |
| Длинные значения | TOAST | overflow pages | LOB/ROW_OVERFLOW | LOB segments |
| Мусор | dead tuples | undo + purge | ghost records | undo |
| Сжатие | TOAST | row/page compression | data/page compression | Advanced Compression |

## Что это меняет на практике

### `ORDER BY`

```sql
-- MySQL: индекс по PK не нужен, данные уже отсортированы
SELECT * FROM orders ORDER BY id LIMIT 100;           -- быстро

-- PostgreSQL: нужен индекс, иначе Sort
SELECT * FROM orders ORDER BY id LIMIT 100;           -- может быть Sort!
```

В PG `ORDER BY id` без индекса — это сортировка (или top-N heapsort при `LIMIT`). В MySQL — лист кластерного индекса.

### Вторичный lookup

```sql
SELECT * FROM orders WHERE user_id = 42;
```

- PG: `Index Scan` по `(user_id)` → `ctid` → heap. Два похода, но heap-страница содержит всю строку.
- MySQL: `Index Scan` по `(user_id)` → PK → кластерный → строка. Тоже два похода, но второй — по дереву.
- SQL Server: аналогично MySQL, если есть кластерный индекс; для heap — RID → heap.

Отсюда: **в MySQL/InnoDB длинный PK (UUID) бьёт по всем запросам**, в PG — только по индексам, где он ключ.

### Вставка

- PG: вставка в heap по FSM + запись во все индексы. Случайный ключ не вызывает split heap (но вызывает split индекса).
- MySQL/SQL Server: вставка в кластерное дерево; случайный ключ → split, фрагментация, рост.
- Отсюда совет «UUID v4 — плохой PK» верен для clustered, но мягче для PG (хотя индекс всё равно пухнет).

### Обновление

- PG: новая версия строки (MVCC) + HOT, если не индексируемые колонки.
- MySQL: обновление на месте, если влезает; иначе — новая страница + указатель; undo для старых версий.
- SQL Server: обновление на месте; если не влезает — forwarded record (heap) или split (clustered).
- Oracle: обновление на месте, если есть место (`PCTFREE`); иначе — migration, ROWID остаётся.

## Как проверить руками

```sql
-- PostgreSQL: где физически строка
SELECT ctid, * FROM orders LIMIT 5;

-- MySQL: кластерный PK
EXPLAIN SELECT * FROM orders WHERE id = 42;
-- type=const, key=PRIMARY

-- SQL Server: heap или clustered?
SELECT index_id, name, type_desc FROM sys.indexes WHERE object_id = OBJECT_ID('orders');
-- index_id = 0 → heap; 1 → clustered
```

## Грабли и мифы

1. **«В PG нет кластерного индекса»** — есть `CLUSTER`, но это разовая пересортировка, а не постоянная поддержка порядка.
2. **`CLUSTER` в PG не поддерживается автоматически** — после вставок порядок снова нарушается.
3. **В MySQL `ORDER BY pk` не всегда бесплатен**: если запрос идёт по вторичному индексу, порядок другой.
4. **Heap в SQL Server ≠ heap в PG**: в SQL Server heap — без кластерного индекса, с forwarded records; в PG heap — всегда.
5. **Колоночное хранение не «лучше»** — оно лучше для сканов и агрегатов, хуже для точечных `UPDATE`.
6. **`fillfactor` (PG) и `PCTFREE` (Oracle) и `FILLFACTOR` (SQL Server)** — разные механизмы с похожей идеей «оставить место».

## Связанное

[[PostgreSQL]] · [[Внутрянка/Физическое хранение]] · [[Другие/MySQL и InnoDB]] · [[Другие/SQL Server]] · [[Другие/Oracle Database]] · [[Сравнения/MVCC и очистка мусора]]
