# ☕ J2SE 1.2 — «Java 2 Platform, Standard Edition»

(Кодовое имя: **Playground**, релиз: **8 декабря 1998 года**)

---

## 🌍 Общая характеристика

**J2SE 1.2** — это одна из **самых значимых и переломных версий Java**.  
Она настолько расширила платформу, что Sun Microsystems решила **переименовать Java**:

> 💡 “Java 2 Platform” — появилось разделение на **J2SE (Standard)**, **J2EE (Enterprise)** и **J2ME (Micro)**.

JDK 1.2 стал основой «современной» Java, которую мы знаем: коллекции, Swing, графика, безопасность и многое другое появились именно здесь.

---

## ⚙️ Ключевые нововведения

### 1️⃣ Java Collections Framework (JCF)

Одна из самых революционных функций:

- Новый пакет `java.util.*` полностью переработан.
    
- Добавлены интерфейсы:  
    `Collection`, `List`, `Set`, `Map`, `Iterator`, `SortedSet`, `SortedMap`.
    
- Добавлены реализации:  
    `ArrayList`, `LinkedList`, `HashSet`, `TreeSet`, `HashMap`, `TreeMap`, `Collections`.
    

📘 Пример:

```java
List<String> list = new ArrayList<>();
list.add("Java");
list.add("1.2");
for (String s : list) {
    System.out.println(s);
}
```

> 💡 До 1.2 в Java не существовало единого унифицированного фреймворка коллекций — только устаревшие `Vector`, `Hashtable`, `Enumeration`.

---

### 2️⃣ Swing GUI Toolkit

- Новый пакет `javax.swing.*`
    
- Полностью заменил старый AWT-компонентный набор.
    
- Поддерживает **pluggable look-and-feel** — интерфейс можно менять на лету (Metal, Windows, Motif и т.д.).
    
- Компоненты с "J": `JButton`, `JLabel`, `JPanel`, `JFrame`, `JTable`, `JTree`, `JTextField` и др.
    

📘 Пример:

```java
import javax.swing.*;
public class SwingDemo {
    public static void main(String[] args) {
        JFrame frame = new JFrame("J2SE 1.2 Demo");
        frame.add(new JButton("Hello Swing!"));
        frame.setSize(200, 100);
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        frame.setVisible(true);
    }
}
```

---

### 3️⃣ Java Plug-in и Java 2D

**Java Plug-in**:

- Позволил запускать апплеты в браузерах с конкретной версией JVM (а не встроенной).  
    **Java 2D API:**
    
- Новый мощный графический движок.
    
- Поддержка векторной графики, альфа-канала, сглаживания, шрифтов TrueType, изображений с цветами и прозрачностью.
    

---

### 4️⃣ Security Architecture (JAAS и Policy)

- Модель безопасности переработана:
    
    - Файлы `java.policy` и `java.security`.
        
    - Возможность задавать разрешения (read, write, connect) для разных источников кода.
        
- Введена **fine-grained security** — контроль доступа к классам, файлам, сетевым операциям.
    
- Подготовка к появлению **JAAS (Java Authentication and Authorization Service)**.
    

---

### 5️⃣ Java Naming and Directory Interface (JNDI)

- Унифицированный API для доступа к каталогам и службам (LDAP, DNS, RMI registry, NDS).
    
- Позже стал важной частью Java EE.
    

---

### 6️⃣ Корни современного RMI

- Улучшена сериализация.
    
- Появилась **RMI over IIOP** (интеграция с CORBA).
    
- Улучшен контроль за классами, передаваемыми по сети.
    

---

### 7️⃣ Java IDL (CORBA Integration)

- Встроенная поддержка CORBA (Common Object Request Broker Architecture).
    
- Пакет `org.omg.*` позволил Java взаимодействовать с другими CORBA-системами (C++, Ada, и т. д.).
    

---

### 8️⃣ Collections + Algorithms Utilities

- Новый класс `java.util.Collections` — утилиты для сортировки, поиска и синхронизации.
    
- Методы: `sort()`, `binarySearch()`, `synchronizedList()`, `unmodifiableMap()` и т. д.
    

---

### 9️⃣ Garbage Collector и JVM улучшения

- Новый **generational garbage collector**.
    
- Улучшения производительности и стабильности HotSpot JVM (хотя официально он стал стандартом в JDK 1.3).
    
- Добавлен JIT (Just-In-Time) компилятор.
    

---

### 🔟 Serialization API

- Стал стандартным механизмом для сохранения состояния объектов.
    
- Появились интерфейсы `Serializable` и `Externalizable`.
    
- Используется в RMI, JavaBeans, и многих фреймворках.
    

---

## 🧱 Архитектура и платформы

После 1.2 Java официально разделилась на три платформы:

|Платформа|Назначение|
|:--|:--|
|**J2SE**|Настольные и стандартные приложения|
|**J2EE**|Серверные и корпоративные системы|
|**J2ME**|Мобильные и встроенные устройства|

---

## 🧩 Примеры других нововведений

- Новый API для drag-and-drop.
    
- Java Accessibility API (доступность для пользователей с ограниченными возможностями).
    
- Улучшения Print API.
    
- Улучшенная поддержка Unicode.
    
- Возможность использовать Policy Files и KeyStore для безопасности.
    

---

## 💡 Почему J2SE 1.2 важен

- Заложил **основу современной архитектуры Java**.
    
- Стал первым по-настоящему зрелым релизом платформы.
    
- После 1.2 Java перестала быть «апплетным языком» и стала **платформой общего назначения**.
    

---

## 📅 Резюме по ключевым фичам

|Компонент|Введение|Значение|
|:--|:--|:--|
|Collections Framework|✅|Унификация структур данных|
|Swing|✅|Новый GUI-фреймворк|
|Java 2D|✅|Современная графика|
|Security Policy|✅|Гранулированная безопасность|
|Serialization|✅|Сохранение объектов|
|JNDI, CORBA|✅|Интеграция с внешними системами|
|JVM GC / JIT|✅|Производительность|
|Java Plug-in|✅|Апплеты с внешним JVM|

---

Хочешь, я покажу тебе **наглядное сравнение JDK 1.1 vs J2SE 1.2** (по API, пакетам, и функциональности) или таблицу **«что впервые появилось в 1.2 и живо до сих пор»**?