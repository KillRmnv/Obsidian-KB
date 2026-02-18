![[Pasted image 20251002195534.png]]

![[Pasted image 20251002195556.png]]
Exceptions can occur due to several reasons, such as:

- Invalid user input
- Device failure
- Loss of network connection
- Physical limitations (out-of-disk memory)
- Code errors
- Out of bound
- Null reference
- Type mismatch
- Opening an unavailable file
- Database errors
- Arithmetic errors
  
  ![[Pasted image 20251002195631.png]]
```java
try {
    // Code that may throw an exception
} catch (ArithmeticException e) {
    // Code to handle the exception
} catch(ArrayIndexOutOfBoundsException e){
    //Code to handle the anothert exception
}catch(NumberFormatException e){
     //Code to handle the anothert exception
}finally{
//executed everytime
}
```
### Methods to Print the Exception Information

1. [****printStackTrace()****](https://www.geeksforgeeks.org/java/throwable-printstacktrace-method-in-java-with-examples/)****:**** Prints the full stack trace of the exception, including the name, message and location of the error.
2. [****toString()****](https://www.geeksforgeeks.org/java/throwable-tostring-method-in-java-with-examples/)****:**** Prints exception information in the format of the Name of the exception.
3. [****getMessage()****](https://www.geeksforgeeks.org/java/throwable-getmessage-method-in-java-with-examples/) ****:**** Prints the description of the exception
   
   |Error|Exception|
|---|---|
|An Error indicates a serious problem that a reasonable application should not try to catch.|Exception indicates conditions that a reasonable application might try to catch|
|This is caused by issues with the JVM or hardware.|This is caused by conditions in the program such as invalid input or logic errors.|
|****Examples****: OutOfMemoryError, StackOverFlowError|****Examples****: IOException, NullPointerException|


## Сравнение: Checked vs Unchecked

Table

Copy

|Характеристика|Checked (IOException)|Unchecked (RuntimeException)|
|:--|:--|:--|
|**Обработка**|Обязательна (`try-catch` или `throws`)|Необязательна|
|**Наследование**|`Exception` (не Runtime)|`RuntimeException`|
|**Семантика**|Восстановимые ошибки|Ошибки программирования/системные|
|**Шум в коде**|Высокий|Минимальный|

---

## Причины перехода на unchecked

### 1. **Проблема "Exception Hell" с checked**

java

Copy

```java
// JDBC (классический пример checked-ада)
public void saveUser(User user) throws SQLException {
    // ...
}

// Сервис должен пробросить или обернуть
public void createUser(User user) throws SQLException {
    saveUser(user);
}

// Контроллер тоже вынужден обрабатывать
public void handleRequest(User user) throws SQLException {
    createUser(user);
}

// Результат: SQLException пронизывает всю архитектуру!
```

**С unchecked (Spring):**

java

Copy

```java
// Просто бросаем, не объявляем
public void saveUser(User user) {
    try {
        // JDBC операция
    } catch (SQLException e) {
        throw new DataAccessException("Failed to save", e); // Unchecked
    }
}

// Сервис чистый
public void createUser(User user) {
    saveUser(user); // Никаких throws!
}

// Контроллер чистый
public void handleRequest(User user) {
    createUser(user);
}

// Обработка в одном месте: @ControllerAdvice
@ExceptionHandler(DataAccessException.class)
public ResponseEntity<Error> handleDatabaseError(DataAccessException e) {
    return ResponseEntity.status(500).body(new Error(e.getMessage()));
}
```

### 2. **Невозможность восстановления на большинстве уровней**

java

Copy

```java
// В 90% случаев вы не можете восстановиться от SQLException на уровне бизнес-логики
public void processOrder(Order order) {
    try {
        dao.save(order);
    } catch (SQLException e) {
        // Что делать? Повторить? Игнорировать? 
        // Обычно: залогировать и пробросить выше
        throw new RuntimeException(e);
    }
}

// Spring сразу даёт unchecked — экономия времени и кода
public void processOrder(Order order) {
    orderRepository.save(order); // Просто работаем, исключение поймает @ControllerAdvice
}
```

### 3. **Полиморфизм и интерфейсы**

java

Copy

```java
// С checked: нарушение принципа подстановки Лисков
interface Repository<T> {
    void save(T entity) throws SQLException;      // JDBC
    void save(T entity) throws MongoException;    // MongoDB
    void save(T entity) throws IOException;       // File
}

// Реализация для JDBC вынуждена знать про MongoException?

// С unchecked: чистые интерфейсы
interface Repository<T> {
    void save(T entity); // Одинаково для всех реализаций!
}

// Конкретные исключения — деталь реализации, не контракта
```

### 4. **Функциональное программирование и лямбды**

java

Copy

```java
// Stream API с checked: многословно и нечитаемо
list.stream()
    .map(s -> {
        try {
            return readFile(s); // throws IOException
        } catch (IOException e) {
            throw new RuntimeException(e); // Вынужденная обёртка
        }
    })
    .collect(toList());

// С unchecked: естественно
list.stream()
    .map(this::fetchUser) // Метод бросает RuntimeException
    .collect(toList());
```

### 5. **Транзакционность и откат**

java

Copy

```java
// Spring: unchecked исключения вызывают rollback по умолчанию
@Transactional
public void transferMoney(Account from, Account to, BigDecimal amount) {
    // Любое RuntimeException → автоматический rollback
    // Checked Exception → commit (неожиданно!)
    
    if (from.getBalance().compareTo(amount) < 0) {
        throw new InsufficientFundsException("Not enough money"); // Unchecked
    }
    // ...
}

// Чтобы checked тоже вызывал rollback:
@Transactional(rollbackFor = SQLException.class) // Дополнительная настройка
```