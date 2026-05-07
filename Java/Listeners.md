Слушатели в сервлетах — это хуки на события жизненного цикла контекста, запросов, сессий и их атрибутов. Они позволяют «подписаться» на создание/уничтожение и изменения состояния без изменения сервлетов.easyoffer+2

## Общая идея

> Listener — это объект, который реализует один из интерфейсов слушателей (`ServletContextListener`, `HttpSessionListener`, `ServletRequestListener` и др.) и выполняет код при наступлении определённых событий в контейнере: старт/остановка приложения, создание/удаление сессии, запросов, изменение атрибутов.codorbits+2

Их подключают либо в `web.xml`, либо аннотацией `@WebListener`.centron+1

## Основные группы слушателей по scope

## 1. Слушатели контекста приложения

- **`ServletContextListener`**:geeksforgeeks+2
    
    - Методы:
        
        - `contextInitialized(ServletContextEvent e)` — вызывается при старте web‑приложения, когда создаётся `ServletContext`.
            
        - `contextDestroyed(ServletContextEvent e)` — при остановке приложения, перед уничтожением `ServletContext`.
            
    - Использование: инициализация/закрытие глобальных ресурсов (пулы соединений, кэши, фоновые задачи).baeldung+2
        
- **`ServletContextAttributeListener`**:easyoffer+1
    
    - Реагирует на добавление/изменение/удаление атрибутов в `ServletContext`.
        
    - Методы: `attributeAdded`, `attributeRemoved`, `attributeReplaced`.
        

## 2. Слушатели сессий

- **`HttpSessionListener`**:baeldung+2
    
    - Методы:
        
        - `sessionCreated(HttpSessionEvent e)` — при создании новой сессии.
            
        - `sessionDestroyed(HttpSessionEvent e)` — при уничтожении/истечении сессии.
            
    - Использование: считать активных пользователей, логировать login/logout, чистить связанные ресурсы.geeksforgeeks+1
        
- **`HttpSessionAttributeListener`**:progler+2
    
    - Реагирует на добавление/изменение/удаление атрибутов в `HttpSession`.
        
    - Удобен для аудита или реакций на изменение пользовательского состояния.
        

## 3. Слушатели запросов

- **`ServletRequestListener`**:codorbits+2
    
    - Методы:
        
        - `requestInitialized(ServletRequestEvent e)` — при создании запроса.
            
        - `requestDestroyed(ServletRequestEvent e)` — при завершении обработки запроса.
            
    - Использование: логирование всех запросов, замер времени обработки, установка encoding и т.п.
        
- **`ServletRequestAttributeListener`**:progler+2
    
    - Реагирует на изменения атрибутов `ServletRequest`.
        

## Пример: ServletContextListener для инициализации ресурса

java

`@WebListener public class AppContextListener implements ServletContextListener {     @Override    public void contextInitialized(ServletContextEvent sce) {        ServletContext ctx = sce.getServletContext();        String url = ctx.getInitParameter("DBURL");        String user = ctx.getInitParameter("DBUSER");        String pwd = ctx.getInitParameter("DBPWD");         DBConnectionManager dbManager = new DBConnectionManager(url, user, pwd);        ctx.setAttribute("DBManager", dbManager);        System.out.println("DB connection init");    }     @Override    public void contextDestroyed(ServletContextEvent sce) {        ServletContext ctx = sce.getServletContext();        DBConnectionManager dbManager =                (DBConnectionManager) ctx.getAttribute("DBManager");        dbManager.closeConnection();        System.out.println("DB connection closed");    } }`

## Как это звучит на собесе

Короткая формулировка:

> В сервлетах есть набор Listener‑ов, которые работают как триггеры на события жизненного цикла: `ServletContextListener` — старт/остановка приложения, `HttpSessionListener` — создание/удаление сессий, `ServletRequestListener` — создание/завершение запросов, плюс слушатели атрибутов для контекста, сессии и запроса. Их используют для инициализации/очистки ресурсов, подсчёта активных пользователей, логирования, метрик и т.п..baeldung+5

Если хочешь, могу отдельно накидать 3–5 типичных вопросов по listeners с короткими ответами в формате «как на собесе ответить».