## JSP (JavaServer Pages) — Полное руководство

JSP (JavaServer Pages) — это технология, которая позволяет создавать динамические веб-страницы на основе Java. По сути, это HTML с вкраплениями Java-кода, который выполняется на сервере перед отправкой страницы клиенту.

---

## 🔍 Что такое JSP и зачем он нужен?

### Проблема сервлетов
В чистых сервлетах мы вынуждены писать HTML внутри Java-кода:

```java
PrintWriter out = response.getWriter();
out.println("<html>");
out.println("<head><title>Привет</title></head>");
out.println("<body>");
out.println("<h1>Привет, " + name + "</h1>");
out.println("</body>");
out.println("</html>");
```

Это неудобно:
- Трудно верстать (нужно перекомпилировать при изменении HTML)
- Код становится нечитаемым
- Дизайнер не может править страницы

### Решение JSP
JSP переворачивает ситуацию: **это HTML, в который встроен Java-код**:

```jsp
<html>
<head><title>Привет</title></head>
<body>
    <h1>Привет, <%= request.getParameter("name") %></h1>
</body>
</html>
```

---

## 🏗️ Архитектура и жизненный цикл JSP

Многие думают, что JSP работает как отдельная сущность. На самом деле:

1. **JSP → Сервлеt** — Контейнер (Tomcat) транслирует JSP-файл в Java-код сервлета
2. **Компиляция** — Полученный Java-код компилируется в class-файл
3. **Выполнение** — Работает обычный сервлет

```
.jsp файл ──(трансляция)──> .java файл (сервлет) ──(компиляция)──> .class ──(выполнение)──> HTML
```

**Жизненный цикл JSP:**
1. `jspInit()` — при загрузке (аналог `init()`)
2. `_jspService()` — при каждом запросе (аналог `service()`)
3. `jspDestroy()` — при выгрузке (аналог `destroy()`)

---

## 📝 Синтаксис JSP

### 1. Директивы (Directives) — `<%@ ... %>`
Директивы дают указания контейнеру на этапе трансляции JSP в сервлет.

| Директива | Назначение | Пример |
|-----------|------------|--------|
| `<%@ page ... %>` | Настройки страницы | `<%@ page contentType="text/html; charset=UTF-8" %>` |
| `<%@ include ... %>` | Включение файла (статическое) | `<%@ include file="header.jsp" %>` |
| `<%@ taglib ... %>` | Подключение библиотек тегов | `<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>` |

**Атрибуты page-директивы:**
- `import="java.util.*, java.io.*"` — импорт классов
- `session="true|false"` — участвует ли в сессии
- `errorPage="error.jsp"` — страница для ошибок
- `isErrorPage="true|false"` — является ли страница страницей ошибок
- `contentType="text/html; charset=UTF-8"` — тип контента
- `pageEncoding="UTF-8"` — кодировка файла

### 2. Скриплеты (Scriptlets) — `<% ... %>`
Блоки Java-кода, выполняемые при каждом запросе.

```jsp
<%
    String user = request.getParameter("user");
    if (user == null || user.isEmpty()) {
        user = "Гость";
    }
%>
<h1>Привет, <%= user %>!</h1>
```

### 3. Выражения (Expressions) — `<%= ... %>`
Сокращенная запись для вывода значения. Не ставьте точку с запятой!

```jsp
<p>Текущее время: <%= new java.util.Date() %></p>
<p>2 + 2 = <%= 2 + 2 %></p>
```

### 4. Декларации (Declarations) — `<%! ... %>`
Объявление методов и переменных уровня класса (а не локальных).

```jsp
<%!
    private int counter = 0;
    
    private String getGreeting(String name) {
        return "Привет, " + name + "!";
    }
%>
<p>Счетчик: <%= ++counter %></p>
<p><%= getGreeting("Мир") %></p>
```

### 5. Комментарии
```jsp
<%-- Это JSP-комментарий — он не виден в HTML --%>
<!-- Это HTML-комментарий — он будет в исходном коде страницы -->
```

### 6. EL (Expression Language) — `${...}`
Упрощенный язык выражений (появился в JSP 2.0). Позволяет обращаться к данным без Java-кода.

```jsp
<!-- Вместо -->
<%= request.getParameter("name") %>

<!-- Пишем -->
${param.name}

<!-- Вместо -->
<%= session.getAttribute("user") != null ? session.getAttribute("user").getName() : "" %>

<!-- Пишем -->
${sessionScope.user.name}
```

**Неявные объекты EL:**
- `pageScope`, `requestScope`, `sessionScope`, `applicationScope` — доступ к атрибутам
- `param`, `paramValues` — параметры запроса
- `header`, `headerValues` — заголовки HTTP
- `cookie` — куки
- `initParam` — параметры контекста (web.xml)
- `pageContext` — объект PageContext

---

## 🎯 Неявные объекты JSP

Внутри JSP доступны объекты без объявления (их создает контейнер):

| Объект | Тип | Описание |
|--------|-----|----------|
| `request` | `HttpServletRequest` | Запрос HTTP |
| `response` | `HttpServletResponse` | Ответ HTTP |
| `session` | `HttpSession` | Сессия пользователя |
| `application` | `ServletContext` | Контекст приложения |
| `out` | `JspWriter` | Поток вывода (аналог PrintWriter) |
| `config` | `ServletConfig` | Конфигурация JSP/сервлета |
| `page` | `Object` | Сам объект JSP (this) |
| `pageContext` | `PageContext` | Контекст страницы (доступ ко всем областям) |
| `exception` | `Throwable` | Доступен только на страницах ошибок |

```jsp
<%
    // Пример использования
    String ip = request.getRemoteAddr();
    session.setAttribute("lastVisit", new java.util.Date());
    application.setAttribute("totalVisits", (Integer)application.getAttribute("totalVisits") + 1);
    out.println("<p>Ваш IP: " + ip + "</p>");
%>
```

---

## 🔄 Взаимодействие между страницами

### 1. Перенаправление (Redirect)
Клиент получает новый URL и делает второй запрос.

```jsp
<%
    response.sendRedirect("login.jsp");
%>
```

### 2. Пересылка (Forward)
Запрос передается другому ресурсу на сервере, клиент не знает об этом.

```jsp
<%
    RequestDispatcher dispatcher = request.getRequestDispatcher("result.jsp");
    dispatcher.forward(request, response);
%>
```

### 3. Включение (Include)
Включение другого ресурса в текущий.

**Статическое включение** (на этапе компиляции):
```jsp
<%@ include file="header.jsp" %>
```

**Динамическое включение** (на этапе выполнения):
```jsp
<jsp:include page="footer.jsp" />
<!-- или -->
<%
    RequestDispatcher dispatcher = request.getRequestDispatcher("footer.jsp");
    dispatcher.include(request, response);
%>
```

---

## 🧩 Стандартные действия JSP (jsp:action)

Действия — это теги JSP для выполнения стандартных операций.

| Действие | Описание | Пример |
|----------|----------|--------|
| `<jsp:include>` | Включение ресурса | `<jsp:include page="header.jsp" />` |
| `<jsp:forward>` | Пересылка запроса | `<jsp:forward page="login.jsp" />` |
| `<jsp:param>` | Передача параметров | `<jsp:param name="id" value="123" />` |
| `<jsp:useBean>` | Использование JavaBean | `<jsp:useBean id="user" class="com.User" />` |
| `<jsp:setProperty>` | Установка свойства Bean | `<jsp:setProperty name="user" property="name" value="John" />` |
| `<jsp:getProperty>` | Получение свойства Bean | `<jsp:getProperty name="user" property="name" />` |

**Пример с JavaBean:**
```jsp
<jsp:useBean id="user" class="com.example.User" scope="session" />
<jsp:setProperty name="user" property="name" value="Иван" />
<jsp:setProperty name="user" property="age" param="userAge" /> <!-- из параметра -->
<p>Имя: <jsp:getProperty name="user" property="name" /></p>
```

---

## 📚 JSTL (JSP Standard Tag Library)

Писать Java-код в JSP считается плохой практикой. JSTL предоставляет набор тегов для решения типовых задач.

**Подключение:**
```jsp
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/fmt" prefix="fmt" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
```

### Основные теги core:

**Условный оператор:**
```jsp
<c:if test="${param.age >= 18}">
    <p>Вы совершеннолетний</p>
</c:if>
```

**Выбор (switch/case):**
```jsp
<c:choose>
    <c:when test="${param.role == 'admin'}">
        <p>Администратор</p>
    </c:when>
    <c:when test="${param.role == 'user'}">
        <p>Пользователь</p>
    </c:when>
    <c:otherwise>
        <p>Гость</p>
    </c:otherwise>
</c:choose>
```

**Циклы:**
```jsp
<c:forEach var="user" items="${userList}" varStatus="status">
    <tr>
        <td>${status.index + 1}</td>
        <td>${user.name}</td>
        <td>${user.email}</td>
    </tr>
</c:forEach>
```

**Работа с URL:**
```jsp
<c:url value="/user/profile" var="profileUrl">
    <c:param name="id" value="${user.id}" />
</c:url>
<a href="${profileUrl}">Профиль</a>
```

---

## 🏗️ Пример полноценной JSP

### login.jsp
```jsp
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<!DOCTYPE html>
<html>
<head>
    <title>Вход в систему</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/css/style.css">
</head>
<body>
    <%@ include file="header.jsp" %>
    
    <div class="login-form">
        <h2>Вход</h2>
        
        <c:if test="${not empty error}">
            <div class="error">${error}</div>
        </c:if>
        
        <form action="${pageContext.request.contextPath}/login" method="post">
            <div>
                <label for="username">Имя пользователя:</label>
                <input type="text" id="username" name="username" value="${param.username}" required>
            </div>
            <div>
                <label for="password">Пароль:</label>
                <input type="password" id="password" name="password" required>
            </div>
            <div>
                <input type="checkbox" id="remember" name="remember">
                <label for="remember">Запомнить меня</label>
            </div>
            <button type="submit">Войти</button>
        </form>
    </div>
    
    <jsp:include page="footer.jsp">
        <jsp:param name="year" value="2026" />
    </jsp:include>
</body>
</html>
```

### error.jsp (страница ошибок)
```jsp
<%@ page isErrorPage="true" contentType="text/html; charset=UTF-8" %>
<html>
<head><title>Ошибка</title></head>
<body>
    <h1>Произошла ошибка</h1>
    <p>Сообщение: <%= exception.getMessage() %></p>
    <p>Тип: <%= exception.getClass().getName() %></p>
    
    <h3>Stack trace:</h3>
    <pre>
        <%
            exception.printStackTrace(new java.io.PrintWriter(out));
        %>
    </pre>
</body>
</html>
```

---

## 💡 Лучшие практики (Best Practices)

### 1. **Не пишите Java-код в JSP!**
Используйте:
- JSTL для логики
- EL для доступа к данным
- Сервлеты как контроллеры
- JavaBeans для хранения данных

**Плохо:**
```jsp
<%
    List<User> users = (List<User>)request.getAttribute("users");
    for(User u : users) {
        out.println("<tr><td>" + u.getName() + "</td></tr>");
    }
%>
```

**Хорошо:**
```jsp
<c:forEach var="u" items="${users}">
    <tr><td>${u.name}</td></tr>
</c:forEach>
```

### 2. **MVC (Model-View-Controller)**
- **Сервлет** — контроллер (получает запрос, вызывает бизнес-логику, передает данные)
- **JSP** — представление (только отображение данных)
- **JavaBeans/POJO** — модель (данные)

```java
// Сервлет-контроллер
@WebServlet("/users")
public class UserServlet extends HttpServlet {
    protected void doGet(HttpServletRequest request, HttpServletResponse response) {
        List<User> users = userService.getAllUsers();
        request.setAttribute("users", users);
        request.getRequestDispatcher("/WEB-INF/users.jsp").forward(request, response);
    }
}
```

### 3. **Храните JSP в WEB-INF**
Это предотвращает прямой доступ к JSP через URL. Все запросы идут через сервлеты.

### 4. **Используйте правильные области видимости**
- `page` — только на текущей странице
- `request` — на время одного запроса
- `session` — на время сессии пользователя
- `application` — глобально для всего приложения

```jsp
<c:set var="temp" value="value" scope="request" />
```

### 5. **Экранируйте вывод**
Предотвращает XSS-атаки.

```jsp
<!-- Плохо (уязвимо) -->
${user.comment}

<!-- Хорошо -->
<c:out value="${user.comment}" />
${fn:escapeXml(user.comment)}
```

---

## 🔧 Настройка в web.xml

```xml
<web-app>
    <!-- Настройка страницы приветствия -->
    <welcome-file-list>
        <welcome-file>index.jsp</welcome-file>
    </welcome-file-list>
    
    <!-- Настройка страниц ошибок -->
    <error-page>
        <error-code>404</error-code>
        <location>/error/404.jsp</location>
    </error-page>
    
    <error-page>
        <exception-type>java.lang.NullPointerException</exception-type>
        <location>/error/general.jsp</location>
    </error-page>
    
    <!-- Конфигурация JSP -->
    <jsp-config>
        <jsp-property-group>
            <url-pattern>*.jsp</url-pattern>
            <page-encoding>UTF-8</page-encoding>
            <include-prelude>/WEB-INF/includes/header.jspf</include-prelude>
            <include-coda>/WEB-INF/includes/footer.jspf</include-coda>
        </jsp-property-group>
    </jsp-config>
</web-app>
```

---

## 🎯 Резюме

| Компонент            | Назначение                                 |
| -------------------- | ------------------------------------------ |
| `<% ... %>`          | Java-код (скриплет)                        |
| `<%= ... %>`         | Вывод выражения                            |
| `<%! ... %>`         | Объявление методов/переменных              |
| `${...}`             | Expression Language                        |
| `<%@ page ... %>`    | Директива страницы                         |
| `<%@ include ... %>` | Статическое включение                      |
| `<jsp:include ...>`  | Динамическое включение                     |
| JSTL                 | Библиотека тегов (вместо Java-кода)        |
| MVC                  | Сервлет (контроллер) + JSP (представление) |