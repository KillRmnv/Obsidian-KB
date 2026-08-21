# Управление Cookies в Selenium (Java)

> **Теги:** `#selenium` `#cookies` `#управление_сессией` `#java`  
> **Актуально для:** Selenium 4.x

##  Что такое Cookies?

Cookies — это небольшие фрагменты данных, которые сервер отправляет в браузер и которые сохраняются на стороне клиента. Они используются для управления сессиями, запоминания настроек пользователя, отслеживания и аутентификации.

В Selenium работа с cookies позволяет:
- Быстро авторизоваться без прохождения формы логина.
- Настраивать состояние сессии перед началом теста.
- Проверять, что сервер правильно устанавливает cookies.

---

##  Основные методы управления cookies

Все методы доступны через `driver.manage().cookies()`:

| Метод | Описание |
|-------|----------|
| `getCookies()` | Возвращает все cookies (Set<Cookie>) |
| `getCookieNamed(String name)` | Возвращает cookie по имени (Cookie) |
| `addCookie(Cookie cookie)` | Добавляет новый cookie |
| `deleteCookie(Cookie cookie)` | Удаляет указанный cookie |
| `deleteCookieNamed(String name)` | Удаляет cookie по имени |
| `deleteAllCookies()` | Удаляет все cookies |
| `getCookie(String name)` | Алиас для `getCookieNamed()` |

---

##  Класс Cookie

Класс `Cookie` представляет один cookie. Конструкторы и основные методы:

```java
// Создание cookie
Cookie cookie = new Cookie("key", "value");

// С расширенными параметрами
Cookie cookie = new Cookie.Builder("sessionId", "abc123")
    .domain("example.com")
    .path("/")
    .expiresOn(new Date(System.currentTimeMillis() + 3600000))
    .isSecure(true)
    .isHttpOnly(true)
    .build();
```

**Основные поля:**
- `name` — имя cookie.
- `value` — значение.
- `domain` — домен, для которого действителен cookie (опционально).
- `path` — путь, для которого действителен cookie (по умолчанию "/").
- `expiry` — дата истечения срока действия (опционально).
- `isSecure` — только для HTTPS.
- `isHttpOnly` — недоступен для JavaScript.

---

##  Практические примеры

### Получение всех cookies

```java
Set<Cookie> cookies = driver.manage().getCookies();
for (Cookie cookie : cookies) {
    System.out.println("Имя: " + cookie.getName());
    System.out.println("Значение: " + cookie.getValue());
    System.out.println("Домен: " + cookie.getDomain());
    System.out.println("---");
}
```

### Получение конкретного cookie

```java
Cookie sessionCookie = driver.manage().getCookieNamed("sessionId");
if (sessionCookie != null) {
    System.out.println("Session ID: " + sessionCookie.getValue());
} else {
    System.out.println("Cookie не найден");
}
```

### Добавление cookie (авторизация без логина)

```java
// Добавить cookie для аутентификации
driver.get("https://example.com"); // Сначала зайти на сайт
driver.manage().addCookie(new Cookie("sessionId", "xyz789"));

// Обновить страницу, чтобы cookie применился
driver.navigate().refresh();
```

### Удаление cookie

```java
// По объекту
Cookie cookie = driver.manage().getCookieNamed("sessionId");
if (cookie != null) {
    driver.manage().deleteCookie(cookie);
}

// По имени
driver.manage().deleteCookieNamed("sessionId");

// Удалить все
driver.manage().deleteAllCookies();
```

---

##  Практический кейс: быстрая авторизация

Вместо того чтобы каждый раз проходить форму логина, можно добавить cookies после первого успешного входа.

```java
public void loginWithCookies(WebDriver driver) {
    // Сохраняем cookies в файл или переменную
    Set<Cookie> cookies = driver.manage().getCookies();
    
    // В следующем тесте загружаем их
    driver.get("https://example.com");
    for (Cookie cookie : cookies) {
        driver.manage().addCookie(cookie);
    }
    driver.navigate().refresh(); // Обновляем страницу, чтобы применить
}
```

** Важно:** Не все cookies можно сохранять между сессиями — некоторые имеют ограничение по времени жизни или привязаны к конкретной сессии браузера.

---

##  Важные нюансы

1. **Сначала перейдите на сайт** — перед добавлением cookies нужно зайти на целевой домен:
   ```java
   driver.get("https://example.com");
   driver.manage().addCookie(new Cookie("key", "value"));
   ```

2. **Домен должен совпадать** — нельзя добавить cookie для `example.com`, если вы находитесь на `google.com`.

3. **Безопасность (Secure)** — если у cookie есть флаг `Secure`, его нельзя добавить через HTTP; нужен HTTPS.

4. **HttpOnly** — cookie с флагом `HttpOnly` не доступны через JavaScript, но Selenium может ими управлять.

5. **Срок действия** — истёкшие cookies игнорируются при добавлении.

---

##  Шпаргалка (быстрый поиск)

| Сценарий | Код |
|----------|-----|
| Получить все cookies | `driver.manage().getCookies();` |
| Получить cookie по имени | `driver.manage().getCookieNamed("sessionId");` |
| Добавить cookie | `driver.manage().addCookie(new Cookie("key", "value"));` |
| Удалить cookie по имени | `driver.manage().deleteCookieNamed("sessionId");` |
| Удалить все cookies | `driver.manage().deleteAllCookies();` |
| Удалить cookie по объекту | `driver.manage().deleteCookie(cookie);` |
| Проверить существование cookie | `driver.manage().getCookieNamed("key") != null` |

---

##  Полезные ссылки

- [Selenium Docs — Cookies](https://www.selenium.dev/documentation/webdriver/browser/cookies/)
- [MDN — Cookies](https://developer.mozilla.org/en-US/docs/Web/HTTP/Cookies)
