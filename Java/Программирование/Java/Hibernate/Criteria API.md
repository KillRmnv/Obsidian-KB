**Criteria API** — это программный, типобезопасный способ построения запросов в JPA/Hibernate. В отличие от HQL/JPQL, где запросы пишутся строками, Criteria API использует Java-объекты, что позволяет отлавливать ошибки на этапе компиляции и динамически формировать запросы.

---

## 🔹 Архитектура Criteria API

| Компонент | Описание |
|-----------|----------|
| `CriteriaBuilder` | Фабрика для создания компонентов запроса (`cb.equal()`, `cb.and()`, и т.д.) |
| `CriteriaQuery<T>` | Сам запрос, определяет тип возвращаемых данных |
| `Root<T>` | Корень запроса (аналог `FROM Entity e`) |
| `Path<T>` | Путь к атрибуту (аналог `e.field`) |
| `Predicate` | Условие фильтрации (аналог `WHERE`) |
| `Join<T, K>` | Присоединение связей (аналог `JOIN`) |

---

## 🔹 Базовый пример

```java
// Получаем CriteriaBuilder из EntityManager
CriteriaBuilder cb = entityManager.getCriteriaBuilder();

// Создаём запрос, указывая тип результата
CriteriaQuery<Employee> query = cb.createQuery(Employee.class);

// Определяем корень (FROM Employee e)
Root<Employee> root = query.from(Employee.class);

// Формируем условия (WHERE e.salary > :minSalary)
Predicate salaryPredicate = cb.greaterThan(root.get("salary"), new BigDecimal("50000"));
Predicate activePredicate = cb.equal(root.get("active"), true);

// Применяем условия и сортировку
query.select(root)
     .where(cb.and(salaryPredicate, activePredicate))
     .orderBy(cb.desc(root.get("salary")));

// Выполняем запрос
List<Employee> result = entityManager.createQuery(query).getResultList();
```

---

## 🔹 Сравнение: HQL vs Criteria API

| Критерий | HQL / JPQL | Criteria API |
|----------|------------|--------------|
| **Синтаксис** | Строковый (`"SELECT e FROM..."`) | Объектный (Java-код) |
| **Безопасность** | Ошибки только в runtime | ✅ Ошибки типов на compile-time |
| **Динамичность** | Сложно (конкатенация строк) | ✅ Легко (if/else логика) |
| **Читаемость** | ✅ Высокая (похож на SQL) | ⚠️ Низкая (много шаблонного кода) |
| **Рефакторинг** | ⚠️ Имена полей в строках не меняются | ✅ IDE помогает переименовывать |
| **Сложные запросы** | ✅ Проще писать | ⚠️ Громоздко |

> 💡 **Золотое правило:** Используйте **HQL** для статических запросов и **Criteria API** для динамических фильтров (поисковые формы, админки).

---

## 🔹 Продвинутые примеры

### 1. Динамический фильтр (Search Query)
Самый частый кейс для Criteria API — построение запроса на основе необязательных параметров.

```java
public List<Employee> searchEmployees(String name, BigDecimal minSalary, Long deptId) {
    CriteriaBuilder cb = em.getCriteriaBuilder();
    CriteriaQuery<Employee> query = cb.createQuery(Employee.class);
    Root<Employee> root = query.from(Employee.class);
    
    // Собираем список предикатов
    List<Predicate> predicates = new ArrayList<>();
    
    if (name != null && !name.isEmpty()) {
        predicates.add(cb.like(cb.lower(root.get("name")), "%" + name.toLowerCase() + "%"));
    }
    if (minSalary != null) {
        predicates.add(cb.ge(root.get("salary"), minSalary));
    }
    if (deptId != null) {
        // Присоединяем связь для фильтрации
        Join<Employee, Department> deptJoin = root.join("department");
        predicates.add(cb.equal(deptJoin.get("id"), deptId));
    }
    
    query.select(root).where(cb.and(predicates.toArray(new Predicate[0])));
    return em.createQuery(query).getResultList();
}
```

### 2. JOIN FETCH (Избежание N+1)
```java
CriteriaQuery<Employee> query = cb.createQuery(Employee.class);
Root<Employee> root = query.from(Employee.class);
// Явно указываем FETCH JOIN
root.fetch("department", JoinType.LEFT); 
root.fetch("projects", JoinType.LEFT);

query.select(root).distinct(true); // distinct обязателен при JOIN FETCH коллекций
```

### 3. Агрегация и Группировка
```java
CriteriaQuery<Object[]> query = cb.createQuery(Object[].class);
Root<Employee> root = query.from(Employee.class);
Join<Employee, Department> dept = root.join("department");

// SELECT d.name, AVG(e.salary), COUNT(e)
query.multiselect(
    dept.get("name"),
    cb.avg(root.get("salary")),
    cb.count(root)
)
.groupBy(dept.get("name"))
.having(cb.gt(cb.avg(root.get("salary")), new BigDecimal("50000")));
```

### 4. DTO Projection (Конструктор)
```java
CriteriaQuery<EmployeeDTO> query = cb.createQuery(EmployeeDTO.class);
Root<Employee> root = query.from(Employee.class);

query.select(cb.construct(
    EmployeeDTO.class,
    root.get("id"),
    root.get("name"),
    root.get("salary")
));
```

### 5. Пагинация
```java
TypedQuery<Employee> typedQuery = em.createQuery(query);
typedQuery.setFirstResult(page * size);
typedQuery.setMaxResults(size);
List<Employee> result = typedQuery.getResultList();
```

---

## 🔹 JPA Metamodel (Полная типобезопасность)

Чтобы избежать магических строк `root.get("salary")`, можно использовать сгенерированный класс метамодели `Employee_`.

```java
// Генерируется аннотационным процессором (hibernate-jpamodelgen)
@StaticMetamodel(Employee.class)
public abstract class Employee_ {
    public static volatile SingularAttribute<Employee, Long> id;
    public static volatile SingularAttribute<Employee, String> name;
    public static volatile SingularAttribute<Employee, BigDecimal> salary;
    public static volatile SingularAttribute<Employee, Department> department;
}
```

**Использование:**
```java
// Вместо root.get("salary") пишем:
Predicate p = cb.gt(root.get(Employee_.salary), minSalary);
```
✅ **Плюс:** При переименовании поля в сущности код не скомпилируется, пока вы не исправите запрос.

---

## 🔹 Spring Data JPA Specifications

В Spring Data JPA есть удобная обертка над Criteria API — интерфейс `Specification`. Это позволяет переиспользовать условия фильтрации.

```java
// 1. Создаём спецификацию
public class EmployeeSpecs {
    public static Specification<Employee> hasName(String name) {
        return (root, query, cb) -> 
            name == null ? null : cb.like(root.get("name"), "%" + name + "%");
    }
    
    public static Specification<Employee> minSalary(BigDecimal min) {
        return (root, query, cb) -> 
            min == null ? null : cb.ge(root.get("salary"), min);
    }
}

// 2. Репозиторий
public interface EmployeeRepository extends JpaRepository<Employee, Long>, 
                                            JpaSpecificationExecutor<Employee> {
}

// 3. Использование в сервисе
Specification<Employee> spec = Specification.where(hasName("Ivan"))
                                            .and(minSalary(new BigDecimal("50000")));
List<Employee> result = repo.findAll(spec);
```

---

## ⚠️ Подводные камни

| Проблема | Решение |
|----------|---------|
| **Дубликаты при JOIN FETCH** | Добавлять `query.distinct(true)` |
| **Громоздкий код** | Использовать `Specifications` или библиотеки типа **QueryDSL** |
| **Сложные условия (OR/AND)** | Группировать предикаты: `cb.or(p1, p2)`, `cb.and(p3, p4)` |
| **Null в параметрах** | Проверять на null перед созданием `Predicate` или возвращать `null` из `Specification` |
| **Сортировка** | Создавать `Order` объекты: `query.orderBy(cb.asc(root.get("name")))` |

---

## 📊 Когда что выбирать?

| Задача | Инструмент |
|--------|------------|
| Простой статический запрос | **HQL / `@Query`** |
| Динамический фильтр (поиск) | **Criteria API / Specifications** |
| Сложная бизнес-логика в запросе | **Criteria API** |
| Максимальная типобезопасность | **Criteria API + Metamodel** |
| Очень сложные запросы | **QueryDSL** (альтернатива Criteria API) |
| Специфика СУБД (JSON, CTE) | **Native SQL** |

---

## ✅ Чек-лист написания Criteria API
1. ✅ Всегда закрывайте `TypedQuery` (в try-with-resources или через `EntityManager` lifecycle)
2. ✅ Используйте `distinct(true)` при `JOIN FETCH` коллекций
3. ✅ Проверяйте параметры на `null` перед созданием `Predicate`
4. ✅ Для переиспользования условий применяйте `Specification`
5. ✅ Рассмотрите **QueryDSL**, если критериев много (синтаксис проще)
6. ✅ Включите логирование SQL, чтобы проверять генерируемые запросы
