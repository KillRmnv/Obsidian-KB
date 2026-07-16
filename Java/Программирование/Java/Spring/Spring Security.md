## Spring Security — полный разбор для собеседования

Spring Security — это мощный и расширяемый фреймворк для аутентификации, авторизации и защиты приложений. На собеседовании важно не перечислить аннотации, а показать понимание **архитектуры фильтров**, **потока запроса**, а также уметь объяснить разницу между `Authentication` и `Authorization`, ролями и правами.

---

### 1. Базовая идея: фильтр‑цепочка (`SecurityFilterChain`)

Spring Security построен на **цепочке сервлетных фильтров**. Каждый HTTP-запрос проходит через эту цепочку, где каждый фильтр выполняет свою задачу:

- Проверка аутентификации (например, `UsernamePasswordAuthenticationFilter`).
- Проверка CSRF-токена (`CsrfFilter`).
- Проверка авторизации (`AuthorizationFilter` / `FilterSecurityInterceptor`).
- Обработка логина/логаута, сохранение сессии и т.д.

Все фильтры управляются через **`SecurityFilterChain`** — это конфигурация, которая определяет, какие фильтры применяются к каким URL-паттернам. В Spring Boot по умолчанию создаётся одна цепочка, но можно создавать несколько для разных частей приложения.

**`Authentication`** — процесс проверки, кто ты (предоставление учётных данных).  
**`Authorization`** — проверка, имеешь ли ты право выполнять данное действие (проверка ролей/прав).

---

### 2. Настройка простой формы логина или Basic Auth

#### 2.1. Базовая конфигурация (Java Config)

Современный способ — наследоваться от `SecurityFilterChain` или использовать `@Bean` для `SecurityFilterChain`. В новых версиях (Spring Security 5.7+) рекомендуется **компонентный подход** вместо наследования от `WebSecurityConfigurerAdapter` (устарел).

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests(authz -> authz
                .requestMatchers("/public/**").permitAll()
                .anyRequest().authenticated()
            )
            .formLogin(form -> form
                .loginPage("/login")
                .defaultSuccessUrl("/dashboard")
                .permitAll()
            )
            .logout(logout -> logout.permitAll())
            .httpBasic(); // или .httpBasic(withDefaults()) для Basic Auth
        return http.build();
    }
}
```

- **`authorizeHttpRequests`** — определяет правила доступа по URL.
- **`formLogin`** — включает стандартную страницу логина (или кастомную).
- **`httpBasic`** — включает HTTP Basic аутентификацию (передача `Authorization: Basic base64(login:password)`).

#### 2.2. `UserDetailsService` — загрузка пользователей

`UserDetailsService` — это интерфейс, который загружает данные пользователя по логину. В реальных проектах вы реализуете его для работы с БД.

```java
@Service
public class CustomUserDetailsService implements UserDetailsService {

    @Autowired
    private UserRepository userRepository;

    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        User user = userRepository.findByEmail(username)
            .orElseThrow(() -> new UsernameNotFoundException("User not found"));

        // Возвращаем объект, реализующий UserDetails (можно использовать встроенный User)
        return org.springframework.security.core.userdetails.User
            .withUsername(user.getEmail())
            .password(user.getPassword())
            .authorities("ROLE_USER") // или authorities из БД
            .build();
    }
}
```

#### 2.3. `PasswordEncoder` — хеширование паролей

Никогда не храните пароли в открытом виде. Spring предоставляет множество реализаций:

- `BCryptPasswordEncoder` (рекомендуется) — стойкое хеширование с солью.
- `Pbkdf2PasswordEncoder`, `SCryptPasswordEncoder`, а также `NoOpPasswordEncoder` (только для тестов).

Пример настройки:

```java
@Bean
public PasswordEncoder passwordEncoder() {
    return new BCryptPasswordEncoder();
}
```

При регистрации пользователя пароль кодируется: `passwordEncoder.encode(rawPassword)`. При проверке Spring сам сравнивает через `matches()`.

---

### 3. Роли vs Authorities и аннотации

#### 3.1. Разница между ролями и правами

- **Authority (право)** — это конкретное разрешение, например, `READ_PRIVILEGES`, `WRITE_PRIVILEGES`. Это строка, которая может быть любой.
- **Role (роль)** — это группа прав. В Spring Security роль — это authority с префиксом `ROLE_`. Например, `ROLE_ADMIN`, `ROLE_USER`.

На практике чаще используют роли, потому что они удобнее для группировки. Но можно использовать и отдельные authority.

#### 3.2. Аннотации для авторизации на уровне методов

Включаются через `@EnableMethodSecurity` (вместо устаревшего `@EnableGlobalMethodSecurity`).

```java
@Configuration
@EnableMethodSecurity
public class MethodSecurityConfig { }
```

- **`@PreAuthorize`** — выполняет проверку **перед** вызовом метода. Поддерживает SpEL (Spring Expression Language).
  
  ```java
  @PreAuthorize("hasRole('ADMIN') or #userId == authentication.principal.id")
  public void updateUser(Long userId, UserData data) { ... }
  ```

- **`@Secured`** — более старая аннотация, проверяет наличие перечисленных ролей/прав. Не поддерживает сложные выражения (только простой список).
  
  ```java
  @Secured({"ROLE_ADMIN", "ROLE_MANAGER"})
  public void deleteUser(Long id) { ... }
  ```

- Также есть `@PostAuthorize` (проверка после выполнения, например, на основе возвращённого объекта) и `@PostFilter`/`@PreFilter` для фильтрации коллекций.

**Важно**: Чтобы работали аннотации, бины должны быть проксированы (обычно через CGLIB или JDK-прокси). Проверка работает через AOP-перехватчики.

---

### 4. Дополнительные важные моменты (для звёздного ответа)

- **`SecurityContext` и `SecurityContextHolder`** — хранит информацию об аутентифицированном пользователе (в рамках потока). Можно получить через `SecurityContextHolder.getContext().getAuthentication()`.
- **CSRF (Cross-Site Request Forgery)** — защита включена по умолчанию для stateful приложений. Отключается для REST API (если используете JWT/токены).
- **CORS (Cross-Origin Resource Sharing)** — настраивается через `http.cors()`.
- **OAuth2 / JWT** — современный подход для микросервисов и SPA. Spring Security поддерживает `OAuth2ResourceServer` и `OAuth2Login`. Валидация JWT происходит через `JwtDecoder`.
- **Безопасность сессий** — можно управлять политикой сессий (`SessionCreationPolicy.STATELESS` для REST).
- **Поток запроса через фильтры**:
  1. Запрос → `SecurityContextPersistenceFilter` (восстанавливает контекст из сессии).
  2. `UsernamePasswordAuthenticationFilter` (при логине).
  3. `AuthorizationFilter` / `FilterSecurityInterceptor` — проверяет правила доступа.
  4. Если авторизация не пройдена — `AccessDeniedException` → обработчик ошибок.
  5. Иначе запрос идёт к вашему контроллеру.

---

### 5. Итоговый скрипт для собеседования

> *"Spring Security основан на цепочке фильтров, где каждый фильтр отвечает за конкретную задачу: аутентификацию, авторизацию, CSRF, логирование и т.д. В конфигурации через `SecurityFilterChain` я определяю правила доступа к URL, включаю форму логина или HTTP Basic, подключаю `UserDetailsService` для загрузки пользователей из БД и обязательно использую `BCryptPasswordEncoder` для хеширования паролей. Разделяю понятия ролей (с префиксом ROLE_) и прав (authorities). Для защиты методов использую `@PreAuthorize` с SpEL-выражениями, например, `hasRole('ADMIN')` или проверку ID пользователя. В современных проектах часто применяю JWT для stateless аутентификации, отключаю CSRF и управляю сессиями. Также всегда настраиваю обработку исключений (`AccessDeniedHandler`, `AuthenticationEntryPoint`) для возврата кастомных JSON-ответов."*

Если спросят про разницу между `@PreAuthorize` и `@Secured` — скажите, что `@PreAuthorize` гибче, т.к. позволяет использовать сложные условия и встроенные объекты (`authentication`, `#param`), тогда как `@Secured` только проверяет наличие ролей.

Можем перейти к следующей теме: **REST API, HTTP-статусы, пагинация, валидация, документация (Swagger)** или к **Микросервисам / Spring Cloud**. Какую тему дальше?