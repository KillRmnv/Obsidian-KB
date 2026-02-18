## 🚪 Что такое `HandlerInterceptor`

`HandlerInterceptor` — это интерфейс, который позволяет **перехватывать и обрабатывать входящие HTTP-запросы** на уровне **Spring MVC** до, после или вокруг выполнения контроллера.

Простыми словами:

> Это "прослойка" между клиентом и контроллером, которая может логировать, проверять авторизацию, измерять время, изменять ответ и т.д.

---

## 🧱 Интерфейс

`public interface HandlerInterceptor {     default boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {         return true;     }      default void postHandle(HttpServletRequest request, HttpServletResponse response, Object handler,                             @Nullable ModelAndView modelAndView) throws Exception {     }      default void afterCompletion(HttpServletRequest request, HttpServletResponse response, Object handler,                                  @Nullable Exception ex) throws Exception {     } }`

### 🔹 1. `preHandle(...)`

- Вызывается **перед** вызовом метода контроллера.
    
- Возвращает `true`, если нужно продолжить обработку, или `false`, чтобы **прервать запрос**.
    
- Здесь делают:
    
    - проверку токена / авторизацию;
        
    - логирование;
        
    - проверку CORS, параметров и т.д.
        

### 🔹 2. `postHandle(...)`

- Вызывается **после** контроллера, но **до рендера View** (или до отправки JSON).
    
- Можно **изменить `ModelAndView`** (если используется MVC, не REST).
    
- Используется для добавления данных в ответ, логов и т.п.
    

### 🔹 3. `afterCompletion(...)`

- Вызывается **после завершения запроса**, даже если была ошибка.
    
- Хорошо подходит для:
    
    - очистки ресурсов;
        
    - метрик;
        
    - логирования времени выполнения.
        

---

## ✅ Пример: логирование всех запросов

`import jakarta.servlet.http.HttpServletRequest; import jakarta.servlet.http.HttpServletResponse; import org.springframework.web.servlet.HandlerInterceptor; import org.springframework.stereotype.Component;  @Component public class LoggingInterceptor implements HandlerInterceptor {      @Override     public boolean preHandle(HttpServletRequest request,                              HttpServletResponse response,                              Object handler) {          System.out.println("➡️ Request: " + request.getMethod() + " " + request.getRequestURI());         return true; // продолжаем выполнение     }      @Override     public void afterCompletion(HttpServletRequest request,                                 HttpServletResponse response,                                 Object handler,                                 Exception ex) {         System.out.println("⬅️ Response: " + response.getStatus());     } }`

---

## ⚙️ Регистрируем перехватчик

Интерцепторы регистрируются в **WebMvcConfigurer**:

`import org.springframework.context.annotation.Configuration; import org.springframework.web.servlet.config.annotation.InterceptorRegistry; import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;  @Configuration public class WebConfig implements WebMvcConfigurer {      private final LoggingInterceptor loggingInterceptor;      public WebConfig(LoggingInterceptor loggingInterceptor) {         this.loggingInterceptor = loggingInterceptor;     }      @Override     public void addInterceptors(InterceptorRegistry registry) {         registry.addInterceptor(loggingInterceptor)                 .addPathPatterns("/api/**")   // применить только к /api/                 .excludePathPatterns("/api/auth/**"); // исключить аутентификацию     } }`

---

## 🧩 Пример: проверка API-ключа в заголовке

`@Component public class ApiKeyInterceptor implements HandlerInterceptor {      @Value("${api.key}")     private String expectedKey;      @Override     public boolean preHandle(HttpServletRequest request,                              HttpServletResponse response,                              Object handler) throws IOException {         String key = request.getHeader("X-API-KEY");         if (!expectedKey.equals(key)) {             response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);             response.getWriter().write("Invalid API key");             return false; // прервать выполнение         }         return true;     } }`

---

## 🧭 Цепочка вызовов

Если несколько интерцепторов:

`Client → [Interceptor1.preHandle()]          → [Interceptor2.preHandle()]         → Controller         ← [Interceptor2.postHandle()]         ← [Interceptor1.postHandle()]         ← Response`

---

## 🧰 HandlerInterceptor vs Filter

|Критерий|`HandlerInterceptor`|`Filter`|
|---|---|---|
|Уровень|Spring MVC|Servlet API|
|Контекст|Только Spring контроллеры|Все запросы (включая статические ресурсы)|
|Использует|`HandlerMethod`|`ServletRequest` / `ServletResponse`|
|Легче интегрировать с Spring|✅ Да|⚙️ Нужно больше кода|
|Для чего лучше|Авторизация, логирование, метрики|Кэш, CORS, gzip, raw доступ|

---

## 💡 Применение в реальных проектах

|Сценарий|Что делает `HandlerInterceptor`|
|---|---|
|🔐 Проверка токена|Проверяет JWT перед каждым запросом|
|🧭 Логирование|Логирует метод, URL, время, статус|
|⏱️ Метрики|Измеряет время выполнения|
|🧹 Очистка контекста|После завершения запроса очищает ThreadLocal|
|🧾 Добавление заголовков|Добавляет кастомные headers в ответ|