## Стандартные immutable классы в Java

### 1. **Классы-обёртки примитивов**

java

Copy

```java
Integer i = 10;      // Неизменяем
i = 20;              // Создание НОВОГО объекта, старый не изменился!

Long l = 100L;
Double d = 3.14;
Boolean b = true;
// + Float, Short, Byte, Character
```

**Особенность:** кэширование частых значений (`Integer.valueOf(-128..127)`).

---

### 2. **String** — самый известный immutable класс

java

Copy

```java
String s = "Hello";
s = s + " World";    // Создаётся НОВЫЙ объект!
// "Hello" остаётся в пуле строк неизменным
```

**Почему immutable:**

- Пул строк (String Pool) возможен только при неизменности
    
- Безопасность (ключи в HashMap, параметры сетевых вызовов)
    
- Потокобезопасность без синхронизации
    

---

### 3. **BigInteger и BigDecimal**

java

Copy

```java
BigInteger bi = new BigInteger("12345678901234567890");
bi = bi.add(BigInteger.ONE);  // Новый объект!

BigDecimal bd = new BigDecimal("99.99");
bd = bd.multiply(new BigDecimal("1.2")); // Новый объект!
```

**Важно:** `BigDecimal` требует `MathContext` для точности операций.

---

### 4. **java.time API (Java 8+)**

Все классы даты/времени неизменяемы:

java

Copy

```java
LocalDate date = LocalDate.now();           // 2024-03-15
LocalDate nextWeek = date.plusWeeks(1);     // Новый объект!

LocalTime time = LocalTime.of(14, 30);
LocalDateTime dateTime = LocalDateTime.now();
ZonedDateTime zoned = ZonedDateTime.now();
Instant instant = Instant.now();
Duration duration = Duration.ofHours(2);
Period period = Period.ofDays(7);
```

**Замена:** устаревших `Date`, `Calendar` (которые mutable!).

---

### 5. **UUID**

java

Copy

```java
UUID uuid = UUID.randomUUID(); // 128-битное неизменяемое значение
```

---

### 6. **Optional, OptionalInt, OptionalLong, OptionalDouble**

java

Copy

```java
Optional<String> opt = Optional.of("value");
opt = opt.map(String::toUpperCase); // Новый Optional!
// Внутреннее значение не меняется
```

---

### 7. **Коллекции unmodifiable / immutable**

java

Copy

```java
// Java 9+ фабричные методы — truly immutable
List<String> list = List.of("a", "b", "c");           // Immutable
Set<Integer> set = Set.of(1, 2, 3);                   // Immutable
Map<String, Integer> map = Map.of("key", 1, "k2", 2); // Immutable

// Java 8 и ранее — unmodifiable view (обёртка)
List<String> unmod = Collections.unmodifiableList(new ArrayList<>());
// Если оригинал изменится — отразится в обёртке!
```

**Различие:**

- `List.of()` — immutable, нельзя ни изменить, ни расширить
    
- `Collections.unmodifiableList()` — view, блокирует модификацию через API, но не гарантирует иммутабельность
    

---

### 8. **java.net классы**

java

Copy

```java
URI uri = new URI("https://example.com/path?query=1");
URL url = new URL("https://example.com");
InetAddress address = InetAddress.getByName("localhost");
```

---

### 9. **Pattern (регулярные выражения)**

java

Copy

```java
Pattern pattern = Pattern.compile("\\d+"); // Компилированный regex immutable
Matcher matcher = pattern.matcher("123");  // Matcher — отдельный mutable объект!
```

---

### 10. **Currency, Locale**

java

Copy

```java
Currency usd = Currency.getInstance("USD"); // Immutable
Locale ru = Locale.forLanguageTag("ru-RU"); // Immutable
```

---

## Как проверить immutable класс

java

Copy

```java
public final class ImmutableCheck {  // 1. Класс final
    
    private final int field;          // 2. Все поля final
    private final List<String> list;  // 3. Ссылки на mutable тоже final
    
    public ImmutableCheck(int field, List<String> list) {
        this.field = field;
        // 4. Защитное копирование!
        this.list = List.copyOf(list); // Или new ArrayList<>(list)
    }
    
    // 5. Нет сеттеров!
    
    public List<String> getList() {
        // 6. Возвращаем копию или unmodifiable view
        return List.copyOf(list);
    }
}
```

---

## Сравнение: Mutable vs Immutable

Table

Copy

|Характеристика|Mutable (StringBuilder)|Immutable (String)|
|:--|:--|:--|
|Изменение|`append()` меняет объект|`concat()` создаёт новый|
|Потокобезопасность|Нужна синхронизация|Безопасен по умолчанию|
|Использование|Сборка строк в цикле|Ключи Map, константы|
|Производительность|Быстрее при множестве изменений|Медленнее при частых модификациях|

---




# Как создать
Создание **immutable (неизменяемого) объекта** требует соблюдения строгих правил на всех уровнях: объявления класса, полей, конструкторов и методов доступа.

---

## Правила создания immutable класса

### 1. **Класс объявить `final`**

Запрещает наследование и переопределение методов.

### 2. **Все поля — `private final`**

Невозможно изменить ни извне, ни случайно переприсвоить.

### 3. **Нет сеттеров (setter'ов)**

Исключает любую модификацию состояния.

### 4. **Защитное копирование в конструкторе**

Приём mutable объектов требует создания их копий.

### 5. **Защитное копирование в геттерах**

Возврат копий вместо оригинальных ссылок.

### 6. **Глубокая неизменяемость**

Все содержащиеся объекты тоже должны быть immutable или защищены.