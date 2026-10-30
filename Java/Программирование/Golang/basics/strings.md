
## 1. Что такое строка в Go?

Строка в Go — это **неизменяемая** последовательность байтов.

```go
s := "Hello, 世界"
```

**Важно:** Строка — это не массив символов (как в других языках), а **срез байтов** (read-only slice of bytes).

---

## 2. Внутреннее устройство строки

Строка в Go — это структура из двух полей:
```go
type stringStruct struct {
    str unsafe.Pointer  // указатель на массив байтов
    len int             // длина в байтах
}
```

**Пример:**
```go
s := "Hello"
fmt.Println(len(s)) // 5 (байт)
fmt.Println(s[0])   // 72 (байт 'H')
fmt.Println(s[1])   // 101 (байт 'e')
```

---

## 3. Строки — неизменяемые (immutable)

**Нельзя изменить символ в строке:**
```go
s := "Hello"
s[0] = 'h'  //  Ошибка компиляции: cannot assign to s[0]
```

**Чтобы изменить строку, создаем новую:**
```go
s := "Hello"
bytes := []byte(s)
bytes[0] = 'h'
s = string(bytes)  // "hello"
```

---

## 4. Байты vs Руны (символы)

**Ключевое отличие:** Go использует UTF-8, поэтому символ может занимать несколько байт.

```go
s := "Hello, 世界"
fmt.Println(len(s))        // 13 (байт)
fmt.Println(len([]rune(s))) // 9 (символов)
```

**Руна (rune)** — это int32, представляющий Unicode-код символа.

**Пример с кириллицей:**
```go
s := "Привет"
fmt.Println(len(s))        // 12 (каждый символ по 2 байта)
fmt.Println(len([]rune(s))) // 6 (символов)
```

---

## 5. Итерация по строке

### Вариант 1: По байтам (неправильно для Unicode)
```go
s := "Hello, 世界"
for i := 0; i < len(s); i++ {
    fmt.Printf("%c ", s[i])  //  Будет кракозябра для китайских символов
}
```

### Вариант 2: По рунам (правильно!)
```go
s := "Hello, 世界"
for _, r := range s {  // rang автоматически декодирует UTF-8
    fmt.Printf("%c ", r)  //  H e l l o ,   世 界
}
```

### Вариант 3: Преобразовать в []rune
```go
s := "Hello, 世界"
runes := []rune(s)
for i := 0; i < len(runes); i++ {
    fmt.Printf("%c ", runes[i])  //  Работает
}
```

---

## 6. Конкатенация строк

### Способ 1: Оператор `+` (простой, но неэффективный)
```go
s := "Hello" + " " + "World"  // Создает новую строку
```

### Способ 2: `fmt.Sprintf()` (гибкий)
```go
name := "Alice"
age := 30
s := fmt.Sprintf("Name: %s, Age: %d", name, age)
```

### Способ 3: `strings.Builder` (эффективный для многих конкатенаций)
```go
var builder strings.Builder
builder.WriteString("Hello")
builder.WriteString(" ")
builder.WriteString("World")
result := builder.String()  // "Hello World"
```

### Способ 4: `strings.Join()` (для слайсов)
```go
parts := []string{"Hello", "World", "Go"}
result := strings.Join(parts, " ")  // "Hello World Go"
```

---

## 7. Сравнение строк

### По значению (лексикографическое сравнение)
```go
s1 := "hello"
s2 := "world"
s3 := "hello"

fmt.Println(s1 == s2)  // false
fmt.Println(s1 == s3)  // true
fmt.Println(s1 < s2)   // true (по алфавиту)
```

### Без учета регистра
```go
import "strings"

fmt.Println(strings.EqualFold("Hello", "HELLO"))  // true
```

---

## 8. Основные операции со строками

### Длина строки
```go
s := "Hello"
len(s)  // 5 (байт)

s := "Привет"
len(s)        // 12 (байт)
utf8.RuneCountInString(s)  // 6 (символов)
```

### Доступ к символу (по индексу)
```go
s := "Hello"
s[1]  // 'e' (байт, 101)

s := "Привет"
s[0]  // 208 (первый байт буквы П)
```

**Правильный способ:**
```go
s := "Привет"
runes := []rune(s)
runes[0]  // 'П' (1043)
```

### Срезы строк (substring)
```go
s := "Hello, World"
s[0:5]   // "Hello"
s[7:]    // "World"
s[:5]    // "Hello"
```

**Важно:** Срез строки — это тоже строка, создается новая.

### Проверка на пустоту
```go
s := ""
if s == "" {  //  Правильно
    // ...
}
if len(s) == 0 {  //  Тоже правильно
    // ...
}
```

---

## 9. Полезные функции из пакета `strings`

```go
import "strings"

// Поиск
strings.Contains("Hello World", "World")  // true
strings.ContainsAny("Hello", "aeiou")     // true
strings.HasPrefix("Hello", "He")          // true
strings.HasSuffix("Hello", "lo")          // true
strings.Index("Hello", "l")               // 2
strings.LastIndex("Hello", "l")           // 3

// Преобразование
strings.ToUpper("hello")                  // "HELLO"
strings.ToLower("HELLO")                  // "hello"
strings.Title("hello world")              // "Hello World" (deprecated)
strings.Replace("Hello World", "World", "Go", 1) // "Hello Go"
strings.Repeat("Go", 3)                   // "GoGoGo"

// Разделение
strings.Split("a,b,c", ",")               // ["a", "b", "c"]
strings.SplitN("a,b,c", ",", 2)           // ["a", "b,c"]
strings.Join([]string{"a","b","c"}, ",")  // "a,b,c"

// Обрезка
strings.Trim("  Hello  ", " ")            // "Hello"
strings.TrimSpace("  Hello  ")            // "Hello"
strings.TrimPrefix("HelloWorld", "Hello") // "World"
strings.TrimSuffix("HelloWorld", "World") // "Hello"

// Замена
strings.ReplaceAll("Hello World World", "World", "Go") // "Hello Go Go"
strings.Replace("Hello World World", "World", "Go", 1) // "Hello Go World"
```

---

## 10. Преобразования типов

### Строка → []byte
```go
s := "Hello"
bytes := []byte(s)  // [72 101 108 108 111]
```

### []byte → Строка
```go
bytes := []byte{72, 101, 108, 108, 111}
s := string(bytes)  // "Hello"
```

### Строка → []rune
```go
s := "Привет"
runes := []rune(s)  // [1055 1088 1080 1074 1077 1090]
```

### []rune → Строка
```go
runes := []rune{1055, 1088, 1080, 1074, 1077, 1090}
s := string(runes)  // "Привет"
```

### Строка → int
```go
import "strconv"

i, err := strconv.Atoi("123")      // 123, nil
i, err := strconv.ParseInt("123", 10, 64) // 123, nil
```

### int → Строка
```go
s := strconv.Itoa(123)             // "123"
s := strconv.FormatInt(123, 10)    // "123"
```

### Строка → float64
```go
f, err := strconv.ParseFloat("3.14", 64) // 3.14, nil
```

---

## 11. Эффективность строк

### Проблемы с конкатенацией через `+`
```go
s := ""
for i := 0; i < 10000; i++ {
    s += "a"  // ❌ Создает новую строку на каждой итерации
}
```

**Решение:**
```go
var builder strings.Builder
for i := 0; i < 10000; i++ {
    builder.WriteString("a")
}
s := builder.String()  //  Эффективно
```

---

## 12. Память и производительность

### Структура строки в памяти:
```
String: "Hello"
[pointer] → [H][e][l][l][o]
[length] = 5
```

### Срез строки не копирует данные:
```go
s := "Hello, World"
sub := s[0:5]  // "Hello" - НЕ копирует данные, использует тот же массив
```
**Важно:** Подстрока использует ту же память, что и исходная строка.

---

## 13. Частые ошибки

### Ошибка 1: Индексация по байтам для Unicode
```go
s := "Привет"
char := s[0]  //  208 (часть байта), а не 'П'
```

### Ошибка 2: Игнорирование длины в байтах
```go
s := "Привет"
for i := 0; i < len(s); i++ {  //  Будет идти по байтам
    fmt.Println(s[i])
}
```

### Ошибка 3: Сравнение строк с разной кодировкой
```go
s1 := "café"   // UTF-8
s2 := "cafe\u0301"  // e + акцент
fmt.Println(s1 == s2)  // false, хотя выглядят одинаково
```

**Решение:** Нормализация
```go
import "golang.org/x/text/unicode/norm"

s1 := "café"
s2 := "cafe\u0301"
fmt.Println(norm.NFC.String(s1) == norm.NFC.String(s2))  // true
```

---

## 14. Полезные паттерны

### Многострочные строки
```go
s := `line 1
line 2
line 3`
```

### Экранирование в кавычках
```go
s := "Hello\nWorld"    // \n = newline
s := `Hello\nWorld`    // Без экранирования, literal "\n"
```
z