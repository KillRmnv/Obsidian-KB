Отлично, теперь понял. Речь идет не про `doGet()`/`doPost()`, а про **инструментарий** — конкретные методы объектов `request` и `response`, которые позволяют работать с HTTP-протоколом на низком уровне: читать заголовки, устанавливать коды, писать тело ответа.

Вот полный набор методов для работы с HTTP.

---

##  Работа с запросом (HttpServletRequest)

Когда приходит HTTP-запрос, контейнер создает объект `HttpServletRequest`. Через него можно извлечь всё, что прислал клиент.

### 1. Чтение заголовков (Headers)
Заголовки — это мета-информация запроса (User-Agent, Accept, Cookie, Referer и т.д.).

| Метод | Назначение | Пример |
| :--- | :--- | :--- |
| `String getHeader(String name)` | Получить значение конкретного заголовка. | `String ua = request.getHeader("User-Agent");` |
| `Enumeration<String> getHeaders(String name)` | Если заголовков с одним именем несколько (например, `Accept-Language`). | `Enumeration<String> langs = request.getHeaders("Accept-Language");` |
| `Enumeration<String> getHeaderNames()` | Получить имена **всех** заголовков запроса. | Для отладки или логирования. |
| `int getIntHeader(String name)` | Удобно, если заголовок — число (например, `Content-Length`). | `int size = request.getIntHeader("Content-Length");` |
| `long getDateHeader(String name)` | Если заголовок содержит дату (`If-Modified-Since`). | `long date = request.getDateHeader("If-Modified-Since");` |

### 2. Чтение тела запроса (Body)
Если клиент прислал данные (в `POST`, `PUT`), их нужно читать как поток.

| Метод | Назначение | Когда использовать |
| :--- | :--- | :--- |
| `ServletInputStream getInputStream()` | Получить поток для чтения **бинарных** данных. | Загрузка файлов, сырой JSON/XML. |
| `BufferedReader getReader()` | Получить ридер для чтения **текстовых** данных. | Данные форм (`application/x-www-form-urlencoded`) или текст. |

```java
// Пример чтения JSON-строки из тела POST-запроса
BufferedReader reader = request.getReader();
StringBuilder jsonBody = new StringBuilder();
String line;
while ((line = reader.readLine()) != null) {
    jsonBody.append(line);
}
// Теперь jsonBody.toString() содержит JSON
```

### 3. Параметры запроса (Parameters)
Удобный метод, который работает **и для GET (строка URL), и для POST (тело формы)**.

| Метод | Назначение |
| :--- | :--- |
| `String getParameter(String name)` | Значение одного параметра (первое попавшееся). |
| `String[] getParameterValues(String name)` | Если параметр повторяется (например, `checkbox`). |
| `Map<String, String[]> getParameterMap()` | Получить карту всех параметров. |
| `Enumeration<String> getParameterNames()` | Имена всех параметров. |

### 4. Специфические HTTP-методы

| Метод | Назначение |
| :--- | :--- |
| `String getMethod()` | Вернет строку: `"GET"`, `"POST"`, `"PUT"`, `"DELETE"` и т.д. |
| `String getRequestURI()` | Путь внутри приложения (например, `/app/user/123`). |
| `StringBuffer getRequestURL()` | Полный URL (с протоколом, доменом и портом). |
| `String getQueryString()` | Всё, что идет после `?` в URL. |
| `String getRemoteAddr()` | IP-адрес клиента. |
| `String getRemoteHost()` | Имя хоста клиента. |
| `String getRemoteUser()` | Имя пользователя, если была аутентификация. |

### 5. Работа с куками (Cookies)

| Метод | Назначение |
| :--- | :--- |
| `Cookie[] getCookies()` | Получить массив всех кук, присланных браузером. |

```java
Cookie[] cookies = request.getCookies();
if (cookies != null) {
    for (Cookie c : cookies) {
        if ("sessionId".equals(c.getName())) {
            String sessionId = c.getValue();
        }
    }
}
```

---

##  Работа с ответом (HttpServletResponse)

Объект ответа собирается разработчиком и отправляется клиенту.

### 1. Установка статуса (Status Code)

| Метод | Назначение | Пример |
| :--- | :--- | :--- |
| `void setStatus(int sc)` | Установить любой код. | `response.setStatus(404);` |
| `void sendError(int sc)` | Отправить ошибку (стандартная страница Tomcat). | `response.sendError(403, "Доступ запрещен");` |
| `void sendError(int sc, String msg)` | Ошибка + свое сообщение. | |
| `void setStatus(int sc, String sm)` | **Устарел.** Лучше использовать `sendError` для ошибок. | |
| `int getStatus()` | Получить текущий код (для проверки). | |

**Полезные константы** (чтобы не писать цифры):
`SC_OK` (200), `SC_NOT_FOUND` (404), `SC_INTERNAL_SERVER_ERROR` (500), `SC_FORBIDDEN` (403), `SC_MOVED_TEMPORARILY` (302).

### 2. Установка заголовков (Headers)

| Метод | Назначение | Пример |
| :--- | :--- | :--- |
| `void setHeader(String name, String value)` | Установить заголовок (заменит старый). | `response.setHeader("Cache-Control", "no-cache");` |
| `void addHeader(String name, String value)` | Добавить еще одно значение к заголовку. | `response.addHeader("Set-Cookie", "...");` |
| `void setIntHeader(String name, int value)` | Для числовых заголовков. | `response.setIntHeader("Content-Length", 1024);` |
| `void setDateHeader(String name, long date)` | Для дат. | `response.setDateHeader("Last-Modified", System.currentTimeMillis());` |
| `boolean containsHeader(String name)` | Проверить, установлен ли заголовок. | |
| `void setContentType(String type)` | **Самый частый.** Указывает тип данных. | `response.setContentType("text/html;charset=UTF-8");` |
| `void setCharacterEncoding(String charset)` | Кодировка ответа. | `response.setCharacterEncoding("UTF-8");` |
| `void setContentLength(int len)` | Длина ответа (если знаете заранее). | |

### 3. Перенаправление (Redirect)

| Метод | Назначение |
| :--- | :--- |
| `void sendRedirect(String location)` | Отправить клиента на другой URL (код 302). |

```java
// После успешного логина кидаем на главную
response.sendRedirect("/app/dashboard");
```

### 4. Работа с телом ответа (Body)

Как и в запросе, есть два потока — для текста и для бинарных данных. **Но использовать можно только один!**

| Метод | Назначение | Когда использовать |
| :--- | :--- | :--- |
| `ServletOutputStream getOutputStream()` | Поток для **бинарных** данных. | Отдача PDF, ZIP, картинок. |
| `PrintWriter getWriter()` | Ридер для **текстовых** данных. | Отдача HTML, JSON, XML. |

```java
// Пример: отдаем JSON
response.setContentType("application/json");
response.setCharacterEncoding("UTF-8");
PrintWriter out = response.getWriter();
out.print("{\"status\":\"ok\"}");
out.flush(); // Отправляем данные
```

### 5. Работа с куками (Cookies)

| Метод | Назначение |
| :--- | :--- |
| `void addCookie(Cookie cookie)` | Добавить куку в ответ. |

```java
Cookie userCookie = new Cookie("username", "john");
userCookie.setMaxAge(60 * 60 * 24); // 1 день
userCookie.setPath("/");
response.addCookie(userCookie);
```

### 6. Буферизация (Buffer)

По умолчанию ответ буферизируется (собирается в памяти) перед отправкой.

| Метод | Назначение |
| :--- | :--- |
| `int getBufferSize()` | Узнать размер буфера. |
| `void setBufferSize(int size)` | Установить размер буфера (до отправки данных!). |
| `void flushBuffer()` | Принудительно отправить данные клиенту. |
| `void resetBuffer()` | Очистить буфер (но не статус и заголовки). |
| `void reset()` | Очистить всё (буфер, статус, заголовки). |
| `boolean isCommitted()` | Проверить, была ли уже отправлена часть ответа. |

---
