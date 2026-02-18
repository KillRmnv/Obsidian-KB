# JDK 1.1 — подробный разбор

**Кратко:** JDK 1.1 (выпущен в феврале 1997) — крупное промежуточное обновление Java 1.0, которое ввело несколько фундаментальных языковых и платформенных возможностей (inner-классы, новый AWT event-model, JavaBeans, JDBC, RMI, базовую рефлексию и т. п.). ([The Java Version Almanac](https://javaalmanac.io/jdk/1.1/?utm_source=chatgpt.com "Java 1.1 - javaalmanac.io"))

---

## Дата релиза и статус

- **Релиз:** 18–19 февраля 1997 (обычно указывают 19 февраля 1997). ([The Java Version Almanac](https://javaalmanac.io/jdk/1.1/?utm_source=chatgpt.com "Java 1.1 - javaalmanac.io"))
    
- Это уже историческая версия; все современные проекты используют более поздние JDK (LTS и т. п.), но 1.1 — важный веховый релиз, давший ключевые концепты. ([columbia.edu](https://www.columbia.edu/cu/help/jdk/docs/relnotes/features.html?utm_source=chatgpt.com "JDK 1.1 New Feature Summary"))
    

---

## Ключевые нововведения (с объяснениями)

### 1) Inner-классы (вложенные классы)

Вводит возможность объявления классов внутри других классов — именованных, анонимных и локальных. Это значительно упростило реализацию callback-ов и реализаций обработчиков, потому что вложенный класс имеет доступ к полям внешнего класса.  
Пример (анонимный класс, как в 1.1):

```java
button.addActionListener(new ActionListener() {
    public void actionPerformed(ActionEvent e) {
        // обработка события
    }
});
```

Эта возможность стала основой для компактной организации кода до появления лямбд в Java 8. ([cs.cornell.edu](https://www.cs.cornell.edu/andru/javaspec/1.1Update.html?utm_source=chatgpt.com "Changes for Java 1.1"))

---

### 2) Новая модель событий AWT — delegation event model

До 1.1 использовалась устаревшая модель, где события перехватывались переопределением методов. В 1.1 введена **делегирующая модель** (addXxxListener), которая разбивает обработку событий на отдельные слушатели и улучшает масштабируемость GUI-программ. Это подготовило почву для последующей экосистемы Swing. ([Википедия](https://en.wikipedia.org/wiki/Java_version_history?utm_source=chatgpt.com "Java version history"))

---

### 3) JavaBeans — компонентная модель

Введён стандарт компонентов (JavaBeans) — соглашения по именованию свойств (`getX/setX`), событиям и сериализации, что упростило создание визуальных редакторов и переиспользуемых UI/логических компонент. JavaBeans сделали возможным RAD-инструменты и визуальное связывание свойств. ([Википедия](https://en.wikipedia.org/wiki/Java_version_history?utm_source=chatgpt.com "Java version history"))

---

### 4) JDBC (Java Database Connectivity)

Появился стандарт доступа к реляционным БД — API `java.sql` и мост JDBC-ODBC. Благодаря этому Java-приложения получили унифицированный способ работать с базами данных (Connection, Statement, ResultSet и т. п.). Простейший пример:

```java
Connection c = DriverManager.getConnection("jdbc:odbc:DataSource", "user", "pass");
Statement s = c.createStatement();
ResultSet rs = s.executeQuery("SELECT id, name FROM users");
```

JDBC сделал Java пригодным и для серверных/бизнес-приложений. ([columbia.edu](https://www.columbia.edu/cu/help/jdk/docs/relnotes/features.html?utm_source=chatgpt.com "JDK 1.1 New Feature Summary"))

---

### 5) RMI (Remote Method Invocation) и улучшенная сериализация

Добавлена стандартная модель удалённого вызова методов (RMI) — удалённые интерфейсы, stub/skeleton-механика, интеграция с сериализацией Java. Это упростило распределённую объектную разработку на Java. ([Википедия](https://en.wikipedia.org/wiki/Java_version_history?utm_source=chatgpt.com "Java version history"))

---

### 6) Reflection / Introspection (ограниченная рефлексия)

Введены возможности **инспекции** классов в рантайме (инспектирование методов, полей) — достаточные для построения фреймворков и инструментов, но без полного набора возможностей модификации байткода в рантайме, которые появились позже. Это позволило, например, инструментам работать с JavaBeans и строить IDE-функции. ([Википедия](https://en.wikipedia.org/wiki/Java_version_history?utm_source=chatgpt.com "Java version history"))

---

### 7) Международализация (i18n) и локали

Добавлены классы для работы с локалями и ресурс-бандлами (`Locale`, `ResourceBundle`, форматы дат/чисел), что улучшило поддержку разных языков/регионов. Unicode-поддержка была обновлена (Unicode 2.0). ([The Java Version Almanac](https://javaalmanac.io/jdk/1.1/?utm_source=chatgpt.com "Java 1.1 - javaalmanac.io"))

---

### 8) Расширение стандартной библиотеки

Появились новые пакеты и классы — больше утилит в `java.util`, поддержка ZIP (`java.util.zip`), изменения в `java.io`, расширенные возможности AWT и т. п. Общее количество публичных классов значительно выросло по сравнению с 1.0. ([eecis.udel.edu](https://www.eecis.udel.edu/~caviness/java/docs/relnotes/classlist.html?utm_source=chatgpt.com "JDK 1.1.1 Class List"))

---

## Почему это было важно

- Многие из концепций 1.1 (JavaBeans, JDBC, RMI, делегирующая модель событий, inner-классы) стали краеугольными камнями для корпоративного и настольного Java.
    
- 1.1 сделал Java пригодной не только для апплетов/клиентских демо, но и для реальных бизнес-приложений с БД и распределённой логикой. ([Википедия](https://en.wikipedia.org/wiki/Java_version_history?utm_source=chatgpt.com "Java version history"))
    

---

## Совместимость и заметки для современных разработчиков

- Код, написанный для JDK 1.1, по большей части компилируется/запускается в более новых JVM, но старые API/поведение и отсутствие современных средств (generics, аннотации, лямбды и т. п.) делают такие проекты некомфортными для поддержки.
    
- Если нужно работать с историческим кодом — изучение 1.1 полезно, но для новых проектов лучше использовать современные LTS-версии (например, Java 17 или 21). ([Википедия](https://en.wikipedia.org/wiki/Java_version_history?utm_source=chatgpt.com "Java version history"))
    

---

## Источники (для дальнейшего чтения)

- Обзор новых возможностей JDK 1.1 — релизные заметки. ([columbia.edu](https://www.columbia.edu/cu/help/jdk/docs/relnotes/features.html?utm_source=chatgpt.com "JDK 1.1 New Feature Summary"))
    
- Краткая история версий Java / список нововведений по релизам. ([Википедия](https://en.wikipedia.org/wiki/Java_version_history?utm_source=chatgpt.com "Java version history"))
    
- Статьи и технические заметки по inner-классам и изменениям API в 1.1. ([cs.cornell.edu](https://www.cs.cornell.edu/andru/javaspec/1.1Update.html?utm_source=chatgpt.com "Changes for Java 1.1"))
    

---

Если хочешь, могу:

- привести **короткие рабочие примеры** (полные файлы) для каждой из ключевых фич (inner-класс, JDBC-запрос, простой RMI-сервер/клиент), или
    
- показать **чем JDK 1.1 отличается от JDK 1.0** по списку классов и API-методам, или
    
- подготовить **мини-гайд по миграции** старого 1.1-проекта на современную Java (например, до Java 17).
    

Что делаем дальше?