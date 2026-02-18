## Правила для полей в интерфейсах



```java
public interface MyInterface {
    // Все эти объявления эквивалентны:
    int CONSTANT = 10;
    public int CONSTANT2 = 20;
    static int CONSTANT3 = 30;
    final int CONSTANT4 = 40;
    public static final int CONSTANT5 = 50; // Полная форма
    
    // ❌ Ошибки компиляции:
    private int privateField = 10;      // Illegal!
    protected int protectedField = 20;  // Illegal!
    
    // ❌ Ошибки:
    int mutable;                        // Must be initialized!
    static int notFinal;                // Must be final implicitly!
}
```

**Компилятор автоматически добавляет:**

- `public` — доступ из любого места
    
- `static` — принадлежит интерфейсу, не экземпляру
    
- `final` — неизменяемое значение
## Что можно использовать вместо полей

### 1. **Константы (разрешено)**



```java
public interface HttpStatus {
    int OK = 200;
    int NOT_FOUND = 404;
    int SERVER_ERROR = 500;
}

// Использование:
int status = HttpStatus.OK; // Статический доступ
```

### 2. **Абстрактные методы (основное назначение)**


```java
public interface Repository<T> {
    T findById(long id);      // public abstract по умолчанию
    List<T> findAll();
    void save(T entity);
}
```

### 3. **Default методы (Java 8+) — с локальными переменными**


```java
public interface Calculator {
    default int sum(int a, int b) {
        // Локальные переменные — разрешены, но это не поля!
        var result = a + b;
        return result;
    }
}
```

### 4. **Private методы (Java 9+) — но не поля!**


```java
public interface Logger {
    default void logInfo(String msg) {
        log("INFO", msg); // Вызываем private метод
    }
    
    default void logError(String msg) {
        log("ERROR", msg);
    }
    
    // ✅ Private метод разрешён (Java 9+)
    private void log(String level, String msg) {
        System.out.println("[" + level + "] " + msg);
    }
    
    // ❌ Private поле — запрещено!
    // private String prefix = "[LOG]"; // Compile error!
}
```