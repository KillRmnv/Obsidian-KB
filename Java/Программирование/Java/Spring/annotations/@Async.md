## Асинхронные методы сервиса (`@Async`) в Spring

Аннотация `@Async` — это механизм Spring, который позволяет выполнять методы асинхронно в отдельном потоке из пула. Это **декларативный способ** вынести тяжелые или долгие операции из основного потока запроса.

### Как это работает под капотом

1. **Proxy-обертка**: Spring создает прокси-объект для вашего сервиса (через CGLIB или JDK Dynamic Proxy).
2. **Перехват вызова**: Когда вы вызываете метод с `@Async`, прокси перехватывает вызов.
3. **Отправка в пул**: Вместо немедленного выполнения, задача упаковывается в `Runnable`/`Callable` и отправляется в `TaskExecutor` (пул потоков).
4. **Возврат управления**: Основной поток продолжает работу немедленно, не дожидаясь завершения асинхронного метода.

---

### 1. Базовая настройка

Чтобы `@Async` заработал, нужно включить поддержку асинхронности в конфигурации:

```java
@Configuration
@EnableAsync // <--- Обязательно!
public class AsyncConfig {

    @Bean(name = "taskExecutor")
    public Executor taskExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(5);      // Минимальное кол-во потоков
        executor.setMaxPoolSize(10);      // Максимальное кол-во потоков
        executor.setQueueCapacity(25);    // Размер очереди задач
        executor.setThreadNamePrefix("Async-");
        executor.initialize();
        return executor;
    }
}
```

> **Важно:** Если не определить свой `Executor`, Spring будет использовать простой `SimpleAsyncTaskExecutor`, который **создает новый поток для каждой задачи**. Это плохо для продакшена! Всегда настраивайте пул явно.

---

### 2. Использование в сервисе

#### Вариант А: `void` метод (Fire-and-Forget)
Идеально для логирования, отправки уведомлений, очистки кэша.

```java
@Service
public class NotificationService {

    @Async("taskExecutor") // Можно указать имя бина executor'а
    public void sendEmail(String to, String message) {
        // Этот код выполнится в отдельном потоке
        try {
            emailClient.send(to, message);
        } catch (Exception e) {
            log.error("Failed to send email", e);
            // Исключение здесь НЕ пробросится вызывающему коду!
        }
    }
}
```

**Вызов из контроллера:**
```java
@PostMapping("/register")
public ResponseEntity<String> register(@RequestBody UserDto user) {
    userService.save(user);
    
    // Контроллер не ждет завершения отправки письма
    notificationService.sendEmail(user.getEmail(), "Welcome!");
    
    return ResponseEntity.ok("Registered");
}
```

#### Вариант Б: Возврат `Future` / `CompletableFuture`
Если нужно получить результат позже.

```java
@Service
public class ReportService {

    @Async("taskExecutor")
    public CompletableFuture<String> generateReport(Long userId) {
        // Тяжелая операция
        String reportData = heavyProcessing(userId);
        return CompletableFuture.completedFuture(reportData);
    }
}
```

**Вызов из контроллера:**
```java
@GetMapping("/report/{id}")
public CompletableFuture<ResponseEntity<String>> getReport(@PathVariable Long id) {
    return reportService.generateReport(id)
        .thenApply(data -> ResponseEntity.ok(data))
        .exceptionally(ex -> ResponseEntity.status(500).body("Error"));
}
```

---

### 3. Критические ограничения и "Грабли"

Это самая важная часть. `@Async` работает через **AOP Proxies**, и у этого есть строгие правила:

####  Грабля №1: Self-invocation (Самовызов)
Если вы вызываете асинхронный метод из другого метода **того же класса**, асинхронность **не сработает**.

```java
@Service
public class MyService {

    public void doWork() {
        // Прямой вызов this.sendEmail() минует прокси!
        // Метод выполнится синхронно в текущем потоке!
        sendEmail("test@test.com", "Hi"); 
    }

    @Async
    public void sendEmail(String to, String msg) { ... }
}
```

**Решение:**
1. Вынести асинхронный метод в **другой сервис** (рекомендуется).
2. Инжектить сам себя (через `@Autowired private MyService self;`) и вызывать `self.sendEmail()`.

####  Грабля №2: Метод должен быть `public`
`@Async` не работает на `private`, `protected` или package-private методах, так как прокси не может их переопределить.

####  Грабля №3: Обработка исключений
Если асинхронный метод возвращает `void`, любое выброшенное исключение **теряется** (попадает в `UncaughtExceptionHandler`).

**Решение:** Реализовать `AsyncUncaughtExceptionHandler`:

```java
@Component
public class CustomAsyncExceptionHandler implements AsyncUncaughtExceptionHandler {
    @Override
    public void handleUncaughtException(Throwable ex, Method method, Object... params) {
        log.error("Async error in method: {}", method.getName(), ex);
        // Отправить алерт, записать в БД и т.д.
    }
}
```

И зарегистрировать его в конфиге:
```java
@Configuration
@EnableAsync
public class AsyncConfig implements AsyncConfigurer {
    @Override
    public AsyncUncaughtExceptionHandler getAsyncUncaughtExceptionHandler() {
        return new CustomAsyncExceptionHandler();
    }
    // ... bean executor'а
}
```

####  Грабля №4: Транзакции
`@Transactional` и `@Async` вместе работают сложно.
- Если `@Async` стоит на методе с `@Transactional`, транзакция откроется в **новом потоке**.
- Вызывающий метод не увидит изменений до коммита в асинхронном потоке.
- Часто это приводит к `LazyInitializationException` или проблемам с консистентностью данных.

**Рекомендация:** Разделяйте логику. Сначала сохраните данные в БД (синхронно, в транзакции), а потом запускайте асинхронную обработку.

---

### 4. Сравнение с другими подходами

| Характеристика | `@Async` | `CompletableFuture` вручную | WebFlux | Virtual Threads |
| :--- | :--- | :--- | :--- | :--- |
| **Сложность кода** | Низкая (аннотация) | Средняя | Высокая | Низкая |
| **Управление потоками** | Централизованное (Spring) | Ручное | Event-loop | JVM |
| **Тип I/O** | Блокирующий | Блокирующий | Неблокирующий | Блокирующий (но дешевый) |
| **Отладка** | Сложная (другой стек) | Средняя | Сложная | Простая |
| **Лучше всего для** | Фоновых задач, уведомлений | Параллельных вызовов API | Высоконагруженных I/O | Масштабирования legacy |

---

### 5. Когда использовать `@Async`?

 **Да:**
*   Отправка email/SMS/push-уведомлений после регистрации.
*   Генерация тяжелых отчетов по расписанию или запросу.
*   Очистка временных файлов или кэша.
*   Логирование аудита, которое не должно замедлять основной ответ.
*   Интеграция с медленными внешними системами, если результат не нужен мгновенно.

 **Нет:**
*   Если клиенту нужен результат этой операции прямо сейчас (лучше использовать синхронный вызов или WebSocket/SSE для долгих операций).
*   Внутри циклов с тысячами итераций (оверхед на создание задач будет огромным).
*   Для методов, которые должны выполняться строго последовательно и зависеть друг от друга в рамках одного запроса.

### Итог
`@Async` — это мощный инструмент для **разгрузки основного потока запроса** от фоновых задач. Он проще в использовании, чем ручное управление `ExecutorService`, но требует понимания ограничений AOP-проксирования. Для высоконагруженных систем с большим количеством I/O лучше смотреть в сторону **WebFlux** или **Virtual Threads** (Java 21+).