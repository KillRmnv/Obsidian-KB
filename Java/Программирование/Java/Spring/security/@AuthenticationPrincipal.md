## 1️⃣ Что такое `@AuthenticationPrincipal`

- Находится в пакете:
    

`import org.springframework.security.core.annotation.AuthenticationPrincipal;`

- Используется в **контроллере**, чтобы получить **объект текущего аутентифицированного пользователя** из `SecurityContext`.
    
- Spring Security хранит информацию о пользователе в объекте **`Authentication`**, который доступен через:
    

`SecurityContextHolder.getContext().getAuthentication()`

`@AuthenticationPrincipal` позволяет автоматически **достать principal** прямо в метод контроллера.