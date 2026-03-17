Маппинг (связывание) сервлетов в `web.xml` — это классический способ сказать веб-контейнеру (Tomcat, Jetty и т.д.): "Когда пользователь зайдет по такому-то URL, запусти вот этот Java-класс".

Хотя сейчас популярны аннотации (например, `@WebServlet`), файл `web.xml` (дескриптор развертывания) до сих пор используется, особенно в крупных проектах или когда нужно менять настройки без перекомпиляции кода.

Вот как это работает, от простого к сложному.

###  Структура `web.xml`

Файл `web.xml` находится в папке `WEB-INF/` вашего веб-приложения. Маппинг сервлета состоит из двух обязательных шагов (блоков):

1.  **`<servlet>`** — объявляем сам класс сервлета и даем ему имя.
2.  **`<servlet-mapping>`** — берем объявленное имя и привязываем к нему URL-адрес.

#### Пример: Маппинг одного сервлета

Допустим, у вас есть Java-класс `MyFirstServlet`.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<web-app xmlns="http://xmlns.jcp.org/xml/ns/javaee"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://xmlns.jcp.org/xml/ns/javaee
                      http://xmlns.jcp.org/xml/ns/javaee/web-app_4_0.xsd"
         version="4.0">

    <!-- Шаг 1: Объявляем сервлет -->
    <servlet>
        <!-- Внутреннее имя (для ссылок внутри web.xml) -->
        <servlet-name>MyServletName</servlet-name>
        <!-- Полное имя класса (с пакетом) -->
        <servlet-class>com.example.MyFirstServlet</servlet-class>
    </servlet>

    <!-- Шаг 2: Связываем имя с URL -->
    <servlet-mapping>
        <!-- То же имя, что и выше -->
        <servlet-name>MyServletName</servlet-name>
        <!-- URL-шаблон, по которому сервлет будет доступен -->
        <url-pattern>/hello</url-pattern>
    </servlet-mapping>

</web-app>
```

**Результат:** Когда пользователь перейдет по адресу `http://localhost:8080/yourapp/hello`, контейнер найдет по имени `MyServletName` класс `com.example.MyFirstServlet` и выполнит его.

---

### 🧭 Типы URL-шаблонов (`url-pattern`)

Значение внутри `<url-pattern>` может быть задано тремя основными способами:

1.  **Точное совпадение**
    *   Пример: `/login`, `/admin/dashboard`, `/user/profile`
    *   Сервлет сработает только при абсолютном совпадении адреса.

2.  **Расширение файла (суффикс)**
    *   Пример: `*.do`, `*.action`, `*.html`
    *   Сервлет сработает на любой URL, который заканчивается на это расширение.
    *   *Важно:* Начинается со звездочки.
        ```xml
        <url-pattern>*.do</url-pattern>
        ```
        *Тогда URL `/user/add.do` или `/order/delete.do` будут вести на этот сервлет.*

3.  **Путь с подстановкой (префикс)**
    *   Пример: `/api/*`, `/admin/*`, `/*`
    *   Сервлет сработает на любой URL, начинающийся с указанного пути.
        ```xml
        <url-pattern>/api/*</url-pattern>
        ```
        *Тогда URL `/api/users`, `/api/orders/1` будут вести на этот сервлет.*

#### ⚠️ Приоритет обработки (что сработает, если есть конфликт)

Контейнер не обрабатывает шаблоны в том порядке, как они написаны в файле. У него есть строгие правила:
1.  **Точное совпадение** — всегда в приоритете.
2.  **Путь с префиксом (`/something/*`)** — если точного нет, ищет по самому длинному совпадению пути.
3.  **Расширение (`*.jsp`)**.

### 🚀 Параметры и настройки сервлета

Внутри тега `<servlet>` можно настроить дополнительные параметры, которые будут доступны сервлету через `getServletConfig()`.

#### Параметры инициализации (`<init-param>`)
Это параметры для **конкретного сервлета**.

```xml
<servlet>
    <servlet-name>PaymentServlet</servlet-name>
    <servlet-class>com.example.PaymentServlet</servlet-class>
    
    <!-- Свои параметры -->
    <init-param>
        <param-name>currency</param-name>
        <param-value>USD</param-value>
    </init-param>
    <init-param>
        <param-name>maxAmount</param-name>
        <param-value>1000</param-value>
    </init-param>
    
    <!-- Цифра говорит контейнеру, в каком порядке загружать сервлет при старте (1 - первым, выше число - ниже приоритет) -->
    <load-on-startup>1</load-on-startup>
</servlet>
```
В Java-коде это читается так:
```java
String currency = getServletConfig().getInitParameter("currency");
```

### 🔄 Несколько маппингов для одного сервлета

Один и тот же сервлет можно "повесить" на несколько разных URL. Для этого просто создаем несколько блоков `<servlet-mapping>` с одинаковым `<servlet-name>`.

```xml
<!-- Объявление одно -->
<servlet>
    <servlet-name>UniversalServlet</servlet-name>
    <servlet-class>com.example.UniversalServlet</servlet-class>
</servlet>

<!-- А маппингов несколько -->
<servlet-mapping>
    <servlet-name>UniversalServlet</servlet-name>
    <url-pattern>/first</url-pattern>
</servlet-mapping>
<servlet-mapping>
    <servlet-name>UniversalServlet</servlet-name>
    <url-pattern>/second</url-pattern>
</servlet-mapping>
<servlet-mapping>
    <servlet-name>UniversalServlet</servlet-name>
    <url-pattern>*.do</url-pattern>
</servlet-mapping>
```

### 🆚 Альтернатива: Аннотация `@WebServlet` (Java EE 6+)

В современных проектах часто используют аннотации, чтобы не плодить XML. Это эквивалент того же маппинга, но прямо в коде.

```java
package com.example;

import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;

// Этот код полностью заменяет запись в web.xml выше
@WebServlet(
    name = "MyServletName", // обычно можно не указывать, имя берется из класса
    urlPatterns = {"/hello", "/hello2"}, // можно сразу массив URL
    initParams = {
        @WebInitParam(name = "currency", value = "USD")
    },
    loadOnStartup = 1
)
public class MyFirstServlet extends HttpServlet {
    // ...
}
```

**Но:** Если у вас сложный проект или вы не хотите перекомпилировать классы ради смены URL, `web.xml` остается незаменимым.

