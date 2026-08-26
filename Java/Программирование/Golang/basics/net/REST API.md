# REST API (полный пример)

REST (Representational State Transfer) -- архитектурный стиль для проектирования веб-сервисов. Основан на HTTP-методах и ресурсах.

Связанные темы: [[HTTP сервер]], [[HTTP клиент]], [[HTTP статусы и методы]], [[Тестирование HTTP]]

---

```go
package main

import (
    "encoding/json"
    "fmt"
    "net/http"
    "strconv"
    "sync"
)

type User struct {
    ID   int    `json:"id"`
    Name string `json:"name"`
    Age  int    `json:"age"`
}

type UserStorage struct {
    mu     sync.RWMutex
    users  map[int]User
    nextID int
}

func NewUserStorage() *UserStorage {
    return &UserStorage{
        users:  make(map[int]User),
        nextID: 1,
    }
}

type UserAPI struct {
    storage *UserStorage
}

func NewUserAPI(storage *UserStorage) *UserAPI {
    return &UserAPI{storage: storage}
}

func (api *UserAPI) GetUsers(w http.ResponseWriter, r *http.Request) {
    api.storage.mu.RLock()
    defer api.storage.mu.RUnlock()

    users := make([]User, 0, len(api.storage.users))
    for _, user := range api.storage.users {
        users = append(users, user)
    }

    respondJSON(w, http.StatusOK, users)
}

func (api *UserAPI) GetUser(w http.ResponseWriter, r *http.Request) {
    id, err := getIDFromPath(r)
    if err != nil {
        http.Error(w, "Invalid ID", http.StatusBadRequest)
        return
    }

    api.storage.mu.RLock()
    defer api.storage.mu.RUnlock()

    user, ok := api.storage.users[id]
    if !ok {
        http.Error(w, "User not found", http.StatusNotFound)
        return
    }

    respondJSON(w, http.StatusOK, user)
}

func (api *UserAPI) CreateUser(w http.ResponseWriter, r *http.Request) {
    var user User
    if err := json.NewDecoder(r.Body).Decode(&user); err != nil {
        http.Error(w, "Invalid JSON", http.StatusBadRequest)
        return
    }

    api.storage.mu.Lock()
    defer api.storage.mu.Unlock()

    user.ID = api.storage.nextID
    api.storage.nextID++
    api.storage.users[user.ID] = user

    respondJSON(w, http.StatusCreated, user)
}

func (api *UserAPI) UpdateUser(w http.ResponseWriter, r *http.Request) {
    id, err := getIDFromPath(r)
    if err != nil {
        http.Error(w, "Invalid ID", http.StatusBadRequest)
        return
    }

    var user User
    if err := json.NewDecoder(r.Body).Decode(&user); err != nil {
        http.Error(w, "Invalid JSON", http.StatusBadRequest)
        return
    }

    api.storage.mu.Lock()
    defer api.storage.mu.Unlock()

    if _, ok := api.storage.users[id]; !ok {
        http.Error(w, "User not found", http.StatusNotFound)
        return
    }

    user.ID = id
    api.storage.users[id] = user

    respondJSON(w, http.StatusOK, user)
}

func (api *UserAPI) DeleteUser(w http.ResponseWriter, r *http.Request) {
    id, err := getIDFromPath(r)
    if err != nil {
        http.Error(w, "Invalid ID", http.StatusBadRequest)
        return
    }

    api.storage.mu.Lock()
    defer api.storage.mu.Unlock()

    if _, ok := api.storage.users[id]; !ok {
        http.Error(w, "User not found", http.StatusNotFound)
        return
    }

    delete(api.storage.users, id)
    w.WriteHeader(http.StatusNoContent)
}

func getIDFromPath(r *http.Request) (int, error) {
    path := r.URL.Path
    idStr := path[len("/users/"):]
    return strconv.Atoi(idStr)
}

func respondJSON(w http.ResponseWriter, status int, data interface{}) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(status)
    json.NewEncoder(w).Encode(data)
}

func main() {
    storage := NewUserStorage()
    api := NewUserAPI(storage)

    http.HandleFunc("/users", func(w http.ResponseWriter, r *http.Request) {
        switch r.Method {
        case http.MethodGet:
            api.GetUsers(w, r)
        case http.MethodPost:
            api.CreateUser(w, r)
        default:
            http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
        }
    })

    http.HandleFunc("/users/", func(w http.ResponseWriter, r *http.Request) {
        switch r.Method {
        case http.MethodGet:
            api.GetUser(w, r)
        case http.MethodPut:
            api.UpdateUser(w, r)
        case http.MethodDelete:
            api.DeleteUser(w, r)
        default:
            http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
        }
    })

    fmt.Println("REST API запущена на :8080")
    http.ListenAndServe(":8080", nil)
}
```
