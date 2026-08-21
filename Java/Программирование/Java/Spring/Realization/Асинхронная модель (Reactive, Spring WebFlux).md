 ## 1 Основная идея WebFlux

- Spring WebFlux = **reactive, non-blocking** фреймворк для обработки HTTP-запросов.
    
- Используется **Netty, Undertow или Servlet 3.1+** с **non-blocking I/O**.
    
- Позволяет одному потоку обрабатывать **тысячи одновременных запросов** без блокировки.
    

###  Отличие от классической Servlet-модели:

|Модель|Потоки|Блокировка|Одновременные пользователи|
|---|---|---|---|
|Servlet (Tomcat)|Thread-per-request|blocking I/O|до сотен (зависит от пула потоков)|
|WebFlux (Netty)|Event-loop (немного потоков)|non-blocking I/O|тысячи и более|

---

## 2 Архитектура WebFlux

```
Client → Netty Event Loop → WebFilter Chain → HandlerMapping → Controller → Service → Repository → Response
```

- **Event Loop**: один поток обрабатывает множество соединений.
    
- **Non-blocking**: поток не ждёт ответа от базы данных или внешнего API, а подписывается на **Mono/Flux** (асинхронный результат).
    
- **Reactive Streams**: управление backpressure и асинхронная обработка данных.
    

---

## 3 Поток запроса

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

## 4 Reactive фильтры (WebFilter)

- Аналог Servlet Filter Chain, но **асинхронный**.
    
- Spring Security поддерживает WebFlux через **SecurityWebFilterChain**.
    

Пример:

```
WebFilter Chain:
  SecurityWebFilterChain (JWT, Authentication)
  CORS WebFilter
  Logging WebFilter
  DispatcherHandler → Controller
```

- Event-loop поток проходит через фильтры, но **не блокируется** на I/O.
    
- Можно обрабатывать тысячи соединений с 2–4 потоками event-loop.
    

---

## 5 Особенности работы с базой данных

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

## 6 Преимущества WebFlux

|Преимущество|Пояснение|
|---|---|
|Масштабируемость|Один поток может обслуживать тысячи соединений|
|Non-blocking I/O|Нет блокировки на сетевых/базовых операциях|
|Reactive Streams|Контроль backpressure, эффективное использование ресурсов|
|Подходит для|REST API, WebSockets, Streaming, микросервисы|

---

## 7 Итог

- WebFlux = **асинхронная, неблокирующая модель**, подходит для **высоконагруженных приложений**.
    
- Потоки не привязаны к одному запросу, используются **event-loop**.
    
- Контроллеры возвращают `Mono`/`Flux`, все фильтры (включая Spring Security) асинхронны.
    
- В отличие от Servlet-модели, можно обслуживать **тысячи одновременных пользователей** на очень небольшом количестве потоков.



    
То есть **WebFlux → это примерно как asyncio в Python**, только на Java с полноценными потоками JVM:

- Один или несколько **event-loop потоков**.
    
- Потоки не ждут, пока I/O завершится.
    
- Используют **callback/subscription**, чтобы обработать результат, когда он готов.


## Spring WebFlux: Реактивный стек

**Spring WebFlux** — это полностью неблокирующий веб-фреймворк, введенный в Spring 5. Он построен на основе **Reactive Streams** и предназначен для создания приложений с высокой пропускной способностью и эффективным использованием ресурсов при большом количестве одновременных подключений.

В отличие от классического Spring MVC (который работает по модели "один поток на запрос"), WebFlux использует **event-loop модель** (подобно Node.js или Nginx), где небольшое количество потоков обслуживает тысячи соединений.

---

### 1. Ключевые отличия от Spring MVC

| Характеристика | Spring MVC (Servlet Stack) | Spring WebFlux (Reactive Stack) |
| :--- | :--- | :--- |
| **Модель I/O** | Блокирующая (Blocking) | Неблокирующая (Non-blocking) |
| **Архитектура** | 1 поток = 1 запрос | Event-loop (несколько потоков на все запросы) |
| **API Сервлетов** | Использует Servlet API (JSR-340/369) | Не использует Servlet API (работает на Netty, Jetty, Undertow) |
| **Типы данных** | Объекты, Collections, Streams | `Mono<T>`, `Flux<T>` (Reactor Project) |
| **Потоки** | Много потоков (Thread-per-request) | Мало потоков (обычно = кол-ву ядер CPU) |
| **Сложность** | Низкая, линейная логика | Выше, требует реактивного мышления |
| **Библиотеки** | Любые JDBC, JPA, HTTP клиенты | Только реактивные драйверы (R2DBC, Reactive Mongo, WebClient) |

---

### 2. Основные концепции

#### A. Reactive Streams и Project Reactor
WebFlux базируется на библиотеке **Project Reactor**, которая реализует спецификацию Reactive Streams. Два основных типа:

1.  **`Mono<T>`**: Представляет асинхронную операцию, которая возвращает **0 или 1** элемент.
    *   Аналог: `CompletableFuture<T>` или `Optional<T>`.
    *   Пример: Поиск пользователя по ID, сохранение сущности.
2.  **`Flux<T>`**: Представляет асинхронную последовательность из **0..N** элементов.
    *   Аналог: `Stream<T>` или `Collection<T>`.
    *   Пример: Список всех пользователей, поток событий с сервера.

#### B. Backpressure (Обратное давление)
Это механизм, позволяющий потребителю данных сигнализировать производителю о том, что он не успевает обрабатывать данные так быстро, как они приходят. Это предотвращает переполнение памяти (OutOfMemoryError) при высоких нагрузках.

#### C. Неблокирующий ввод-вывод
Когда WebFlux делает запрос к базе данных или внешнему API, поток **не блокируется** в ожидании ответа. Он освобождается для обработки других запросов. Когда ответ приходит, событие ставится в очередь, и один из потоков event-loop продолжает обработку.

---

### 3. Архитектура WebFlux

WebFlux предлагает две модели программирования:

#### 1. Аннотированные контроллеры (Annotation-based)
Похоже на Spring MVC, но возвращает `Mono`/`Flux`.

```java
@RestController
@RequestMapping("/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    // Возвращает одного пользователя или пустоту
    @GetMapping("/{id}")
    public Mono<User> getUser(@PathVariable String id) {
        return userService.findById(id);
    }

    // Возвращает поток пользователей
    @GetMapping
    public Flux<User> getAllUsers() {
        return userService.findAll();
    }

    // Сохранение пользователя
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public Mono<User> createUser(@RequestBody User user) {
        return userService.save(user);
    }
}
```

#### 2. Функциональные эндпоинты (Functional Endpoints)
Более явный стиль, использующий лямбда-выражения и маршрутизацию через код.

```java
@Configuration
public class RouterConfig {

    @Bean
    public RouterFunction<ServerResponse> userRoutes(UserHandler handler) {
        return route(GET("/users/{id}"), handler::getUser)
                .andRoute(GET("/users"), handler::getAllUsers)
                .andRoute(POST("/users"), handler::createUser);
    }
}

@Component
public class UserHandler {
    
    private final UserService userService;

    public UserHandler(UserService userService) {
        this.userService = userService;
    }

    public Mono<ServerResponse> getUser(ServerRequest request) {
        String id = request.pathVariable("id");
        return userService.findById(id)
                .flatMap(user -> ServerResponse.ok().bodyValue(user))
                .switchIfEmpty(ServerResponse.notFound().build());
    }
    
    // ... другие методы
}
```

---

### 4. Экосистема и совместимость

Чтобы получить выгоду от WebFlux, **вся цепочка вызовов должна быть неблокирующей**. Если вы вызовете блокирующий JDBC-драйвер внутри WebFlux, вы заблокируете весь event-loop, и приложение "умрет".

#### Реактивные компоненты:
*   **База данных**: 
    *   R2DBC (Reactive Relational Database Connectivity) для SQL (PostgreSQL, MySQL, H2).
    *   Reactive MongoDB, Cassandra, Couchbase драйверы.
    *   *Важно:* JPA/Hibernate **не поддерживаются** в WebFlux.
*   **HTTP Клиент**: 
    *   `WebClient` (вместо `RestTemplate`). Он неблокирующий и реактивный.
*   **Безопасность**: 
    *   Spring Security поддерживает WebFlux.
*   **Тестирование**: 
    *   `WebTestClient` для тестирования реактивных эндпоинтов.

#### Пример использования WebClient:
```java
@Service
public class ExternalApiService {

    private final WebClient webClient;

    public ExternalApiService(WebClient.Builder builder) {
        this.webClient = builder.baseUrl("https://api.example.com").build();
    }

    public Mono<String> getData(String id) {
        return webClient.get()
                .uri("/data/{id}", id)
                .retrieve()
                .bodyToMono(String.class);
    }
}
```

---

### 5. Преимущества и недостатки

####  Преимущества:
1.  **Высокая масштабируемость**: Может обрабатывать десятки тысяч одновременных подключений на небольшом количестве потоков.
2.  **Эффективное использование ресурсов**: Меньше потребления памяти и CPU за счет отсутствия накладных расходов на создание/переключение тысяч потоков.
3.  **Backpressure**: Встроенная защита от перегрузки.
4.  **Композиция**: Легко комбинировать несколько асинхронных вызовов (`zip`, `merge`, `concat`).

####  Недостатки:
1.  **Сложность отладки**: Stack traces в реактивном коде могут быть огромными и трудночитаемыми (хотя Reactor Debug Agent помогает).
2.  **Кривая обучения**: Требует смены парадигмы мышления с императивной на реактивную.
3.  **Ограниченная поддержка библиотек**: Многие старые библиотеки (JDBC, некоторые HTTP клиенты) являются блокирующими и не подходят напрямую.
4.  **Не всегда быстрее**: Для CPU-bound задач или простых CRUD-операций с низкой нагрузкой WebFlux может быть даже медленнее из-за оверхеда на реактивную обвязку.

---

### 6. Когда использовать WebFlux?

 **Используйте WebFlux, если:**
*   У вас высоконагруженное приложение с большим количеством одновременных подключений (чаты, стриминг, IoT).
*   Вы активно используете неблокирующие базы данных (MongoDB, Cassandra) или R2DBC.
*   Вам нужна интеграция с множеством внешних микросервисов через HTTP, и вы хотите делать это параллельно и неблокирующе.
*   Вы строите систему, где важны backpressure и устойчивость к пиковым нагрузкам.

 **Не используйте WebFlux, если:**
*   У вас стандартное enterprise-приложение с умеренной нагрузкой.
*   Вы сильно зависите от JPA/Hibernate и блокирующих JDBC-драйверов.
*   Ваша команда не готова изучать реактивное программирование.
*   У вас много CPU-intensive операций (лучше использовать виртуальные потоки Java 21+).

---

### 7. Сравнение с Virtual Threads (Java 21+)

С появлением Virtual Threads вопрос "WebFlux или нет?" стал сложнее.

*   **Virtual Threads** позволяют писать простой синхронный код, который масштабируется почти так же хорошо, как реактивный, за счет дешевизны потоков.
*   **WebFlux** все еще имеет преимущество в сценариях с экстремальным I/O и необходимостью тонкого контроля над backpressure и ресурсами.

**Тренд:** Для новых проектов на Java 21+ часто рекомендуют начинать с обычного Spring MVC + Virtual Threads, переходя на WebFlux только если есть специфические требования к реактивности (например, стриминг данных или сложная композиция событий).

### Итог
Spring WebFlux — это мощный инструмент для создания высокопроизводительных, неблокирующих приложений. Он требует изменения подхода к разработке и использования специальной экосистемы (Reactor, R2DBC, WebClient), но дает значительные преимущества в масштабируемости и эффективности использования ресурсов при правильном применении.