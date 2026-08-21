# XPath в Selenium (Java)

> **Теги:** `#xpath` `#selenium` `#локаторы` `#java`  
> **Версия Selenium:** 4.x

##  Что такое XPath?

**XPath** (XML Path Language) — язык запросов к элементам XML/HTML-документа. В Selenium используется для поиска элементов, когда другие локаторы (id, name, class) не подходят или недостаточно уникальны.

---

##  Абсолютный vs Относительный XPath

| Тип               | Пример                                | Надёжность                                       |
| ----------------- | ------------------------------------- | ------------------------------------------------ |
| **Абсолютный**    | `/html/body/div[1]/div[2]/form/input` | Очень хрупкий (меняется при любом изменении DOM) |
| **Относительный** | `//input[@id='email']`                |  Устойчивый, рекомендуется всегда использовать   |

> **Правило:** Всегда начинайте с `//` (двойной слеш) — это поиск по всему документу.

---

##  Основные конструкции

### Поиск по атрибуту
```xpath
//tagname[@attribute='value']
//input[@type='text']
//button[@id='submit']
//div[@data-testid='modal']
```

### Поиск по тексту (точное совпадение)
```xpath
//tagname[text()='точный текст']
//button[text()='Отправить']
//a[text()='Главная']
```

### Поиск по частичному тексту (contains)
```xpath
//tagname[contains(text(), 'часть текста')]
//button[contains(text(), 'Отпр')]
//a[contains(text(), 'Глав')]
```

### Поиск по частичному значению атрибута
```xpath
//tagname[contains(@attribute, 'часть')]
//input[contains(@class, 'search')]
//div[contains(@id, 'menu')]
```

### Поиск по началу строки (starts-with)
```xpath
//tagname[starts-with(@attribute, 'начало')]
//input[starts-with(@id, 'user_')]
```

### Поиск по нескольким условиям (and / or)
```xpath
//input[@type='text' and @name='username']
//button[@class='btn' or @class='btn-primary']
```

### Нормализация пробелов (normalize-space)
Используется, когда текст может содержать лишние пробелы или переносы:
```xpath
//button[normalize-space(text())='Отправить']
```

---

##  Оси XPath (Axes)

Оси позволяют перемещаться по дереву DOM относительно текущего узла.

| Ось | Синтаксис | Описание |
|-----|-----------|----------|
| `child` | `//div/child::span` | Все дочерние элементы (обычно `//div/span`) |
| `descendant` | `//div/descendant::a` | Все потомки (все уровни вложенности) |
| `parent` | `//span/parent::div` | Родительский элемент |
| `ancestor` | `//input/ancestor::form` | Все предки (до корня) |
| `following-sibling` | `//h1/following-sibling::p` | Следующие соседние элементы того же уровня |
| `preceding-sibling` | `//h1/preceding-sibling::p` | Предыдущие соседние элементы |
| `following` | `//div/following::p` | Все элементы после текущего (не только соседи) |
| `preceding` | `//div/preceding::p` | Все элементы перед текущим |

### Примеры осей
```xpath
//label[text()='Email']/following-sibling::input   # поле ввода после метки
//table[@id='data']/tbody/tr[2]/td[3]              # конкретная ячейка
```

---

##  Индексы и позиции

Индексы в XPath начинаются с **1**.
```xpath
(//div[@class='item'])[2]   # второй элемент с классом 'item'
//ul/li[3]                  # третий дочерний li
//tr[position() > 1]        # все строки кроме первой
//tr[last()]                # последняя строка
```

---

##  Предикаты (условия в квадратных скобках)

Внутри `[]` можно использовать любые логические выражения:
- Сравнение: `=`, `!=`, `>`, `<`, `>=`, `<=`
- Логические: `and`, `or`, `not()`
- Функции: `contains()`, `starts-with()`, `normalize-space()`, `text()`

Примеры:
```xpath
//input[@type='text' and @placeholder='Введите имя']
//button[not(@disabled)]
//div[contains(@class, 'error') and text()='Ошибка']
```

---

##  Продвинутые функции

| Функция | Пример | Описание |
|---------|--------|----------|
| `count()` | `count(//li)` | Количество элементов |
| `name()` | `//*[name()='div']` | Имя тега (аналог `//div`) |
| `last()` | `//tr[last()]` | Последний элемент |
| `position()` | `//tr[position()<4]` | Позиция (индекс) |
| `string-length()` | `//input[string-length(@value)>0]` | Длина строки |
| `substring()` | `//a[substring(text(),1,3)='Вхо']` | Подстрока |

---

##  Проверка XPath в браузере

**Chrome / Edge:**
1. Открыть DevTools (F12)
2. Вкладка Console
3. Ввести:
   ```javascript
   $x("//input[@id='email']")   // возвращает массив элементов
   ```
**Firefox:**
   - Аналогично, но команда `$x` тоже работает.

**Или через поиск в Elements:**
- Нажать `Ctrl+F` в DevTools, ввести XPath — подсветит совпадения.

---

##  Примеры Java-кода

```java
import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;

// Поиск одного элемента
WebElement element = driver.findElement(By.xpath("//input[@id='email']"));

// Поиск нескольких элементов
List<WebElement> items = driver.findElements(By.xpath("//ul[@class='menu']/li"));

// Сложный XPath с осью
WebElement parentDiv = driver.findElement(By.xpath("//span[text()='Цена']/parent::div"));
```

---

##  Лучшие практики

1. **Избегайте абсолютных путей** — они ломаются при рефакторинге.
2. **Не используйте индексы без необходимости** — лучше искать по уникальному атрибуту.
3. **Отдавайте предпочтение атрибутам `id`, `name`, `data-*`** — они стабильнее текста.
4. **Пишите относительные XPath от устойчивого родителя**:
   ```xpath
   //div[@id='loginForm']//input[@name='username']
   ```
5. **Используйте `contains()` для классов** — классы часто меняются или содержат пробелы.
6. **Не злоупотребляйте `text()`** — если текст переведён на другой язык, локатор сломается.
7. **Проверяйте XPath в консоли браузера** перед добавлением в код.

---

##  XPath vs CSS (когда что использовать)

| Случай | Предпочтение |
|--------|--------------|
| Простые селекторы по id/class | CSS (быстрее) |
| Поиск по тексту (содержит/равен) | XPath |
| Сложные логические условия (and/or) | XPath |
| Навигация по дереву (родители/соседи) | XPath |
| Кроссбраузерность | Оба работают, но XPath иногда медленнее |

---

##  Полезные ссылки

- [Официальная документация Selenium по XPath](https://www.selenium.dev/documentation/webdriver/locating_elements/#xpath)
- [W3C XPath 1.0](https://www.w3.org/TR/xpath-10/)
- [XPath онлайн-тестер](https://www.freeformatter.com/xpath-tester.html)

---

##  Шпаргалка (быстрый поиск)

| Что нужно | XPath |
|-----------|-------|
| Элемент с ID | `//*[@id='myId']` |
| Элемент с классом | `//*[@class='myClass']` |
| Точный текст | `//button[text()='Нажми']` |
| Часть текста | `//a[contains(text(), 'Подроб')]` |
| По атрибуту | `//input[@type='password']` |
| По нескольким атрибутам | `//input[@type='text' and @name='user']` |
| Родитель | `//span[@id='price']/parent::div` |
| Следующий сосед | `//label[text()='Email']/following-sibling::input` |
| Индекс | `(//div[@class='item'])[2]` |

---

*Заметка готова к использованию. Добавляйте свои частые примеры в раздел "Шпаргалка".*