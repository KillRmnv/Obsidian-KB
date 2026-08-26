
## Создание мапов

```go
// Создание через make
m1 := make(map[string]int)          // пустая мапа, готова к использованию
m2 := make(map[string]int, 100)     // с предвыделением ёмкости

// Создание с литералом
m3 := map[string]int{
    "apple":  5,
    "banana": 3,
    "cherry": 7,
}

// nil-мапа (нельзя добавлять элементы!)
var m4 map[string]int               // nil, panic при добавлении
```

## Базовые операции

### Добавление и обновление элементов

```go
m := make(map[string]int)

// Добавление
m["apple"] = 5
m["banana"] = 3

// Обновление
m["apple"] = 10                    // теперь apple = 10

// Добавление нескольких
m["cherry"] = 7
m["date"] = 4
```

### Получение элементов

```go
m := map[string]int{"apple": 5, "banana": 3}

// Получение значения
val := m["apple"]                  // 5

// Получение с проверкой существования
val, ok := m["apple"]              // val = 5, ok = true
val, ok := m["grape"]              // val = 0, ok = false

// Проверка существования
if val, ok := m["banana"]; ok {
    fmt.Println("banana =", val)
} else {
    fmt.Println("banana not found")
}
```

### Удаление элементов

```go
m := map[string]int{"apple": 5, "banana": 3, "cherry": 7}

// Удаление элемента
delete(m, "banana")                // удаляет banana
delete(m, "grape")                 // ничего не делает, не паникует

// Удаление с проверкой
if _, ok := m["cherry"]; ok {
    delete(m, "cherry")
}
```

### Очистка мапы

```go
m := map[string]int{"apple": 5, "banana": 3}

// Способ 1: создать новую (для GC)
m = make(map[string]int)

// Способ 2: удалить все ключи (Go 1.21+)
clear(m)                           // очищает мапу
```

## Итерация

### Обход всех элементов

```go
m := map[string]int{"apple": 5, "banana": 3, "cherry": 7}

// Обход ключей и значений
for key, value := range m {
    fmt.Printf("%s: %d\n", key, value)
}

// Обход только ключей
for key := range m {
    fmt.Println(key)
}

// Обход только значений
for _, value := range m {
    fmt.Println(value)
}
```

### Итерация в определённом порядке

```go
m := map[string]int{"apple": 5, "banana": 3, "cherry": 7}

// Сортировка ключей
keys := make([]string, 0, len(m))
for k := range m {
    keys = append(keys, k)
}
sort.Strings(keys)

for _, k := range keys {
    fmt.Printf("%s: %d\n", k, m[k])
}
```

## Поиск и проверка

### Поиск значения

```go
m := map[string]int{"apple": 5, "banana": 3, "cherry": 7}

// Поиск по значению (линейный поиск)
func findKey(m map[string]int, val int) (string, bool) {
    for k, v := range m {
        if v == val {
            return k, true
        }
    }
    return "", false
}

key, found := findKey(m, 3)        // "banana", true
```

### Проверка условий

```go
m := map[string]int{"apple": 5, "banana": 3, "cherry": 7}

// Все ли значения > 0
allPositive := true
for _, v := range m {
    if v <= 0 {
        allPositive = false
        break
    }
}

// Есть ли значение > 10
hasLarge := false
for _, v := range m {
    if v > 10 {
        hasLarge = true
        break
    }
}
```

## Преобразования

### Map (трансформация значений)

```go
m := map[string]int{"apple": 5, "banana": 3, "cherry": 7}

// Удвоить все значения
for k, v := range m {
    m[k] = v * 2
}
// {"apple": 10, "banana": 6, "cherry": 14}

// Создание новой мапы с преобразованием
func mapValues(m map[string]int, f func(int) int) map[string]int {
    result := make(map[string]int, len(m))
    for k, v := range m {
        result[k] = f(v)
    }
    return result
}

squared := mapValues(m, func(x int) int { return x * x })
```

### Filter (фильтрация)

```go
m := map[string]int{"apple": 5, "banana": 3, "cherry": 7, "date": 2}

// Оставить только значения > 4
func filter(m map[string]int, f func(int) bool) map[string]int {
    result := make(map[string]int)
    for k, v := range m {
        if f(v) {
            result[k] = v
        }
    }
    return result
}

filtered := filter(m, func(x int) bool { return x > 4 })
// {"apple": 5, "cherry": 7}
```

### Слияние мапов

```go
m1 := map[string]int{"apple": 5, "banana": 3}
m2 := map[string]int{"banana": 10, "cherry": 7}

// Слияние с перезаписью
func merge(m1, m2 map[string]int) map[string]int {
    result := make(map[string]int, len(m1)+len(m2))
    for k, v := range m1 {
        result[k] = v
    }
    for k, v := range m2 {
        result[k] = v
    }
    return result
}

merged := merge(m1, m2)
// {"apple": 5, "banana": 10, "cherry": 7}

// Слияние с суммированием значений
func mergeSum(m1, m2 map[string]int) map[string]int {
    result := make(map[string]int, len(m1)+len(m2))
    for k, v := range m1 {
        result[k] = v
    }
    for k, v := range m2 {
        result[k] += v
    }
    return result
}
```

## Копирование мапов

```go
m := map[string]int{"apple": 5, "banana": 3, "cherry": 7}

// Копирование через цикл
func copyMap(m map[string]int) map[string]int {
    result := make(map[string]int, len(m))
    for k, v := range m {
        result[k] = v
    }
    return result
}

copied := copyMap(m)

// Копирование с помощью литерала (Go 1.21+)
copied2 := maps.Copy(m)           // доступно в пакете maps
```

## Вложенные мапы

```go
// Создание вложенной мапы
nested := make(map[string]map[string]int)
nested["fruits"] = map[string]int{"apple": 5, "banana": 3}
nested["vegetables"] = map[string]int{"carrot": 4, "potato": 6}

// Инициализация вложенных мап
func getNested(m map[string]map[string]int, key string) map[string]int {
    if m[key] == nil {
        m[key] = make(map[string]int)
    }
    return m[key]
}

// Добавление во вложенную мапу
if nested["berries"] == nil {
    nested["berries"] = make(map[string]int)
}
nested["berries"]["strawberry"] = 8
```

## Мапы с структурами

```go
type User struct {
    Name  string
    Email string
    Age   int
}

// Мапа с структурами
users := map[int]User{
    1: {Name: "Alice", Email: "alice@example.com", Age: 30},
    2: {Name: "Bob", Email: "bob@example.com", Age: 25},
}

// Обновление структуры
user := users[1]
user.Age = 31
users[1] = user                    // нужно присвоить обратно

// Или через указатели
usersPtr := map[int]*User{
    1: {Name: "Alice", Email: "alice@example.com", Age: 30},
}
usersPtr[1].Age = 31               // работает напрямую
```

## Полезные функции

### Получение всех ключей

```go
m := map[string]int{"apple": 5, "banana": 3, "cherry": 7}

func keys(m map[string]int) []string {
    result := make([]string, 0, len(m))
    for k := range m {
        result = append(result, k)
    }
    return result
}

keysList := keys(m)                // ["apple", "banana", "cherry"]
```

### Получение всех значений

```go
func values(m map[string]int) []int {
    result := make([]int, 0, len(m))
    for _, v := range m {
        result = append(result, v)
    }
    return result
}

valuesList := values(m)            // [5, 3, 7]
```

### Инвертирование мапы

```go
m := map[string]int{"apple": 5, "banana": 3, "cherry": 7}

// Инвертирование (ключ -> значение, значение -> ключ)
func invert(m map[string]int) map[int]string {
    result := make(map[int]string, len(m))
    for k, v := range m {
        result[v] = k               // значения должны быть уникальными!
    }
    return result
}

inverted := invert(m)              // {5: "apple", 3: "banana", 7: "cherry"}

// Инвертирование с множественными значениями
func invertMulti(m map[string]int) map[int][]string {
    result := make(map[int][]string)
    for k, v := range m {
        result[v] = append(result[v], k)
    }
    return result
}
```

### Преобразование слайса в мапу

```go
// Из слайса в мапу (ключи - элементы)
func sliceToMap(s []string) map[string]bool {
    result := make(map[string]bool, len(s))
    for _, v := range s {
        result[v] = true
    }
    return result
}

// Из слайса в мапу (ключи - индексы)
func sliceToMapIndex(s []string) map[int]string {
    result := make(map[int]string, len(s))
    for i, v := range s {
        result[i] = v
    }
    return result
}

// Из слайса структур в мапу
type Item struct {
    ID   int
    Name string
}
items := []Item{{1, "apple"}, {2, "banana"}, {3, "cherry"}}
itemsMap := make(map[int]string)
for _, item := range items {
    itemsMap[item.ID] = item.Name
}
```

## Безопасность и конкурентность

```go
// Мапа не потокобезопасна!
// Для конкурентного доступа используйте sync.RWMutex или sync.Map

// sync.RWMutex
type SafeMap struct {
    mu   sync.RWMutex
    data map[string]int
}

func NewSafeMap() *SafeMap {
    return &SafeMap{
        data: make(map[string]int),
    }
}

func (s *SafeMap) Set(key string, value int) {
    s.mu.Lock()
    defer s.mu.Unlock()
    s.data[key] = value
}

func (s *SafeMap) Get(key string) (int, bool) {
    s.mu.RLock()
    defer s.mu.RUnlock()
    val, ok := s.data[key]
    return val, ok
}

// sync.Map (для специфических случаев)
var syncMap sync.Map
syncMap.Store("key", 42)
val, ok := syncMap.Load("key")
syncMap.Delete("key")
syncMap.Range(func(key, value interface{}) bool {
    // обход всех элементов
    return true
})
```

## Советы по производительности

```go
// 1. Предвыделяйте ёмкость
m := make(map[string]int, 1000)    // если знаете примерное количество

// 2. Используйте правильные типы ключей
// Ключи должны быть сравнимыми (==)
// int, string, float, struct (сравнимые поля)

// 3. Избегайте nil-мап для записи
var m map[string]int
// m["key"] = 1                    // panic!

// 4. Используйте ok-паттерн для проверки
if val, ok := m["key"]; ok {
    // работаем с val
}

// 5. Избегайте хранения больших структур напрямую
// Лучше хранить указатели
m := make(map[string]*LargeStruct)
```

## Сложность операций

| Операция | Сложность | Примечание |
|----------|-----------|------------|
| Добавление | O(1) | Амортизированно |
| Получение | O(1) | Среднее |
| Удаление | O(1) | Среднее |
| Итерация | O(n) | Обход всех элементов |
| Проверка существования | O(1) | Среднее |

## Полезные паттерны

### Кэш с ограничением размера

```go
type Cache struct {
    maxSize int
    data    map[string]interface{}
    order   []string
    mu      sync.RWMutex
}

func NewCache(maxSize int) *Cache {
    return &Cache{
        maxSize: maxSize,
        data:    make(map[string]interface{}),
        order:   make([]string, 0),
    }
}

func (c *Cache) Set(key string, value interface{}) {
    c.mu.Lock()
    defer c.mu.Unlock()
    
    if _, exists := c.data[key]; !exists {
        if len(c.order) >= c.maxSize {
            oldest := c.order[0]
            delete(c.data, oldest)
            c.order = c.order[1:]
        }
        c.order = append(c.order, key)
    }
    c.data[key] = value
}
```

### Счетчики

```go
// Подсчёт вхождений
func countOccurrences(words []string) map[string]int {
    counts := make(map[string]int)
    for _, word := range words {
        counts[word]++
    }
    return counts
}

// Подсчёт с несколькими полями
type Stats struct {
    Count int
    Sum   int
}
func aggregate(nums []int) map[int]Stats {
    stats := make(map[int]Stats)
    for _, n := range nums {
        s := stats[n]
        s.Count++
        s.Sum += n
        stats[n] = s
    }
    return stats
}
```

### Группировка

```go
type Person struct {
    Name string
    City string
    Age  int
}

// Группировка по городу
func groupByCity(people []Person) map[string][]Person {
    groups := make(map[string][]Person)
    for _, p := range people {
        groups[p.City] = append(groups[p.City], p)
    }
    return groups
}

// Группировка с агрегацией
func averageAgeByCity(people []Person) map[string]float64 {
    cityData := make(map[string][2]int) // [sum, count]
    for _, p := range people {
        data := cityData[p.City]
        data[0] += p.Age
        data[1]++
        cityData[p.City] = data
    }
    
    result := make(map[string]float64)
    for city, data := range cityData {
        result[city] = float64(data[0]) / float64(data[1])
    }
    return result
}
```