# HTTP Клиент

Пакет `net/http` предоставляет полноценный HTTP-клиент для выполнения запросов к внешним сервисам.

Связанные темы: [[HTTP сервер]], [[REST API]], [[HTTP статусы и методы]]

---

## Базовый GET запрос

```go
package main

import (
    "encoding/json"
    "fmt"
    "io"
    "net/http"
    "time"
)

func main() {
    resp, err := http.Get("https://api.github.com/users/golang")
    if err != nil {
        panic(err)
    }
    defer resp.Body.Close()

    body, err := io.ReadAll(resp.Body)
    if err != nil {
        panic(err)
    }

    fmt.Println("Status:", resp.StatusCode)
    fmt.Println("Body:", string(body))
}
```

---

## HTTP Клиент с настройками

```go
package main

import (
    "bytes"
    "encoding/json"
    "fmt"
    "io"
    "net/http"
    "time"
)

type User struct {
    Name string `json:"name"`
    Age  int    `json:"age"`
}

func main() {
    client := &http.Client{
        Timeout: 10 * time.Second,
        Transport: &http.Transport{
            MaxIdleConns:    10,
            IdleConnTimeout: 30 * time.Second,
        },
    }

    user := User{Name: "Alice", Age: 30}
    jsonData, _ := json.Marshal(user)

    req, err := http.NewRequest("POST", "https://httpbin.org/post", bytes.NewBuffer(jsonData))
    if err != nil {
        panic(err)
    }

    req.Header.Set("Content-Type", "application/json")
    req.Header.Set("Authorization", "Bearer token123")

    resp, err := client.Do(req)
    if err != nil {
        panic(err)
    }
    defer resp.Body.Close()

    body, _ := io.ReadAll(resp.Body)
    fmt.Println("Response:", string(body))
}
```

---

## HTTP Клиент с повторными попытками

```go
package main

import (
    "fmt"
    "net/http"
    "time"
)

func makeRequestWithRetry(url string, maxRetries int) (*http.Response, error) {
    var resp *http.Response
    var err error

    for i := 0; i < maxRetries; i++ {
        resp, err = http.Get(url)
        if err == nil && resp.StatusCode < 500 {
            return resp, nil
        }

        if resp != nil {
            resp.Body.Close()
        }

        time.Sleep(time.Duration(i+1) * time.Second)
    }

    return nil, fmt.Errorf("failed after %d retries: %w", maxRetries, err)
}
```
