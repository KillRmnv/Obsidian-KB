В Hibernate (и JPA) стратегия генерации первичного ключа определяется аннотацией `@GeneratedValue`. Выбор стратегии критически влияет на производительность, особенно при пакетной вставке (batch insert), и на возможность миграции между базами данных.

Вот основные стратегии:

---

### 1. `IDENTITY` (Автоинкремент БД)
Ключ генерируется самой базой данных при вставке записи (например, `AUTO_INCREMENT` в MySQL или `IDENTITY` в SQL Server).

*   **Аннотация:** `@GeneratedValue(strategy = GenerationType.IDENTITY)`
*   **Как работает:** Hibernate отправляет `INSERT` без ID → БД генерирует ID → Hibernate делает `SELECT` (или использует JDBC getGeneratedKeys), чтобы узнать ID.
*   **Плюсы:**
    *   Просто и понятно.
    *   Нативно поддерживается MySQL, SQL Server, H2, Derby.
*   **Минусы:**
    *   **Нет пакетной вставки (Batching):** Hibernate должен выполнить `INSERT` и получить ID сразу, чтобы присвоить его объекту. Поэтому он не может группировать несколько `INSERT` в один пакет. Это сильно снижает производительность при массовой загрузке.
    *   Нельзя узнать ID объекта до момента сохранения в БД.

```java
@Entity
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
}
```

---

### 2. `SEQUENCE` (Последовательность БД)
Используется объект последовательности (Sequence) в базе данных (Oracle, PostgreSQL, DB2, H2).

*   **Аннотация:** `@GeneratedValue(strategy = GenerationType.SEQUENCE)`
*   **Как работает:** Hibernate запрашивает следующее значение у последовательности (`SELECT nextval(...)`) **до** выполнения `INSERT`.
*   **Плюсы:**
    *   **Поддерживает пакетную вставку:** Так как ID известен заранее, Hibernate может отправить пачку `INSERT` запросов одновременно.
    *   Высокая производительность.
    *   Гибкая настройка (размер блока `allocationSize`).
*   **Минусы:**
    *   Не поддерживается MySQL (до версии 8.0.12 нативных последовательностей не было, хотя сейчас есть, но исторически используется IDENTITY).
    *   Требует создания последовательности в БД (Hibernate может сделать это сам через `hbm2ddl`).

```java
@Entity
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "user_seq")
    @SequenceGenerator(name = "user_seq", sequenceName = "user_sequence", allocationSize = 1)
    private Long id;
}
```
*   `allocationSize = 1`: Каждый раз ходить в БД за новым ID (медленнее, но без дыр в нумерации).
*   `allocationSize = 50`: Hibernate берет блок из 50 ID в память и раздает их без обращения к БД (быстрее, но могут быть пропуски в нумерации при рестарте).

---

### 3. `TABLE` (Эмуляция последовательности)
Hibernate создает специальную таблицу в БД, которая хранит текущее значение ключа, и эмулирует работу последовательности.

*   **Аннотация:** `@GeneratedValue(strategy = GenerationType.TABLE)`
*   **Как работает:** Hibernate делает `SELECT` из таблицы-генератора, обновляет её (`UPDATE`), получает ID.
*   **Плюсы:**
    *   Максимальная переносимость (работает на любой БД, даже где нет Sequence).
*   **Минусы:**
    *   **Низкая производительность:** Требует дополнительных запросов и блокировок таблицы генератора.
    *   Считается устаревшей стратегией.

```java
@Entity
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.TABLE, generator = "tbl_gen")
    @TableGenerator(name = "tbl_gen", table = "id_generator", pkColumnName = "gen_name", valueColumnName = "gen_value")
    private Long id;
}
```

---

### 4. `AUTO` (Выбор Hibernate)
Стратегия по умолчанию. Hibernate сам выбирает стратегию в зависимости от диалекта базы данных.

*   **Аннотация:** `@GeneratedValue(strategy = GenerationType.AUTO)`
*   **Поведение:**
    *   **Hibernate 5:** Для MySQL выбирал `IDENTITY`, для PostgreSQL/Oracle — `SEQUENCE`.
    *   **Hibernate 6:** По умолчанию стремится к `SEQUENCE` (даже для MySQL, эмулируя её таблицей), чтобы включить поддержку batching.
*   **Плюсы:** Удобно для быстрой разработки.
*   **Минусы:** Поведение может измениться при обновлении версии Hibernate или смене БД. Для продакшена лучше указывать стратегию явно.

```java
@Entity
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.AUTO)
    private Long id;
}
```

---

### 5. `UUID` / `GUID` (Генерация на стороне приложения)
Ключ генерируется в Java-коде до сохранения в БД. Часто используется в распределенных системах.

*   **Аннотация:** Используется `@GenericGenerator` (Hibernate specific) или `GenerationType.UUID` (в Hibernate 6).
*   **Типы:** `String` (36 символов) или `Binary` (16 байт, эффективнее).
*   **Плюсы:**
    *   Не требует обращения к БД за ID.
    *   Безопаснее (нельзя перебирать ID пользователей).
    *   Удобно для слияния баз данных (нет конфликтов ключей).
    *   Поддерживает batching.
*   **Минусы:**
    *   Ключи больше по размеру (индексы занимают больше места).
    *   Не последовательные (плохая локальность в индексах B-Tree, может фрагментировать индекс).

```java
// Hibernate 5
@Entity
public class User {
    @Id
    @GeneratedValue(generator = "uuid")
    @GenericGenerator(name = "uuid", strategy = "uuid2")
    private String id;
}

// Hibernate 6
@Entity
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;
}
```

---

### 6. `ASSIGNED` (Ручное присваивание)
Вы сами присваиваете ID объекту перед сохранением.

*   **Аннотация:** Отсутствие `@GeneratedValue`.
*   **Применение:** Обычно для натуральных ключей (например, ISBN книги, код валюты), а не суррогатных ID.

```java
@Entity
public class Currency {
    @Id
    private String code; // "USD", "EUR" присваиваете вручную
}
```

---

### Сравнительная таблица

| Стратегия | Производительность | Batch Insert | Переносимость | Когда использовать |
| :--- | :--- | :--- | :--- | :--- |
| **IDENTITY** | Средняя | ❌ Нет | Средняя (MySQL, SQL Server) | Простые проекты на MySQL, где нет массовых вставок. |
| **SEQUENCE** | **Высокая** | ✅ **Да** | Низкая (PostgreSQL, Oracle) | **Рекомендуемый выбор** для высоконагруженных систем. |
| **TABLE** | Низкая | ✅ Да | **Высокая** (Любая БД) | Legacy проекты, специфичные БД без Sequence. |
| **UUID** | Высокая | ✅ Да | **Высокая** | Микросервисы, распределенные системы, безопасность. |
| **AUTO** | Зависит от БД | Зависит | **Высокая** | Прототипирование, демо. |

---

### Рекомендации (Best Practices)

1.  **Для PostgreSQL / Oracle:** Используйте **`SEQUENCE`**. Это нативный и самый быстрый механизм.
2.  **Для MySQL:**
    *   Если важна производительность вставок: Используйте **`SEQUENCE`** (Hibernate 6 эмулирует) или **`UUID`**.
    *   Если проект простой и вставок мало: Можно оставить **`IDENTITY`** (проще администрировать).
3.  **Для микросервисов:** Используйте **`UUID`** (лучше в бинарном формате), чтобы избежать конфликтов ID при слиянии данных из разных сервисов.
4.  **Избегайте `AUTO` в продакшене:** Явно указывайте стратегию, чтобы поведение не изменилось при миграции или обновлении зависимостей.
5.  **Настройка `allocationSize`:** Если используете `SEQUENCE`, настройте `allocationSize = 50` (или больше), чтобы уменьшить количество запросов к БД за новыми ID. Помните, что при падении приложения неиспользованные ID из блока потеряются (будут дыры в нумерации), но для PK это обычно не проблема.

### Пример идеальной настройки (PostgreSQL + Hibernate)

```java
@Entity
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.SEQUENCE, generator = "user_id_gen")
    @SequenceGenerator(
        name = "user_id_gen",
        sequenceName = "user_id_sequence",
        allocationSize = 50 // Берем блок по 50 ID
    )
    private Long id;
}
```