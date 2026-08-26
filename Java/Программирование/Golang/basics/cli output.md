Отличный вопрос! В Go есть несколько способов вывода, и они отличаются от Java. Давай разберём все варианты.

##  Основные функции вывода в Go

### 1. **Пакет `fmt`** — основной инструмент

| Функция   | Назначение            | Добавляет перевод строки? | Поддерживает форматирование? |
| --------- | --------------------- | ------------------------- | ---------------------------- |
| `Print`   | Простой вывод         | Нет                       | Нет                          |
| `Println` | Вывод с новой строкой | Да                        | Нет                          |
| `Printf`  | Форматированный вывод | Нет (нужно `\n`)          |  Да (как в C)                |
| `Fprint*` | Вывод в `io.Writer`   | Зависит от функции        | Зависит от функции           |
| `Sprint*` | Вывод в строку        | Зависит от функции        | Зависит от функции           |

---

##  Детальный разбор

### `Print` — просто вывод
```go
fmt.Print("Hello")
fmt.Print("World")
// Вывод: HelloWorld (без пробела!)
```

### `Println` — вывод с новой строкой
```go
fmt.Println("Hello")
fmt.Println("World")
// Вывод:
// Hello
// World

// Автоматически добавляет пробелы между аргументами
fmt.Println("Hello", "World", 123)
// Вывод: Hello World 123
```

### `Printf` — форматированный вывод (как в C)
```go
name := "Alice"
age := 30
price := 99.99

fmt.Printf("Name: %s, Age: %d, Price: %.2f\n", name, age, price)
// Вывод: Name: Alice, Age: 30, Price: 99.99
```

---

##  Форматные спецификаторы (как в Java `String.format`)

| Спецификатор | Описание | Пример |
|--------------|----------|--------|
| `%v` | **Значение по умолчанию** (универсальный) | `fmt.Printf("%v", user)` → `{Alice 30}` |
| `%+v` | Со структурой с именами полей | `fmt.Printf("%+v", user)` → `{Name:Alice Age:30}` |
| `%#v` | Go-синтаксис значения | `fmt.Printf("%#v", user)` → `main.User{Name:"Alice", Age:30}` |
| `%T` | Тип значения | `fmt.Printf("%T", user)` → `main.User` |
| `%d` | Целое число (десятичное) | `fmt.Printf("%d", 42)` → `42` |
| `%x` | Шестнадцатеричное | `fmt.Printf("%x", 255)` → `ff` |
| `%s` | Строка | `fmt.Printf("%s", "hello")` → `hello` |
| `%q` | Строка в кавычках | `fmt.Printf("%q", "hello")` → `"hello"` |
| `%f` | Число с плавающей точкой | `fmt.Printf("%f", 3.14)` → `3.140000` |
| `%.2f` | С точностью до 2 знаков | `fmt.Printf("%.2f", 3.14159)` → `3.14` |
| `%t` | Булево значение | `fmt.Printf("%t", true)` → `true` |
| `%p` | Указатель (адрес) | `fmt.Printf("%p", &x)` → `0xc000012088` |
| `%%` | Символ процента | `fmt.Printf("100%%")` → `100%` |

---

##  Примеры со структурами

```go
type User struct {
    Name string
    Age  int
    Email string
}

func main() {
    u := User{Name: "Alice", Age: 30, Email: "alice@example.com"}
    
    // %v - просто значения
    fmt.Printf("%v\n", u)   
    // {Alice 30 alice@example.com}
    
    // %+v - с именами полей
    fmt.Printf("%+v\n", u)  
    // {Name:Alice Age:30 Email:alice@example.com}
    
    // %#v - Go-синтаксис
    fmt.Printf("%#v\n", u)  
    // main.User{Name:"Alice", Age:30, Email:"alice@example.com"}
}
```

---

##  Продвинутое использование

### 1. **Вывод в файл или любой `io.Writer`**

```go
// В файл
file, _ := os.Create("output.txt")
fmt.Fprintf(file, "Hello, %s!\n", "World")
file.Close()

// В stderr
fmt.Fprintf(os.Stderr, "Error: %v\n", err)

// В буфер
var buf bytes.Buffer
fmt.Fprintf(&buf, "Hello, %s", "World")
```

### 2. **Форматирование без вывода (в строку)**

```go
// Как String.format() в Java
message := fmt.Sprintf("User: %s, Age: %d", "Alice", 30)
fmt.Println(message) // User: Alice, Age: 30
```

### 3. **Вывод с отступами и выравниванием**

```go
// Выравнивание по ширине
fmt.Printf("|%10s|%10d|\n", "Alice", 30)   // |    Alice|        30|
fmt.Printf("|%-10s|%-10d|\n", "Bob", 25)   // |Bob      |25        |

// Спецификация ширины
fmt.Printf("Price: %8.2f\n", 123.456)      // Price:   123.46
fmt.Printf("Price: %08.2f\n", 123.456)     // Price: 00123.46
```

---

##  Важные нюансы

### 1. **Типы в `Printf` не проверяются компилятором!**
```go
//  Будет работать, но выведет неправильно
fmt.Printf("%d", "hello") // %!d(string=hello)

//  Проверяй соответствие типов
fmt.Printf("%s", "hello") // hello
```

### 2. **`%v` — твой лучший друг для отладки**
```go
// Универсальный вывод для любого типа
fmt.Printf("%v\n", 42)          // 42
fmt.Printf("%v\n", "hello")     // hello
fmt.Printf("%v\n", []int{1,2})  // [1 2]
fmt.Printf("%v\n", struct{}{})  // {}
```

### 3. **Вывод ошибок**
```go
// Стандартный паттерн
if err != nil {
    fmt.Printf("Error: %v\n", err)
    // Или
    fmt.Fprintf(os.Stderr, "Error: %v\n", err)
}
```

---

##  Практические примеры

### Логгирование
```go
// Информационное сообщение
fmt.Printf("[INFO] %s started\n", time.Now().Format("2006-01-02 15:04:05"))

// Отладочное сообщение
debug := true
if debug {
    fmt.Printf("[DEBUG] User: %+v\n", user)
}
```

### Табличный вывод
```go
fmt.Printf("%-15s %-10s %-10s\n", "Name", "Age", "City")
fmt.Printf("%-15s %-10d %-10s\n", "Alice", 30, "NYC")
fmt.Printf("%-15s %-10d %-10s\n", "Bob", 25, "LA")
// Вывод:
// Name            Age        City      
// Alice           30         NYC       
// Bob             25         LA
```

### JSON-подобный вывод
```go
data := map[string]interface{}{
    "name": "Alice",
    "age":  30,
}
fmt.Printf("%#v\n", data)
// map[string]interface {}{"age":30, "name":"Alice"}
```

---

##  Шпаргалка

```go
// Базовый вывод
fmt.Print("text")          // text
fmt.Println("text")        // text\n
fmt.Printf("%s\n", "text") // text\n

// В строку
str := fmt.Sprintf("%s %d", "hello", 42)

// В файл/ошибку
fmt.Fprint(os.Stderr, "error")
fmt.Fprintf(os.Stdout, "%s\n", "log")

// Полезные форматы
fmt.Printf("%v\n", x)   // любой тип
fmt.Printf("%+v\n", x)  // структура с именами
fmt.Printf("%#v\n", x)  // Go-синтаксис
fmt.Printf("%T\n", x)   // тип переменной
```

