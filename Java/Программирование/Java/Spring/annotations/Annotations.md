1.[[@Component]]
Помечает класс как Spring-компонент, который будет управляться контейнером Spring (IoC).
2.[[@Autowired]]
Автоматически внедряет зависимости (dependency injection) в поля, конструкторы или сеттеры.
3.@Value
Подставляет значения из `application.properties` или `application.yml`
4.[[@Configuration]]
Говорит Spring, что класс содержит **bean-методы** для конфигурации
5.[[@Bean]]
6.[[@Scope]]
Определяет жизненный цикл бина
7.`@PostConstruct` / `@PreDestroy`

- `@PostConstruct` — метод вызывается **после создания бина и внедрения зависимостей**.
    
- `@PreDestroy` — вызывается **перед уничтожением бина**.
8.@Primary
Помечает бин как основной, если есть несколько кандидатов для внедрения.
9.@Qualifier
Выбирает конкретный бин, если есть несколько кандидатов.
10.@ComponentScan
Говорит Spring, где искать компоненты (`@Component`, `@Service` и т.д.).
```java
@Configuration
@ComponentScan("io.spring") // все пакеты и подпакеты
public class AppConfig {}
```
11.@EnableWebSecurity
12.@RestController
(@Controller
@ResponseBody)
Обозначает класс как **REST-контроллер**, т.е. все методы будут возвращать **тело ответа (JSON, XML и т.д.)**, а не имя view (как в обычном MVC).Если бы был просто `@Controller`, Spring ожидал бы **view template** (Thymeleaf, JSP).
13.@RequestMapping
- Определяет **URL-путь**, на который реагирует контроллер или конкретный метод.
- Может быть применена к классу или к методу.
- Поддерживает:
    - `path` / `value` → URL
    - `method` → HTTP-метод (GET, POST…)
    - `params`, `headers` → фильтрация по параметрам или заголовкам
14.[[@AuthenticationPrincipal]]
