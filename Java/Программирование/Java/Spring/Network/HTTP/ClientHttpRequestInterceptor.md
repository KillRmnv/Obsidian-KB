## 🧱 Что это такое

Интерфейс:

`public interface ClientHttpRequestInterceptor {     ClientHttpResponse intercept(         HttpRequest request,         byte[] body,         ClientHttpRequestExecution execution     ) throws IOException; }`

То есть у тебя есть **3 участника**:

|Параметр|Что это|
|---|---|
|`HttpRequest request`|Исходящий HTTP-запрос (метод, URL, заголовки)|
|`byte[] body`|Тело запроса в виде байтов|
|`ClientHttpRequestExecution execution`|Механизм, который отправляет запрос дальше по цепочке (или реально делает HTTP-запрос)|

---

## 🧩 Как это работает

Каждый `RestTemplate` может содержать **цепочку перехватчиков**, которые вызываются **до** и/или **после** реального запроса.

Ты можешь:

- добавить заголовки (например `Authorization`);
    
- логировать тело и ответ;
    
- изменять URL;
    
- повторять запросы (retry);
    
- кэшировать ответы.
    

---

## ✅ Пример: добавить авторизацию ко всем запросам

`import org.springframework.http.HttpRequest; import org.springframework.http.client.ClientHttpRequestExecution; import org.springframework.http.client.ClientHttpRequestInterceptor; import org.springframework.http.client.ClientHttpResponse;  import java.io.IOException;  public class AuthInterceptor implements ClientHttpRequestInterceptor {     private final String token;      public AuthInterceptor(String token) {         this.token = token;     }      @Override     public ClientHttpResponse intercept(             HttpRequest request, byte[] body, ClientHttpRequestExecution execution) throws IOException {          // Добавляем заголовок         request.getHeaders().add("Authorization", "Bearer " + token);          // Продолжаем выполнение цепочки         return execution.execute(request, body);     } }`

---

## 🧩 Регистрируем интерцептор в `RestTemplate`

`import org.springframework.context.annotation.Bean; import org.springframework.context.annotation.Configuration; import org.springframework.web.client.RestTemplate;  import java.util.List;  @Configuration public class RestTemplateConfig {      @Bean     public RestTemplate restTemplate() {         RestTemplate restTemplate = new RestTemplate();          restTemplate.setInterceptors(List.of(                 new AuthInterceptor("my_secret_token")         ));          return restTemplate;     } }`

Теперь любой `restTemplate.postForEntity(...)` автоматически добавит токен 🔐

---

## ⚙️ Пример логирования всех исходящих запросов

`public class LoggingInterceptor implements ClientHttpRequestInterceptor {     @Override     public ClientHttpResponse intercept(             HttpRequest request, byte[] body, ClientHttpRequestExecution execution) throws IOException {          System.out.println("➡️ Request: " + request.getMethod() + " " + request.getURI());         System.out.println("Headers: " + request.getHeaders());         System.out.println("Body: " + new String(body));          ClientHttpResponse response = execution.execute(request, body);          System.out.println("⬅️ Response: " + response.getStatusCode());          return response;     } }`

---

## 💡 Цепочка вызовов

Если у тебя несколько интерцепторов, Spring вызывает их **в порядке добавления**:

`Request → [Interceptor1] → [Interceptor2] → [HTTP Client]                                ↑                         Response возвращается`

То есть ты можешь делать, например:

1. `AuthInterceptor` — добавляет токен
    
2. `LoggingInterceptor` — логирует запрос и ответ
    
3. `RetryInterceptor` — повторяет при 500 ошибке
    

---

## ⚠️ Разница с серверным `HandlerInterceptor`

| Тип                            | Где работает                  | Что делает                      |
| ------------------------------ | ----------------------------- | ------------------------------- |
| `ClientHttpRequestInterceptor` | На клиенте (в `RestTemplate`) | Перехватывает исходящие запросы |
| `HandlerInterceptor`           | На сервере (в Spring MVC)     | Перехватывает входящие запросы  |