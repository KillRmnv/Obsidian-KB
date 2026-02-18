 JavaBean — это класс Java, который следует определённым соглашениям (conventions), позволяющим использовать его как переиспользуемый компонент, особенно в фреймворках и инструментах вроде Spring, Hibernate, JavaBeans API.

## Основные признаки JavaBean:

### 1. **Наличие конструктора без параметров (no-arg constructor)**
```java
public class UserBean {
    public UserBean() {
        // Обязательно пустой или с дефолтной инициализацией
    }
}
```

### 2. **Приватные поля (private fields)**
Все свойства должны быть приватными для инкапсуляции:
```java
private String name;
private int age;
```

### 3. **Публичные геттеры и сеттеры (getters/setters)**
Для каждого свойства должны быть методы доступа:
```java
public String getName() {
    return name;
}

public void setName(String name) {
    this.name = name;
}

public int getAge() {
    return age;
}

public void setAge(int age) {
    this.age = age;
}
```

**Особенности именования:**
- Для `boolean` можно использовать префикс `is` вместо `get`: `isActive()` / `setActive(boolean active)`
- Для коллекций: `getItems()` / `setItems(List<Item> items)`

### 4. **Сериализуемость (Serializable) — желательно**
```java
public class UserBean implements java.io.Serializable {
    private static final long serialVersionUID = 1L;
    // ...
}
```

### 5. **Отсутствие публичных полей**
Все данные доступны только через методы доступа.

### 6. **Независимость от GUI**
JavaBean не должен зависеть от конкретного графического интерфейса (хотя изначально JavaBeans разрабатывались для GUI-компонентов, сейчас это более широкое понятие).

## Пример полноценного JavaBean:

```java
import java.io.Serializable;

public class PersonBean implements Serializable {
    
    private static final long serialVersionUID = 1L;
    
    private String firstName;
    private String lastName;
    private int age;
    private boolean active;
    
    // Конструктор без параметров
    public PersonBean() {
    }
    
    // Геттеры и сеттеры
    public String getFirstName() {
        return firstName;
    }
    
    public void setFirstName(String firstName) {
        this.firstName = firstName;
    }
    
    public String getLastName() {
        return lastName;
    }
    
    public void setLastName(String lastName) {
        this.lastName = lastName;
    }
    
    public int getAge() {
        return age;
    }
    
    public void setAge(int age) {
        this.age = age;
    }
    
    // Для boolean — префикс is
    public boolean isActive() {
        return active;
    }
    
    public void setActive(boolean active) {
        this.active = active;
    }
}
```

## Дополнительные возможности (необязательно):

- **PropertyChangeSupport** — для уведомления слушателей об изменениях свойств
- **Indexed properties** — для работы с массивами (`getItem(int index)`, `setItem(int index, Item item)`)
- **Bound properties** и **Constrained properties** — для валидации и событий

## Где используются JavaBeans:

- **Spring Framework** — для конфигурации бинов и DI
- **Hibernate/JPA** — для маппинга сущностей
- **JSF, JSP** — для компонентов представления
- **JavaBeans API** — для визуальных компонентов в IDE

Современные альтернативы (Record-классы в Java 14+, Lombok `@Data`, Immutables) упрощают создание таких классов, но понимание JavaBean-конвенций остаётся фундаментальным для работы с Java-экосистемой.