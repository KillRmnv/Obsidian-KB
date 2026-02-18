## Основное различие

|Метод|Входной тип|Возвращаемый тип|Назначение|
|---|---|---|---|
|**`map()`**|Примитивный стрим|Примитивный стрим|Преобразование примитив → примитив|
|**`mapToObj()`**|Примитивный стрим|Объектный стрим (`Stream<T>`)|Преобразование примитив → объект|

---

## Наглядные примеры

### 1. **`map()`** — примитив → примитив (остаемся в примитивном мире)

java

IntStream.range(1, 5)
    .map(x -> x * 2)        // IntStream → IntStream
    .forEach(System.out::println); // 2, 4, 6, 8

// Доступны только примитивные операции
int sum = IntStream.of(1, 2, 3)
    .map(x -> x * x)        // 1→1, 2→4, 3→9
    .sum();                 // 14 (можно, т.к. IntStream)

### 2. **`mapToObj()`** — примитив → объект (переходим в объектный мир)

java

// IntStream → Stream<String>
Stream<String> strings = IntStream.range(1, 4)
    .mapToObj(i -> "Number: " + i); // Преобразовали int в String

strings.forEach(System.out::println);
// Вывод:
// Number: 1
// Number: 2
// Number: 3

// После mapToObj() нельзя вызывать примитивные операции
Stream<Integer> boxed = IntStream.of(1, 2, 3)
    .mapToObj(x -> x * 10); // IntStream → Stream<Integer>
// boxed.sum(); // ОШИБКА! У Stream<Integer> нет метода sum()

---