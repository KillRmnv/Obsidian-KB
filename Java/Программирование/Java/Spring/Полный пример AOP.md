Ниже — полноценный пример, который демонстрирует **все аннотации Spring AOP** (`@Aspect`, `@Pointcut`, `@Before`, `@AfterReturning`, `@AfterThrowing`, `@After`, `@Around`), а также различные **pointcut-выражения** (execution, within, args, @annotation, bean), комбинирование срезов, передачу параметров, обработку исключений и замер времени.

В примере используется Spring Boot (AOP включён автоматически), но логика полностью применима и к чистому Spring с аннотацией `@EnableAspectJAutoProxy` на конфигурации.

---

## 📦 Зависимость (Boot)

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-aop</artifactId>
</dependency>
```

---

## 🎯 1. Кастомная аннотация для маркировки методов

Будем использовать её, чтобы показать pointcut по аннотации.

```java
package com.example.demo.aop;

import java.lang.annotation.ElementType;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface Loggable {
    String value() default "";   // дополнительный комментарий
}
```

---

## 🧩 2. Целевые сервисы (Join Points)

Создадим два сервиса, чтобы протестировать разные срезы: один обычный, второй с кастомной аннотацией.

```java
package com.example.demo.service;

import com.example.demo.aop.Loggable;
import org.springframework.stereotype.Service;

@Service
public class UserService {

    public String getUser(String name) {
        return "User: " + name;
    }

    @Loggable("получение списка пользователей")
    public String getAllUsers() {
        return "All users list";
    }

    public void riskyMethod(boolean fail) {
        if (fail) {
            throw new RuntimeException("Ошибка в UserService");
        }
    }
}
```

```java
package com.example.demo.service;

import org.springframework.stereotype.Service;

@Service
public class OrderService {

    public String createOrder(String product) {
        return "Order for: " + product;
    }
}
```

---

## 🎭 3. Полноценный аспект со всеми аннотациями

```java
package com.example.demo.aop;

import org.aspectj.lang.JoinPoint;
import org.aspectj.lang.ProceedingJoinPoint;
import org.aspectj.lang.annotation.*;
import org.springframework.stereotype.Component;

import java.util.Arrays;

@Aspect                // объявляет класс как аспект
@Component             // регистрируем в Spring-контейнере
public class DemoAspect {

    // ======== Определение срезов (Pointcuts) ========

    // 1) Все методы в пакете service любого класса с любыми аргументами
    @Pointcut("execution(* com.example.demo.service.*.*(..))")
    public void allServiceMethods() {}

    // 2) Только методы, помеченные нашей аннотацией @Loggable
    @Pointcut("@annotation(com.example.demo.aop.Loggable)")
    public void loggableMethods() {}

    // 3) Методы, где первый аргумент — строка (покажем передачу параметра)
    @Pointcut("execution(* com.example.demo.service.*.*(String, ..))")
    public void methodsWithFirstStringArg() {}

    // 4) Комбинированный срез: метод с аннотацией @Loggable И принадлежащий service-слою
    @Pointcut("allServiceMethods() && loggableMethods()")
    public void loggableServiceMethods() {}

    // 5) Бин с конкретным именем (например, orderService)
    @Pointcut("bean(orderService)")
    public void orderServiceBean() {}

    // 6) Методы, выбрасывающие исключение — отдельный срез для демонстрации @AfterThrowing
    @Pointcut("execution(* com.example.demo.service..riskyMethod(..))")
    public void riskyMethods() {}

    // ======== Советы (Advice) ========

    // 1. @Before – перед выполнением метода, получаем детали вызова
    @Before("allServiceMethods()")
    public void beforeAnyServiceMethod(JoinPoint joinPoint) {
        String methodName = joinPoint.getSignature().toShortString();
        Object[] args = joinPoint.getArgs();
        System.out.println("[Before] Вызов: " + methodName + " | аргументы: " + Arrays.toString(args));
    }

    // 2. @AfterReturning – после успешного возврата, можно получить результат
    @AfterReturning(pointcut = "loggableServiceMethods()", returning = "result")
    public void afterReturningFromLoggable(JoinPoint joinPoint, Object result) {
        System.out.println("[AfterReturning] Метод " + joinPoint.getSignature().getName()
                + " отработал успешно, результат: " + result);
    }

    // 3. @AfterThrowing – если метод выбросил исключение
    @AfterThrowing(pointcut = "riskyMethods()", throwing = "ex")
    public void afterThrowingFromRisky(JoinPoint joinPoint, Throwable ex) {
        System.out.println("[AfterThrowing] Метод " + joinPoint.getSignature().getName()
                + " упал с ошибкой: " + ex.getMessage());
    }

    // 4. @After – выполняется всегда (аналог finally), независимо от успешности
    @After("allServiceMethods()")
    public void afterAnyServiceMethod(JoinPoint joinPoint) {
        System.out.println("[After] Завершён метод: " + joinPoint.getSignature().getName());
    }

    // 5. @Around – полный контроль: можно обернуть вызов, замерить время, подавить исключение
    @Around("orderServiceBean()")
    public Object aroundOrderService(ProceedingJoinPoint pjp) throws Throwable {
        long start = System.currentTimeMillis();

        System.out.println("[Around] >>> До вызова: " + pjp.getSignature().getName());
        Object result;
        try {
            result = pjp.proceed();   // выполняем целевой метод
        } catch (Exception e) {
            // Можно изменить поведение: проглотить, логировать, обернуть
            System.out.println("[Around] Перехвачено исключение: " + e.getMessage());
            result = "ЗАГЛУШКА (исключение подавлено аспектом)";
        }
        long time = System.currentTimeMillis() - start;
        System.out.println("[Around] <<< После вызова: " + pjp.getSignature().getName()
                + " | время: " + time + " мс | результат: " + result);
        return result;
    }

    // 6. Дополнительный @Before с фильтрацией по имени аргумента
    @Before("methodsWithFirstStringArg() && args(param)")
    public void beforeStringArgMethods(String param) {
        System.out.println("[Before String Arg] Первый аргумент-строка: " + param);
    }
}
```

---

## ⚙️ Конфигурация (если не Boot, иначе не требуется)

В чистом Spring нужно включить AOP прокси:

```java
@Configuration
@EnableAspectJAutoProxy
@ComponentScan(basePackages = "com.example.demo")
public class AppConfig {}
```

В Spring Boot ничего добавлять не надо — AOP включается автоматически при наличии `spring-boot-starter-aop`.

---

## 🚀 4. Демонстрация работы

Запустим приложение и вызовем несколько методов через контроллер или CommandLineRunner.

```java
@Component
public class Runner implements CommandLineRunner {
    @Autowired private UserService userService;
    @Autowired private OrderService orderService;

    @Override
    public void run(String... args) {
        System.out.println("=== getUser ===");
        userService.getUser("Alice");

        System.out.println("\n=== getAllUsers (@Loggable) ===");
        userService.getAllUsers();

        System.out.println("\n=== riskyMethod(true) ===");
        try {
            userService.riskyMethod(true);
        } catch (Exception ignored) { }

        System.out.println("\n=== createOrder (OrderService) ===");
        orderService.createOrder("Book");
    }
}
```

### Вывод в консоль (примерный):

```
=== getUser ===
[Before] Вызов: UserService.getUser(..) | аргументы: [Alice]
[Before String Arg] Первый аргумент-строка: Alice
[After] Завершён метод: getUser

=== getAllUsers (@Loggable) ===
[Before] Вызов: UserService.getAllUsers(..) | аргументы: []
[AfterReturning] Метод getAllUsers отработал успешно, результат: All users list
[After] Завершён метод: getAllUsers

=== riskyMethod(true) ===
[Before] Вызов: UserService.riskyMethod(..) | аргументы: [true]
[AfterThrowing] Метод riskyMethod упал с ошибкой: Ошибка в UserService
[After] Завершён метод: riskyMethod

=== createOrder (OrderService) ===
[Around] >>> До вызова: createOrder
[Before] Вызов: OrderService.createOrder(..) | аргументы: [Book]
[Before String Arg] Первый аргумент-строка: Book
[Around] <<< После вызова: createOrder | время: 12 мс | результат: Order for: Book
[After] Завершён метод: createOrder
```

---

## 📌 Объяснение ключевых моментов

- **`@Pointcut`** определяет именованные срезы, которые можно переиспользовать и комбинировать (`&&`, `||`, `!`).
- **`@Before`** – выполняется до метода, позволяет видеть аргументы.
- **`@AfterReturning`** – получает возвращаемое значение (только при успехе).
- **`@AfterThrowing`** – перехватывает бросаемое исключение, но не может его подавить (для этого нужен `@Around`).
- **`@After`** – работает как `finally`, вызывается всегда.
- **`@Around`** – самый мощный: полностью оборачивает вызов, позволяет измерять время, обрабатывать ошибки, менять возвращаемое значение, а также предотвращать дальнейшее выполнение pointcut'а.
- **Передача параметров** – через `args(param)` в pointcut и одноимённый параметр в advice.
- **Pointcut по аннотации** – `@annotation(com.example.demo.aop.Loggable)` позволяет аспектно реагировать на присутствие аннотации на методе.
- **Срез по имени бина** – `bean(orderService)` применяет advice только к бину с именем `orderService`.

---

## 💡 Когда это пригождается

- **Логирование и трассировка** всех сервисов, методов с аннотациями.
- **Транзакционность** (внутренний механизм `@Transactional`).
- **Метрики и мониторинг** (замер времени выполнения).
- **Безопасность** (проверка прав доступа до вызова метода).
- **Кеширование** (оборачивание результата `@Around`).
- **Повторные попытки** (retry) при исключениях.

Этот пример покрывает практически все аннотации и сценарии, которые используются в реальных проектах.