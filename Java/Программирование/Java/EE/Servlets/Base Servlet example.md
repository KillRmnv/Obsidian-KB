``` java
package com.example.servlet;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.Map;

/**
 * Единый обработчик всех HTTP-методов в одном месте
 */
@WebServlet("/unified/*")
public class UnifiedServiceServlet extends HttpServlet {

    @Override
    protected void service(HttpServletRequest req, HttpServletResponse resp) 
            throws IOException {
        
        req.setCharacterEncoding("UTF-8");
        resp.setContentType("application/json;charset=UTF-8");
        
        String method = req.getMethod();
        String path = req.getPathInfo();
        
        PrintWriter out = resp.getWriter();
        
        // Единая логика маршрутизации
        switch (method) {
            case "GET" -> handleGet(req, resp, path, out);
            case "POST" -> handlePost(req, resp, path, out);
            case "PUT" -> handlePut(req, resp, path, out);
            case "DELETE" -> handleDelete(req, resp, path, out);
            case "PATCH" -> handlePatch(req, resp, path, out);
            default -> {
                resp.setStatus(HttpServletResponse.SC_METHOD_NOT_ALLOWED);
                out.print("{\"error\": \"Метод " + method + " не поддерживается\"}");
            }
        }
    }
    
    // Приватные методы-обработчики
    private void handleGet(HttpServletRequest req, HttpServletResponse resp, 
                          String path, PrintWriter out) {
        Map<String, String[]> params = req.getParameterMap();
        out.print("{\"method\": \"GET\", \"path\": \"" + path + 
                  "\", \"params\": " + params.size() + "}");
    }
    
    private void handlePost(HttpServletRequest req, HttpServletResponse resp, 
                           String path, PrintWriter out) throws IOException {
        // Чтение тела запроса
        String body = new String(req.getInputStream().readAllBytes());
        out.print("{\"method\": \"POST\", \"received\": " + body.length() + " bytes}");
    }
    
    private void handlePut(HttpServletRequest req, HttpServletResponse resp, 
                          String path, PrintWriter out) {
        out.print("{\"method\": \"PUT\", \"message\": \"Обновление ресурса\"}");
    }
    
    private void handleDelete(HttpServletRequest req, HttpServletResponse resp, 
                             String path, PrintWriter out) {
        out.print("{\"method\": \"DELETE\", \"message\": \"Удаление ресурса\"}");
    }
    
    private void handlePatch(HttpServletRequest req, HttpServletResponse resp, 
                            String path, PrintWriter out) {
        out.print("{\"method\": \"PATCH\", \"message\": \"Частичное обновление\"}");
    }
}
```