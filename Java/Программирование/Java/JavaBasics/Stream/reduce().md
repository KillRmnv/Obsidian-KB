![[Pasted image 20260113221557.png]]

Отлично! `reduce()` — одна из самых мощных и фундаментальных операций в Stream API. Это **терминальная операция**, которая сводит (редуцирует) поток элементов к одному значению.

## Что такое `reduce()`?

**`reduce()`** — это операция, которая комбинирует все элементы потока в один результат, используя:
1. **Начальное значение** (identity)
2. **Функцию аккумуляции** (accumulator)
3. **Опционально: функцию комбинирования** (combiner) для parallel streams

---

## Три варианта reduce()

### 1. **С identity (начальным значением)**
```java
T reduce(T identity, BinaryOperator<T> accumulator)

// Пример: сумма чисел
int sum = Stream.of(1, 2, 3, 4, 5)
    .reduce(0, (a, b) -> a + b); // 15
    
// Пошагово:
// identity = 0
// Шаг 1: 0 + 1 = 1
// Шаг 2: 1 + 2 = 3  
// Шаг 3: 3 + 3 = 6
// Шаг 4: 6 + 4 = 10
// Шаг 5: 10 + 5 = 15
```

### 2. **Без identity (возвращает Optional)**
```java
Optional<T> reduce(BinaryOperator<T> accumulator)

// Пример: максимум
Optional<Integer> max = Stream.of(1, 5, 3, 9, 2)
    .reduce((a, b) -> a > b ? a : b); // Optional[9]
    
// Пустой поток:
Optional<Integer> empty = Stream.<Integer>empty()
    .reduce((a, b) -> a + b); // Optional.empty()
```

### 3. **С combiner (для parallel streams)**
```java
<U> U reduce(U identity,
             BiFunction<U, ? super T, U> accumulator,
             BinaryOperator<U> combiner)
```

---

## Базовые примеры

### 1. Суммирование
```java
// Способ 1: reduce()
int sum1 = Stream.of(1, 2, 3, 4, 5)
    .reduce(0, Integer::sum); // 15

// Способ 2: sum() для IntStream (частный случай reduce)
int sum2 = IntStream.of(1, 2, 3, 4, 5).sum(); // 15

// Собственная логика суммирования
int customSum = Stream.of(1, 2, 3)
    .reduce(0, (acc, num) -> acc + num * 2); // 12
// 0 + 1*2 = 2
// 2 + 2*2 = 6  
// 6 + 3*2 = 12
```

### 2. Произведение
```java
int product = Stream.of(2, 3, 4)
    .reduce(1, (a, b) -> a * b); // 24

// Факториал через range
int factorial = IntStream.rangeClosed(1, 5)
    .reduce(1, (a, b) -> a * b); // 120
```

### 3. Конкатенация строк
```java
// Простая конкатенация
String concat = Stream.of("Hello", " ", "World", "!")
    .reduce("", String::concat); // "Hello World!"

// С разделителем
String withDelimiter = Stream.of("a", "b", "c", "d")
    .reduce((a, b) -> a + "," + b)
    .orElse(""); // "a,b,c,d"
```

### 4. Поиск минимума/максимума
```java
// Максимум
Optional<Integer> max = Stream.of(10, 5, 8, 15, 3)
    .reduce(Integer::max); // Optional[15]

// Минимум
Optional<Integer> min = Stream.of(10, 5, 8, 15, 3)
    .reduce(Integer::min); // Optional[3]

// С кастомным сравнением
Optional<String> longest = Stream.of("cat", "elephant", "dog")
    .reduce((s1, s2) -> s1.length() > s2.length() ? s1 : s2);
// Optional["elephant"]
```

---

## Сложные примеры

### 1. Свертка объектов
```java
record Transaction(String account, double amount) {}

List<Transaction> transactions = List.of(
    new Transaction("A", 100.0),
    new Transaction("B", 200.0),
    new Transaction("A", 50.0),
    new Transaction("C", 300.0),
    new Transaction("B", 150.0)
);

// Общая сумма всех транзакций
double total = transactions.stream()
    .map(Transaction::amount)
    .reduce(0.0, Double::sum); // 800.0

// Сумма по аккаунту "A"
double sumA = transactions.stream()
    .filter(t -> t.account().equals("A"))
    .map(Transaction::amount)
    .reduce(0.0, Double::sum); // 150.0
```

### 2. Построение сложных объектов
```java
// Объединение списков
List<List<Integer>> lists = List.of(
    List.of(1, 2),
    List.of(3, 4),
    List.of(5, 6)
);

List<Integer> combined = lists.stream()
    .reduce(new ArrayList<>(),
        (acc, list) -> {
            acc.addAll(list);
            return acc;
        });
// [1, 2, 3, 4, 5, 6]

// Построение Map
Map<String, Integer> map = Stream.of(
        "apple", "banana", "apple", "orange", "banana", "apple"
    )
    .reduce(new HashMap<>(),
        (acc, fruit) -> {
            acc.merge(fruit, 1, Integer::sum);
            return acc;
        },
        (map1, map2) -> { // combiner для parallel streams
            map2.forEach((k, v) -> map1.merge(k, v, Integer::sum));
            return map1;
        });
// {apple=3, banana=2, orange=1}
```

### 3. Статистика за один проход
```java
// Вычисляем min, max, sum и count за один проход
class Stats {
    int count = 0;
    int sum = 0;
    int min = Integer.MAX_VALUE;
    int max = Integer.MIN_VALUE;
    
    void accept(int value) {
        count++;
        sum += value;
        min = Math.min(min, value);
        max = Math.max(max, value);
    }
    
    Stats combine(Stats other) {
        count += other.count;
        sum += other.sum;
        min = Math.min(min, other.min);
        max = Math.max(max, other.max);
        return this;
    }
}

Stats stats = IntStream.of(10, 5, 8, 15, 3, 20)
    .collect(Stats::new, Stats::accept, Stats::combine);

System.out.printf("Count: %d, Sum: %d, Min: %d, Max: %d%n",
    stats.count, stats.sum, stats.min, stats.max);
// Count: 6, Sum: 61, Min: 3, Max: 20
```

---

## Parallel reduce (с combiner)

### Как работает комбайнер:
```java
// Пример параллельного reduce
List<String> words = List.of("Hello", "World", "Java", "Streams");

// identity, accumulator, combiner
String result = words.parallelStream()
    .reduce("",
        (partial, word) -> partial + word.length() + " ", // аккумулятор
        (part1, part2) -> part1 + part2);                 // комбайнер
// "5 5 4 7 "

// Что происходит в параллельном режиме:
// Поток 1: "" + "Hello".length() + " " = "5 "
// Поток 2: "" + "World".length() + " " = "5 "  
// Поток 3: "" + "Java".length() + " " = "4 "
// Поток 4: "" + "Streams".length() + " " = "7 "
// Комбайнер: "5 " + "5 " + "4 " + "7 " = "5 5 4 7 "
```

### Важно: требования к функциям
```java
// Для корректной работы в parallel stream:
// 1. identity должен быть нейтральным элементом
//    acc(identity, x) = x
// 2. accumulator и combiner должны быть ассоциативными
//    acc(acc(a, b), c) = acc(a, acc(b, c))
// 3. combiner должен быть совместим с identity
//    combiner.apply(identity, x) = x

// ПРАВИЛЬНО: сложение
.reduce(0, (a, b) -> a + b, (a, b) -> a + b);

// НЕПРАВИЛЬНО: вычитание (не ассоциативно)
.reduce(0, (a, b) -> a - b, (a, b) -> a - b); // Может давать разный результат!
```

---

## Сравнение с collect()

### `reduce()` vs `collect()`:
```java
List<String> words = List.of("Hello", "World");

// reduce(): иммутабельная операция
String reduced = words.stream()
    .reduce("", (acc, word) -> acc + word); // Создает новые строки

// collect(): мутабельная операция (обычно эффективнее)
String collected = words.stream()
    .collect(StringBuilder::new,
             StringBuilder::append,
             StringBuilder::append)
    .toString();

// collect() часто более эффективен для mutable контейнеров
```

### Когда использовать что:
- **`reduce()`** — для иммутабельных операций (числа, строки, immutable объекты)
- **`collect()`** — для mutable операций (списки, мапы, StringBuilder)

---

## Практические паттерны

### Паттерн 1: Каскадные вычисления
```java
// Вычисление среднего, дисперсии и стандартного отклонения
class Statistics {
    private int count = 0;
    private double mean = 0.0;
    private double m2 = 0.0; // сумма квадратов отклонений
    
    public Statistics accept(double value) {
        count++;
        double delta = value - mean;
        mean += delta / count;
        m2 += delta * (value - mean);
        return this;
    }
    
    public Statistics combine(Statistics other) {
        if (count == 0) return other;
        if (other.count == 0) return this;
        
        int totalCount = count + other.count;
        double delta = other.mean - mean;
        
        double newMean = (count * mean + other.count * other.mean) / totalCount;
        double newM2 = m2 + other.m2 + delta * delta * count * other.count / totalCount;
        
        this.count = totalCount;
        this.mean = newMean;
        this.m2 = newM2;
        return this;
    }
    
    public double variance() { return count > 1 ? m2 / (count - 1) : 0.0; }
    public double stdDev() { return Math.sqrt(variance()); }
}

Statistics stats = DoubleStream.of(1.0, 2.0, 3.0, 4.0, 5.0)
    .collect(Statistics::new, Statistics::accept, Statistics::combine);

System.out.printf("Mean: %.2f, Variance: %.2f, StdDev: %.2f%n",
    stats.mean, stats.variance(), stats.stdDev());
```

### Паттерн 2: Поиск оптимального решения
```java
// Найти самый дешевый путь удовлетворительного качества
record Route(String name, double cost, int quality) {}

List<Route> routes = List.of(
    new Route("A", 100.0, 80),
    new Route("B", 150.0, 90),
    new Route("C", 80.0, 70),
    new Route("D", 200.0, 95)
);

Route best = routes.stream()
    .filter(route -> route.quality() >= 75)
    .reduce((r1, r2) -> r1.cost() < r2.cost() ? r1 : r2)
    .orElse(null);
// Route{name='C', cost=80.0, quality=70} - самый дешевый с quality >= 75
```

### Паттерн 3: Комплексная агрегация
```java
// Анализ текста: количество слов, символов, строк
String text = """
    Hello world
    This is a test
    of reduce operation
    """;

TextAnalysis analysis = text.lines()
    .reduce(new TextAnalysis(),
        (acc, line) -> {
            acc.lineCount++;
            acc.charCount += line.length();
            acc.wordCount += line.split("\\s+").length;
            return acc;
        },
        (a1, a2) -> {
            a1.lineCount += a2.lineCount;
            a1.charCount += a2.charCount;
            a1.wordCount += a2.wordCount;
            return a1;
        });

System.out.println(analysis);
// TextAnalysis{lineCount=3, wordCount=10, charCount=43}
```

---

## Ловушки и best practices

### 1. **Используйте правильный identity**
```java
// ПЛОХО: identity должен быть нейтральным
int wrong = Stream.of(1, 2, 3)
    .reduce(1, (a, b) -> a + b); // 1 + 1 + 2 + 3 = 7 (не ожидали!)

// ХОРОШО: 0 - нейтральный элемент для сложения
int correct = Stream.of(1, 2, 3)
    .reduce(0, (a, b) -> a + b); // 0 + 1 + 2 + 3 = 6
```

### 2. **Проверяйте Optional при отсутствии identity**
```java
// Всегда проверяйте isPresent()
Optional<Integer> result = Stream.<Integer>empty()
    .reduce((a, b) -> a + b);

if (result.isPresent()) {
    // есть результат
} else {
    // пустой поток
}

// Или используйте orElse/orElseGet
int value = result.orElse(0); // 0 по умолчанию
```

### 3. **Избегайте побочных эффектов**
```java
// ПЛОХО: reduce с побочными эффектами
List<String> collected = new ArrayList<>();
Stream.of("a", "b", "c")
    .reduce("", (acc, s) -> {
        collected.add(s); // ПОБОЧНЫЙ ЭФФЕКТ!
        return acc + s;
    });

// ЛУЧШЕ: используйте collect() для mutable операций
List<String> proper = Stream.of("a", "b", "c")
    .collect(Collectors.toList());
```

### 4. **Для parallel streams нужен combiner**
```java
// Без combiner parallel stream не сработает
// ПЛОХО:
String bad = words.parallelStream()
    .reduce("", (acc, word) -> acc + word); // Может работать некорректно

// ХОРОШО: с combiner
String good = words.parallelStream()
    .reduce("",
        (acc, word) -> acc + word,
        (s1, s2) -> s1 + s2);
```

---

## Производительность

### Benchmark: reduce vs loop
```java
int size = 10_000_000;

// 1. Традиционный цикл (самый быстрый)
int[] array = IntStream.range(0, size).toArray();
int sum1 = 0;
for (int n : array) {
    sum1 += n;
}

// 2. Stream reduce
int sum2 = Arrays.stream(array)
    .reduce(0, Integer::sum);

// 3. Parallel stream reduce
int sum3 = Arrays.stream(array).parallel()
    .reduce(0, Integer::sum);

// Результаты (примерно):
// Loop: 10ms
// Stream reduce: 50ms  
// Parallel reduce: 15ms (на многоядерном процессоре)
```

---

## Упражнения для закрепления

### Задача 1: Найти самый длинный палиндром
```java
List<String> words = List.of("radar", "hello", "level", "world", "deified", "java");

Optional<String> longestPalindrome = words.stream()
    .filter(word -> word.equals(new StringBuilder(word).reverse().toString()))
    .reduce((w1, w2) -> w1.length() > w2.length() ? w1 : w2);

// Результат: Optional["deified"]
```

### Задача 2: Вычислить взвешенное среднее
```java
record Grade(double score, int weight) {}

List<Grade> grades = List.of(
    new Grade(4.5, 3),
    new Grade(3.8, 2),
    new Grade(5.0, 5),
    new Grade(4.2, 4)
);

// Вычисляем: сумма(score * weight) / сумма(weight)
double weightedAverage = grades.stream()
    .reduce(new double[2], // [0] = сумма произведений, [1] = сумма весов
        (acc, grade) -> {
            acc[0] += grade.score() * grade.weight();
            acc[1] += grade.weight();
            return acc;
        },
        (a1, a2) -> {
            a1[0] += a2[0];
            a1[1] += a2[1];
            return a1;
        });

double result = weightedAverage[0] / weightedAverage[1]; // ~4.47
```

---

## Ключевые выводы

1. **`reduce()` сводит поток к одному значению** (терминальная операция)
2. **Три формы**: с identity, без identity (Optional), с combiner
3. **Используйте для**: суммирования, произведения, конкатенации, поиска min/max
4. **Identity должен быть нейтральным элементом** операции
5. **Для parallel streams** нужны ассоциативные функции и combiner
6. **Частные случаи**: `sum()`, `min()`, `max()` — это специализированные reduce
7. **Для mutable операций** часто лучше подходит `collect()`

**Главное правило:**  
Если нужно **комбинировать** элементы потока по какому-то правилу — `reduce()` ваш выбор!