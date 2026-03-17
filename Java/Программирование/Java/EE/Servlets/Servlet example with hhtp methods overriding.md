``` java
package com.example.servlet;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.io.PrintWriter;

// Аннотация для маппинга URL (альтернатива web.xml)
@WebServlet(name = "HelloServlet", urlPatterns = {"/hello"})
public class HelloServlet extends HttpServlet {

    // Инициализация сервлета
    @Override
    public void init() throws ServletException {
        super.init();
        System.out.println("Servlet инициализирован!");
    }

    // Обработка GET-запросов
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        // Установка типа контента и кодировки
        response.setContentType("text/html;charset=UTF-8");
        
        // Получение параметра из URL (например, /hello?name=Иван)
        String name = request.getParameter("name");
        if (name == null || name.isEmpty()) {
            name = "Гость";
        }

        // Запись ответа
        try (PrintWriter out = response.getWriter()) {
            out.println("<!DOCTYPE html>");
            out.println("<html>");
            out.println("<head><title>Приветствие</title></head>");
            out.println("<body>");
            out.println("<h1>Привет, " + name + "!</h1>");
            out.println("<p>Метод запроса: " + request.getMethod() + "</p>");
            out.println("<p>IP клиента: " + request.getRemoteAddr() + "</p>");
            out.println("</body>");
            out.println("</html>");
        }
    }

    // Обработка POST-запросов
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response) 
            throws ServletException, IOException {
        
        // Установка кодировки для корректной обработки русских символов
        request.setCharacterEncoding("UTF-8");
        
        String message = request.getParameter("message");
        
        response.setContentType("text/plain;charset=UTF-8");
        PrintWriter out = response.getWriter();
        out.println("Получено сообщение: " + message);
    }

    // Уничтожение сервлета
    @Override
    public void destroy() {
        System.out.println("Servlet уничтожен!");
        super.destroy();
    }
}
```