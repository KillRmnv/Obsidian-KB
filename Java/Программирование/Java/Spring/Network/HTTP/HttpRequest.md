# 🧭 1. `java.net.http.HttpRequest` (Java 11+)

Это стандартный **HTTP-клиент** в Java без Spring, появившийся в **Java 11**.  
Используется вместе с `HttpClient` и `HttpResponse`.

---

### ✅ Пример:

```java
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;

public class SimpleClient {
    public static void main(String[] args) throws Exception {
        HttpClient client = HttpClient.newHttpClient();

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create("https://api.example.com/data"))
                .header("Authorization", "Bearer myToken")
                .GET()
                .build();

        HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());

        System.out.println(response.statusCode());
        System.out.println(response.body());
    }
}
```

---

### 📦 Основные методы билдера:

|Метод|Назначение|
|---|---|
|`.uri(URI)`|Устанавливает адрес|
|`.header(String, String)`|Добавляет заголовок|
|`.GET() / .POST(BodyPublisher)`|HTTP-метод|
|`.timeout(Duration)`|Таймаут запроса|
|`.build()`|Собирает объект|

---

### 📤 Пример POST с телом:

```java
HttpRequest request = HttpRequest.newBuilder()
        .uri(URI.create("https://api.example.com/users"))
        .header("Content-Type", "application/json")
        .POST(HttpRequest.BodyPublishers.ofString("{\"name\":\"Alex\"}"))
        .build();
```

---

### 📩 Ответ:

```java
HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
System.out.println(response.statusCode()); // 200
System.out.println(response.body());       // Тело ответа
```

---

## ⚙️ Отличия от Spring `RestTemplate`

|Критерий|`HttpClient` (Java 11)|`RestTemplate` (Spring)|
|---|---|---|
|Уровень|Низкоуровневый|Высокоуровневый|
|Сериализация JSON|❌ вручную|✅ автоматически|
|Multipart / Form|❌ вручную|✅ встроено|
|Простота|Прост, но многословен|Очень удобен|
|Асинхронность|✅ Поддерживается (`sendAsync`)|⚠️ Нет (только блокирующий)|

---

# 🧱 2. `org.springframework.http.HttpRequest` (Spring)

> Это интерфейс, который **описывает входящий HTTP-запрос** внутри Spring Framework.

Ты с ним сталкиваешься, если реализуешь фильтры, интерсепторы или обработчики (`HandlerInterceptor`, `ClientHttpRequestInterceptor`, и т.д.).

---

### 📦 Определение:

```java
public interface HttpRequest extends HttpMessage {
    HttpMethod getMethod();
    URI getURI();
}
```

`HttpMessage` даёт доступ к заголовкам и телу.

---

### ✅ Пример в `ClientHttpRequestInterceptor`:

```java
import org.springframework.http.HttpRequest;
import org.springframework.http.client.ClientHttpRequestExecution;
import org.springframework.http.client.ClientHttpRequestInterceptor;
import org.springframework.http.client.ClientHttpResponse;

import java.io.IOException;

public class AuthHeaderInterceptor implements ClientHttpRequestInterceptor {
    @Override
    public ClientHttpResponse intercept(
            HttpRequest request,
            byte[] body,
            ClientHttpRequestExecution execution
    ) throws IOException {

        request.getHeaders().add("Authorization", "Bearer myToken");
        return execution.execute(request, body);
    }
}
```

💡 Этот код внедряет токен в каждый исходящий запрос `RestTemplate`.

---

### 📥 Пример в серверной части:

Если ты хочешь получить `HttpRequest` (например, чтобы посмотреть заголовки или URI запроса) — можно использовать **`HttpServletRequest`**, а не `HttpRequest`.

```java
@GetMapping("/info")
public ResponseEntity<?> showInfo(HttpServletRequest request) {
    return ResponseEntity.ok(Map.of(
        "method", request.getMethod(),
        "url", request.getRequestURL().toString(),
        "headers", Collections.list(request.getHeaderNames())
    ));
}
```

---

# 🧩 Сводная таблица

|Класс|Где используется|Что делает|Пример|
|---|---|---|---|
|`java.net.http.HttpRequest`|В чистой Java (11+)|Клиент для HTTP-запросов|`HttpClient.send(request, ...)`|
|`org.springframework.http.HttpRequest`|Внутри Spring (RestTemplate, interceptors)|Представление HTTP-запроса (метод, URI, заголовки)|В `ClientHttpRequestInterceptor`|
|`jakarta.servlet.http.HttpServletRequest`|На сервере (в контроллерах)|Представляет входящий HTTP-запрос от клиента|`@RequestMapping`|

---

# ⚡ В двух словах:

- `HttpEntity` → тело + заголовки
    
- `HttpRequest` → метаинформация о запросе (URI, метод, заголовки)
    
- `HttpResponse` → ответ от сервера
    
- `RestTemplate` / `HttpClient` → отправляют `HttpRequest` и возвращают `HttpResponse`
    

---

Хочешь, я покажу диаграмму “жизненного цикла” HTTP-запроса в Spring — от контроллера до RestTemplate (включая `HttpRequest`, `HttpEntity` и `ResponseEntity`)? Это поможет понять, кто где участвует в цепочке.