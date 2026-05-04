
## 🏗️ Подготовка: Сущность и Репозиторий

```java
@Entity
@Inheritance(strategy = InheritanceType.SINGLE_TABLE)
@DiscriminatorColumn(name = "emp_type")
@Table(name = "employees")
public class Employee {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(nullable = false)
    private String name;
    
    @Column(nullable = false, unique = true)
    private String email;
    
    private BigDecimal salary;
    
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "department_id")
    private Department department;
    
    // constructors, getters, setters
}

@Repository
public interface EmployeeRepository extends JpaRepository<Employee, Long> {
    
    // ✅ Derived Query (автоматическая генерация)
    Optional<Employee> findByEmail(String email);
    List<Employee> findByDepartmentName(String deptName);
    boolean existsByEmail(String email);
    
    // ✅ @Query (кастомный HQL/JPQL)
    @Query("SELECT e FROM Employee e JOIN FETCH e.department WHERE e.id = :id")
    Optional<Employee> findWithDepartment(@Param("id") Long id);
    
    // ✅ Projection (DTO)
    @Query("SELECT new com.example.dto.EmployeeDTO(e.id, e.name, e.salary) FROM Employee e WHERE e.department.id = :deptId")
    List<EmployeeDTO> findDTOsByDepartment(@Param("deptId") Long deptId);
    
    // ✅ Модифицирующий запрос
    @Modifying
    @Transactional
    @Query("UPDATE Employee e SET e.salary = e.salary * :factor WHERE e.department.id = :deptId")
    int increaseSalary(@Param("deptId") Long deptId, @Param("factor") BigDecimal factor);
}
```

---

## 1️⃣ CREATE (Создание)

### ✅ Лучший подход: `save()`
```java
@Service
@Transactional
public class EmployeeService {
    @Autowired private EmployeeRepository repo;
    
    public Employee createEmployee(EmployeeDTO dto) {
        // Валидация перед сохранением
        if (repo.existsByEmail(dto.getEmail())) {
            throw new DuplicateResourceException("Email exists");
        }
        
        Employee emp = new Employee();
        emp.setName(dto.getName());
        emp.setEmail(dto.getEmail());
        emp.setSalary(dto.getSalary());
        
        return repo.save(emp); // persist + flush
    }
}
```
**Почему это хорошо:**
- `save()` автоматически делает `persist` (для новых) или `merge` (для существующих)
- Транзакция гарантирует атомарность
- Валидация предотвращает нарушение уникальных ограничений

### ⚠️ Ошибки
```java
// ❌ Ручной persist без транзакции
em.persist(employee); // не сохранится в БД без @Transactional

// ❌ Игнорирование исключений
repo.save(employee); // может выбросить DataIntegrityViolationException
```

---

## 2️⃣ READ (Чтение)

### ✅ Вариант 1: По ID (с ленивой загрузкой связей)
```java
public Employee getById(Long id) {
    return repo.findById(id)
        .orElseThrow(() -> new EntityNotFoundException("Employee not found: " + id));
}
```

### ✅ Вариант 2: С подгруженными связями (избегаем N+1)
```java
// В репозитории
@Query("SELECT e FROM Employee e JOIN FETCH e.department WHERE e.id = :id")
Optional<Employee> findWithDepartment(@Param("id") Long id);

// В сервисе
public Employee getWithDepartment(Long id) {
    return repo.findWithDepartment(id)
        .orElseThrow(EntityNotFoundException::new);
}
```

### ✅ Вариант 3: Пагинация + Сортировка
```java
// В репозитории
Page<Employee> findByDepartmentId(Long deptId, Pageable pageable);

// В сервисе
public Page<Employee> getEmployeesByDept(Long deptId, int page, int size) {
    Pageable pageable = PageRequest.of(page, size, Sort.by("name").ascending());
    return repo.findByDepartmentId(deptId, pageable);
}
```

### ✅ Вариант 4: DTO Projection (для списков)
```java
// В репозитории
@Query("SELECT new com.example.dto.EmployeeDTO(e.id, e.name, e.salary) FROM Employee e")
List<EmployeeDTO> findAllDTOs();

// Быстрее и легче, чем загружать полные сущности
```

---

## 3️⃣ UPDATE (Обновление)

### ✅ Вариант 1: Полное обновление (через сущность)
```java
@Transactional
public Employee updateEmployee(Long id, EmployeeDTO dto) {
    Employee emp = repo.findById(id)
        .orElseThrow(EntityNotFoundException::new);
    
    emp.setName(dto.getName());
    emp.setSalary(dto.getSalary());
    // email обычно не меняют
    
    return repo.save(emp); // merge, flush при commit
}
```

### ✅ Вариант 2: Частичное обновление (PATCH)
```java
@Transactional
public Employee patchEmployee(Long id, Map<String, Object> updates) {
    Employee emp = repo.findById(id)
        .orElseThrow(EntityNotFoundException::new);
    
    updates.forEach((field, value) -> {
        switch (field) {
            case "name" -> emp.setName((String) value);
            case "salary" -> emp.setSalary((BigDecimal) value);
            default -> throw new IllegalArgumentException("Unknown field: " + field);
        }
    });
    
    return emp; // dirty checking сделает UPDATE автоматически
}
```

### ✅ Вариант 3: Массовое обновление (HQL)
```java
// В репозитории
@Modifying
@Transactional
@Query("UPDATE Employee e SET e.salary = e.salary * :factor WHERE e.department.id = :deptId")
int increaseSalary(@Param("deptId") Long deptId, @Param("factor") BigDecimal factor);

// В сервисе
@Transactional
public void bulkIncreaseSalary(Long deptId, BigDecimal factor) {
    int updated = repo.increaseSalary(deptId, factor);
    em.clear(); // ⚠️ Обязательно очистить кэш после bulk-операции!
}
```

### ⚠️ Ошибки
```java
// ❌ Обновление без транзакции
emp.setSalary(newSalary); // изменения не сохранятся

// ❌ Bulk update без clear()
repo.increaseSalary(deptId, factor);
// Кэш Hibernate не знает об изменениях, могут быть неконсистентные данные
```

---

## 4️⃣ DELETE (Удаление)

### ✅ Вариант 1: По ID
```java
@Transactional
public void deleteEmployee(Long id) {
    if (!repo.existsById(id)) {
        throw new EntityNotFoundException("Employee not found: " + id);
    }
    repo.deleteById(id);
}
```

### ✅ Вариант 2: По сущности (с каскадами)
```java
@Transactional
public void deleteEmployee(Employee emp) {
    repo.delete(emp); // сработают cascade = REMOVE, orphanRemoval
}
```

### ✅ Вариант 3: Массовое удаление (HQL)
```java
// В репозитории
@Modifying
@Transactional
@Query("DELETE FROM Employee e WHERE e.department.id = :deptId")
int deleteByDepartment(@Param("deptId") Long deptId);

// В сервисе
@Transactional
public void deleteByDept(Long deptId) {
    repo.deleteByDepartment(deptId);
    em.clear(); // ⚠️ Очистка кэша обязательна
}
```

---

## 📊 Сводная таблица CRUD-операций

| Операция | Метод | Когда использовать | Производительность |
|----------|-------|-------------------|-------------------|
| **Create** | `repo.save()` | Стандартное создание | ✅ Высокая |
| **Read by ID** | `repo.findById()` | Получение одной сущности | ✅ Высокая |
| **Read with relations** | `@Query + FETCH` | Избежание N+1 | ✅ Высокая (1 запрос) |
| **Read list** | `Pageable + Projection` | Списки, таблицы | ✅✅ Очень высокая |
| **Update single** | `save()` + dirty checking | Изменение полей | ✅ Высокая |
| **Update bulk** | `@Modifying + UPDATE` | Массовые изменения | ✅✅ Очень высокая |
| **Delete single** | `deleteById()` | Удаление одной | ✅ Высокая |
| **Delete bulk** | `@Modifying + DELETE` | Массовое удаление | ✅✅ Очень высокая |

---

## ⚠️ Топ-5 ошибок в CRUD

| Ошибка | Проблема | Решение |
|--------|----------|---------|
| ❌ Нет `@Transactional` | Изменения не сохраняются | Добавлять на сервис-методы |
| ❌ N+1 проблема | 1 + N запросов при итерации | `JOIN FETCH` или `@EntityGraph` |
| ❌ Bulk без `clear()` | Кэш не синхронизирован с БД | `em.clear()` после `UPDATE/DELETE` |
| ❌ `EAGER` fetch по умолчанию | Загрузка лишних данных | Использовать `LAZY` + явный `FETCH` |
| ❌ Возврат сущностей в API | Сериализация, lazy init exception | Использовать DTO / MapStruct |

---

## ✅ Полный пример сервиса

```java
@Service
@Transactional(readOnly = true)
public class EmployeeService {
    
    @Autowired private EmployeeRepository repo;
    @Autowired private EntityManager em;
    
    @Transactional
    public Employee create(CreateEmployeeRequest req) {
        Employee emp = new Employee();
        emp.setName(req.getName());
        emp.setEmail(req.getEmail());
        emp.setSalary(req.getSalary());
        return repo.save(emp);
    }
    
    public EmployeeDTO getById(Long id) {
        Employee emp = repo.findWithDepartment(id)
            .orElseThrow(() -> new EntityNotFoundException(id));
        return toDTO(emp);
    }
    
    public Page<EmployeeDTO> getByDepartment(Long deptId, Pageable pageable) {
        return repo.findByDepartmentId(deptId, pageable)
            .map(this::toDTO);
    }
    
    @Transactional
    public Employee update(Long id, UpdateEmployeeRequest req) {
        Employee emp = repo.findById(id)
            .orElseThrow(() -> new EntityNotFoundException(id));
        
        emp.setName(req.getName());
        emp.setSalary(req.getSalary());
        return emp; // dirty checking
    }
    
    @Transactional
    public void delete(Long id) {
        repo.deleteById(id);
    }
    
    @Transactional
    public int bulkIncreaseSalary(Long deptId, BigDecimal factor) {
        int count = repo.increaseSalary(deptId, factor);
        em.clear();
        return count;
    }
    
    private EmployeeDTO toDTO(Employee emp) {
        return new EmployeeDTO(emp.getId(), emp.getName(), emp.getSalary());
    }
}
```

---

## 🎯 Итоговые рекомендации

1. **Всегда `@Transactional`** на методах записи (CUD)
2. **`readOnly = true`** на методах чтения (оптимизация Hibernate)
3. **DTO для API**, не возвращайте сущности наружу
4. **`JOIN FETCH`** для связей, но осторожно с пагинацией
5. **`em.clear()`** после bulk-операций
6. **Валидация** перед сохранением (Bean Validation или ручная)
