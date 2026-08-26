# Работа с файлами и потоками в Go (пакет io)

## Основные интерфейсы

### Reader и Writer - основа всего

```go
type Reader interface {
    Read(p []byte) (n int, err error)
}

type Writer interface {
    Write(p []byte) (n int, err error)
}

// Комбинированные интерфейсы
type ReadWriter interface {
    Reader
    Writer
}

type ReadCloser interface {
    Reader
    Closer
}

type WriteCloser interface {
    Writer
    Closer
}

type ReadWriteCloser interface {
    Reader
    Writer
    Closer
}
```

### Closer - для закрытия ресурсов

```go
type Closer interface {
    Close() error
}
```

---

## Чтение файлов

### 1. Чтение всего файла целиком (io.ReadAll / os.ReadFile)

```go
package main

import (
    "fmt"
    "os"
)

func main() {
    // Самый простой способ (Go 1.16+)
    data, err := os.ReadFile("file.txt")
    if err != nil {
        panic(err)
    }
    fmt.Println(string(data))
}
```

### 2. Построчное чтение (bufio.Scanner)

```go
package main

import (
    "bufio"
    "fmt"
    "os"
)

func main() {
    file, err := os.Open("file.txt")
    if err != nil {
        panic(err)
    }
    defer file.Close()  // обязательно закрыть!

    scanner := bufio.NewScanner(file)
    
    // Читаем построчно
    for scanner.Scan() {
        fmt.Println(scanner.Text())
    }
    
    if err := scanner.Err(); err != nil {
        panic(err)
    }
}
```

### 3. Чтение по кускам (bufio.Reader)

```go
package main

import (
    "bufio"
    "fmt"
    "io"
    "os"
)

func main() {
    file, err := os.Open("file.txt")
    if err != nil {
        panic(err)
    }
    defer file.Close()

    reader := bufio.NewReader(file)
    buf := make([]byte, 1024)  // буфер 1KB

    for {
        n, err := reader.Read(buf)
        if err == io.EOF {
            break
        }
        if err != nil {
            panic(err)
        }
        fmt.Print(string(buf[:n]))
    }
}
```

### 4. Чтение через io.Reader (общий интерфейс)

```go
package main

import (
    "fmt"
    "io"
    "os"
)

func main() {
    file, err := os.Open("file.txt")
    if err != nil {
        panic(err)
    }
    defer file.Close()

    // Можно использовать любой Reader
    data, err := io.ReadAll(file)
    if err != nil {
        panic(err)
    }
    fmt.Println(string(data))
}
```

---

## Запись в файлы

### 1. Запись всей строки (os.WriteFile)

```go
package main

import "os"

func main() {
    data := []byte("Hello, World!\n")
    
    // Простая запись (Go 1.16+)
    err := os.WriteFile("output.txt", data, 0644)
    if err != nil {
        panic(err)
    }
}
```

### 2. Запись через bufio.Writer

```go
package main

import (
    "bufio"
    "os"
)

func main() {
    file, err := os.Create("output.txt")
    if err != nil {
        panic(err)
    }
    defer file.Close()

    writer := bufio.NewWriter(file)
    
    // Пишем в буфер
    writer.WriteString("Hello, ")
    writer.WriteString("World!\n")
    writer.Write([]byte("Second line\n"))
    
    // Обязательно сбрасываем буфер на диск!
    writer.Flush()
}
```

### 3. Запись через fmt.Fprintf

```go
package main

import (
    "fmt"
    "os"
)

func main() {
    file, err := os.Create("output.txt")
    if err != nil {
        panic(err)
    }
    defer file.Close()

    name := "Alice"
    age := 30
    
    fmt.Fprintf(file, "Name: %s, Age: %d\n", name, age)
}
```

---

## Копирование данных (io.Copy)

```go
package main

import (
    "io"
    "os"
)

func main() {
    // Копирование файла в файл
    src, err := os.Open("source.txt")
    if err != nil {
        panic(err)
    }
    defer src.Close()

    dst, err := os.Create("destination.txt")
    if err != nil {
        panic(err)
    }
    defer dst.Close()

    // Копируем данные
    _, err = io.Copy(dst, src)
    if err != nil {
        panic(err)
    }

    // Копирование с ограничением
    // io.CopyN(dst, src, 1024)  // только 1KB

    // Копирование из Reader в Stdout
    // io.Copy(os.Stdout, src)
}
```

---

## Составные Reader/Writer

### 1. TeeReader (читает и копирует)

```go
package main

import (
    "fmt"
    "io"
    "os"
    "strings"
)

func main() {
    r := strings.NewReader("Hello, World!")
    
    // TeeReader дублирует поток: читает в r, пишет в os.Stdout
    tee := io.TeeReader(r, os.Stdout)
    
    data, _ := io.ReadAll(tee)
    fmt.Println("\nData:", string(data))
}
```

### 2. MultiReader (объединение нескольких Reader)

```go
package main

import (
    "fmt"
    "io"
    "strings"
)

func main() {
    r1 := strings.NewReader("Part 1 ")
    r2 := strings.NewReader("Part 2 ")
    r3 := strings.NewReader("Part 3")
    
    // Читает последовательно: сначала r1, потом r2, потом r3
    multi := io.MultiReader(r1, r2, r3)
    
    data, _ := io.ReadAll(multi)
    fmt.Println(string(data))  // "Part 1 Part 2 Part 3"
}
```

### 3. LimitReader (ограничение чтения)

```go
package main

import (
    "fmt"
    "io"
    "strings"
)

func main() {
    r := strings.NewReader("1234567890")
    
    // Читает только 5 байт
    limited := io.LimitReader(r, 5)
    
    data, _ := io.ReadAll(limited)
    fmt.Println(string(data))  // "12345"
}
```

---

## Работа с буферами (bytes, strings)

### bytes.Buffer

```go
package main

import (
    "bytes"
    "fmt"
)

func main() {
    var buf bytes.Buffer
    
    // Запись
    buf.WriteString("Hello, ")
    buf.WriteByte('W')
    buf.Write([]byte("orld!"))
    
    // Чтение
    fmt.Println(buf.String())  // "Hello, World!"
    
    // Использование как io.Reader
    data, _ := io.ReadAll(&buf)
    fmt.Println(string(data))
}
```

### strings.Reader

```go
package main

import (
    "fmt"
    "io"
    "strings"
)

func main() {
    // Reader из строки
    r := strings.NewReader("Hello, World!")
    
    // Читаем по байтам
    buf := make([]byte, 5)
    for {
        n, err := r.Read(buf)
        if err == io.EOF {
            break
        }
        fmt.Print(string(buf[:n]))
    }
    // Output: Hello, World!
}
```

---

## Работа с файловыми дескрипторами

### os.File - основные методы

```go
package main

import (
    "fmt"
    "io"
    "os"
)

func main() {
    // Открытие с разными режимами
    file, err := os.Open("file.txt")                 // только чтение
    // file, err := os.Create("file.txt")            // создание (перезапись)
    // file, err := os.OpenFile("file.txt", os.O_RDWR|os.O_CREATE, 0644)  // чтение/запись
    
    if err != nil {
        panic(err)
    }
    defer file.Close()

    // Информация о файле
    info, err := file.Stat()
    if err != nil {
        panic(err)
    }
    fmt.Println("Name:", info.Name())
    fmt.Println("Size:", info.Size())
    fmt.Println("IsDir:", info.IsDir())
    fmt.Println("Mode:", info.Mode())
    fmt.Println("ModTime:", info.ModTime())

    // Позиция в файле (для Seek)
    offset, err := file.Seek(10, io.SeekStart)  // сместиться на 10 байт от начала
    fmt.Println("Offset:", offset)

    // Создание файла
    newFile, err := os.Create("new.txt")
    if err != nil {
        panic(err)
    }
    defer newFile.Close()
    
    newFile.WriteString("Hello, World!")
}
```

### Константы для os.OpenFile

```go
// Режимы открытия
const (
    O_RDONLY int = syscall.O_RDONLY  // только чтение
    O_WRONLY int = syscall.O_WRONLY  // только запись
    O_RDWR   int = syscall.O_RDWR    // чтение и запись
    O_APPEND int = syscall.O_APPEND  // дописывать в конец
    O_CREATE int = syscall.O_CREAT   // создавать, если не существует
    O_EXCL   int = syscall.O_EXCL    // использовать с O_CREATE, ошибка если файл существует
    O_SYNC   int = syscall.O_SYNC    // синхронная запись
    O_TRUNC  int = syscall.O_TRUNC   // обрезать файл при открытии
)
```

---

## Вспомогательные функции

### ioutil (deprecated, но часто встречается)

```go
package main

import (
    "io/ioutil"
    "log"
)

func main() {
    // Устаревшие функции (ещё работают, но использовать не рекомендуется)
    
    // Чтение всего файла
    data, err := ioutil.ReadFile("file.txt")
    if err != nil {
        log.Fatal(err)
    }
    
    // Запись всего файла
    err = ioutil.WriteFile("output.txt", data, 0644)
    if err != nil {
        log.Fatal(err)
    }
    
    // Чтение директории
    files, err := ioutil.ReadDir(".")
    if err != nil {
        log.Fatal(err)
    }
    for _, file := range files {
        log.Println(file.Name())
    }
}
```

### Замена ioutil (Go 1.16+)

```go
package main

import (
    "io"
    "os"
)

func main() {
    // Вместо ioutil.ReadFile
    data, err := os.ReadFile("file.txt")  // ✅
    
    // Вместо ioutil.WriteFile
    err = os.WriteFile("output.txt", data, 0644)  // ✅
    
    // Вместо ioutil.ReadDir
    files, err := os.ReadDir(".")  // ✅ (возвращает []DirEntry)
    
    // Вместо ioutil.ReadAll
    file, _ := os.Open("file.txt")
    defer file.Close()
    data, err = io.ReadAll(file)  // ✅
}
```

---

## Работа с директориями

```go
package main

import (
    "fmt"
    "os"
    "path/filepath"
)

func main() {
    // Создание директории
    err := os.Mkdir("mydir", 0755)
    if err != nil {
        panic(err)
    }
    
    // Создание вложенных директорий
    err = os.MkdirAll("path/to/nested/dir", 0755)
    if err != nil {
        panic(err)
    }

    // Удаление директории (пустой)
    err = os.Remove("mydir")
    if err != nil {
        panic(err)
    }
    
    // Удаление директории со всем содержимым
    err = os.RemoveAll("path")
    if err != nil {
        panic(err)
    }

    // Обход файловой системы
    err = filepath.Walk(".", func(path string, info os.FileInfo, err error) error {
        if err != nil {
            return err
        }
        if info.IsDir() {
            fmt.Printf("Directory: %s\n", path)
        } else {
            fmt.Printf("File: %s (%d bytes)\n", path, info.Size())
        }
        return nil
    })
    if err != nil {
        panic(err)
    }
}
```

---

## Временные файлы

```go
package main

import (
    "fmt"
    "os"
)

func main() {
    // Создание временного файла
    tmpFile, err := os.CreateTemp("", "example-*.txt")
    if err != nil {
        panic(err)
    }
    defer os.Remove(tmpFile.Name())  // удалить после использования
    defer tmpFile.Close()
    
    fmt.Println("Temporary file:", tmpFile.Name())
    
    // Запись
    tmpFile.WriteString("Hello, temp!")
}
```

---

## Проверка существования файла

```go
package main

import (
    "errors"
    "fmt"
    "os"
)

func fileExists(filename string) bool {
    info, err := os.Stat(filename)
    if os.IsNotExist(err) {
        return false
    }
    return !info.IsDir()  // существует и не директория
}

func main() {
    if fileExists("file.txt") {
        fmt.Println("File exists")
    } else {
        fmt.Println("File does not exist")
    }
}
```

---

## Практический пример: безопасная запись файла

```go
package main

import (
    "fmt"
    "io/ioutil"
    "os"
    "path/filepath"
)

func WriteFileSafe(filename string, data []byte) error {
    // 1. Создаём временный файл в той же директории
    dir := filepath.Dir(filename)
    tmp, err := os.CreateTemp(dir, ".tmp-*")
    if err != nil {
        return fmt.Errorf("create temp file: %w", err)
    }
    tmpName := tmp.Name()
    defer os.Remove(tmpName)  // в случае ошибки - удаляем
    
    // 2. Пишем данные
    if _, err := tmp.Write(data); err != nil {
        tmp.Close()
        return fmt.Errorf("write temp file: %w", err)
    }
    
    // 3. Закрываем перед перемещением
    if err := tmp.Close(); err != nil {
        return fmt.Errorf("close temp file: %w", err)
    }
    
    // 4. Атомарно перемещаем
    if err := os.Rename(tmpName, filename); err != nil {
        return fmt.Errorf("rename temp file: %w", err)
    }
    
    return nil
}

func main() {
    err := WriteFileSafe("output.txt", []byte("Hello, World!"))
    if err != nil {
        panic(err)
    }
}
```

---

## Таблица: Reader/Writer комбинации

| Интерфейс | Методы | Используется |
|-----------|--------|--------------|
| `io.Reader` | `Read(p []byte) (n int, err error)` | Чтение |
| `io.Writer` | `Write(p []byte) (n int, err error)` | Запись |
| `io.Closer` | `Close() error` | Закрытие |
| `io.Seeker` | `Seek(offset int64, whence int) (int64, error)` | Позиционирование |
| `io.ReaderAt` | `ReadAt(p []byte, off int64) (n int, err error)` | Чтение с позиции |
| `io.WriterAt` | `WriteAt(p []byte, off int64) (n int, err error)` | Запись в позицию |
| `io.ByteReader` | `ReadByte() (byte, error)` | Побайтовое чтение |
| `io.ByteWriter` | `WriteByte(c byte) error` | Побайтовая запись |
| `io.RuneReader` | `ReadRune() (r rune, size int, err error)` | Чтение рун (UTF-8) |
| `io.StringWriter` | `WriteString(s string) (n int, err error)` | Запись строки |

---

## Полезные функции из пакета io

```go
// Копирование
func Copy(dst Writer, src Reader) (written int64, err error)
func CopyBuffer(dst Writer, src Reader, buf []byte) (written int64, err error)
func CopyN(dst Writer, src Reader, n int64) (written int64, err error)

// Чтение
func ReadAll(r Reader) ([]byte, error)
func ReadAtLeast(r Reader, buf []byte, min int) (n int, err error)
func ReadFull(r Reader, buf []byte) (n int, err error)

// Составные ридеры
func LimitReader(r Reader, n int64) Reader
func MultiReader(readers ...Reader) Reader
func TeeReader(r Reader, w Writer) Reader

// Запись
func WriteString(w Writer, s string) (n int, err error)

// Остальное
func NopCloser(r Reader) ReadCloser
func Discard // Writer, который ничего не пишет (io.Discard)
```