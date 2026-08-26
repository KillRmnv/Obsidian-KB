# HTTP Сервер (стандартный net/http)

HTTP работает поверх TCP. Пакет `net/http` -- стандартная библиотека для создания HTTP-серверов и клиентов в Go.

Связанные темы: [[TCP]], [[REST API]], [[HTTP клиент]], [[Middleware]], [[Graceful Shutdown]], [[Обработка форм и файлов]], [[HTTP статусы и методы]]

---

## Базовый HTTP сервер

```go
package main

import (
    "fmt"
    "net/http"
)

func main() {
    http.HandleFunc("/", homePage)
    http.HandleFunc("/hello", helloHandler)
    http.HandleFunc("/user/", userHandler)

    http.Handle("/static/", http.StripPrefix("/static/", http.FileServer(http.Dir("./static"))))

    fmt.Println("Сервер запущен на :8080")
    http.ListenAndServe(":8080", nil)
}

func homePage(w http.ResponseWriter, r *http.Request) {
    fmt.Fprintf(w, "Главная страница")
}

func helloHandler(w http.ResponseWriter, r *http.Request) {
    name := r.URL.Query().Get("name")
    if name == "" {
        name = "World"
    }
    fmt.Fprintf(w, "Hello, %s!", name)
}

func userHandler(w http.ResponseWriter, r *http.Request) {
    id := r.URL.Path[len("/user/"):]
    fmt.Fprintf(w, "User ID: %s", id)
}
```

---

## HTTP сервер с роутером (свой)

```go
package main

import (
    "fmt"
    "net/http"
    "strings"
)

type Router struct {
    routes map[string]map[string]http.HandlerFunc
}

func NewRouter() *Router {
    return &Router{
        routes: make(map[string]map[string]http.HandlerFunc),
    }
}

func (r *Router) Handle(method, path string, handler http.HandlerFunc) {
    if r.routes[path] == nil {
        r.routes[path] = make(map[string]http.HandlerFunc)
    }
    r.routes[path][method] = handler
}

func (r *Router) GET(path string, handler http.HandlerFunc) {
    r.Handle(http.MethodGet, path, handler)
}

func (r *Router) POST(path string, handler http.HandlerFunc) {
    r.Handle(http.MethodPost, path, handler)
}

func (r *Router) ServeHTTP(w http.ResponseWriter, req *http.Request) {
    path := req.URL.Path
    method := req.Method

    if handlers, ok := r.routes[path]; ok {
        if handler, ok := handlers[method]; ok {
            handler(w, req)
            return
        }
        http.Error(w, "Method Not Allowed", http.StatusMethodNotAllowed)
        return
    }
    http.Error(w, "Not Found", http.StatusNotFound)
}

func main() {
    router := NewRouter()

    router.GET("/", func(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintf(w, "Главная")
    })

    router.GET("/hello", func(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintf(w, "Hello, World!")
    })

    router.POST("/submit", func(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintf(w, "POST запрос обработан")
    })

    http.ListenAndServe(":8080", router)
}
```
