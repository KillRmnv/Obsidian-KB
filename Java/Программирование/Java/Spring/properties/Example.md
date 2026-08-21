# Принципы написания application.yaml в Spring Boot

## 1. Иерархическая структура (отступы)

YAML использует **отступы** для создания иерархии. **Только пробелы, никаких табов!**

```yaml
#  НЕПРАВИЛЬНО (табуляция)
spring:
→datasource:
→→url: jdbc:...

#  ПРАВИЛЬНО (2 пробела)
spring:
  datasource:
    url: jdbc:...
```

---

## 2. Три способа записи свойств

| Способ | Пример | Когда использовать |
|--------|--------|------------------|
| **Точечная нотация** | `server.port=8080` | Простые свойства в `.properties` |
| **Вложенная** | `server: port: 8080` | Группировка связанных свойств |
| **Массивы/Списки** | `- item1` | Коллекции значений |

```yaml
# Все три стиля в YAML:
server:
  port: 8080                    # вложенный
  servlet:
    context-path: /api          # вложенный глубже

spring:
  profiles:
    active:                     # список
      - dev
      - local
```

---

## 3. Связывание с кодом (3 способа)

### Способ 1: @Value (простые значения)

```yaml
# application.yaml
приложение:
  название: "Мой Сервис"
  версия: "2.0"
  включен: true
```

```java
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class ИнфоСервис {
    
    @Value("${приложение.название}")
    private String название;
    
    @Value("${приложение.версия}")
    private String версия;
    
    @Value("${приложение.включен:true}")  // значение по умолчанию
    private boolean включен;
    
    public void показатьИнфо() {
        System.out.println("Приложение: " + название);
        System.out.println("Версия: " + версия);
    }
}
```

---

### Способ 2: @ConfigurationProperties (сложные объекты)  РЕКОМЕНДУЕТСЯ

```yaml
# application.yaml
сервер:
  хост: localhost
  порт: 8080
  ssl:
    включен: true
    сертификат: /path/to/cert.pem
    
настройки-пула:
  минимум: 5
  максимум: 20
  таймаут: 30s
  
разрешенные-ip:
  - 192.168.1.1
  - 192.168.1.2
  - 10.0.0.1
```

```java
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;
import java.util.List;

@Component
@ConfigurationProperties(prefix = "сервер")  // префикс из YAML
public class НастройкиСервера {
    
    private String хост;
    private int порт;
    private Ssl ssl;           // вложенный объект
    private List<String> разрешенныеIp;  // список
    
    // Геттеры и сеттеры ОБЯЗАТЕЛЬНЫ!
    public String getХост() { return хост; }
    public void setХост(String хост) { this.хост = хост; }
    
    public int getПорт() { return порт; }
    public void setПорт(int порт) { this.порт = порт; }
    
    public Ssl getSsl() { return ssl; }
    public void setSsl(Ssl ssl) { this.ssl = ssl; }
    
    public List<String> getРазрешенныеIp() { return разрешенныеIp; }
    public void setРазрешенныеIp(List<String> разрешенныеIp) { 
        this.разрешенныеIp = разрешенныеIp; 
    }
    
    // Вложенный класс для ssl:
    public static class Ssl {
        private boolean включен;
        private String сертификат;
        
        // геттеры и сеттеры...
        public boolean isВключен() { return включен; }
        public void setВключен(boolean включен) { this.включен = включен; }
        
        public String getСертификат() { return сертификат; }
        public void setСертификат(String сертификат) { this.сертификат = сертификат; }
    }
}
```

**Активация @ConfigurationProperties:**
```java
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@Configuration
@EnableConfigurationProperties(НастройкиСервера.class)
public class КонфигурацияПриложения {
}
```

**Использование в сервисе:**
```java
import org.springframework.stereotype.Service;

@Service
public class СетевойСервис {
    
    private final НастройкиСервера настройки;
    
    // Внедрение через конструктор (рекомендуется)
    public СетевойСервис(НастройкиСервера настройки) {
        this.настройки = настройки;
    }
    
    public void запустить() {
        System.out.println("Запуск на " + настройки.getХост() + ":" + настройки.getПорт());
        
        if (настройки.getSsl().isВключен()) {
            System.out.println("SSL включен, сертификат: " + настройки.getSsl().getСертификат());
        }
        
        System.out.println("Разрешённые IP: " + настройки.getРазрешенныеIp());
    }
}
```

---

### Способ 3: Environment (доступ ко всем свойствам)

```java
import org.springframework.core.env.Environment;
import org.springframework.stereotype.Component;

@Component
public class КонфигПроверка {
    
    private final Environment env;
    
    public КонфигПроверка(Environment env) {
        this.env = env;
    }
    
    public void проверить() {
        // Получить любое свойство
        String порт = env.getProperty("server.port");
        String профиль = env.getProperty("spring.profiles.active");
        
        // С проверкой
        Boolean включен = env.getProperty("фича.включена", Boolean.class, false);
    }
}
```

---

## 4. Профили (разные конфигурации для сред)

```
src/main/resources/
 application.yaml          # общая конфигурация
 application-dev.yaml      # разработка
 application-test.yaml     # тестирование
 application-prod.yaml     # продакшен
```

```yaml
# application.yaml (общий)
spring:
  profiles:
    active: dev  # активный профиль по умолчанию
    
приложение:
  название: "Универсальное Приложение"
```

```yaml
# application-dev.yaml (активируется только в dev)
server:
  port: 8080

spring:
  datasource:
    url: jdbc:h2:mem:testdb  # встроенная БД для разработки
    driver-class-name: org.h2.Driver
    
logging:
  level:
    root: DEBUG  # подробные логи
```

```yaml
# application-prod.yaml (активируется в продакшене)
server:
  port: 80

spring:
  datasource:
    url: jdbc:postgresql://prod-db:5432/production
    hikari:
      maximum-pool-size: 50  # большой пул для нагрузки
      
logging:
  level:
    root: WARN  # только важные сообщения
```

**Переключение профилей:**
```bash
# Через аргумент JVM
java -jar app.jar --spring.profiles.active=prod

# Через переменную окружения
export SPRING_PROFILES_ACTIVE=prod
```

---

## 5. Полный рабочий пример

```yaml
# application.yaml
приложение:
  название: "CRM Система"
  модуль:
    импорт:
      включен: true
      путь: /data/imports
      форматы: [csv, xlsx, json]
      лимит-строк: 10000
      
    экспорт:
      включен: true
      путь: /data/exports
      форматы:
        - pdf
        - xlsx
        - csv
        
  уведомления:
    email:
      включен: true
      сервер: smtp.company.ru
      порт: 587
      логин: ${EMAIL_LOGIN}      # переменная окружения
      пароль: ${EMAIL_PASSWORD}  # переменная окружения
```

```java
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;
import java.util.List;
import java.util.Map;

@Component
@ConfigurationProperties(prefix = "приложение")
public class НастройкиПриложения {
    
    private String название;
    private Map<String, Модуль> модуль;  // динамические ключи
    private Уведомления уведомления;
    
    // Геттеры и сеттеры...
    
    public static class Модуль {
        private boolean включен;
        private String путь;
        private List<String> форматы;
        private Integer лимитСтрок;
        
        // геттеры и сеттеры...
        public boolean isВключен() { return включен; }
        public void setВключен(boolean включен) { this.включен = включен; }
        
        public String getПуть() { return путь; }
        public void setПуть(String путь) { this.путь = путь; }
        
        public List<String> getФорматы() { return форматы; }
        public void setФорматы(List<String> форматы) { this.форматы = форматы; }
        
        public Integer getЛимитСтрок() { return лимитСтрок; }
        public void setЛимитСтрок(Integer лимитСтрок) { this.лимитСтрок = лимитСтрок; }
    }
    
    public static class Уведомления {
        private Email email;
        
        public static class Email {
            private boolean включен;
            private String сервер;
            private int порт;
            private String логин;
            private String пароль;
            
            // геттеры и сеттеры...
        }
    }
}
```

```java
import org.springframework.stereotype.Service;

@Service
public class ИмпортСервис {
    
    private final НастройкиПриложения настройки;
    
    public ИмпортСервис(НастройкиПриложения настройки) {
        this.настройки = настройки;
    }
    
    public void импортироватьДанные(String файл) {
        var настройкиИмпорта = настройки.getМодуль().get("импорт");
        
        if (!настройкиИмпорта.isВключен()) {
            throw new IllegalStateException("Модуль импорта отключен");
        }
        
        String расширение = получитьРасширение(файл);
        if (!настройкиИмпорта.getФорматы().contains(расширение)) {
            throw new IllegalArgumentException("Формат не поддерживается: " + расширение);
        }
        
        System.out.println("Импорт из: " + настройкиИмпорта.getПуть());
        System.out.println("Максимум строк: " + настройкиИмпорта.getЛимитСтрок());
    }
}
```

---

## 6. Шпаргалка: типы данных

| В YAML | В Java |
|--------|--------|
| `порт: 8080` | `int` |
| `включен: true` | `boolean` |
| `название: "Текст"` | `String` |
| `- a`<br>`- b`<br>`- c` | `List<String>` |
| `ключ: значение` | `Map<String, String>` |
| `дата: 2024-01-15` | `LocalDate` (с `@DateTimeFormat`) |
| `время: 30s` | `Duration` |

---

## 7. Главные правила

1. **Отступы = 2 пробела** (не табы!)
2. **Префиксы** в `@ConfigurationProperties` должны совпадать с YAML
3. **Геттеры и сеттеры** обязательны для `@ConfigurationProperties`
4. **Конструкторное внедрение** предпочтительнее `@Autowired`
5. **Профили** разделяют конфигурации по средам
6. **Переменные окружения** `${VAR}` для секретов