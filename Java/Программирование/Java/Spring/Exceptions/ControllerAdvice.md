Обработка ошибок на уровне контроллеров в Spring Boot строится на централизованном механизме перехвата исключений. Это позволяет отделить инфраструктурную логику от бизнес-правил, унифицировать формат ответов и избежать дублирования try-catch блоков в каждом обработчике запроса.

---

### 1. Базовый механизм: @RestControllerAdvice и @ExceptionHandler

`@RestControllerAdvice` применяется к классу, который содержит методы с аннотацией `@ExceptionHandler`. Эти методы автоматически вызываются при возникновении указанных исключений в любом `@RestController` приложения.

**Стандартизированный DTO ошибки**
```java
public class ApiError {
    private int status;
    private String error;
    private String message;
    private String path;
    private Map<String, String> fieldErrors;
    // конструкторы, геттеры, сеттеры
}
```

**Глобальный обработчик**
```java
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ApiError> handleNotFound(ResourceNotFoundException ex, WebRequest request) {
        ApiError error = new ApiError(
            HttpStatus.NOT_FOUND.value(),
            HttpStatus.NOT_FOUND.getReasonPhrase(),
            ex.getMessage(),
            request.getDescription(false).replace("uri=", "")
        );
        return new ResponseEntity<>(error, HttpStatus.NOT_FOUND);
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiError> handleGeneral(Exception ex, WebRequest request) {
        ApiError error = new ApiError(
            HttpStatus.INTERNAL_SERVER_ERROR.value(),
            HttpStatus.INTERNAL_SERVER_ERROR.getReasonPhrase(),
            "Внутренняя ошибка сервера",
            request.getDescription(false).replace("uri=", "")
        );
        // Логирование критично только для 5xx
        logger.error("Unhandled exception", ex);
        return new ResponseEntity<>(error, HttpStatus.INTERNAL_SERVER_ERROR);
    }
}
```

---

### 2. Обработка ошибок валидации (@Valid)

При использовании `@Valid` или `@Validated` Spring выбрасывает `MethodArgumentNotValidException`. Обработчик должен извлечь детали полей.

```java
@ExceptionHandler(MethodArgumentNotValidException.class)
public ResponseEntity<ApiError> handleValidation(MethodArgumentNotValidException ex, WebRequest request) {
    Map<String, String> errors = new HashMap<>();
    ex.getBindingResult().getFieldErrors().forEach(fieldError ->
        errors.put(fieldError.getField(), fieldError.getDefaultMessage())
    );

    ApiError error = new ApiError(
        HttpStatus.BAD_REQUEST.value(),
        HttpStatus.BAD_REQUEST.getReasonPhrase(),
        "Ошибка валидации входных данных",
        request.getDescription(false).replace("uri=", "")
    );
    error.setFieldErrors(errors);
    return new ResponseEntity<>(error, HttpStatus.BAD_REQUEST);
}
```

---

### 3. Обработка типичных исключений Spring MVC

Spring фреймворк генерирует ряд стандартных исключений при разборе запроса. Их целесообразно перехватывать для возврата понятных клиенту сообщений.

```java
@ExceptionHandler(HttpMessageNotReadableException.class)
public ResponseEntity<ApiError> handleBadRequest(HttpMessageNotReadableException ex, WebRequest request) {
    ApiError error = new ApiError(
        HttpStatus.BAD_REQUEST.value(),
        HttpStatus.BAD_REQUEST.getReasonPhrase(),
        "Некорректный формат запроса",
        request.getDescription(false).replace("uri=", "")
    );
    return new ResponseEntity<>(error, HttpStatus.BAD_REQUEST);
}

@ExceptionHandler(MissingServletRequestParameterException.class)
public ResponseEntity<ApiError> handleMissingParam(MissingServletRequestParameterException ex, WebRequest request) {
    ApiError error = new ApiError(
        HttpStatus.BAD_REQUEST.value(),
        HttpStatus.BAD_REQUEST.getReasonPhrase(),
        "Отсутствует обязательный параметр: " + ex.getParameterName(),
        request.getDescription(false).replace("uri=", "")
    );
    return new ResponseEntity<>(error, HttpStatus.BAD_REQUEST);
}

@ExceptionHandler(MethodArgumentTypeMismatchException.class)
public ResponseEntity<ApiError> handleTypeMismatch(MethodArgumentTypeMismatchException ex, WebRequest request) {
    ApiError error = new ApiError(
        HttpStatus.BAD_REQUEST.value(),
        HttpStatus.BAD_REQUEST.getReasonPhrase(),
        "Параметр '" + ex.getName() + "' должен быть типа " + ex.getRequiredType().getSimpleName(),
        request.getDescription(false).replace("uri=", "")
    );
    return new ResponseEntity<>(error, HttpStatus.BAD_REQUEST);
}
```

---

### 4. Современный стандарт: RFC 7807 (ProblemDetails)

Spring Boot 3.x предоставляет встроенную поддержку стандарта ProblemDetails (`org.springframework.http.ProblemDetail`). Это рекомендуемый подход для новых проектов.

**Включение поддержки**
```properties
# application.properties
spring.mvc.problemdetails.enabled=true
```

**Реализация обработчика**
```java
@RestControllerAdvice
public class ProblemDetailExceptionHandler {

    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<ProblemDetail> handleNotFound(ResourceNotFoundException ex, WebRequest request) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
            HttpStatus.NOT_FOUND,
            ex.getMessage()
        );
        problem.setTitle("Ресурс не найден");
        problem.setInstance(URI.create(request.getDescription(false).replace("uri=", "")));
        problem.setProperty("resourceName", ex.getResourceName());
        problem.setProperty("field", ex.getFieldName());
        return new ResponseEntity<>(problem, HttpStatus.NOT_FOUND);
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ProblemDetail> handleValidation(MethodArgumentNotValidException ex, WebRequest request) {
        ProblemDetail problem = ProblemDetail.forStatusAndDetail(
            HttpStatus.BAD_REQUEST,
            "Ошибка валидации"
        );
        problem.setTitle("Некорректные данные запроса");
        Map<String, List<String>> errors = new HashMap<>();
        ex.getBindingResult().getFieldErrors().forEach(fe ->
            errors.computeIfAbsent(fe.getField(), k -> new ArrayList<>()).add(fe.getDefaultMessage())
        );
        problem.setProperty("validationErrors", errors);
        return new ResponseEntity<>(problem, HttpStatus.BAD_REQUEST);
    }
}
```

---

### 5. Приоритеты и порядок обработки

Если в приложении несколько классов с `@RestControllerAdvice`, Spring определяет порядок вызова обработчиков по специфичности исключения и аннотации `@Order`.

```java
@RestControllerAdvice
@Order(1)
public class HighPriorityHandler { ... }

@RestControllerAdvice
@Order(2)
public class LowPriorityHandler { ... }
```

Правила разрешения:
1. Локальный `@ExceptionHandler` в контроллере имеет высший приоритет.
2. Глобальные обработчики сортируются по `@Order` (меньшее число = выше приоритет).
3. Внутри одного класса выбирается метод с наиболее специфичным типом исключения.
4. Если типы равны, выбирается первый объявленный метод.

---

### 6. Локальная обработка в конкретном контроллере

Иногда логика ошибок специфична для одного модуля. В этом случае обработчик объявляется внутри самого контроллера.

```java
@RestController
@RequestMapping("/api/orders")
public class OrderController {

    @PostMapping
    public ResponseEntity<OrderDto> create(@Valid @RequestBody OrderRequest request) {
        return ResponseEntity.ok(service.create(request));
    }

    @ExceptionHandler(OrderAlreadyExistsException.class)
    public ResponseEntity<ApiError> handleOrderConflict(OrderAlreadyExistsException ex) {
        ApiError error = new ApiError(HttpStatus.CONFLICT.value(), "Conflict", ex.getMessage(), null);
        return new ResponseEntity<>(error, HttpStatus.CONFLICT);
    }
}
```

---

### 7. Рекомендации по проектированию

1. **Не логируйте 4xx как ошибки уровня ERROR**. Используйте `WARN` или `INFO`. Стратегию логирования настраивайте через SLF4J маркеры или фильтры.
2. **Не раскрывайте стек-трейс или SQL-запросы клиенту**. Это создаёт уязвимости. Детали сохраняйте в логах или системах трассировки (Sentry, ELK).
3. **Разделяйте бизнес-исключения и технические**. `UserNotFoundException` должно маппиться в 404, а `DatabaseAccessException` в 503/500.
4. **Используйте @ResponseStatus только для простых случаев**. `ResponseEntity` или `ProblemDetail` дают явный контроль над телом ответа и заголовками.
5. **Тестируйте обработчики**. Используйте `@WebMvcTest` с `MockMvc` для проверки статусов и структуры JSON без запуска полного контекста.
6. **Версионируйте формат ошибок**. Если API меняется, добавляйте поле `version` в `ApiError` или `ProblemDetail`, чтобы клиенты могли адаптироваться.

---

### 8. Пример теста обработчика (JUnit 5 + MockMvc)

```java
@WebMvcTest(controllers = UserController.class)
class UserControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void shouldReturnValidationErrorWhenNameIsBlank() throws Exception {
        String requestJson = objectMapper.writeValueAsString(new UserCreateRequest(""));

        mockMvc.perform(post("/api/users")
                .contentType(MediaType.APPLICATION_JSON)
                .content(requestJson))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.title").value("Некорректные данные запроса"))
            .andExpect(jsonPath("$.validationErrors.name").exists());
    }
}
```

Централизованная обработка ошибок на уровне контроллеров является архитектурным стандартом в Spring-экосистеме. Она обеспечивает согласованность ответов, упрощает поддержку и соответствует современным стандартам REST API.