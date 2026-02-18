
## 1️⃣ Расшифровка

**CORS** = **Cross-Origin Resource Sharing**  
→ «Совместное использование ресурсов между разными источниками (доменами)».

- **Origin (источник)** = схема + домен + порт.  
    Примеры:
    
    - `http://localhost:8080`
        
    - `https://example.com`
        
- **Cross-Origin** — когда веб-страница делает запрос на **другой origin**.
    

Пример:

```javascript
fetch("http://api.example.com/data") // JS на http://localhost:3000
```

- Браузер блокирует такие запросы **по умолчанию** из-за политики **Same-Origin Policy (SOP)**.
    
- CORS позволяет браузеру разрешить такие запросы.
    

---

## 2️⃣ Почему нужен CORS

Без CORS:

- JS на `localhost:3000` не может обращаться к API на `localhost:8080`.
    
- Браузер вернёт ошибку:
    
    ```
    Access to fetch at 'http://localhost:8080/data' from origin 'http://localhost:3000' has been blocked by CORS policy.
    ```
    

CORS добавляет специальные HTTP-заголовки, чтобы сервер говорил:

> «Я разрешаю этому другому домену делать запросы к моему API».

---

## 3️⃣ Основные HTTP-заголовки CORS

|Заголовок|Что делает|
|---|---|
|`Access-Control-Allow-Origin`|Какие домены разрешены|
|`Access-Control-Allow-Methods`|Какие HTTP-методы разрешены (GET, POST, PUT...)|
|`Access-Control-Allow-Headers`|Какие заголовки разрешены в запросе (Content-Type, Authorization…)|
|`Access-Control-Allow-Credentials`|Разрешить cookies и HTTP-авторизацию|
|`Access-Control-Expose-Headers`|Какие заголовки можно читать JS-коду|
|`Access-Control-Max-Age`|Время кеширования preflight запроса|

---

## 4️⃣ Preflight-запросы

- Если JS делает **непростой запрос** (например, с Authorization или методом PUT/DELETE), браузер сначала отправляет **OPTIONS-запрос** (preflight) к серверу.
    
- Сервер должен ответить с разрешением, иначе браузер **не выполнит основной запрос**.
    

Пример preflight:

```
OPTIONS /api/data HTTP/1.1
Origin: http://localhost:3000
Access-Control-Request-Method: POST
Access-Control-Request-Headers: Content-Type, Authorization
```

Ответ сервера:

```
HTTP/1.1 200 OK
Access-Control-Allow-Origin: http://localhost:3000
Access-Control-Allow-Methods: POST
Access-Control-Allow-Headers: Content-Type, Authorization
```

---

## 5️⃣ CORS в Spring

- **Spring MVC**: через `WebMvcConfigurer` → `addCorsMappings`
    
- **Spring Security**: через `http.cors()` и `CorsConfigurationSource`
    

Пример (разрешаем все домены, JWT без cookies):

```java
@Bean
public CorsConfigurationSource corsConfigurationSource() {
    CorsConfiguration configuration = new CorsConfiguration();
    configuration.setAllowedOrigins(List.of("*"));
    configuration.setAllowedMethods(List.of("GET","POST","PUT","DELETE","OPTIONS"));
    configuration.setAllowedHeaders(List.of("Authorization","Content-Type"));
    configuration.setAllowCredentials(false);
    UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
    source.registerCorsConfiguration("/**", configuration);
    return source;
}
```

---

## 1️⃣ Первый пример — `CorsConfigurationSource`

```java
@Bean
public CorsConfigurationSource corsConfigurationSource() {
    final CorsConfiguration configuration = new CorsConfiguration();
    configuration.setAllowedOrigins(asList("*"));
    configuration.setAllowedMethods(asList("HEAD", "GET", "POST", "PUT", "DELETE", "PATCH"));
    configuration.setAllowCredentials(false);
    configuration.setAllowedHeaders(asList("Authorization", "Cache-Control", "Content-Type"));
    final UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
    source.registerCorsConfiguration("/**", configuration);
    return source;
}
```

### 🔹 Что делает

1. Разрешает все домены: `*` → любой сайт может обращаться к API.
    
2. Разрешает методы: HEAD, GET, POST, PUT, DELETE, PATCH.
    
3. `setAllowCredentials(false)` — **не разрешает cookies/credentials**.
    
    - Если включить `true` и оставить `*` в allowedOrigins → ошибка браузера.
        
4. Разрешает только определённые заголовки: Authorization, Cache-Control, Content-Type.
    
5. Применяется ко всем URL (`/**`).
    

### 🔹 Особенности

- Строго контролирует, какие заголовки можно отправлять.
    
- Полезно для **REST API без сессий** (JWT).
    
- Не позволяет использовать cookies или HTTP-auth.
    

---

## 2️⃣ Второй пример — `WebMvcConfigurer`

```java
@Bean
public WebMvcConfigurer corsConfigurer() {
    return new WebMvcConfigurer() {
        @Override
        public void addCorsMappings(CorsRegistry registry) {
            registry.addMapping("/**")
                    .allowedOrigins(
                            "http://localhost:8084",
                            "http://localhost:8080",
                            "http://localhost:8081",
                            "http://localhost:8082"
                    )
                    .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                    .allowedHeaders("*")
                    .allowCredentials(true);
        }
    };
}
```

### 🔹 Что делает

1. Разрешает **конкретные домены** (localhost:8080–8084).
    
2. Разрешает методы: GET, POST, PUT, DELETE, OPTIONS.
    
3. Разрешает **все заголовки** (`*`).
    
4. `allowCredentials(true)` → разрешает cookies и HTTP-auth.
    
5. Применяется ко всем URL (`/**`).
    

### 🔹 Особенности

- Подходит, когда фронтенд **отдельный домен** и использует авторизацию по cookies.
    
- Безопаснее, чем `*` в allowedOrigins с credentials.
    
- Удобно для локальной разработки с несколькими фронтенд-серверами.
    

---

## 3️⃣ Главные различия

|Характеристика|CorsConfigurationSource|WebMvcConfigurer|
|---|---|---|
|Allowed origins|`*` (все)|Конкретные домены|
|Credentials|`false`|`true`|
|Allowed headers|Список (`Authorization`, `Content-Type`)|Все (`*`)|
|Подходит для|Stateless API (JWT)|API с cookies/session|
|Способ настройки|Spring Security|Spring MVC (Controller layer)|
