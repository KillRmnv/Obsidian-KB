

## 1️⃣ Что такое `ResponseEntity`

- `ResponseEntity<T>` — это **обёртка над HTTP-ответом**, которая содержит:
    

1. **Тело ответа (`body`)** — объект, который сериализуется в JSON/HTML/XML и отправляется клиенту.
    
2. **HTTP статус (`status code`)** — 200, 404, 500 и т.д.
    
3. **HTTP заголовки (`headers`)** — например, `Content-Type`, `Location`, `Authorization`.
    

- Используется в REST-контроллерах для **полного контроля над ответом**.
    

---

## 2️⃣ Простой пример

```java
@RestController
@RequestMapping("/articles")
public class ArticleController {

    @GetMapping("/{id}")
    public ResponseEntity<Article> getArticle(@PathVariable String id) {
        Article article = articleService.findById(id);

        if (article == null) {
            return ResponseEntity.notFound().build(); // 404
        }

        return ResponseEntity.ok(article); // 200 + тело
    }
}
```

- `ResponseEntity.ok(article)` → HTTP 200 + JSON тело статьи
    
- `ResponseEntity.notFound().build()` → HTTP 404, тело пустое
    

---

## 3️⃣ Установка заголовков

Можно добавлять заголовки через `ResponseEntity`:

```java
return ResponseEntity
        .ok()
        .header("X-Custom-Header", "value")
        .body(article);
```

- HTTP ответ будет включать:
    

```
HTTP/1.1 200 OK
X-Custom-Header: value
Content-Type: application/json

{ "id": 1, "title": "Spring Article" }
```

---

## 4️⃣ Другие способы создать ResponseEntity

|Метод|Что делает|
|---|---|
|`ResponseEntity.ok(body)`|200 OK + тело|
|`ResponseEntity.status(HttpStatus.CREATED).body(body)`|201 Created + тело|
|`ResponseEntity.badRequest().body(error)`|400 Bad Request + тело|
|`ResponseEntity.notFound().build()`|404 Not Found без тела|
|`ResponseEntity.noContent().build()`|204 No Content|

---

## 5️⃣ Отличие от простого возвращения объекта

```java
@GetMapping("/{id}")
public Article getArticle(@PathVariable String id) {
    return articleService.findById(id);
}
```

- Возвращает только **тело ответа** (по умолчанию HTTP 200)
    
- Нет контроля над заголовками и статусом HTTP.
    
- Для продвинутого REST API обычно используют `ResponseEntity`.
    

---

## 6️⃣ Итог

- **ResponseEntity** = полный контроль над HTTP-ответом.
    
- Можно задавать:
    
    - **Статус ответа**
        
    - **Тело**
        
    - **Заголовки**
        
- Полезно для REST API, где важно сообщать клиенту **разные коды состояния** или добавлять специальные заголовки.
    
