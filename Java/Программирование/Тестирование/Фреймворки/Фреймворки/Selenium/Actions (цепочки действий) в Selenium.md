# Actions (цепочки действий) в Selenium (Java)

> **Теги:** `#selenium` `#actions` `#keyboard` `#mouse` `#java`  
> **Актуально для:** Selenium 4.x

##  Что такое Actions?

Класс `Actions` в Selenium WebDriver предоставляет API для эмуляции сложных взаимодействий пользователя с веб-страницей: движение мыши, перетаскивание, двойной клик, контекстное меню, нажатие клавиш-модификаторов и составные цепочки действий. В отличие от прямых вызовов `click()` или `sendKeys()`, `Actions` позволяет построить последовательность действий и выполнить их за один раз.

```java
import org.openqa.selenium.interactions.Actions;

Actions actions = new Actions(driver);
```

---

##  Основные методы

Все методы класса `Actions` возвращают сам объект `Actions`, что позволяет строить цепочки (fluent interface). Для выполнения цепочки вызывается метод `perform()`.

| Метод | Описание |
|-------|----------|
| `click()` | Клик левой кнопкой мыши (на текущей позиции или на элементе) |
| `click(WebElement target)` | Клик на элементе |
| `doubleClick()` | Двойной клик |
| `doubleClick(WebElement target)` | Двойной клик на элементе |
| `contextClick()` | Клик правой кнопкой (контекстное меню) |
| `contextClick(WebElement target)` | Клик правой кнопкой на элементе |
| `moveToElement(WebElement target)` | Навести мышь на элемент (hover) |
| `moveToElement(WebElement target, int xOffset, int yOffset)` | Навести с заданным смещением внутри элемента |
| `moveByOffset(int xOffset, int yOffset)` | Переместить мышь на указанные координаты (относительно текущей позиции) |
| `dragAndDrop(WebElement source, WebElement target)` | Перетащить элемент source на target |
| `dragAndDropBy(WebElement source, int xOffset, int yOffset)` | Перетащить элемент на смещение |
| `clickAndHold(WebElement target)` | Зажать левую кнопку мыши на элементе |
| `release()` | Отпустить зажатую кнопку мыши |
| `keyDown(Keys key)` | Нажать клавишу-модификатор (Shift, Ctrl, Alt) |
| `keyDown(WebElement target, Keys key)` | Нажать клавишу-модификатор после наведения на элемент |
| `keyUp(Keys key)` | Отпустить клавишу-модификатор |
| `keyUp(WebElement target, Keys key)` | Отпустить клавишу на элементе |
| `sendKeys(CharSequence... keys)` | Ввести текст или нажать клавиши |
| `sendKeys(WebElement target, CharSequence... keys)` | Ввести текст в элемент |
| `pause(long millis)` или `pause(Duration duration)` | Добавить паузу между действиями |

---

##  Работа с мышью

### Наведение (hover)

```java
Actions actions = new Actions(driver);
WebElement menu = driver.findElement(By.id("main-menu"));
WebElement subItem = driver.findElement(By.id("sub-item"));

// Навести на меню, затем кликнуть по подпункту
actions.moveToElement(menu)
       .pause(Duration.ofMillis(500))
       .click(subItem)
       .perform();
```

### Двойной клик

```java
WebElement text = driver.findElement(By.id("editable-text"));
actions.doubleClick(text).perform();
```

### Контекстное меню (правый клик)

```java
WebElement element = driver.findElement(By.id("target"));
actions.contextClick(element).perform();
```

### Клик по координатам (относительно элемента)

```java
WebElement canvas = driver.findElement(By.tagName("canvas"));
// Клик в точку (50, 100) внутри canvas
actions.moveToElement(canvas, 50, 100).click().perform();
```

### Клик по координатам на странице

```java
// Переместить мышь на 200 пикселей вправо и 300 вниз от текущей позиции
actions.moveByOffset(200, 300).click().perform();
```

---

##  Перетаскивание (Drag & Drop)

### Перетаскивание на другой элемент

```java
WebElement source = driver.findElement(By.id("draggable"));
WebElement target = driver.findElement(By.id("droppable"));

actions.dragAndDrop(source, target).perform();
```

### Перетаскивание на смещение

```java
WebElement slider = driver.findElement(By.id("slider"));
actions.dragAndDropBy(slider, 50, 0).perform(); // переместить ползунок вправо на 50px
```

### Ручное построение перетаскивания

Более детальный контроль:

```java
actions.clickAndHold(source)
       .moveToElement(target)
       .release()
       .perform();
```

---

## ⌨ Работа с клавиатурой

### Комбинации клавиш через Actions

```java
// Ctrl+A (выделить всё) и удалить
WebElement field = driver.findElement(By.id("text-input"));
actions.click(field)
       .keyDown(Keys.CONTROL)
       .sendKeys("a")
       .keyUp(Keys.CONTROL)
       .sendKeys(Keys.DELETE)
       .perform();
```

### Нажатие и удержание модификатора при клике

```java
// Ctrl+клик для открытия ссылки в новой вкладке (если поддерживается)
WebElement link = driver.findElement(By.linkText("Открыть в новой вкладке"));
actions.keyDown(Keys.CONTROL)
       .click(link)
       .keyUp(Keys.CONTROL)
       .perform();
```

---

##  Цепочки действий (Chaining)

Одно из главных преимуществ `Actions` — выполнение последовательности действий за один вызов `perform()`.

```java
actions.moveToElement(menu)
       .pause(200)
       .click(subMenu)
       .moveToElement(searchField)
       .click()
       .sendKeys("Selenium")
       .sendKeys(Keys.ENTER)
       .perform();
```

Это эмулирует: навести на меню, подождать, кликнуть подпункт, переместиться в поле поиска, кликнуть, ввести текст, нажать Enter.

---

##  Важные нюансы

1. **`perform()` обязателен**: цепочка действий не выполняется, пока не вызван `perform()`.

2. **Сброс состояния**: после `perform()` состояние Actions сбрасывается. Если нужно повторить цепочку, её нужно построить заново.

3. **Использование `pause()`**: полезно для эмуляции реального поведения пользователя (паузы между действиями). Рекомендуется использовать `Duration`:
   ```java
   actions.pause(Duration.ofMillis(200)).perform();
   ```

4. **Работа с фреймами**: если элементы находятся внутри фрейма, нужно сначала переключиться на фрейм, иначе Actions будут работать с текущим контекстом.

5. **Совместимость с браузерами**: не все браузеры одинаково поддерживают все жесты. Например, двойной клик может работать по-разному в разных драйверах.

6. **Игнорирование невидимых элементов**: действия, такие как `moveToElement`, могут не сработать, если элемент не видим. Используйте ожидания перед построением цепочки.

---

##  Actions vs обычные методы

| Критерий | WebElement.click() / sendKeys() | Actions |
|----------|---------------------------------|---------|
| Сложность | Простые действия | Сложные цепочки |
| Эмуляция | Базовое взаимодействие | Максимально приближено к реальному пользователю |
| Множественные действия | Требует отдельных вызовов | Одна цепочка, один `perform()` |
| Поддержка комбинаций клавиш | Только `sendKeys(Keys.CONTROL, "a")` | Полный контроль через `keyDown`/`keyUp` |
| Перетаскивание |  Не поддерживается |  Полноценная поддержка |
| Наведение (hover) |  Только через Actions |  `moveToElement` |
| Контекстное меню |  |  `contextClick` |

---

##  Практические примеры

### Пример 1: Работа с выпадающим меню

```java
WebElement mainMenu = driver.findElement(By.id("mainMenu"));
WebElement subMenuItem = driver.findElement(By.id("subMenu"));

new Actions(driver)
    .moveToElement(mainMenu)
    .pause(Duration.ofMillis(300))
    .click(subMenuItem)
    .perform();
```

### Пример 2: Перетаскивание элемента в корзину

```java
WebElement item = driver.findElement(By.cssSelector(".draggable-item"));
WebElement trash = driver.findElement(By.id("trash"));

new Actions(driver)
    .dragAndDrop(item, trash)
    .perform();
```

### Пример 3: Выделение текста в поле (Ctrl+A) и замена

```java
WebElement field = driver.findElement(By.id("comment"));
new Actions(driver)
    .click(field)
    .keyDown(Keys.CONTROL)
    .sendKeys("a")
    .keyUp(Keys.CONTROL)
    .sendKeys("Новый текст")
    .perform();
```

### Пример 4: Клик с зажатым Shift (для выделения диапазона)

```java
WebElement firstItem = driver.findElement(By.xpath("(//li)[1]"));
WebElement lastItem = driver.findElement(By.xpath("(//li)[5]"));

new Actions(driver)
    .click(firstItem)
    .keyDown(Keys.SHIFT)
    .click(lastItem)
    .keyUp(Keys.SHIFT)
    .perform();
```

---

##  Расширенное использование: FluentWait + Actions

Иногда нужно дождаться, когда элемент станет кликабельным, а затем выполнить сложную цепочку.

```java
WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(10));
WebElement element = wait.until(ExpectedConditions.elementToBeClickable(By.id("dynamic")));

new Actions(driver)
    .moveToElement(element)
    .pause(Duration.ofMillis(200))
    .doubleClick()
    .perform();
```

---

##  Best Practices

1. **Используйте `pause()`** для эмуляции реального поведения, но не злоупотребляйте большими задержками — это замедляет тесты.
2. **Всегда вызывайте `perform()`** после построения цепочки.
3. **Для длительных цепочек** разбивайте их на логические части, если это улучшает читаемость.
4. **Не забывайте про контекст**: если вы переключились на фрейм, все действия будут применяться внутри него.
5. **При использовании `keyDown` всегда вызывайте `keyUp`**, чтобы не оставить клавишу зажатой (это может повлиять на дальнейшие взаимодействия).
6. **Для сложных жестов (например, drag-and-drop) сначала проверьте, что элементы видимы и доступны**.
7. **Используйте `Actions` для тестирования UI-компонентов**, которые не поддаются простым кликам (слайдеры, календари, карты).

---

##  Шпаргалка (быстрый поиск)

| Сценарий | Код |
|----------|-----|
| Навести на элемент | `actions.moveToElement(element).perform();` |
| Двойной клик | `actions.doubleClick(element).perform();` |
| Правый клик | `actions.contextClick(element).perform();` |
| Перетащить на другой элемент | `actions.dragAndDrop(source, target).perform();` |
| Перетащить на смещение | `actions.dragAndDropBy(source, x, y).perform();` |
| Зажать Ctrl и кликнуть | `actions.keyDown(Keys.CONTROL).click(element).keyUp(Keys.CONTROL).perform();` |
| Ввод с задержкой | `actions.sendKeys("text").pause(500).sendKeys(Keys.ENTER).perform();` |
| Клик по координатам внутри элемента | `actions.moveToElement(element, offsetX, offsetY).click().perform();` |
| Составная цепочка | `actions.moveToElement(a).click(b).sendKeys(c).perform();` |

---

##  Полезные ссылки

- [Selenium Docs — Actions API](https://www.selenium.dev/documentation/webdriver/actions_api/)
- [Selenium Docs — Mouse Actions](https://www.selenium.dev/documentation/webdriver/actions_api/mouse/)
- [Selenium Docs — Keyboard Actions](https://www.selenium.dev/documentation/webdriver/actions_api/keyboard/)

---

*Заметка готова. Используйте для автоматизации сложных взаимодействий в ваших тестах.*