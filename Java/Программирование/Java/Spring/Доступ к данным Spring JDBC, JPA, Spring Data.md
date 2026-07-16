## Доступ к данным в Spring: от JdbcTemplate до Spring Data JPA

Spring предоставляет несколько слоёв абстракции для работы с базами данных. На собеседовании важно показать, что вы понимаете эволюцию подходов, их сильные стороны и ограничения, а также умеете выбирать инструмент под задачу.

---

### 1. Spring JDBC — классический низкоуровневый подход

**`JdbcTemplate`** — это центральный класс, который устраняет всю шаблонную работу с JDBC (открытие/закрытие соединений, обработка исключений, управление ресурсами).

#### Преимущества над чистым JDBC:
- **Управление ресурсами** — автоматически открывает и закрывает `Connection`, `Statement`, `ResultSet`.
- **Обработка исключений** — трансформирует SQL-исключения в иерархию **`DataAccessException`** (непроверяемые), что избавляет от громоздких `try-catch`.
- **Шаблонные методы** — единообразный код для запросов, обновлений, пакетных операций.
- **Поддержка именованных параметров** через `NamedParameterJdbcTemplate`.

#### Пример с `RowMapper`:
```java
@Repository
public class UserRepository {
    private final JdbcTemplate jdbcTemplate;

    public UserRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public User findById(Long id) {
        String sql = "SELECT id, name, email FROM users WHERE id = ?";
        return jdbcTemplate.queryForObject(sql, new UserRowMapper(), id);
    }

    // RowMapper — преобразует ResultSet в объект
    private static class UserRowMapper implements RowMapper<User> {
        @Override
        public User mapRow(ResultSet rs, int rowNum) throws SQLException {
            return new User(rs.getLong("id"), rs.getString("name"), rs.getString("email"));
        }
    }
}
```

#### Когда использовать:
- Простые запросы, где не нужна сложная объектная модель.
- Проекты без ORM (например, микросервисы с лёгкими хранилищами).
- Там, где нужен полный контроль над SQL.

---

### 2. JPA + Hibernate — стандарт объектно-реляционного отображения

**JPA (Java Persistence API)** — это спецификация, а **Hibernate** — самая популярная реализация. Spring интегрирует JPA через `EntityManager` (управляемый контейнером).

#### Базовые аннотации сущностей:
```java
@Entity
@Table(name = "users")
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY) // автоинкремент
    private Long id;

    @Column(nullable = false, unique = true)
    private String email;

    private String name;

    // Связи: @OneToMany, @ManyToOne, @OneToOne, @ManyToMany
    @OneToMany(mappedBy = "user", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<Order> orders;

    // конструкторы, геттеры, сеттеры
}
```

#### `EntityManager` — основной интерфейс для работы с сущностями:
```java
@Repository
public class UserDao {
    @PersistenceContext
    private EntityManager em;

    public User find(Long id) {
        return em.find(User.class, id);
    }

    public void save(User user) {
        em.persist(user);  // для нового
        em.merge(user);    // для существующего
    }

    public List<User> findByEmail(String email) {
        return em.createQuery("SELECT u FROM User u WHERE u.email = :email", User.class)
                 .setParameter("email", email)
                 .getResultList();
    }
}
```

#### Жизненный цикл сущности:
- **New/Transient** — объект создан, но не связан с `EntityManager`.
- **Managed** — объект находится в контексте persistence, изменения отслеживаются.
- **Detached** — объект вышел из контекста (после закрытия EM или сериализации).
- **Removed** — помечен на удаление.

#### Проблема N+1 запросов:
При `FetchType.LAZY` доступ к коллекции вне транзакции вызывает дополнительный запрос. Решения:
- **`JOIN FETCH`** в JPQL: `SELECT u FROM User u JOIN FETCH u.orders`
- **`@EntityGraph`** — аннотация для указания графа загрузки.
- **Переключение на `EAGER`** (не рекомендуется — может загружать слишком много).

#### Кэширование:
- **Первый уровень (L1)** — кэш сессии (в рамках `EntityManager`), включён всегда.
- **Второй уровень (L2)** — глобальный кэш для всех сессий, настраивается отдельно.

---

### 3. Spring Data JPA — высший уровень абстракции

**Spring Data JPA** предоставляет репозитории, которые генерируют реализацию за вас на основе интерфейсов.

#### Базовые интерфейсы:
- **`CrudRepository<T, ID>`** — базовые методы CRUD.
- **`PagingAndSortingRepository<T, ID>`** — добавляет пагинацию и сортировку.
- **`JpaRepository<T, ID>`** — расширяет предыдущие методами для массовых операций и сброса контекста (обычно используют его).

#### Пример репозитория:
```java
@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    // Метод по имени — Spring автоматически генерирует JPQL
    Optional<User> findByEmail(String email);

    List<User> findByNameContainingIgnoreCase(String namePart);

    // Пагинация
    Page<User> findByAgeBetween(int from, int to, Pageable pageable);

    // Свой запрос через @Query
    @Query("SELECT u FROM User u JOIN u.orders o WHERE o.total > :minTotal")
    List<User> findUsersWithOrdersAbove(@Param("minTotal") BigDecimal minTotal);

    // Native SQL
    @Query(value = "SELECT * FROM users u WHERE u.email LIKE %:domain", nativeQuery = true)
    List<User> findByEmailDomain(@Param("domain") String domain);
}
```

#### Как это работает:
- Spring Data JPA анализирует имя метода, разбивает на ключевые слова (`findBy`, `And`, `Or`, `Containing`, `OrderBy` и т.д.) и строит JPQL-запрос.
- Реализация создаётся динамически во время старта через **Proxy-бины**.

#### Пагинация и сортировка:
```java
Pageable pageable = PageRequest.of(0, 20, Sort.by("name").ascending());
Page<User> page = userRepository.findAll(pageable);
page.getContent(); // список
page.getTotalElements(); // общее количество
```

#### Проекции (DTO) для избежания лишних данных:
```java
// Интерфейсная проекция
public interface UserProjection {
    String getName();
    String getEmail();
}

// Метод в репозитории
List<UserProjection> findByAge(int age);

// Классовая проекция (закрывает поля через конструктор)
@Query("SELECT new com.example.UserDTO(u.name, u.email) FROM User u WHERE u.age = :age")
List<UserDTO> findDTOsByAge(@Param("age") int age);
```

---

### 4. Транзакции — `@Transactional`

Транзакции объединяют несколько операций в атомарную единицу. В Spring управление транзакциями осуществляется через **AOP**.

#### Пример использования:
```java
@Service
@Transactional(rollbackFor = Exception.class) // по умолчанию откат только для RuntimeException
public class UserService {
    private final UserRepository userRepository;

    public void createUserWithOrders(User user, List<Order> orders) {
        userRepository.save(user);
        for (Order order : orders) {
            order.setUser(user);
            orderRepository.save(order);
        }
        // если здесь возникнет исключение — всё откатится
    }
}
```

#### Важные параметры:
- **`propagation`** — как транзакция относится к существующей:
  - `REQUIRED` (по умолчанию) — присоединяется к существующей, иначе создаёт новую.
  - `REQUIRES_NEW` — всегда создаёт новую, приостанавливая текущую.
  - `SUPPORTS`, `MANDATORY`, `NEVER`, `NESTED`.
- **`isolation`** — уровень изоляции (READ_UNCOMMITTED, READ_COMMITTED, REPEATABLE_READ, SERIALIZABLE).
- **`readOnly = true`** — оптимизация для выборок (может отключить dirty checking).

#### Подводные камни:
- Вызов `@Transactional` метода из того же класса не сработает (из-за прокси) — нужно либо внедрить сам бин, либо вынести в отдельный класс.
- Исключения типа `Exception` (не `RuntimeException`) по умолчанию не откатывают транзакцию — нужно явно указывать `rollbackFor`.

---

### 5. Что выбрать в реальном проекте?

| Уровень | Когда использовать |
| :--- | :--- |
| **Spring JDBC** | Для простых CRUD, микросервисов с минимальными сущностями, для сложных отчётов с кастомным SQL. |
| **JPA + Hibernate (без Spring Data)** | Когда нужен полный контроль над `EntityManager`, кэшированием, но не хочется генерации репозиториев (редко). |
| **Spring Data JPA** | **Стандарт для 90% проектов** — быстрое начало, минимальный бойлерплейт, гибкость через `@Query`. |
| **Spring Data JDBC** (отдельно) — альтернатива для простых моделей без сложных связей, менее "тяжёлый", чем JPA. | |

---

### 6. Дополнительные темы для "звёздного" ответа

- **Ленивая загрузка и DTO**: всегда возвращайте DTO, а не сущности, чтобы не тащить лишние данные и избежать `LazyInitializationException` за пределами транзакции.
- **Массовые операции**: `saveAll()`, `deleteAll()` — генерация одного запроса на пакет (но иногда лучше использовать batch-параметры в JDBC).
- **Аудит**: `@CreatedDate`, `@LastModifiedDate` с аннотацией `@EnableJpaAuditing`.
- **Кэширование запросов**: `@QueryHints` для кэша второго уровня.
- **Тестирование**: `@DataJpaTest` для срезов только JPA-компонентов с H2 in-memory.

---

### Итоговый скрипт для собеседования:

> *"Для доступа к данным Spring предлагает три уровня. На нижнем — JdbcTemplate, который избавляет от boilerplate кода и даёт полный контроль над SQL. На среднем — JPA/Hibernate с EntityManager и аннотациями, где мы моделируем объекты и связи. На высшем — Spring Data JPA, которая по интерфейсам репозиториев генерирует реализации, поддерживает query по именам методов, кастомные @Query и пагинацию. Все эти подходы интегрируются с транзакциями через @Transactional. В своих проектах я обычно использую Spring Data JPA, а для сложных отчётов дополняю JdbcTemplate или Native Query, при этом всегда возвращаю DTO, а не сущности, чтобы изолировать представление от данных."*

Эта структура покрывает от основ до продвинутых нюансов. Если спросят про различия JPA и Hibernate — отвечайте, что JPA — это спецификация, а Hibernate — реализация, и Spring использует Hibernate как провайдер по умолчанию, но можно подменить на EclipseLink и т.д.