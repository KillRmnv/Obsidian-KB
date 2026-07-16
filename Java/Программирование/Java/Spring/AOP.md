## Что такое АОП (Aspect-Oriented Programming)

Это парадигма программирования, которая позволяет вынести **сквозную функциональность** (cross-cutting concerns) из основного кода в отдельные модули — **аспекты**. Сквозная функциональность — это логика, которая пронизывает множество модулей системы: логирование, безопасность, кеширование, управление транзакциями.

Вместо того чтобы дублировать код вызова логгера в каждом сервисе, вы описываете его **один раз** в аспекте, а Spring автоматически «вплетает» этот код в нужные места приложения.

---

## Основные понятия

| Термин | Объяснение |
|--------|------------|
| **Aspect (Аспект)** | Модуль, реализующий сквозную функциональность (класс с аннотацией `@Aspect`). |
| **Join Point (Точка соединения)** | Конкретная точка в работе программы, где можно применить аспект (вызов метода, обращение к полю). В Spring AOP это всегда **выполнение метода**. |
| **Advice (Совет)** | Код аспекта, который выполняется в определённой точке. Типы: `@Before`, `@After`, `@Around`, `@AfterReturning`, `@AfterThrowing`. |
| **Pointcut (Срез)** | Выражение, определяющее, к каким Join Point'ам применять Advice. Например: `execution(* com.example.service.*.*(..))` — все методы всех классов в пакете `service`. |
| **Weaving (Вплетение)** | Процесс внедрения аспекта в целевой код. Spring AOP использует **прокси (JDK dynamic proxy или CGLIB)** во время выполнения. |

---

## Пример в Spring (аннотационный стиль)

### 1. Добавьте зависимость
```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-aop</artifactId>
</dependency>
```

### 2. Создайте аспект
```java
@Aspect
@Component
public class LoggingAspect {

    // Срез для всех методов сервисного слоя
    @Pointcut("execution(* com.example.service.*.*(..))")
    public void serviceLayer() {}

    // Выполняется перед методом
    @Before("serviceLayer()")
    public void logBefore(JoinPoint joinPoint) {
        System.out.println("▶️ Вызов метода: " + joinPoint.getSignature().getName());
    }

    // Выполняется после успешного возврата
    @AfterReturning(pointcut = "serviceLayer()", returning = "result")
    public void logAfterReturning(JoinPoint joinPoint, Object result) {
        System.out.println("✅ Метод " + joinPoint.getSignature().getName()
                + " вернул: " + result);
    }

    // Оборачивает метод целиком (можно замерить время)
    @Around("serviceLayer()")
    public Object logTime(ProceedingJoinPoint pjp) throws Throwable {
        long start = System.currentTimeMillis();
        Object result = pjp.proceed();
        long time = System.currentTimeMillis() - start;
        System.out.println("⏱️ " + pjp.getSignature().getName() + " выполнен за " + time + " мс");
        return result;
    }
}
```

### 3. Целевой сервис
```java
@Service
public class UserService {
    public String getUser() {
        return "Alice";
    }
}
```

Теперь при вызове `userService.getUser()` автоматически сработают все советы аспекта.

---

## Где применяется АОП в реальных проектах

- **Декларативные транзакции** — аннотация `@Transactional` внутри работает через AOP-аспект.
- **Логирование и аудит**.
- **Обработка ошибок** (глобальный перехват исключений и повторные попытки).
- **Измерение производительности** (замер времени выполнения методов).
- **Проверка прав доступа** (security-аннотации вроде `@PreAuthorize`).
- **Кеширование** (`@Cacheable`).

---

## Spring AOP и AspectJ

Spring AOP — это proxy-based AOP, т.е. работает только для бинов, вызываемых через Spring-контейнер. Для более мощных возможностей (перехват создания объектов, private-методы, межтиповое объявление) используется **AspectJ** — полноценный фреймворк АОП, который может быть интегрирован со Spring.

---

## Итог

**AOP (Aspect-Oriented Programming)** в Spring — мощный инструмент для чистого отделения сквозной логики от бизнес-кода. С помощью аннотаций `@Aspect`, `@Before`, `@Around` и срезов вы можете централизованно управлять такими задачами, как логирование, безопасность и транзакции, без дублирования кода.

![[image-11.png]]