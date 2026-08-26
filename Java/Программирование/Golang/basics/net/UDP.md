# UDP (User Datagram Protocol)

UDP -- это легковесный протокол без установления соединения. Не гарантирует доставку и порядок, но работает быстрее TCP.

Связанные темы: [[TCP]], [[HTTP сервер]]

---

## UDP Сервер

```go
package main

import (
    "fmt"
    "net"
)

func main() {
    addr, err := net.ResolveUDPAddr("udp", ":8081")
    if err != nil {
        panic(err)
    }

    conn, err := net.ListenUDP("udp", addr)
    if err != nil {
        panic(err)
    }
    defer conn.Close()

    fmt.Println("UDP сервер запущен на порту 8081")

    buffer := make([]byte, 1024)

    for {
        n, clientAddr, err := conn.ReadFromUDP(buffer)
        if err != nil {
            fmt.Println("Ошибка чтения:", err)
            continue
        }

        message := string(buffer[:n])
        fmt.Printf("Получено от %s: %s\n", clientAddr, message)

        response := fmt.Sprintf("Эхо: %s", message)
        conn.WriteToUDP([]byte(response), clientAddr)
    }
}
```

---

## UDP Клиент

```go
package main

import (
    "fmt"
    "net"
)

func main() {
    serverAddr, err := net.ResolveUDPAddr("udp", "localhost:8081")
    if err != nil {
        panic(err)
    }

    conn, err := net.DialUDP("udp", nil, serverAddr)
    if err != nil {
        panic(err)
    }
    defer conn.Close()

    message := "Hello, UDP Server!"
    _, err = conn.Write([]byte(message))
    if err != nil {
        panic(err)
    }

    buffer := make([]byte, 1024)
    n, _, err := conn.ReadFromUDP(buffer)
    if err != nil {
        panic(err)
    }

    fmt.Printf("Ответ от сервера: %s\n", string(buffer[:n]))
}
```
