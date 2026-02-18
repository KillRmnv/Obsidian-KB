
## 1️⃣ Архитектура классического Spring MVC

В классической модели Spring работает на **Servlet-контейнере** (Tomcat, Jetty, Undertow). Основные компоненты:

```
Client (браузер/фронт)
      |
      v
HTTP request
      |
Connector (Tomcat/Jetty)
      |
Thread Pool
      |
Servlet (DispatcherServlet)
      |
HandlerMapping -> Controller
      |
HandlerAdapter -> Service -> DAO
      |
ViewResolver -> Response
      |
HTTP Response
      v
Client
```

---

## 2️⃣ Пошаговое объяснение

### 🔹 Шаг 1: HTTP-запрос приходит на сервер

- Пользователь делает запрос к API, например:
    

```
GET /articles/123
```

- Tomcat слушает порт (8080) через **Connector** (HTTP connector).
    

---

### 🔹 Шаг 2: Поток из пула потоков

- Tomcat имеет **пул потоков**, например 200 потоков.
    
- Для каждого входящего запроса берётся свободный поток:
    

```
Thread-101 <- обрабатывает запрос GET /articles/123
```

- Если все потоки заняты → новые запросы **ждут** в очереди.
    

---

### 🔹 Шаг 3: DispatcherServlet

- Tomcat передаёт запрос **Servlet**, в Spring это **`DispatcherServlet`**.
    
- `DispatcherServlet` — основной компонент Spring MVC, который маршрутизирует запросы к нужным контроллерам.
    

```java
@RestController
@RequestMapping("/articles")
public class ArticleController {

    @GetMapping("/{id}")
    public Article getArticle(@PathVariable String id) {
        return articleService.findById(id);
    }
}
```

---

### 🔹 Шаг 4: HandlerMapping и Controller

- `DispatcherServlet` использует **HandlerMapping**, чтобы определить, какой метод контроллера должен обработать запрос.
    
- Находит `ArticleController.getArticle`.
    

---

### 🔹 Шаг 5: HandlerAdapter и сервисный слой

- `HandlerAdapter` вызывает метод контроллера.
    
- Контроллер вызывает **сервисный слой**, который вызывает **DAO / репозиторий** для доступа к базе данных.
    

```java
Article article = articleRepository.findById(id);
```

- На этом шаге поток блокируется **до завершения всех операций** (blocking I/O).
    

---

### 🔹 Шаг 6: ViewResolver / ResponseBody

- Контроллер возвращает объект (`Article`), Spring сериализует его в **JSON** (если `@RestController`).
    
- `DispatcherServlet` отправляет ответ обратно через поток Tomcat.
    

---

### 🔹 Шаг 7: Поток освобождается

- После отправки ответа поток возвращается в **пул потоков**, готовый для следующего запроса.
    

---

## 3️⃣ Особенности блокирующей модели

|Особенность|Пояснение|
|---|---|
|Thread-per-request|Каждый HTTP-запрос обрабатывается отдельным потоком из пула|
|Blocking I/O|Если сервис ждёт базы данных или внешнего API, поток **заблокирован**|
|Ограничение на пользователей|Максимум = размер пула потоков, остальным придётся ждать|
|Масштабирование|Добавление серверов / увеличение пула потоков|

---

## 4️⃣ Пример Thread Pool Tomcat

- Параметры в `application.properties` (Spring Boot):
    

```properties
server.tomcat.max-threads=200
server.tomcat.min-spare-threads=10
server.tomcat.accept-count=100
```

- **max-threads** — максимальное количество потоков для обработки запросов
    
- **min-spare-threads** — минимальное количество свободных потоков
    
- **accept-count** — очередь для ожидающих соединений
    

---

## 5️⃣ Пример с Spring Security

- Поток также обрабатывает фильтры Spring Security:
    

```
Thread-101
 ├─ SecurityContextPersistenceFilter
 ├─ JwtTokenFilter / UsernamePasswordAuthenticationFilter
 ├─ ExceptionTranslationFilter
 └─ DispatcherServlet -> Controller
```

- Всё происходит **в рамках одного потока** на весь жизненный цикл запроса.
    

---

## 6️⃣ Итог

1. Классическая модель = **thread-per-request**.
    
2. Поток блокируется на время обработки запроса (контроллер, сервис, DAO, база).
    
3. Ограничение количества одновременных запросов зависит от **размера пула потоков**.
    
4. Spring MVC + Tomcat = идеальная связка для **blocking I/O приложений** (REST, формы, CRUD).
    
