[[Cookies]]
# Создание 
```java
import javax.servlet.http.Cookie;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;

// ... внутри метода doGet или doPost сервлета

public void setCookie(HttpServletResponse response) throws IOException {
    // 1. Создание cookie (имя, значение)
    Cookie cookie = new Cookie("userTheme", "dark");

    // 2. Настройка времени жизни (в секундах)
    // -1: кука живет до закрытия браузера (сессионная)
    // 0: удаление куки
    // >0: время хранения в секундах (например, 3600 = 1 час)
    cookie.setMaxAge(60 * 60 * 24 * 7); // 1 неделя

    // 3. Настройка пути (доступна только для этой папки и ниже)
    cookie.setPath("/"); // Доступна для всего сайта

    // 4. Безопасность (только через HTTPS)
    cookie.setSecure(true); 

    // 5. Защита от XSS (JavaScript не получит доступ к куке)
    cookie.setHttpOnly(true);

    // 6. Добавление в ответ
    response.addCookie(cookie);
    
    response.getWriter().println("Cookie установлен!");
}
```
# Чтение
```java
import javax.servlet.http.Cookie;
import javax.servlet.http.HttpServletRequest;
import java.io.IOException;
import java.io.PrintWriter;

// ... внутри метода doGet или doPost

public void getCookie(HttpServletRequest request, HttpServletResponse response) throws IOException {
    PrintWriter out = response.getWriter();
    
    // 1. Получаем массив всех куки
    Cookie[] cookies = request.getCookies();
    
    String theme = "not found";

    if (cookies != null) {
        // 2. Ищем нужную куку по имени
        for (Cookie c : cookies) {
            if ("userTheme".equals(c.getName())) {
                theme = c.getValue();
                break;
            }
        }
    }

    out.println("Ваша тема: " + theme);
}
```