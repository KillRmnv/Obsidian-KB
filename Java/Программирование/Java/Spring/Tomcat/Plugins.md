Плагины для Maven и Gradle значительно упрощают жизнь разработчика: они позволяют запускать Tomcat прямо из консоли, деплоить приложения на удаленный сервер и не копировать файлы вручную в папку `webapps`.

Здесь важно разделить два сценария:
1.  **Spring Boot (Встроенный Tomcat):** Плагин нужен для запуска самого приложения.
2.  **Классический WAR (Внешний Tomcat):** Плагин нужен для управления внешним сервером (запуск, деплой).

---

### 1. Maven Плагины

#### Сценарий А: Spring Boot (Встроенный Tomcat)
Вам **не нужен** плагин Tomcat. Вам нужен плагин Spring Boot, который сам поднимет встроенный сервер.

**В `pom.xml`:**
```xml
<build>
    <plugins>
        <plugin>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-maven-plugin</artifactId>
        </plugin>
    </plugins>
</build>
```
**Команды:**
*   `mvn spring-boot:run` — Запускает приложение со встроенным Tomcat.
*   `mvn package` — Создает исполняемый JAR.

#### Сценарий Б: Классический WAR (Внешний Tomcat)
Если вы делаете WAR-файл и хотите деплоить его на отдельный Tomcat (локальный или удаленный).

**Популярный плагин:** `tomcat7-maven-plugin` (работает и с Tomcat 8/9).

**В `pom.xml`:**
```xml
<build>
    <plugins>
        <plugin>
            <groupId>org.apache.tomcat.maven</groupId>
            <artifactId>tomcat7-maven-plugin</artifactId>
            <version>2.2</version>
            <configuration>
                <!-- Путь к менеджеру Tomcat -->
                <url>http://localhost:8080/manager/text</url>
                <!-- Имя сервера в settings.xml (где хранятся логин/пароль) -->
                <server>TomcatServer</server>
                <!-- Путь к приложению -->
                <path>/my-app</path>
            </configuration>
        </plugin>
    </plugins>
</build>
```

**Настройка доступа (`~/.m2/settings.xml`):**
Чтобы не хранить пароль в `pom.xml`, добавьте в файл настроек Maven:
```xml
<servers>
  <server>
    <id>TomcatServer</id>
    <username>admin</username>
    <password>password123</password>
  </server>
</servers>
```

**Команды:**
*   `mvn tomcat7:run` — Запускает Tomcat локально и деплоит приложение (для разработки).
*   `mvn tomcat7:deploy` — Деплоит WAR на удаленный сервер.
*   `mvn tomcat7:undeploy` — Удаляет приложение.

---

### 2. Gradle Плагины

#### Сценарий А: Spring Boot (Встроенный Tomcat)
Аналогично Maven, используем официальный плагин Spring.

**В `build.gradle`:**
```groovy
plugins {
    id 'org.springframework.boot' version '3.1.0'
    id 'java'
}

// Зависимости
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-web'
}
```
**Команды:**
*   `./gradlew bootRun` — Запускает приложение со встроенным Tomcat.
*   `./gradlew bootJar` — Собирает исполняемый JAR.

#### Сценарий Б: Классический WAR (Внешний Tomcat)
В мире Gradle нет одного "официального" плагина от Apache, но есть популярные.community решения.

**Вариант 1: Gretty (Рекомендуемый для WAR)**
Очень мощный плагин для запуска WAR-приложений локально (поддерживает Tomcat и Jetty).

**В `build.gradle`:**
```groovy
plugins {
    id 'war'
    id 'org.gretty' version '3.1.0'
}

gretty {
    servletContainer = 'tomcat9' // Или tomcat8, tomcat10
    httpPort = 8080
    contextPath = '/'
}
```
**Команды:**
*   `./gradlew appRun` — Запускает Tomcat и приложение.
*   `./gradlew appStop` — Останавливает.

**Вариант 2: com.bmuschko.tomcat**
Старый, но надежный плагин для управления внешним Tomcat (деплой на удаленный сервер).

**В `build.gradle`:**
```groovy
plugins {
    id 'com.bmuschko.tomcat' version '2.7.0'
}

tomcat {
    httpPort = 8080
    stopPort = 8081
    // Настройки для удаленного деплоя
    tomcatDeployer {
        url = 'http://localhost:8080/manager/text'
        username = 'admin'
        password = 'password123'
    }
}
```
**Команды:**
*   `./gradlew tomcatRun` — Локальный запуск.
*   `./gradlew tomcatDeploy` — Деплой на сервер.

---

### 3. Критически важная настройка сервера

Чтобы плагины Maven/Gradle могли деплоить приложения на **внешний** Tomcat (команды `deploy`), на самом сервере Tomcat должен быть настроен пользователь с правами менеджера.

Файл: `conf/tomcat-users.xml`

```xml
<tomcat-users>
    <!-- Роль для управления через GUI (браузер) -->
    <role rolename="manager-gui"/>
    <!-- Роль для управления через скрипты (Maven/Gradle) -->
    <role rolename="manager-script"/>
    
    <!-- Пользователь -->
    <user username="admin" password="strong_password" roles="manager-gui,manager-script"/>
</tomcat-users>
```
*Без роли `manager-script` команды `mvn tomcat7:deploy` вернут ошибку 403 Forbidden.*

---

### 4. Что выбрать? (Сводная таблица)

| Задача | Рекомендация | Инструмент |
| :--- | :--- | :--- |
| **Новый проект (Spring)** | **Spring Boot** | `spring-boot-maven-plugin` / `bootRun` |
| **Локальная разработка (WAR)** | **Gretty** (Gradle) или `tomcat7:run` (Maven) | Запускает Tomcat внутри сборки |
| **Деплой на прод (WAR)** | **CI/CD (Jenkins/GitLab)** | Лучше копировать WAR скриптом, чем через плагин |
| **Микросервисы** | **Spring Boot (JAR)** | Плагины Tomcat не нужны вовсе |

### Главный совет
Если вы только начинаете или у вас нет жестких требований использовать WAR-файлы:
1.  Используйте **Spring Boot**.
2.  Используйте **встроенный Tomcat**.
3.  Запускайте через `mvn spring-boot:run` или `gradle bootRun`.

Это избавит вас от 90% проблем с настройкой плагинов, версий Tomcat и прав доступа `tomcat-users.xml`. Плагины для внешнего Tomcat нужны в основном для поддержки легаси-проектов.