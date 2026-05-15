Здесь очень любят чёткие контрастные формулировки, давай так и сделаем.

## ServletConfig: конфиг конкретного сервлета

`ServletConfig` — это объект, через который контейнер передаёт **параметры инициализации конкретному сервлету**.codorbits+6

Ключевые моменты:

- У **каждого сервлета свой собственный** объект `ServletConfig`, создаваемый контейнером при инициализации этого сервлета.studfile+3
    
- Параметры задаются в `web.xml` внутри тега `<servlet>` через `<init-param>`:javarush+4
    
    xml
    
    `<servlet>     <servlet-name>MyServlet</servlet-name>    <servlet-class>com.example.MyServlet</servlet-class>    <init-param>        <param-name>email</param-name>        <param-value>admin@example.com</param-value>    </init-param> </servlet>`
    
- Получить `ServletConfig` можно внутри сервлета через `getServletConfig()`, а параметры — через `getInitParameter(name)` / `getInitParameterNames()`.java-online+4
    
- `ServletConfig` **не предназначен** для хранения атрибутов в рантайме, это только конфигурация на старте.javastudy+3
    

Формулировка:

> `ServletConfig` — это конфигурация конкретного сервлета: объект, уникальный для каждого сервлета, содержащий init‑параметры из `web.xml` (или аннотаций). Через него сервлет получает свои настройки при инициализации.github+5

## ServletContext: контекст всего приложения

`ServletContext` — это **общий контекст для всего веб‑приложения**: объект, разделяемый всеми сервлетами внутри одного приложения.codorbits+3

Основное:

- В приложении **один объект `ServletContext`**, общий для всех сервлетов.java-online+3
    
- Через него можно:
    
    - получать **параметры инициализации уровня приложения** (`<context-param>` в `web.xml`);studfile+2
        
    - хранить и читать **атрибуты, общие для разных сервлетов**: `setAttribute`, `getAttribute`, `removeAttribute`;javastudy+3
        
    - получать информацию о среде выполнения (сервер, версия, реальные пути к ресурсам) и доступ к ресурсам (`getResource`, `getResourceAsStream`);java-online+1
        
    - логировать сообщения, доступные в логах контейнера.[java-online](https://java-online.ru/servlet-context.xhtml)
        

Пример параметров в `web.xml`:progler+2

xml

`<context-param>     <param-name>appName</param-name>    <param-value>MyApp</param-value> </context-param>`

Получение:

java

`ServletContext ctx = getServletContext(); String appName = ctx.getInitParameter("appName"); ctx.setAttribute("cache", myCache); // общий атрибут для всех сервлетов`

Формулировка:

> `ServletContext` — это общий контекст веб‑приложения: один объект на приложение, через который все сервлеты получают общие параметры (`context-param`), обмениваются атрибутами и работают с ресурсами и логированием.codorbits+3

## Отличия ServletConfig vs ServletContext (как сказать на собесе)

Практически каждый список вопросов по сервлетам содержит это сравнение.github+3

Коротко, пунктами:

- **Область действия**:
    
    - `ServletConfig` — **для одного сервлета**, уникальный экземпляр на сервлет.github+3
        
    - `ServletContext` — **для всего приложения**, один экземпляр на web‑app.studfile+3
        
- **Источник параметров**:
    
    - `ServletConfig` читает `<init-param>` внутри `<servlet>` в `web.xml` — настройки конкретного сервлета.javarush+4
        
    - `ServletContext` читает `<context-param>` в `web.xml` — настройки уровня приложения.progler+3
        
- **Атрибуты**:
    
    - В `ServletConfig` атрибуты не хранят, он только отдаёт параметры конфигурации.codorbits+3
        
    - В `ServletContext` можно хранить/изменять атрибуты (`setAttribute`, `getAttribute`) и делиться ими между сервлетами.javastudy+2
        

Фраза, которую можно выдать:

> `ServletConfig` — это конфигурация отдельного сервлета: уникален на сервлет, читает его `<init-param>` и не предназначен для хранения атрибутов. `ServletContext` — это общий контекст приложения: один на всё web‑приложение, читает `<context-param>` и позволяет хранить атрибуты, доступные всем сервлетам.github+6

Хочешь, дальше по тому же шаблону разберём `HttpSession` и способы трекинга сессий (cookies, URL rewriting, hidden fields), чтобы закрыть весь блок по «состоянию»?