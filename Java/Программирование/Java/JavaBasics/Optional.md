### ❌ Неудачное использование (Anti-patterns)

#### 1. Использование в качестве параметров методов

Это заставляет вызывающую сторону каждый раз оборачивать данные в `Optional`. Это загромождает код и создает лишние объекты в памяти.

Java

```
// ПЛОХО:
public void updateInfo(String id, Optional<String> newName) { ... }

// ХОРОШО (старая добрая перегрузка или проверка на null):
public void updateInfo(String id, String newName) { ... }
```

#### 2. Optional как поле класса (Fields)

`Optional` не реализует интерфейс `Serializable`. Если вы сделаете поле класса типом `Optional`, у вас возникнут проблемы с сериализацией (например, в Jackson или при сохранении в БД).

Java

```
// ПЛОХО:
public class Person {
    private Optional<String> middleName; // Так делать не стоит
}

// ХОРОШО:
public class Person {
    private String middleName; // Храним null
    
    public Optional<String> getMiddleName() { // Оборачиваем только в геттере
        return Optional.ofNullable(middleName);
    }
}
```

#### 3. Использование `.get()` без проверки

Вызов `.get()` на пустом `Optional` бросает `NoSuchElementException`. Это ничем не лучше, чем `NullPointerException`.

Java

```
// ХУЖЕ ВСЕГО:
User user = userOpt.get(); // Если там пусто, программа упадет

// ЛУЧШЕ:
User user = userOpt.orElseThrow(() -> new UserNotFoundException());
```

#### 4. Обертывание коллекций

Никогда не возвращайте `Optional<List<T>>`. Если список пуст, верните пустой список (`Collections.emptyList()`). Это стандарт де-факто в Java.