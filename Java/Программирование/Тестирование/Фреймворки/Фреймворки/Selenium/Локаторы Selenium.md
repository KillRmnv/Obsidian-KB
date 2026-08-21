# Локаторы Selenium

> **Ключевые слова:** `#selenium` `#локаторы` `#java` `#webdriver`  
> **Актуально для:** Selenium 4.x, Java

##  Основные типы локаторов

Selenium предоставляет 8 способов поиска элементов на странице. Все они наследуются от класса `By`.

| Локатор               | Метод в Java                     | Пример HTML                       | Пример кода                          |
|-----------------------|----------------------------------|-----------------------------------|--------------------------------------|
| **ID**                | `By.id("id")`                   | `<div id="login">`                | `driver.findElement(By.id("login"))` |
| **Name**              | `By.name("name")`               | `<input name="username">`         | `driver.findElement(By.name("username"))` |
| **Class Name**        | `By.className("class")`         | `<div class="btn-primary">`       | `driver.findElement(By.className("btn-primary"))` |
| **Tag Name**          | `By.tagName("tag")`             | `<h1>Заголовок</h1>`              | `driver.findElement(By.tagName("h1"))` |
| **Link Text**         | `By.linkText("текст")`          | `<a href="/">Главная</a>`         | `driver.findElement(By.linkText("Главная"))` |
| **Partial Link Text** | `By.partialLinkText("часть")`   | `<a href="/about">О нас</a>`      | `driver.findElement(By.partialLinkText("О н"))` |
| **XPath**             | `By.xpath("//tag[@attr='val']")`| `<input type="text" id="email">`  | `driver.findElement(By.xpath("//input[@id='email']"))` |
| **CSS Selector**      | `By.cssSelector("selector")`    | `<div class="main">`              | `driver.findElement(By.cssSelector(".main"))` |

---

##  XPath (основы)

### Абсолютный vs относительный
- **Абсолютный** – начинается с `/html/body/...` – **не использовать** (хрупкий).
- **Относительный** – начинается с `//` – **рекомендуется**.

### Полезные оси
- `//div[@id='menu']//a` – все ссылки внутри `div` с `id='menu'`.
- `//input[contains(@class, 'search')]` – частичное совпадение класса.
- `//button[text()='Отправить']` – точное совпадение текста.
- `//*[@data-testid='submit']` – поиск по пользовательскому атрибуту.

### Функции XPath
- `contains(@attr, 'value')`
- `starts-with(@attr, 'value')`
- `normalize-space(text())` – очистка пробелов
- `position()` – индекс (например, `(//li)[2]`)

---

##  CSS-селекторы (кратко)

| Синтаксис          | Пример                   | Описание                        |
|--------------------|--------------------------|---------------------------------|
| `#id`              | `#login`                 | по ID                           |
| `.class`           | `.btn-primary`           | по классу                       |
| `tag[attr='val']`  | `input[type='text']`     | по атрибуту                     |
| `tag.class`        | `div.main`               | тег + класс                     |
| `parent > child`   | `ul > li`                | прямой потомок                  |
| `tag1 tag2`        | `div a`                  | любой потомок                   |
| `tag:nth-child(n)` | `li:nth-child(2)`        | второй дочерний элемент         |

---

##  Рекомендации

1. **Приоритет локаторов** (от лучшего к худшему):
   - `id` → `name` → `class` → `cssSelector` → `xpath` → `linkText` → `partialLinkText` → `tagName`
2. **Уникальность** – локатор должен возвращать **один** элемент.
3. **Избегайте** индексов в XPath, если есть альтернатива (они ломаются при изменении DOM).
4. **Давайте атрибуты `data-*`** разработчикам для тестирования – это лучший способ.
5. **Проверяйте локаторы в консоли браузера**:
   ```javascript
   $x("//div[@id='menu']")   // XPath
   $$(".btn-primary")        // CSS
   ```

---

##  Пример Java-кода с разными локаторами

```java
import org.openqa.selenium.By;
import org.openqa.selenium.WebDriver;
import org.openqa.selenium.WebElement;

// ...

WebElement el1 = driver.findElement(By.id("email"));
WebElement el2 = driver.findElement(By.name("password"));
WebElement el3 = driver.findElement(By.className("btn-submit"));
WebElement el4 = driver.findElement(By.xpath("//input[@type='submit']"));
WebElement el5 = driver.findElement(By.cssSelector("div.form > input[type='text']"));
```

---

##  Полезные ссылки

- [Selenium Docs – Locators](https://www.selenium.dev/documentation/webdriver/locating_elements/)
- [XPath Tester Online](https://www.freeformatter.com/xpath-tester.html)
- [CSS Selector Reference](https://www.w3schools.com/cssref/css_selectors.asp)

---

##  Шпаргалка (короткая)

| Если нужно найти… | Используйте… |
|-------------------|--------------|
| элемент по уникальному ID | `By.id` |
| элемент по имени | `By.name` |
| ссылку с точным текстом | `By.linkText` |
| элемент со сложным условием | `By.xpath` |
| элемент по классу или атрибуту | `By.cssSelector` |

---

*Заметка создана для быстрого доступа. Дополняйте своими примерами по мере накопления опыта.*