Сформулирую ответы так, чтобы их можно было почти дословно говорить на собесе.

## HttpServletRequest: что важно уметь назвать

`HttpServletRequest` инкапсулирует **входящий HTTP‑запрос**: метод, URL, заголовки, параметры, тело, атрибуты, сессию и доступ к `RequestDispatcher`.studfile+3

Ключевые группы методов:

1. **Общая информация о запросе**:javarush+2
    
    - `getMethod()` — HTTP‑метод (`GET`, `POST`, `PUT`, …).
        
    - `getRequestURI()`, `getRequestURL()` — URI и полный URL.
        
    - `getQueryString()` — строка после `?`.
        
    - `getProtocol()`, `getScheme()`, `getServerName()`, `getServerPort()`.
        
2. **Параметры запроса** (query‑params и form‑data):proselyte+1
    
    - `getParameter(String name)` — одно значение параметра.
        
    - `getParameterMap()`, `getParameterNames()`, `getParameterValues(String)` — все параметры.
        
3. **Заголовки**:javarush+1
    
    - `getHeader(String name)`, `getHeaders(String name)`, `getHeaderNames()`.
        
    - Плюс спец‑методы: `getContentType()`, `getContentLength()`, `getCharacterEncoding()`.
        
4. **Тело запроса**:elib.psu+2
    
    - `getInputStream()` — бинарный поток (для файлов, JSON, бинарных данных).
        
    - `getReader()` — символьный поток (чтение текста/JSON как строки).
        
5. **Атрибуты и контекст**:studfile+1
    
    - `setAttribute(String, Object)`, `getAttribute(String)`, `removeAttribute(String)` — данные только на время обработки текущего запроса (request scope).
        
    - `getServletContext()` — доступ к `ServletContext` (приложение).
        
6. **Сессия и dispatcher**:elib.psu+2
    
    - `getSession()`, `getSession(boolean)` — получение/создание `HttpSession`.
        
    - `getRequestDispatcher(String path)` — получение `RequestDispatcher` для `forward`/`include`.
        

Формулировка:

> `HttpServletRequest` даёт доступ ко всей информации входящего HTTP‑запроса: методу, URL, параметрам, заголовкам, телу, атрибутам, сессии и позволяет получить `RequestDispatcher` для серверного `forward`.java-online+3

## HttpServletResponse: основные задачи и методы

`HttpServletResponse` инкапсулирует **ответ сервера**: статус, заголовки, тип содержимого и тело ответа.javarush+3

Ключевые вещи:

1. **Статус и заголовки**:javarush+2
    
    - `setStatus(int sc)` — установить HTTP‑статус (например, 200, 404).
        
    - Упрощённо: `sendError(int sc, String msg)` — статус + страница ошибки.
        
    - Заголовки: `setHeader(String, String)`, `addHeader(...)`, `setDateHeader(...)`, `setIntHeader(...)`.
        
    - `setContentType(String)` — `Content-Type`, например `text/html;charset=UTF-8`.
        
2. **Тело ответа**:javarush+2
    
    - `getWriter()` — возвращает `PrintWriter` для записи **текстового** ответа (HTML, JSON, XML и т.п.).
        
    - `getOutputStream()` — возвращает `ServletOutputStream` для **бинарных** данных (файлы, изображения и т.п.).
        
    - Важно: нельзя использовать и `getWriter()`, и `getOutputStream()` в одном ответе.
        
3. **Перенаправление**:java-online+2
    
    - `sendRedirect(String location)` — отправляет клиенту ответ 3xx с заголовком `Location`, браузер делает **новый запрос** по указанному URL.
        

Фраза:

> `HttpServletResponse` позволяет установить статус и заголовки HTTP‑ответа, задать тип содержимого, записать тело ответа через `getWriter()` или `getOutputStream()`, а также отправить редирект с помощью `sendRedirect()`.java-online+3

## Forward vs Redirect (RequestDispatcher.forward vs sendRedirect)

Это прям классика собеса, важно уметь чётко противопоставить.

## RequestDispatcher.forward

- Получаем через `request.getRequestDispatcher("/path")` или `getServletContext().getRequestDispatcher(...)`.javaportal+1
    
- Метод: `dispatcher.forward(request, response)`.
    

Суть:javaportal+3

- **Работает на стороне сервера**: контейнер внутри себя передаёт управление другому сервлету/JSP **без нового HTTP‑запроса от клиента**.
    
- Используются **те же объекты** `HttpServletRequest` и `HttpServletResponse`; все атрибуты запроса сохраняются.
    
- В браузере URL **не меняется**.
    
- Обычно используется для внутренней передачи управления (MVC: контроллер → JSP).
    

## HttpServletResponse.sendRedirect

- Вызов: `response.sendRedirect("/new-url")`.
    

Суть:studfile+3

- **Работает на стороне клиента**: сервер отправляет ответ 3xx с заголовком `Location`, браузер получает его и сам делает **новый HTTP‑запрос** по новому URL.
    
- Создаются **новые** `HttpServletRequest` и `HttpServletResponse`; атрибуты запроса теряются, можно использовать сессию или параметры в URL.
    
- В браузере URL **меняется** на новый.
    
- Удобен, когда нужно сделать PRG‑паттерн (Post/Redirect/Get), уйти на другой сайт/домен, или чтобы пользователь увидел «чистый» URL.
    

Фраза для собеса:

> `forward` (`RequestDispatcher.forward`) — серверный перенаправитель: выполняется внутри контейнера, без нового HTTP‑запроса, с теми же request/response и тем же URL в браузере. `sendRedirect` — клиентский редирект: сервер отправляет код 3xx и `Location`, браузер делает новый запрос, URL меняется, создаются новые request/response.elib.psu+3

---

Если готов, следом можем закрыть блок:

- `HttpSession` и способы трекинга сессий (cookies, URL rewriting, hidden fields).
    
- Или сразу прыгнуть в Spring MVC и провести параллели: как `DispatcherServlet` делает примерно то же самое, что контейнер + RequestDispatcher.
    

Что из этого тебе важнее добить первым к собесу?