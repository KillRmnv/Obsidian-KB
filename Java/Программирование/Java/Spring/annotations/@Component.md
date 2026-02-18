@Component
public class MyComponent {
    public void sayHello() {
        System.out.println("Hello from MyComponent!");
    }
}
Spring автоматически создаст бин этого класса.

Можно внедрять в другие бины через @Autowired

| Аннотация         | Для чего используется                                         | Пример                                   |
| ----------------- | ------------------------------------------------------------- | ---------------------------------------- |
| `@Service`        | Сервисный слой (бизнес-логика)                                | `@Service class UserService {}`          |
| `@Repository`     | Слой доступа к данным, поддерживает обработку исключений JDBC | `@Repository class UserRepository {}`    |
| `@Controller`     | Веб-контроллер для обработки HTTP-запросов                    | `@Controller class UserController {}`    |
| `@RestController` | То же, что `@Controller` + `@ResponseBody` (возвращает JSON)  | `@RestController class ApiController {}` |
