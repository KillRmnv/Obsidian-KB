# TCP (Transmission Control Protocol)

TCP -- это надежный транспортный протокол с установлением соединения. Гарантирует доставку, порядок и контроль целостности данных.

Связанные темы: [[UDP]], [[HTTP сервер]], [[WebSocket]]

---

## TCP Сервер

```go
package main

import (
    "bufio"
    "fmt"
    "net"
    "strings"
)

func main() {
    listener, err := net.Listen("tcp", ":8080")
    if err != nil {
        panic(err)
    }
    defer listener.Close()

    fmt.Println("TCP сервер запущен на порту 8080")

    for {
        conn, err := listener.Accept()
        if err != nil {
            fmt.Println("Ошибка Accept:", err)
            continue
        }

        go handleTCPConnection(conn)
    }
}

func handleTCPConnection(conn net.Conn) {
    defer conn.Close()

    reader := bufio.NewReader(conn)

    for {
        message, err := reader.ReadString('\n')
        if err != nil {
            fmt.Println("Ошибка чтения:", err)
            return
        }

        message = strings.TrimSpace(message)
        fmt.Printf("Получено: %s\n", message)

        response := fmt.Sprintf("Эхо: %s\n", message)
        conn.Write([]byte(response))

        if message == "exit" {
            fmt.Println("Клиент отключился")
            return
        }
    }
}
```

---

## TCP Клиент

```go
package main

import (
    "bufio"
    "fmt"
    "net"
    "os"
    "strings"
)

func main() {
    conn, err := net.Dial("tcp", "localhost:8080")
    if err != nil {
        panic(err)
    }
    defer conn.Close()

    fmt.Println("Подключено к серверу")

    go func() {
        reader := bufio.NewReader(conn)
        for {
            response, err := reader.ReadString('\n')
            if err != nil {
                fmt.Println("Сервер закрыл соединение")
                return
            }
            fmt.Print("Сервер: " + response)
        }
    }()

    scanner := bufio.NewScanner(os.Stdin)
    for scanner.Scan() {
        text := scanner.Text()
        conn.Write([]byte(text + "\n"))

        if text == "exit" {
            break
        }
    }
}
```
