Отлично, переходим к **Spring MVC**. Это один из ключевых блоков на любом собеседовании. Тут важно не просто перечислить аннотации, а показать, что вы понимаете **жизненный цикл HTTP-запроса** от входа в приложение до выдачи ответа.

Ниже — полный разбор с архитектурой, аннотациями, ошибками и бонусными "киллер-фичами" для звёздного ответа.

---

### 1. Архитектура Spring MVC (Пошаговый цикл запроса)

Spring MVC построен на паттерне **Front Controller**. Главный диспетчер — `DispatcherServlet`. Вот как запрос путешествует по системе:

1. **Клиент** отправляет HTTP-запрос.
2. **DispatcherServlet** (единственная точка входа) перехватывает запрос.
3. Спрашивает у **HandlerMapping**: «Кто должен обработать этот URL?»
   - *HandlerMapping* смотрит на аннотации (`@RequestMapping`) и возвращает **HandlerExecutionChain** (объект контроллера + список перехватчиков Interceptors).
4. Получает **HandlerAdapter** (адаптер, умеющий вызывать нужный контроллер, например, `RequestMappingHandlerAdapter`).
5. HandlerAdapter **вызывает метод контроллера**, преобразует параметры запроса в аргументы метода (это называется **Data Binder**).
6. Контроллер возвращает:
   - *Традиционный MVC*: `ModelAndView` (имя представления + данные).
   - *REST*: объект (например, JSON) + `ResponseEntity` или просто `@ResponseBody`.
7. Если возвращено представление (view name), **ViewResolver** преобразует имя в реальный файл (JSP, Thymeleaf, FreeMarker) и рендерит HTML.
8. **DispatcherServlet** отправляет HTTP-ответ клиенту.

**Важно для собеса**: `DispatcherServlet` — это обычный `HttpServlet`, который регистрируется в web-контейнере (Tomcat). В Spring Boot это происходит автоматически.

---

### 2. Основные аннотации (с нюансами)

| Аннотация | Применение | Важные детали |
| :--- | :--- | :--- |
| **`@Controller`** | Класс-контроллер для MVC (возвращает имя представления). | Обычно используется с `ViewResolver`. |
| **`@RestController`** | = `@Controller` + `@ResponseBody`. | **Стандарт для REST API**. Все ответы автоматически сериализуются в JSON/XML. |
| **`@RequestMapping`** | Маппинг URL на метод или класс (уровень класса задаёт префикс). | Атрибуты: `method = RequestMethod.GET`, `produces = MediaType.APPLICATION_JSON_VALUE`, `consumes`. |
| **`@GetMapping`** | Сокращение для `@RequestMapping(method = GET)`. | Используйте их вместо `@RequestMapping` — это современный стиль. |
| **`@PostMapping`** | Аналогично для POST. | - |
| **`@PathVariable`** | Извлекает значение из шаблона URL: `/users/{id}`. | Может быть необязательным (`required = false`) с Java 8 Optional. |
| **`@RequestParam`** | Извлекает параметры строки запроса: `?name=John`. | Можно задать `defaultValue = "1"`. Обязателен по умолчанию (`required=true`). |
| **`@RequestBody`** | Преобразует **тело HTTP-запроса** (JSON/XML) в Java-объект. | Работает через `HttpMessageConverter` (обычно Jackson). |
| **`@ResponseBody`** | Указывает, что возвращаемое значение должно быть записано в тело ответа (а не в представление). | Стоит над методом; при `@RestController` нужна редко. |
| **`@ModelAttribute`** | Связывает параметры запроса с полями объекта (часто для форм). | Также может использоваться для подгрузки данных до вызова метода (например, загрузка сущности из БД). |
| **`@CrossOrigin`** | Для настройки CORS (разрешение запросов с других доменов). | Можно вешать и на класс, и на метод. |

**Киллер-фича для ответа**: 
*Спросите себя: "Можно ли заменить `@PathVariable` на `@RequestParam`?"* — Да, но `@PathVariable` нужен для RESTful-URL (идентификатор ресурса в пути), а `@RequestParam` — для фильтрации/пагинации.

---

### 3. Обработка ошибок (Глобальный и локальный подходы)

#### 3.1. Локальный `@ExceptionHandler`
- Пишется прямо внутри контроллера.
- Ловит исключения только из этого контроллера.
```java
@Controller
public class UserController {
    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<String> handleConflict(IllegalArgumentException ex) {
        return ResponseEntity.badRequest().body(ex.getMessage());
    }
}
```

#### 3.2. Глобальный `@ControllerAdvice` (AOP-перехват)
- Это **единый центр управления ошибками** для всего приложения.
- Может принимать `basePackages`, чтобы ограничить область действия.
```java
@ControllerAdvice
public class GlobalExceptionHandler {

    // Кастомная обработка
    @ExceptionHandler(UserNotFoundException.class)
    @ResponseStatus(HttpStatus.NOT_FOUND)
    public ErrorResponse handleNotFound(UserNotFoundException ex) {
        return new ErrorResponse("USER_NOT_FOUND", ex.getMessage());
    }

    // Обработка ошибок валидации (@Valid)
    @ExceptionHandler(MethodArgumentNotValidException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public Map<String, String> handleValidation(MethodArgumentNotValidException ex) {
        return ex.getBindingResult().getFieldErrors().stream()
            .collect(Collectors.toMap(
                FieldError::getField,
                FieldError::getDefaultMessage
            ));
    }
}
```

#### 3.3 Статус коды и `ResponseEntity`
- **Через аннотацию**: `@ResponseStatus(HttpStatus.NOT_FOUND)` над классом исключения.
- **Через объект**: `return ResponseEntity.status(HttpStatus.CONFLICT).body("Error");`
- **Через `@ControllerAdvice`**: возвращаете кастомный объект со статусом.

---

### 4. Бонусный блок (чтобы выделиться на собеседовании)

Добавьте эти темы в рассказ, и интервьюер поймёт, что вы знаете Spring глубоко.

#### 4.1. Валидация входных данных (`@Valid`)
- Вместе с `@RequestBody` используется `@Valid` (или `@Validated`).
- В DTO ставим `@NotNull`, `@Size`, `@Email` и т.д.
- Если валидация не пройдена — выбрасывается `MethodArgumentNotValidException`, которую мы ловим в `@ControllerAdvice`.

#### 4.2. `HttpMessageConverter` (как работает сериализация)
- Когда вы ставите `@ResponseBody`, Spring ищет подходящий конвертер по заголовку `Accept` клиента.
- `MappingJackson2HttpMessageConverter` преобразует Java-объект в JSON.
- Важно: если вы возвращаете сущность JPA (`@Entity`), может возникнуть проблема **LazyInitializationException** за пределами транзакции. Решение — DTO (Data Transfer Object).

#### 4.3. `HandlerInterceptor` (перехватчики)
- Это как фильтры, но на уровне Spring (работают *после* того, как DispatcherServlet нашёл контроллер, но *до* вызова метода).
- Позволяют делать аутентификацию, логирование, добавление общих атрибутов в `Model`.
- Отличаются от **Servlet Filter** тем, что имеют доступ к `ModelAndView` и информации о самом контроллере.

#### 4.4. Принцип работы с `Model` и `ViewResolver`
- Если метод возвращает `String` (например, `"userProfile"`), `ViewResolver` ищет файл `userProfile.jsp` или `userProfile.html`.
- В метод можно передать `Model model` и положить туда объекты: `model.addAttribute("user", user)`. На фронтенде к ним обращаются через `${user.name}`.

#### 4.5. REST vs Традиционный MVC
- **Традиционный**: возвращает страницу (HTML), использует `ViewResolver`, зависит от браузера.
- **REST**: возвращает данные (JSON/XML), аннотация `@RestController`, клиентом чаще всего является SPA (React/Angular) или мобильное приложение.

#### 4.6. Асинхронная обработка (для хардкорщины)
- Можно вернуть `Callable<T>` или `DeferredResult<T>`, чтобы освободить поток Tomcat на время длительной операции (например, запроса к внешнему API).
- Spring MVC держит соединение открытым, но обрабатывает ответ в отдельном потоке.

---

### Итоговый шаблон ответа на собеседовании:

> *"Spring MVC основан на DispatcherServlet, который работает как Front Controller. Сначала запрос попадает в HandlerMapping, который определяет контроллер, затем HandlerAdapter вызывает нужный метод. Для REST-контроллеров я использую `@RestController`, маппинг через `@GetMapping`, данные принимаю через `@RequestBody`, а идентификаторы через `@PathVariable`. Все ошибки централизованно обрабатываю через `@ControllerAdvice` с кастомными DTO для ошибок. Если нужно вернуть HTML — использую `@Controller` и `ViewResolver` (например, Thymeleaf). Дополнительно я всегда использую валидацию `@Valid` для DTO и конвертирую сущности в DTO, чтобы избежать проблем с ленивыми загрузками Hibernate. Для фильтрации запросов применяю `HandlerInterceptor`, а для глобальной конфигурации CORS — `@CrossOrigin`."*

Если спросят про жизненный цикл — рассказывайте последовательно, от входящего запроса до исходящего ответа. Удачи! Если хотите, можем перейти к следующей теме (например, **Spring Boot Autoconfiguration** или **Spring Security**).