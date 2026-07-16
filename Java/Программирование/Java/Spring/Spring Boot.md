## Spring Boot — полный разбор для собеседования

Spring Boot — это не замена Spring, а **надстройка** над ним, решающая главную проблему «чистого» Spring: **сложность настройки**. Он вводит принцип **«opinionated defaults»** (разумные настройки по умолчанию) и позволяет запускать приложение как самостоятельный JAR с встроенным сервером. На собеседовании важно показать, что вы понимаете, **как Boot упрощает разработку** и как работает его магия.

---

### 1. Что Spring Boot добавляет относительно «чистого» Spring

| Функция | Описание |
| :--- | :--- |
| **Auto‑configuration** | Автоматически настраивает бины на основе зависимостей в classpath. Если есть `spring-boot-starter-data-jpa` — поднимется `DataSource`, `EntityManagerFactory`, `TransactionManager` без лишних конфигураций. |
| **Starter‑зависимости** | Сборные артефакты, которые тянут все необходимые библиотеки для определённой функциональности (web, jpa, security, test). Убирают головную боль с совместимостью версий. |
| **Встроенный сервер** | Tomcat, Jetty или Undertow по умолчанию запускаются внутри приложения. Приложение становится самостоятельным JAR с точкой входа `main`. |
| **Externalized Configuration** | Гибкая система конфигурации из множества источников: `application.properties`, переменные окружения, аргументы командной строки, системные свойства. |
| **Actuator** | Production‑ready endpoints для мониторинга (health, metrics, info, env, и т.д.) и управления приложением. |
| **Профили** | Поддерживаются профили (`dev`, `prod`, `test`) для разделения конфигураций, без каких‑либо дополнительных библиотек. |
| **Упрощённое тестирование** | Аннотации `@SpringBootTest`, `@DataJpaTest`, `@WebMvcTest` для срезов контекста. |

---

### 2. Основная аннотация — `@SpringBootApplication`

Это **композитная** аннотация, объединяющая три других:

- **`@Configuration`** — помечает класс как источник определения бинов.
- **`@EnableAutoConfiguration`** — включает механизм автоматической конфигурации Spring Boot (ключевая магия).
- **`@ComponentScan`** — сканирует компоненты в текущем пакете и подпакетах (аналог `@ComponentScan` без явных параметров).

Типичная точка входа:

```java
@SpringBootApplication
public class MyApplication {
    public static void main(String[] args) {
        SpringApplication.run(MyApplication.class, args);
    }
}
```

`SpringApplication.run()` создаёт контекст, запускает встроенный сервер и инициализирует все автоконфигурации.

---

### 3. Конфигурация через `application.properties` / `application.yml`

Spring Boot загружает настройки из файлов с именами `application` с расширениями `.properties` или `.yml` (YAML удобнее для иерархии). Места поиска (приоритет возрастает):

1. `file:./config/` (папка в корне приложения)
2. `file:./` (корень приложения)
3. `classpath:/config/` (папка в ресурсах)
4. `classpath:/` (корень classpath)

Эти файлы можно переопределять через переменные окружения или аргументы командной строки.

Пример:

```properties
# application.properties
server.port=8081
spring.datasource.url=jdbc:mysql://localhost:3306/mydb
spring.datasource.username=root
spring.datasource.password=123
```

Или YAML:

```yaml
server:
  port: 8081
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/mydb
    username: root
    password: 123
```

Для доступа к пропертям в коде используется `@Value` или `@ConfigurationProperties` (предпочтительнее для группировки).

---

### 4. Профили (`@Profile`, `spring.profiles.active`)

Профили позволяют иметь разные конфигурации для разных сред. В Boot это работает так же, как и в чистом Spring, но добавляется поддержка **многофайловой конфигурации**:

- `application-dev.properties` / `application-prod.properties`
- в `application.properties` можно указать `spring.profiles.active=dev` — тогда загрузятся общие настройки + специфичные для профиля.

Активация профиля:
- В `application.properties`: `spring.profiles.active=dev`
- Аргументом JVM: `-Dspring.profiles.active=prod`
- Переменной окружения: `SPRING_PROFILES_ACTIVE=test`

Пример в коде:

```java
@Configuration
@Profile("dev")
public class DevConfig { ... }

@Configuration
@Profile("prod")
public class ProdConfig { ... }
```

---

### 5. Externalized Configuration — внешние источники конфигурации

Spring Boot умеет читать настройки из множества источников с чётким приоритетом (от высокого к низкому):
1. Аргументы командной строки (`--server.port=8082`)
2. Свойства из `SPRING_APPLICATION_JSON` (переменная окружения)
3. Переменные окружения ОС (`SERVER_PORT=8083`)
4. Файлы `application-{profile}.properties` за пределами JAR
5. Файлы `application-{profile}.properties` внутри JAR
6. Встроенные дефолты

Это даёт гибкость для контейнеризации (Docker, Kubernetes) — настройки можно передавать через переменные окружения без пересборки артефакта.

---

### 6. Actuator — мониторинг и управление

Добавляется зависимостью:

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-actuator</artifactId>
</dependency>
```

Actuator предоставляет готовые REST endpoints для контроля состояния приложения:

- `/actuator/health` — статус (UP/DOWN) и детали здоровья (БД, диск, внешние сервисы).
- `/actuator/info` — пользовательская информация (версия, описание).
- `/actuator/metrics` — метрики (память, потоки, HTTP запросы).
- `/actuator/env` — окружение и свойства (можно скрыть чувствительные).
- `/actuator/loggers` — управление уровнями логирования на лету.

По умолчанию доступны только `/health` и `/info`, остальные нужно открывать через настройку:

```properties
management.endpoints.web.exposure.include=health,info,metrics,env
```

Можно интегрировать с Prometheus и Micrometer для сбора метрик в production.

---

### 7. Как работает auto‑configuration (под капотом)

Spring Boot анализирует classpath и наличие определённых классов. Например:

- Есть `DataSource` в classpath? → Boot создаст `DataSource` (если не определён свой).
- Есть `spring-boot-starter-web`? → Настроит `DispatcherServlet`, встроенный Tomcat, Jackson, валидацию.

Автоконфигурации реализованы через `@Configuration` классы, которые включаются **условно** (`@ConditionalOnClass`, `@ConditionalOnMissingBean`, `@ConditionalOnProperty` и т.д.). Это позволяет переопределять бины, просто создавая свои экземпляры.

**Важно**: Если вы создаёте свой бин того же типа, Boot его не перезаписывает, а использует ваш (благодаря `@ConditionalOnMissingBean`). Это даёт контроль над конфигурацией.

---

### 8. Дополнительные "киллер-фичи" для собеседования

- **DevTools**: `spring-boot-devtools` — автоматический перезапуск при изменении кода, LiveReload, отключение кэшей шаблонов для удобства разработки.
- **Spring Boot Starter Parent**: стандартный BOM (Bill of Materials) с заранее согласованными версиями зависимостей — избавляет от конфликтов.
- **Graceful shutdown**: в новых версиях (2.3+) можно включить плавное завершение, чтобы не обрывать запросы.
- **Кастомизация баннера**: настраиваемый ASCII‑баннер при старте.
- **Создание собственных стартеров**: для переиспользования внутри компании — создаётся авто-конфигурационный модуль с `spring.factories`.

---

### Итоговый шаблон ответа на собеседовании:

> *"Spring Boot — это утилитарный слой над Spring, который решает проблему конфигурации. Вместо того чтобы вручную настраивать `DispatcherServlet`, `DataSource`, `TransactionManager`, я просто добавляю стартер, и Boot делает всё за меня, используя разумные значения по умолчанию. В основе лежит аннотация `@SpringBootApplication`, объединяющая `@Configuration`, `@EnableAutoConfiguration` и `@ComponentScan`. Все настройки хранятся в `application.properties` или YAML, при этом поддерживаются профили и внешние источники (переменные окружения, командная строка). Для мониторинга в проде использую Actuator — health, metrics, info. Важно понимать, что автоконфигурация работает через `@Conditional`, поэтому я всегда могу переопределить любой бин, просто создав свой экземпляр в конфигурации."*

Если спросят про отличие от Spring Framework: отвечайте, что Boot не добавляет новых возможностей, а только упрощает их подключение и настройку, и является стандартом для всех современных проектов. 

Готовы к следующей теме? Могу раскрыть **Spring Security**, **REST API** или **Микросервисы/Spring Cloud**.