`@PropertySource` — это аннотация Spring, которая добавляет указанный файл свойств (`.properties`) в `Environment` приложения, делая значения доступными через `${...}`.

---

## Основное назначение
- Декларативно загрузить дополнительные `.properties`-файлы в контекст Spring.
- Работает на уровне стандартного Spring (не требует Spring Boot), но часто используется и в Boot-приложениях, если нужно подключить кастомные файлы.

---

## 1. Базовое использование

Ставится на класс, помеченный `@Configuration` (или любой, который попадает в контекст).

```java
@Configuration
@PropertySource("classpath:custom.properties")
public class AppConfig {
    // ...
}
```

Файл `src/main/resources/custom.properties`:
```properties
app.name=MyApp
app.timeout=5000
```

Теперь можно внедрять значения:

### Через `@Value`
```java
@Service
public class MyService {
    @Value("${app.name}")
    private String appName;
}
```

### Через `Environment`
```java
@Autowired
private Environment env;

public void print() {
    System.out.println(env.getProperty("app.name"));
}
```

---

## 2. Несколько файлов

Можно указать массив `@PropertySource` или воспользоваться контейнерной аннотацией `@PropertySources`:

```java
@Configuration
@PropertySources({
    @PropertySource("classpath:db.properties"),
    @PropertySource("classpath:security.properties")
})
public class AppConfig { }
```

---

## 3. Префиксы расположения

- `classpath:` — ищет в ресурсах (по умолчанию, можно опустить)
- `file:` — абсолютный/относительный путь в файловой системе

```java
@PropertySource("file:/etc/myapp/config.properties")
```

---

## 4. Обработка отсутствующего файла

По умолчанию, если файл не найден, контекст упадет с ошибкой.  
Чтобы игнорировать отсутствие, добавьте `ignoreResourceNotFound = true`:

```java
@PropertySource(value = "classpath:optional.properties", ignoreResourceNotFound = true)
```

---

## 5. Кодировка

Если файл содержит кириллицу или другие non-ASCII символы, укажите кодировку:

```java
@PropertySource(value = "classpath:labels.properties", encoding = "UTF-8")
```

---

## 6. Загрузка YAML-файлов

**Важно:** Стандартная `@PropertySource` **не поддерживает YAML** – она обрабатывает только `.properties` через `PropertiesLoader`.  
Для YAML используйте **`PropertySourceFactory`** (доступно с Spring 4.3+):

```java
@Configuration
@PropertySource(value = "classpath:app.yml", factory = YamlPropertySourceFactory.class)
public class AppConfig { }

// Реализация factory
public class YamlPropertySourceFactory implements PropertySourceFactory {
    @Override
    public PropertySource<?> createPropertySource(String name, EncodedResource resource) 
            throws IOException {
        YamlPropertiesFactoryBean factory = new YamlPropertiesFactoryBean();
        factory.setResources(resource.getResource());
        Properties properties = factory.getObject();
        return new PropertiesPropertySource(name != null ? name : resource.getResource().getFilename(), properties);
    }
}
```

В Spring Boot для YAML чаще используют нативный механизм `application.yml` и `@ConfigurationProperties`, но фабрика полезна для не-Boot приложений.

---

## 7. Работа с `@ConfigurationProperties` (Spring Boot)

В Spring Boot `application.properties` подгружается автоматически.  
`@PropertySource` используют для дополнительных файлов, которые затем мапят через `@ConfigurationProperties`:

```java
@Component
@PropertySource("classpath:extra.properties")
@ConfigurationProperties(prefix = "extra")
public class ExtraSettings {
    private String host;
    private int port;
    // getters/setters
}
```

В `extra.properties`:
```properties
extra.host=localhost
extra.port=9090
```

Однако лучше, если файл не входит в стандартный список Boot’а (например, не `application-*`), использовать ручное описание `@PropertySource`.

---

## 8. Альтернатива в XML

До появления аннотаций использовался элемент:

```xml
<context:property-placeholder location="classpath:app.properties" />
```

Аннотация `@PropertySource` – это современный аналог для Java-конфигурации.

---

## 9. Важные замечания

- Все загруженные свойства попадают в общий `Environment` и могут быть переопределены свойствами с более высоким приоритетом (например, переменными окружения, системными свойствами).
- Spring Boot автоматически сканирует `application.properties` и `application-{profile}.properties`, поэтому для них `@PropertySource` не нужна.
- Порядок объявления `@PropertySource` влияет на приоритет: если несколько файлов содержат один ключ, победит тот, который был загружен первым.

---

## Краткий итог

`@PropertySource` — простой и удобный способ добавить сторонний `.properties`-файл в контекст Spring. Используйте его, когда нужно вынести настройки из стандартного `application.properties` или в проектах без Spring Boot.