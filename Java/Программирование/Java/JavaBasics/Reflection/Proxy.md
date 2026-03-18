**Proxy** в Java — это механизм из пакета `java.lang.reflect`, который позволяет создавать динамические реализации интерфейсов во время выполнения программы.

Простыми словами: это способ "перехватить" вызов метода к объекту и добавить свою логику до, после или вместо вызова реального метода (без изменения исходного кода класса).

## Основные компоненты

1.  **`InvocationHandler`** : Функциональный интерфейс, содержащий один метод `invoke(Object proxy, Method method, Object[] args)`. Именно здесь пишется логика перехвата.
2.  **`Proxy`** : Класс, который генерирует новый класс и создает его экземпляр (прокси-объект).
3.  **Интерфейс**: Динамический прокси в Java может проксировать только интерфейсы (не классы).

## Пример использования

Допустим, у вас есть интерфейс сервиса и его реализация:

```java
// 1. Интерфейс
interface UserService {
    String getUserName(int id);
}

// 2. Реальная реализация
class SimpleUserService implements UserService {
    public String getUserName(int id) {
        // Имитация долгой работы
        try { Thread.sleep(500); } catch (InterruptedException e) {}
        return "User_" + id;
    }
}
```

Теперь создадим прокси для логирования времени выполнения метода:

```java
import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;

public class ProxyExample {
    public static void main(String[] args) {
        // Создаем оригинальный объект
        UserService originalService = new SimpleUserService();

        // Создаем прокси через статический метод newProxyInstance
        UserService proxyService = (UserService) Proxy.newProxyInstance(
                originalService.getClass().getClassLoader(), // ClassLoader
                new Class[]{UserService.class},             // Интерфейсы для проксирования
                new TimeLoggingHandler(originalService)     // InvocationHandler
        );

        // Вызываем метод у прокси (автоматически попадаем в handler)
        System.out.println(proxyService.getUserName(5));
    }
}

// Реализация InvocationHandler
class TimeLoggingHandler implements InvocationHandler {
    private final Object target; // Оригинальный объект, который мы оборачиваем

    public TimeLoggingHandler(Object target) {
        this.target = target;
    }

    @Override
    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
        long start = System.currentTimeMillis();

        // ВАЖНО: вызываем метод у оригинального объекта!
        Object result = method.invoke(target, args);

        long elapsed = System.currentTimeMillis() - start;
        System.out.println("Метод " + method.getName() + " выполнялся " + elapsed + " мс");

        return result;
    }
}
```

**Вывод в консоль:**
```
Метод getUserName выполнялся 503 мс
User_5
```

## Где применяется?

1.  **AOP (Аспектно-ориентированное программирование)**: Spring (через `@Transactional`, `@Cacheable`).
2.  **Ленивая инициализация**: Создание тяжелого объекта только в момент первого обращения.
3.  **Проверка прав доступа**: Проверка роли пользователя перед вызовом метода.
4.  **Логирование и мониторинг**.

## Важное ограничение

Как уже упоминалось, `java.lang.reflect.Proxy` работает **только с интерфейсами**. Если вам нужно проксировать конкретный класс (а не интерфейс), обычно используют библиотеку **CGLIB** (которая лежит в основе Spring-прокси), создающую прокси через наследование (дочерний класс).