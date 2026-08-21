**HQL (Hibernate Query Language)** — объектно-ориентированный язык запросов, предоставляемый фреймворком Hibernate. Он оперирует **сущностями и их полями**, а не таблицами и столбцами БД.

С приходом стандарта JPA появился **JPQL**, который является подмножеством HQL. На практике в Spring Boot / Hibernate 5+ эти термины часто используют как синонимы, но технически:
```
HQL = JPQL + расширения Hibernate
```

---

##  HQL vs JPQL vs SQL

| Критерий | SQL | JPQL (JPA) | HQL (Hibernate) |
|----------|-----|------------|-----------------|
| Объект запроса | Таблицы, столбцы | Сущности, поля | Сущности, поля |
| Стандарт | ANSI SQL | JPA спецификация | Проприетарный (Hibernate) |
| Полиформизм |  Нет |  `SELECT e FROM Employee e` вернёт подклассы |  + дополнительные ключевые слова |
| Переносимость | Зависит от диалекта СУБД |  Работает на любом JPA-провайдере |  Привязка к Hibernate (миграция обычно trivial) |
| Расширения | Native SQL | Ограничены стандартом | `WITH` в JOIN, `FILTER`, `KEY()`, `VALUE()`, `INDEX()` для коллекций |

>  В Spring Data JPA аннотация `@Query` по умолчанию использует **JPQL/HQL синтаксис**. Для чистого SQL добавляют `nativeQuery = true`.

---

##  Базовый синтаксис

```java
// 1. Выборка всех сущностей (алиас обязателен в JPQL/HQL)
SELECT e FROM Employee e

// 2. Фильтрация с именованными параметрами
SELECT e FROM Employee e WHERE e.salary > :minSalary AND e.department.name = :dept

// 3. Выборка конкретных полей (возвращает Object[] или DTO)
SELECT e.name, e.salary FROM Employee e

// 4. JOIN
SELECT e, p FROM Employee e JOIN e.projects p WHERE p.deadline > CURRENT_DATE

// 5. ORDER BY, GROUP BY, HAVING
SELECT e.department.name, AVG(e.salary) 
FROM Employee e 
GROUP BY e.department.name 
HAVING AVG(e.salary) > :threshold
ORDER BY AVG(e.salary) DESC
```

###  Правила синтаксиса
- Имена сущностей и полей **чувствительны к регистру** (как в Java)
- Алиасы **обязательны** при обращении к полям: `e.name`, а не `Employee.name`
- Параметры: `:named` или `?1` (позиционные с индексами, начиная с 1)
- `JOIN` по умолчанию `INNER JOIN`. Для внешних: `LEFT JOIN`, `RIGHT JOIN`

---

##  Продвинутые возможности HQL

| Фича | Синтаксис | Примечание |
|------|-----------|------------|
| **Polymorphic query** | `FROM Person p` | Вернёт `Employee`, `Contractor` и т.д. |
| **FETCH JOIN** | `SELECT DISTINCT e FROM Employee e JOIN FETCH e.department` | Загружает коллекцию/связь в одном запросе, избегает N+1 |
| **Subqueries** | `WHERE e.salary > (SELECT AVG(s.salary) FROM Employee s)` | Поддерживаются в `WHERE` и `SELECT` |
| **Bulk UPDATE/DELETE** | `UPDATE Employee e SET e.salary = e.salary * 1.1 WHERE e.department = :dept` |  Не вызывают каскады, `@PreUpdate`/`@PreRemove`, не обновляют L2/L1 кэш автоматически |
| **Коллекции & Map** | `WHERE SIZE(e.tasks) > 5` / `WHERE KEY(e.settings) = 'theme'` | `SIZE()`, `INDEX()`, `KEY()`, `VALUE()` |
| **WITH clause** | `LEFT JOIN e.projects p WITH p.status = 'ACTIVE'` | Фильтрация на уровне JOIN (Hibernate-специфично) |

---

##  Выполнение запросов (Java API)

```java
// 1. Типизированный запрос (рекомендуется)
TypedQuery<Employee> q = em.createQuery(
    "SELECT e FROM Employee e WHERE e.department.name = :dept", Employee.class);
List<Employee> list = q.setParameter("dept", "IT")
                         .setFirstResult(0)
                         .setMaxResults(20)
                         .getResultList();

// 2. Конструктор DTO (Projection)
TypedQuery<EmployeeSummary> q = em.createQuery(
    "SELECT new com.example.dto.EmployeeSummary(e.name, e.salary) FROM Employee e", 
    EmployeeSummary.class);

// 3. Единственный результат
Employee emp = em.createQuery("SELECT e FROM Employee e WHERE e.id = :id", Employee.class)
                 .setParameter("id", 1L)
                 .getSingleResult(); // бросит NoResultException / NonUniqueResultException
```

---

##  Подводные камни & Best Practices

| Проблема | Решение |
|----------|---------|
| **N+1 Selects** | Используйте `JOIN FETCH` или `@EntityGraph`. Избегайте `FetchType.EAGER` в production. |
| **Pagination + JOIN FETCH** | Hibernate 5.2+ требует `DISTINCT`. Для сложных случаев: `setHint("hibernate.query.passDistinctThrough", false)` или разбейте на 2 запроса. |
| **Bulk UPDATE/DELETE** | После выполнения вызовите `entityManager.clear()` или используйте `Query.executeUpdate()` с учётом того, что кэш не инвалидируется автоматически. |
| **Конструктор DTO в HQL** | Класс DTO должен иметь **ровно такой же конструктор**, как в запросе. Поля не маппятся автоматически. |
| **HQL-функции vs DB-функции** | `CURRENT_DATE`, `LOWER()`, `SUBSTRING()` работают на уровне диалекта. Для специфичных функций используйте `function('db_func', arg)`. |
| **Регистр имён** | `employee` ≠ `Employee`. Всегда пишите как Java-класс. |

---

##  Когда использовать HQL/JPQL?
| Задача | Рекомендуемый подход |
|--------|----------------------|
| Простой CRUD по ID | `em.find()`, `repository.findById()` |
| Фильтрация, сортировка, пагинация | HQL/JPQL или Spring Data derived queries |
| Агрегации, сложные `JOIN`, `GROUP BY` | HQL/JPQL |
| Загрузка коллекций без N+1 | `JOIN FETCH` + `@EntityGraph` |
| Массовое обновление/удаление | HQL `UPDATE/DELETE` (с осторожностью) или native SQL + `@Modifying` |
| Специфичные функции СУБД (CTE, window functions, JSONB) | `nativeQuery = true` |

---

##  Чек-лист написания HQL
1.  Использовать имена сущностей/полей Java, а не таблицы БД
2.  Всегда задавать алиасы (`e`, `d`, `p`)
3.  Предпочитать именованные параметры `:name`
4.  Для DTO использовать `SELECT new package.Class(...)`
5.  Проверять `setFirstResult`/`setMaxResults` на корректность с `JOIN FETCH`
6.  Тестировать с `spring.jpa.show-sql=true` или `org.hibernate.SQL=DEBUG`

Если скинете конкретный сценарий (сущности, связь, что хотите получить), напишу оптимальный HQL-запрос с пояснениями по производительности и кэшированию.