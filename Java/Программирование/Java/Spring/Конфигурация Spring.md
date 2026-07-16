## Конфигурация Spring — полный разбор для собеседования

Spring — это фреймворк, основанный на **инверсии управления (IoC)** и **внедрении зависимостей (DI)**. Всё управление объектами (бинами) возложено на **контейнер Spring**. Способ описания этих бинов и их связей — это и есть **конфигурация**. На собеседовании важно показать, что вы понимаете эволюцию подходов, внутреннее устройство контейнера, скоупы, а также современные best practices.

---

### 1. Варианты конфигурации

#### 1.1. XML-конфигурация (исторический подход)
- Ранние версии Spring (до 3.0) использовали исключительно XML.
- Все бины описывались в `<beans>` файле с тегами `<bean>`, свойства и зависимости прописывались через `<property>` или `<constructor-arg>`.
- **Недостатки**: громоздкость, неудобная поддержка, отсутствие type-safety.
- **Пример**:
```xml
<beans>
    <bean id="userService" class="com.example.UserService">
        <property name="userRepository" ref="userRepository"/>
    </bean>
    <bean id="userRepository" class="com.example.UserRepository"/>
</beans>
```
- Сегодня используется крайне редко, но в легаси может встречаться.

#### 1.2. Java-конфигурация (`@Configuration` + `@Bean`)
- Появилась в Spring 3.0 и стала основным способом.
- Класс помечается `@Configuration`, внутри методы с `@Bean` создают и настраивают объекты.
- **Преимущества**: type-safe, легко читается, поддерживает рефакторинг, можно использовать любой Java-код внутри метода.
- **Пример**:
```java
@Configuration
public class AppConfig {
    @Bean
    public UserRepository userRepository() {
        return new UserRepository();
    }

    @Bean
    public UserService userService(UserRepository userRepository) {
        return new UserService(userRepository);
    }
}
```
- Также используются аннотации: `@Component`, `@Service`, `@Repository`, `@Controller` для автоматического обнаружения бинов.

#### 1.3. Другие способы (менее популярные)
- **Groovy-конфигурация** (Spring 4+) — DSL на Groovy.
- **Kotlin DSL** в Spring Boot.
- Но на практике вы встретите либо Java-конфиг, либо Spring Boot с автоконфигурацией.

---

### 2. Контейнер Spring: BeanFactory vs ApplicationContext

**Контейнер** — это основа IoC. Он создаёт объекты (бины), управляет их жизненным циклом и разрешает зависимости.

#### 2.1. `BeanFactory` (интерфейс)
- Базовый контейнер.
- **Ленивая инициализация** — бин создаётся только при первом запросе.
- Минимальный функционал: только создание и внедрение бинов.
- Используется редко, обычно в ограниченных средах (например, мобильные устройства).

#### 2.2. `ApplicationContext` (расширяет BeanFactory)
- **Более богатый функционал**, именно он используется в 99% случаев.
- Что добавляет:
  - **Интернационализация** (`MessageSource`) — поддержка сообщений для разных локалей.
  - **Публикация событий** (`ApplicationEventPublisher`) — механизм событий внутри контекста.
  - **Поддержка AOP** (через прокси-бины).
  - **Автоматическое сканирование компонентов** (component scan) — если включено.
  - **Доступ к ресурсам** (абстракция `ResourceLoader`).
  - **Единая точка входа** для всех бинов.
  - **Eager-инициализация** по умолчанию — все синглтоны создаются при старте контекста.
- Самые частые реализации:
  - `AnnotationConfigApplicationContext` — для standalone-приложений.
  - `ClassPathXmlApplicationContext` / `FileSystemXmlApplicationContext` — для XML (устарели).
  - `WebApplicationContext` — для веб-приложений.

**На собеседовании спросят**: "Почему мы используем ApplicationContext, а не BeanFactory?" — отвечайте про богатую функциональность и удобство.

---

### 3. Скоупы бинов (Scopes)

Скоуп определяет жизненный цикл и видимость бина внутри контейнера.

| Скоуп | Описание |
|-------|----------|
| **singleton** (по умолчанию) | Один экземпляр на весь контейнер. Создаётся при старте (eager) или лениво, если указано `@Lazy`. |
| **prototype** | Новый экземпляр при каждом запросе (при каждом внедрении или вызове `getBean`). Контейнер не управляет его жизненным циклом после создания (не вызывает destroy-методы). |
| **request** (только веб) | Один бин на один HTTP-запрос. Живёт в рамках запроса. |
| **session** (только веб) | Один бин на одну HTTP-сессию. |
| **application** (только веб) | Один бин на весь жизненный цикл `ServletContext` (похож на синглтон, но привязан к контексту сервлета). |
| **websocket** (только веб) | Один бин на WebSocket-сессию. |

**Как указать скоуп:**
```java
@Bean
@Scope("prototype")
public MyPrototypeBean myPrototypeBean() { ... }

// или через константы
@Scope(ConfigurableBeanFactory.SCOPE_PROTOTYPE)
```

**Важно**: при внедрении prototype-бина в singleton, prototype-бин становится как бы "замороженным" — если вам нужно каждый раз новый экземпляр, используйте `@Lookup` или `ObjectFactory`.

---

### 4. Как создаётся контекст (способы запуска)

#### 4.1. В standalone (Java-приложение)
```java
ApplicationContext context = new AnnotationConfigApplicationContext(AppConfig.class);
UserService service = context.getBean(UserService.class);
```
- Также можно указать пакеты для сканирования: `new AnnotationConfigApplicationContext("com.example")`.

#### 4.2. В Spring Boot
- Используется **автоконфигурация** (`@SpringBootApplication` = `@Configuration` + `@EnableAutoConfiguration` + `@ComponentScan`).
- Контекст создаётся автоматически в `SpringApplication.run(...)`.
- Spring Boot анализирует classpath, подключает свойства, настраивает бины по умолчанию (DataSource, JPA, MVC и т.д.).

#### 4.3. В веб-приложении (без Spring Boot)
- В web.xml или через `WebApplicationInitializer` (Servlet 3.0+) создаётся корневой `WebApplicationContext` и отдельный контекст для `DispatcherServlet`.
- `DispatcherServlet` создаёт свой дочерний контекст, который может обращаться к бинам родительского.
- `WebApplicationContext` расширяет `ApplicationContext` и имеет доступ к `ServletContext`.

---

### 5. Аннотационный конфиг + Component Scan

#### Что такое Component Scan?
- Механизм, который автоматически находит классы, помеченные стереотипными аннотациями (`@Component`, `@Service`, `@Repository`, `@Controller`, `@RestController`, `@Configuration`), и регистрирует их как бины в контейнере.
- Для этого используется `@ComponentScan` (явно или неявно через `@SpringBootApplication`).

#### Как работает?
1. Spring сканирует указанные пакеты (и подпакеты) на наличие классов с аннотациями.
2. Для каждого подходящего класса создаётся `BeanDefinition` (метаданные бина).
3. Затем контейнер создаёт экземпляры бинов и внедряет зависимости.
4. Механизм использует **ASM** (библиотеку для работы с байт-кодом) — не загружает все классы в память, что экономит ресурсы.

#### "Если понимаешь component scan — понимаешь Spring"
- Эта фраза подчёркивает, что **основная ценность Spring** — это автоматическая сборка контекста. Если вы понимаете, как и где сканируются классы, как исключить ненужные, как настроить фильтры, как работают `@Conditional` и `@Profile` — вы понимаете всю экосистему.
- Важно уметь настраивать `@ComponentScan(basePackages = ...)`, `excludeFilters`, `includeFilters`.
- Также важно понимать, что **сканирование — это ресурсоёмкая операция**, и в больших проектах его нужно настраивать грамотно.

#### Пример:
```java
@Configuration
@ComponentScan(basePackages = "com.example.services")
public class AppConfig {
    // бины из пакета com.example.services будут найдены автоматически
}
```

---

### 6. Профили (`@Profile`)

Профили позволяют иметь разные конфигурации для разных сред (dev, test, prod).

#### Основные аннотации и настройки:
- `@Profile("dev")` — помечается класс `@Configuration` или отдельный `@Bean`, чтобы активировать его только если профиль активен.
- `spring.profiles.active` — свойство для указания активных профилей (через `application.properties`, переменную окружения, аргументы JVM: `-Dspring.profiles.active=dev`).
- Можно задать несколько профилей через запятую.

#### Пример:
```java
@Configuration
@Profile("prod")
public class ProdConfig {
    @Bean
    public DataSource dataSource() {
        // возвращаем production DataSource
    }
}

@Configuration
@Profile("dev")
public class DevConfig {
    @Bean
    public DataSource dataSource() {
        // возвращаем in-memory H2
    }
}
```
- Также можно комбинировать: `@Profile({"dev", "test"})`.

#### Варианты активации:
- В `application.properties`: `spring.profiles.active=dev`
- В коде: `new AnnotationConfigApplicationContext(); context.getEnvironment().setActiveProfiles("dev");`
- В Spring Boot тестах: `@ActiveProfiles("test")`

#### Дополнительно:
- `@Conditional` — более гибкий механизм, позволяет включать бины на основе любых условий (наличие класса, свойство, ОС и т.д.).
- `@ConditionalOnProperty` (из Spring Boot) — часто используется для автоконфигурации.

---

### 7. Дополнительные моменты для собеседования

- **Циклические зависимости**: Spring может разрешить их для синглтонов (используя кеш ранних ссылок), но для prototype – выбросит исключение.
- **Жизненный цикл бина**: создание → заполнение свойств → `@PostConstruct` → `InitializingBean` → использование → `@PreDestroy` → `DisposableBean`.
- **Внедрение зависимостей**: через конструктор (рекомендуется), через сеттер, через поле (`@Autowired`). В Spring 4.3+ конструктор с одним аргументом может не требовать `@Autowired`.
- **`@Primary`** – указывает, какой бин использовать, если есть несколько кандидатов.
- **`@Qualifier`** – уточняет, какой именно бин внедрить.

---

### Итоговый совет для собеседования

На вопрос "Расскажите о конфигурации Spring" вы должны:
1. Сказать, что конфигурация бывает XML и Java-based, но сейчас стандарт – Java-конфиг.
2. Объяснить, что такое контейнер, сравнить `BeanFactory` и `ApplicationContext`.
3. Перечислить скоупы и сказать, какой используется по умолчанию.
4. Рассказать, как создаётся контекст в разных типах приложений.
5. Подробно остановиться на component scan – как он работает и почему важен.
6. Упомянуть профили для разделения окружений.

Покажите, что вы не просто заучили теорию, а понимаете, как эти механизмы работают вместе. Например, что Spring Boot включает автоконфигурацию, которая сама использует `@Conditional` и профили, а component scan находит ваши компоненты.

Удачи на собеседовании! Если будут уточняющие вопросы — задавайте.