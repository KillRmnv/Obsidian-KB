# Application Context в Spring

## Простое определение

**Application Context** (контекст приложения) — это **"коробка" (контейнер)**, в которой Spring хранит все Bean'ы и управляет ими. Это сердце Spring-приложения.

```
┌─────────────────────────────────────────┐
│         Application Context             │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐   │
│  │  Bean   │ │  Bean   │ │  Bean   │   │
│  │   A     │ │   B     │ │   C     │   │
│  │ (Сервис)│ │(Репозит)│ │(Контрол)│   │
│  └─────────┘ └─────────┘ └─────────┘   │
│                                         │
│  • Создаёт Bean'ы                       │
│  • Связывает их (Dependency Injection)   │
│  • Управляет жизненным циклом           │
│  • Хранит конфигурацию                  │
└─────────────────────────────────────────┘
```

---

## Типы Application Context

| Тип | Для чего | Когда использовать |
|-----|---------|------------------|
| `AnnotationConfigApplicationContext` | Конфигурация через Java-аннотации | Обычные приложения |
| `ClassPathXmlApplicationContext` | Конфигурация через XML | Устарело, legacy |
| `FileSystemXmlApplicationContext` | XML из файловой системы | Редко |
| `WebApplicationContext` | Web-приложения (Spring Boot) | Web/API сервисы |

---

## Как получить доступ к Context

### Вариант 1: Автоматически (рекомендуется)

Spring Boot сам создаёт и настраивает Context — вы просто используете Bean'ы:

```java
@SpringBootApplication
public class МоеПриложение {
    public static void main(String[] args) {
        // Spring создаёт Context автоматически
        SpringApplication.run(МоеПриложение.class, args);
    }
}
```

### Вариант 2: Вручную (для понимания)

```java
import org.springframework.context.annotation.AnnotationConfigApplicationContext;

public class Демо {
    public static void main(String[] args) {
        // Создаём Context вручную
        AnnotationConfigApplicationContext context = 
            new AnnotationConfigApplicationContext(Конфигурация.class);
        
        // Получаем Bean из Context
        СервисОплаты сервис = context.getBean(СервисОплаты.class);
        сервис.обработатьПлатеж(100.0);
        
        // Закрываем Context
        context.close();
    }
}
```

---

## Что умеет Application Context

### 1. Получение Bean'ов

```java
import org.springframework.context.ApplicationContext;
import org.springframework.stereotype.Component;

@Component
public class ДемоContext {
    
    private final ApplicationContext context;
    
    public ДемоContext(ApplicationContext context) {
        this.context = context;
    }
    
    public void примерыПолученияBean() {
        // По классу
        СервисОплаты сервис1 = context.getBean(СервисОплаты.class);
        
        // По имени (если задано @Bean(name="..."))
        Object сервис2 = context.getBean("сервисОплаты");
        
        // Все Bean'ы определённого типа
        Map<String, Сервис> всеСервисы = 
            context.getBeansOfType(Сервис.class);
        
        // Проверка существования
        boolean есть = context.containsBean("сервисОплаты");
    }
}
```

### 2. Доступ к окружению и свойствам

```java
@Component
public class РаботаСОкружением {
    
    private final ApplicationContext context;
    private final Environment env;
    
    public РаботаСОкружением(ApplicationContext context, Environment env) {
        this.context = context;
        this.env = env;
    }
    
    public void показатьВозможности() {
        // Профили приложения
        String[] профили = context.getEnvironment().getActiveProfiles();
        
        // Свойства из application.yaml
        String порт = env.getProperty("server.port");
        String название = env.getProperty("spring.application.name");
        
        // Со значением по умолчанию
        Boolean дебаг = env.getProperty("debug", Boolean.class, false);
    }
}
```

### 3. Публикация событий

```java
// === СОЗДАЁМ СОБЫТИЕ ===
public class ЗаказСозданСобытие {
    private final Long idЗаказа;
    private final double сумма;
    
    public ЗаказСозданСобытие(Long id, double сумма) {
        this.idЗаказа = id;
        this.сумма = сумма;
    }
    // геттеры...
}

// === ПУБЛИКУЕМ СОБЫТИЕ ===
@Component
public class СервисЗаказов {
    private final ApplicationContext context;
    
    public СервисЗаказов(ApplicationContext context) {
        this.context = context;
    }
    
    public void создатьЗаказ() {
        // ... логика создания ...
        
        // Отправляем событие в Context
        context.publishEvent(new ЗаказСозданСобытие(123L, 1500.0));
    }
}

// === ПРИНИМАЕМ СОБЫТИЕ ===
@Component
public class ОбработчикУведомлений {
    
    @EventListener
    public void приЗаказеСоздан(ЗаказСозданСобытие событие) {
        System.out.println("Отправляем email о заказе #" + событие.getIdЗаказа());
    }
}
```

---

## Иерархия Context'ов

```
┌─────────────────────────────┐
│    Root Context (родитель)   │
│  • Общие сервисы            │
│  • Безопасность             │
│  • База данных              │
└─────────────┬───────────────┘
              │
    ┌─────────┴─────────┐
    ▼                   ▼
┌─────────────┐    ┌─────────────┐
│ Web Context │    │ Job Context │
│ (контроллеры)│   │ (задачи)    │
│ • Servlet'ы  │    │ • Планировщик│
└─────────────┘    └─────────────┘
```

```java
// Дочерний Context видит Bean'ы родителя, но не наоборот!
```

---

## ApplicationContext vs BeanFactory

| | BeanFactory | ApplicationContext |
|--|-------------|-------------------|
| **Что это** | Базовый контейнер | Расширенный контейнер |
| **Ленивая загрузка** | Bean'ы создаются при запросе | Bean'ы создаются при старте (eager) |
| **Возможности** | Только DI | DI + события + i18n + ресурсы + AOP |
| **Использование** | Редко | Всегда в Spring Boot |

```java
// BeanFactory — низкоуровневый
BeanFactory factory = new XmlBeanFactory(...);
Object bean = factory.getBean("myBean");

// ApplicationContext — высокоуровневый, предпочтительный
ApplicationContext context = new AnnotationConfigApplicationContext(...);
```

---

## Практический пример: полный цикл

```java
// === КОНФИГУРАЦИЯ ===
@Configuration
@ComponentScan("com.example")
public class КонфигурацияПриложения {
    
    @Bean
    public DataSource dataSource() {
        return new HikariDataSource();  // пул соединений
    }
}

// === СЕРВИС ===
@Service
public class ПользовательСервис {
    public void приветствие() {
        System.out.println("Привет из сервиса!");
    }
}

// === ЗАПУСК ===
public class Главный {
    public static void main(String[] args) {
        // 1. Создаём Context
        ApplicationContext context = 
            new AnnotationConfigApplicationContext(КонфигурацияПриложения.class);
        
        // 2. Получаем Bean
        ПользовательСервис сервис = context.getBean(ПользовательСервис.class);
        
        // 3. Используем
        сервис.приветствие();
        
        // 4. Проверяем что внутри Context
        System.out.println("Все Bean'ы:");
        for (String имя : context.getBeanDefinitionNames()) {
            System.out.println("  - " + имя);
        }
        
        // 5. Закрываем
        ((AnnotationConfigApplicationContext) context).close();
    }
}
```

**Вывод:**
```
Привет из сервиса!
Все Bean'ы:
  - конфигурацияПриложения
  - пользовательСервис
  - dataSource
  - org.springframework.context.annotation...
```

---

## В Spring Boot всё проще

```java
@SpringBootApplication
public class Приложение {
    public static void main(String[] args) {
        // Spring Boot сам создаёт и настраивает ApplicationContext
        ConfigurableApplicationContext context = 
            SpringApplication.run(Приложение.class, args);
        
        // Можно получить доступ если нужно
        Сервис сервис = context.getBean(Сервис.class);
        
        // Или использовать @Autowired в любом Bean'е
    }
}
```

---

## Итог

| Вопрос | Ответ |
|--------|-------|
| **Что такое Application Context?** | Контейнер, где живут все Bean'ы |
| **Кто создаёт Bean'ы?** | Context |
| **Кто связывает зависимости?** | Context |
| **Кто управляет жизнью Bean'ов?** | Context |
| **Как получить доступ?** | Через `@Autowired` или `SpringApplication.run()` |

**Application Context = "мозг" Spring-приложения**, который знает про все компоненты и управляет ими.