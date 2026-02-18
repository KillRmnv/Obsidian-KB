

## 1️⃣ `HttpSecurity`

- Класс из пакета `org.springframework.security.config.annotation.web.builders.HttpSecurity`.
    
- Используется для **конфигурации веб-безопасности HTTP-запросов**.
    
- Позволяет настраивать:
    
    - CSRF
        
    - CORS
        
    - Авторизацию
        
    - Аутентификацию
        
    - Фильтры
        
    - Политику сессий
        
- Он используется в **методе `configure(HttpSecurity http)`**, который переопределяется в классе `WebSecurityConfigurerAdapter` (до Spring Security 5.7) или через `SecurityFilterChain` (в новых версиях Spring Security).
    

---

## 2️⃣ Цепочка методов

Методы в цепочке — это **билдеры**, которые конфигурируют HTTP-безопасность. Разберём твой пример по шагам:

---

### 🔹 1. `http.csrf().disable()`

- Отключает **CSRF-защиту** (Cross-Site Request Forgery).
    
- Обычно делают для **REST API**, где нет сессий и браузерных форм.
    

```java
http.csrf().disable();
```

---

### 🔹 2. `cors()`

- Включает поддержку **CORS** (Cross-Origin Resource Sharing)
    
- Позволяет фронтенду с другого домена делать запросы к API.
    
- Нужно настраивать через `CorsConfigurationSource` при необходимости.
    

```java
http.cors();
```

---

### 🔹 3. `exceptionHandling().authenticationEntryPoint(...)`

- Настраивает **обработку ошибок аутентификации**.
    
- `HttpStatusEntryPoint(HttpStatus.UNAUTHORIZED)` → возвращает 401, если пользователь не аутентифицирован.
    

```java
.exceptionHandling()
    .authenticationEntryPoint(new HttpStatusEntryPoint(HttpStatus.UNAUTHORIZED))
```

---

### 🔹 4. `sessionManagement().sessionCreationPolicy(SessionCreationPolicy.STATELESS)`

- Конфигурирует политику сессий.
    
- `STATELESS` → **нет хранения сессий** на сервере, идеально для JWT.
    

```java
.sessionManagement()
    .sessionCreationPolicy(SessionCreationPolicy.STATELESS)
```

---

### 🔹 5. `authorizeRequests()`

- Настраивает **доступ к URL**.
    
- Методы цепочки:
    

|Метод|Что делает|
|---|---|
|`antMatchers(HttpMethod.OPTIONS).permitAll()`|Разрешает все OPTIONS-запросы (для CORS preflight)|
|`antMatchers("/graphiql").permitAll()`|Доступ к GraphiQL без авторизации|
|`antMatchers(HttpMethod.GET, "/articles/feed").authenticated()`|GET `/articles/feed` только для авторизованных|
|`anyRequest().authenticated()`|Все остальные запросы требуют авторизации|

> `antMatchers` можно комбинировать с `permitAll()`, `authenticated()`, `hasRole()`, `hasAuthority()`.

---

### 🔹 6. `http.addFilterBefore(jwtTokenFilter(), UsernamePasswordAuthenticationFilter.class)`

- Добавляет **кастомный фильтр** (`JwtTokenFilter`) **перед стандартным фильтром аутентификации по username/password**.
    
- Это нужно, чтобы JWT обрабатывался **до** фильтров Spring Security, которые проверяют авторизацию.
    

```java
http.addFilterBefore(jwtTokenFilter(), UsernamePasswordAuthenticationFilter.class);
```

---

## 3️⃣ Визуальная цепочка

Можно представить так:

```
HTTP request
 ├─ CSRF disabled
 ├─ CORS enabled
 ├─ Exception handling → 401 if unauthorized
 ├─ Stateless session
 ├─ URL rules (antMatchers)
 │    ├─ /users/login → permitAll
 │    ├─ /articles/feed → authenticated
 │    └─ ... 
 ├─ JwtTokenFilter → проверка JWT
 └─ UsernamePasswordAuthenticationFilter → проверка логина/пароля
```

---

## 4️⃣ Важно

- `HttpSecurity` — **билдер**, каждый метод возвращает объект для дальнейшей конфигурации.
    
- Цепочка читается **слева направо**: сначала настройки, потом фильтры, потом правила URL.
    
- После Spring Security 5.7 `WebSecurityConfigurerAdapter` устарел,  
    сейчас используется `SecurityFilterChain` через `@Bean`.
    

---

Если хочешь, я могу сделать **схему с порядком фильтров и цепочкой методов `HttpSecurity`**,  
чтобы наглядно видеть, что происходит при каждом HTTP-запросе.

Хочешь такую схему?