Да, вы абсолютно правы. Хардкодить строки вроде `root.get("salary")` — это плохая практика (риск опечаток, проблемы при рефакторинге).

Существует **три основных способа** избавиться от строк и сделать запросы типобезопасными:

---

## 🔹 1. JPA Metamodel (Стандартное решение)

Генерирует классы с суффиксом `_` (например, `Employee_`), которые содержат статические поля-ссылки на атрибуты сущности.

### 🔧 Подключение
**Maven:**
```xml
<dependency>
    <groupId>org.hibernate.orm</groupId>
    <artifactId>hibernate-jpamodelgen</artifactId>
    <version>6.4.0.Final</version>
    <scope>provided</scope>
</dependency>
```

**Gradle:**
```gradle
annotationProcessor 'org.hibernate.orm:hibernate-jpamodelgen:6.4.0.Final'
```

### 📄 Генерируемый класс
```java
@StaticMetamodel(Employee.class)
public abstract class Employee_ {
    public static volatile SingularAttribute<Employee, Long> id;
    public static volatile SingularAttribute<Employee, String> name;
    public static volatile SingularAttribute<Employee, BigDecimal> salary;
    public static volatile SingularAttribute<Employee, Department> department;
}
```

### ✅ Использование в Criteria API
```java
// Было (строка)
root.get("salary")

// Стало (типобезопасно)
root.get(Employee_.salary)
```

**Полный пример:**
```java
CriteriaBuilder cb = em.getCriteriaBuilder();
CriteriaQuery<Employee> query = cb.createQuery(Employee.class);
Root<Employee> root = query.from(Employee.class);

Predicate p = cb.gt(root.get(Employee_.salary), new BigDecimal("50000"));
query.select(root).where(p);
```

| Плюсы | Минусы |
|-------|--------|
| ✅ Стандарт JPA, работает везде | ❌ Громоздкий синтаксис `root.get(Employee_.field)` |
| ✅ Рефакторинг полей работает | ❌ Нужно перекомпилировать метамодель при изменениях |
| ✅ Нет строк в коде | ❌ Генерирует много классов-заглушек |

---

## 🔹 2. QueryDSL (Лучшая альтернатива)

Самая популярная библиотека для типобезопасных запросов. Синтаксис намного чище, чем у Criteria API + Metamodel.

### 🔧 Подключение
```xml
<dependency>
    <groupId>com.querydsl</groupId>
    <artifactId>querydsl-jpa</artifactId>
    <version>5.1.0</version>
</dependency>
<dependency>
    <groupId>com.querydsl</groupId>
    <artifactId>querydsl-apt</artifactId>
    <version>5.1.0</version>
    <classifier>jakarta</classifier>
    <scope>provided</scope>
</dependency>
```

### 📄 Генерируемый класс
Создаётся класс `QEmployee` с инстансом `employee`:
```java
public class QEmployee extends EntityPathBase<Employee> {
    public static final QEmployee employee = new QEmployee("employee");
    public final NumberPath<Long> id = createNumber("id", Long.class);
    public final StringPath name = createString("name");
    public final NumberPath<BigDecimal> salary = createNumber("salary", BigDecimal.class);
}
```

### ✅ Использование
```java
QEmployee emp = QEmployee.employee;

List<Employee> result = new JPAQueryFactory(entityManager)
    .selectFrom(emp)
    .where(emp.salary.gt(new BigDecimal("50000")))
    .where(emp.name.contains("Ivan"))
    .orderBy(emp.salary.desc())
    .fetch();
```

**С Spring Data JPA:**
```java
public interface EmployeeRepository extends JpaRepository<Employee, Long>, 
                                            QuerydslPredicateExecutor<Employee> {
}

// Использование Specification-подобного API
Predicate predicate = QEmployee.employee.salary.gt(new BigDecimal("50000"));
Iterable<Employee> result = repo.findAll(predicate);
```

| Плюсы | Минусы |
|-------|--------|
| ✅ Очень чистый и читаемый синтаксис | ❌ Дополнительная зависимость |
| ✅ Поддержка Spring Data out-of-the-box | ❌ Требуется генерация Q-классов |
| ✅ Мощный API для сложных запросов | ⚠️ Проект в режиме поддержки (но стабилен) |

---

## 🔹 3. jOOQ (Для сложной аналитики)

Библиотека для типобезопасного построения **SQL-запросов**. Лучше подходит для сложной аналитики, чем для простого CRUD.

```java
// Пример jOOQ
List<EmployeeRecord> result = dslContext
    .selectFrom(EMPLOYEE)
    .where(EMPLOYEE.SALARY.gt(50000))
    .fetch();
```

| Плюсы | Минусы |
|-------|--------|
| ✅ Полная типобезопасность SQL | ❌ Не работает с JPA-сущностями напрямую |
| ✅ Поддержка всех фишек СУБД | ❌ Платная для некоторых СУБД |
| ✅ Лучшая поддержка оконных функций, CTE | ❌ Отдельный маппинг на DTO/сущности |

---

## 📊 Сравнение подходов

| Критерий | Criteria + Strings | Criteria + Metamodel | QueryDSL | jOOQ |
|----------|-------------------|---------------------|----------|------|
| **Типобезопасность** | ❌ Нет | ✅ Да | ✅ Да | ✅ Да |
| **Рефакторинг** | ❌ Ручной | ✅ Автоматический | ✅ Автоматический | ✅ Автоматический |
| **Читаемость** | ✅ Высокая | ⚠️ Низкая | ✅✅ Очень высокая | ✅ Высокая |
| **Сложность настройки** | ✅ Нет | ⚠️ Средняя | ⚠️ Средняя | ⚠️ Средняя/Высокая |
| **Интеграция со Spring Data** | ✅ Встроенная | ✅ Встроенная | ✅ Отличная | ⚠️ Отдельная |
| **Рекомендация** | Только для прототипов | Если нельзя добавлять либы | ✅ **Для JPA-проектов** | Для сложной аналитики/SQL |

---

## ✅ Итоговая рекомендация

| Сценарий | Что выбрать |
|----------|-------------|
| **Новый проект на Spring Data JPA** | **QueryDSL** (лучший баланс удобства и мощности) |
| **Нельзя добавлять зависимости** | **JPA Metamodel** (стандартное решение) |
| **Сложная аналитика, много SQL** | **jOOQ** (в дополнение к JPA для чтения) |
| **Простые запросы** | **HQL/`@Query`** (не усложняйте без нужды) |

### 🚀 Пример с QueryDSL + Spring Data (Best Practice)

```java
// 1. Репозиторий
public interface EmployeeRepository extends JpaRepository<Employee, Long>, 
                                            QuerydslPredicateExecutor<Employee> {
}

// 2. Сервис с динамическим фильтром
@Service
public class EmployeeService {
    @Autowired private EmployeeRepository repo;
    
    public List<Employee> search(String name, BigDecimal minSalary, Long deptId) {
        QEmployee emp = QEmployee.employee;
        
        BooleanExpression predicate = emp.isNotNull(); // базовое условие
        
        if (name != null) {
            predicate = predicate.and(emp.name.containsIgnoreCase(name));
        }
        if (minSalary != null) {
            predicate = predicate.and(emp.salary.goe(minSalary));
        }
        if (deptId != null) {
            predicate = predicate.and(emp.department.id.eq(deptId));
        }
        
        return StreamSupport.stream(repo.findAll(predicate).spliterator(), false)
                            .collect(Collectors.toList());
    }
}
```

