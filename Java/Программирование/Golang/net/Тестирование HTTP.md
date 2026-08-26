# Тестирование HTTP

Для тестирования HTTP-обработчиков в Go используется пакет `net/http/httptest`. Он позволяет создавать тестовые серверы и отправлять фейковые запросы без реального сетевого взаимодействия.

Связанные темы: [[REST API]], [[HTTP сервер]]

---

```go
package main

import (
    "encoding/json"
    "net/http"
    "net/http/httptest"
    "testing"
)

func TestUserAPI_GetUser(t *testing.T) {
    storage := NewUserStorage()
    api := NewUserAPI(storage)

    storage.mu.Lock()
    storage.users[1] = User{ID: 1, Name: "Test", Age: 25}
    storage.mu.Unlock()

    req, err := http.NewRequest("GET", "/users/1", nil)
    if err != nil {
        t.Fatal(err)
    }

    rr := httptest.NewRecorder()

    handler := http.HandlerFunc(api.GetUser)
    handler.ServeHTTP(rr, req)

    if rr.Code != http.StatusOK {
        t.Errorf("Expected 200, got %d", rr.Code)
    }

    var user User
    if err := json.NewDecoder(rr.Body).Decode(&user); err != nil {
        t.Fatal(err)
    }

    if user.Name != "Test" {
        t.Errorf("Expected 'Test', got '%s'", user.Name)
    }
}
```
