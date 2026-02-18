## 1️⃣ Основная идея WebFlux

- Spring WebFlux = **reactive, non-blocking** фреймворк для обработки HTTP-запросов.
    
- Используется **Netty, Undertow или Servlet 3.1+** с **non-blocking I/O**.
    
- Позволяет одному потоку обрабатывать **тысячи одновременных запросов** без блокировки.
    

### 🔹 Отличие от классической Servlet-модели:

|Модель|Потоки|Блокировка|Одновременные пользователи|
|---|---|---|---|
|Servlet (Tomcat)|Thread-per-request|blocking I/O|до сотен (зависит от пула потоков)|
|WebFlux (Netty)|Event-loop (немного потоков)|non-blocking I/O|тысячи и более|

---

## 2️⃣ Архитектура WebFlux

```
Client → Netty Event Loop → WebFilter Chain → HandlerMapping → Controller → Service → Repository → Response
```

- **Event Loop**: один поток обрабатывает множество соединений.
    
- **Non-blocking**: поток не ждёт ответа от базы данных или внешнего API, а подписывается на **Mono/Flux** (асинхронный результат).
    
- **Reactive Streams**: управление backpressure и асинхронная обработка данных.
    

---

## 3️⃣ Поток запроса

1. HTTP-запрос приходит в **Netty** (event-loop).
    
2. Поток обрабатывает цепочку **WebFilter** (аналог фильтров Spring Security).
    
3. Контроллер возвращает **Mono или Flux**, а поток **не блокируется**, пока результат формируется.
    
4. Когда данные готовы, callback/event-loop отправляет ответ клиенту.
    

Пример контроллера:

```java
@RestController
@RequestMapping("/articles")
public class ArticleController {

    private final ArticleService articleService;

    public ArticleController(ArticleService articleService) {
        this.articleService = articleService;
    }

    @GetMapping("/{id}")
    public Mono<Article> getArticle(@PathVariable String id) {
        return articleService.findByIdReactive(id); // возвращает Mono<Article>
    }
}
```

- `Mono` = 0 или 1 объект
    
- `Flux` = 0..N объектов
    
- Поток не блокируется, пока объект не готов.
    

---

## 4️⃣ Reactive фильтры (WebFilter)

- Аналог Servlet Filter Chain, но **асинхронный**.
    
- Spring Security поддерживает WebFlux через **SecurityWebFilterChain**.
    

Пример:

```
WebFilter Chain:
 ├─ SecurityWebFilterChain (JWT, Authentication)
 ├─ CORS WebFilter
 ├─ Logging WebFilter
 └─ DispatcherHandler → Controller
```

- Event-loop поток проходит через фильтры, но **не блокируется** на I/O.
    
- Можно обрабатывать тысячи соединений с 2–4 потоками event-loop.
    

---

## 5️⃣ Особенности работы с базой данных

- Для максимальной производительности используют **reactive DB драйверы**:
    
    - **R2DBC** для SQL
        
    - **Reactive MongoDB**
        
- Поток не ждёт завершения запроса к базе, а подписывается на результат:
    

```java
Mono<Article> findByIdReactive(String id) {
    return databaseClient.select().from("articles").matching(where("id").is(id)).fetch().one();
}
```

---

## 6️⃣ Преимущества WebFlux

|Преимущество|Пояснение|
|---|---|
|Масштабируемость|Один поток может обслуживать тысячи соединений|
|Non-blocking I/O|Нет блокировки на сетевых/базовых операциях|
|Reactive Streams|Контроль backpressure, эффективное использование ресурсов|
|Подходит для|REST API, WebSockets, Streaming, микросервисы|

---

## 7️⃣ Итог

- WebFlux = **асинхронная, неблокирующая модель**, подходит для **высоконагруженных приложений**.
    
- Потоки не привязаны к одному запросу, используются **event-loop**.
    
- Контроллеры возвращают `Mono`/`Flux`, все фильтры (включая Spring Security) асинхронны.
    
- В отличие от Servlet-модели, можно обслуживать **тысячи одновременных пользователей** на очень небольшом количестве потоков.



    
То есть **WebFlux → это примерно как asyncio в Python**, только на Java с полноценными потоками JVM:

- Один или несколько **event-loop потоков**.
    
- Потоки не ждут, пока I/O завершится.
    
- Используют **callback/subscription**, чтобы обработать результат, когда он готов.