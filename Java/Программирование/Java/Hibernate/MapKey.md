Аннотация `@MapKey` используется для маппинга отношений `@OneToMany` или `@ManyToMany` в виде `java.util.Map`. Она определяет, **что будет выступать ключом карты**: сама сущность, её `@Id` или произвольное поле.

---

##  1. Как определяется ключ
| Запись в коде | Что будет ключом `Map<K, V>` | Примечание |
|--------------|-----------------------------|------------|
| `@MapKey` (без `name`) | `@Id` целевой сущности | Если тип ключа совпадает с типом `@Id` |
| `@MapKey(name = "code")` | Значение поля `code` | Поле должно быть частью сущности |
| Без `@MapKey` (если `K` = сущность или `@Id`) | Автоматически выводится | JPA сам догадается, но явная запись надёжнее |

```java
@Entity
public class Department {
    @Id Long id;

    // Ключ = employee.id
    @OneToMany(mappedBy = "department")
    @MapKey
    private Map<Long, Employee> employeesById = new HashMap<>();

    // Ключ = employee.login
    @OneToMany(mappedBy = "department")
    @MapKey(name = "login")
    private Map<String, Employee> employeesByLogin = new HashMap<>();
}
```

---

##  2. Связанные аннотации для кастомизации ключа
| Аннотация | Когда использовать |
|-----------|-------------------|
| `@MapKeyColumn(name = "map_key_col")` | Ключ хранится в **отдельном столбце** таблицы, не маппится на поле сущности |
| `@MapKeyJoinColumn(name = "fk_col")` | Ключом является внешний ключ (редко, обычно для сложных `@ManyToMany`) |
| `@MapKeyEnumerated` / `@MapKeyTemporal` | Ключ имеет тип `Enum` или `Date/Time` |

```java
// Ключ не является полем сущности, а хранится в отдельной колонке
@OneToMany(mappedBy = "category")
@MapKeyColumn(name = "product_code")
private Map<String, Product> productsByCode = new HashMap<>();
```

---

##  3. Сортировка `Map` в JPA
`Map` **не сохраняет порядок вставки**. Если нужен предсказуемый порядок, используйте `@OrderBy` или инициализируйте `LinkedHashMap`.

```java
@OneToMany(mappedBy = "department")
@MapKey(name = "login")
@OrderBy("hireDate ASC") // Сортирует по значениям карты (сотрудникам)
private Map<String, Employee> sortedEmployees = new LinkedHashMap<>();
```
 **Важно:** 
- `@OrderBy` на `Map` сортирует **по значениям**, а не по ключам.
- `@OrderColumn` **не поддерживается** для `Map` (только для `List`).
- Без `@OrderBy` порядок элементов не гарантируется спецификацией JPA.

---

##  4. Критические нюансы и подводные камни
1. **Не меняйте ключевое поле после сохранения**  
   Если поле, указанное в `@MapKey(name = "...")`, изменится в БД, Hibernate может не синхронизировать изменения в persistence context, и карта станет неконсистентной.

2. `Map` не поддерживает positional operations  
   В отличие от `List`, в `Map` нет индексов. Удаление/вставка не вызывает массовых `UPDATE`, но и не даёт контроля над позицией.

3. `cascade = CascadeType.ALL` + `orphanRemoval = true`  
   При удалении элемента из карты (`map.remove(key)`) Hibernate автоматически удалит сущность из БД. Это удобно, но требует аккуратности.

4. **Инициализация коллекции**  
   Всегда инициализируйте поле, иначе получите `NullPointerException` при `map.put()`:
   ```java
   private Map<String, Book> books = new HashMap<>(); // или new LinkedHashMap<>()
   ```

5. JPA 3 (Jakarta EE)  
   Пакет изменился: `jakarta.persistence.MapKey`, логика идентична.

---
