# Метод sendKeys() в Selenium (Java)

> **Теги:** `#selenium` `#sendkeys` `#ввод` `#действия` `#java`  
> **Актуально для:** Selenium 4.x

##  Что такое `sendKeys()`?

Метод `sendKeys(CharSequence... keysToSend)` используется для эмуляции ввода текста с клавиатуры в поля ввода (`input`, `textarea`), а также для отправки специальных клавиш (Enter, Tab, Esc) и комбинаций (Ctrl+C, Ctrl+V). Также с его помощью можно загружать файлы через элемент `<input type="file">`.

```java
WebElement input = driver.findElement(By.id("username"));
input.sendKeys("testuser");
```

---

##  Базовое использование

```java
// Ввод текста
driver.findElement(By.id("email")).sendKeys("user@example.com");

// Очистка поля перед вводом
WebElement field = driver.findElement(By.name("password"));
field.clear(); // очищает поле
field.sendKeys("securePass123");
```

**Важно:** `sendKeys()` не заменяет существующий текст, а добавляет к нему. Поэтому перед вводом часто вызывают `clear()`.

---

## ⌨ Специальные клавиши и комбинации

Selenium предоставляет класс `Keys` со статическими константами для всех клавиш.

### Основные специальные клавиши

| Клавиша | Константа |
|---------|-----------|
| Enter (Return) | `Keys.ENTER` или `Keys.RETURN` |
| Tab | `Keys.TAB` |
| Escape | `Keys.ESCAPE` |
| Backspace | `Keys.BACK_SPACE` |
| Delete | `Keys.DELETE` |
| Стрелки | `Keys.ARROW_UP`, `ARROW_DOWN`, `ARROW_LEFT`, `ARROW_RIGHT` |
| Shift | `Keys.SHIFT` |
| Control (Cmd на Mac) | `Keys.CONTROL` |
| Alt | `Keys.ALT` |
| Home / End | `Keys.HOME`, `Keys.END` |
| Page Up / Down | `Keys.PAGE_UP`, `Keys.PAGE_DOWN` |
| Пробел | `Keys.SPACE` |

### Сочетания клавиш (модификаторы)

```java
// Ctrl+A (выделить всё)
field.sendKeys(Keys.CONTROL, "a");

// Ctrl+C (копировать)
field.sendKeys(Keys.CONTROL, "c");

// Ctrl+V (вставить)
field.sendKeys(Keys.CONTROL, "v");

// Ctrl+X (вырезать)
field.sendKeys(Keys.CONTROL, "x");

// Нажать Shift+A (заглавная)
field.sendKeys(Keys.SHIFT, "a");
```

**Важно:** На Mac используйте `Keys.COMMAND` вместо `Keys.CONTROL`.

---

##  Отправка Enter для отправки формы

```java
// Ввести текст и нажать Enter (как отправка формы)
searchInput.sendKeys("Selenium" + Keys.ENTER);
```

Это эквивалентно нажатию кнопки "Поиск".

---

##  Последовательный ввод (Actions)

`Actions` позволяет строить цепочки действий, включая ввод с задержками и комбинации с движением мыши.

```java
import org.openqa.selenium.interactions.Actions;

Actions actions = new Actions(driver);
WebElement field = driver.findElement(By.id("comment"));

actions.moveToElement(field)
       .click()
       .sendKeys("Привет, мир!")
       .keyDown(Keys.CONTROL)
       .sendKeys("a")
       .keyUp(Keys.CONTROL)
       .perform();
```

Это эмулирует: навести мышь, кликнуть, ввести текст, выделить всё через Ctrl+A.

---

##  Загрузка файлов через sendKeys()

Элемент `<input type="file">` позволяет указать путь к файлу через `sendKeys()`.

```java
WebElement fileInput = driver.findElement(By.id("upload"));
fileInput.sendKeys("/home/user/Documents/photo.jpg");
```

**Особенности:**
- Работает только с элементами `input[type="file"]`.
- Путь должен быть абсолютным (или относительным, но лучше абсолютный).
- Не требует нажатия кнопки "Загрузить" — файл прикрепляется к элементу.

---

##  Проблемы и их решение

### 1. Поле не принимает ввод (неактивно, disabled)

```java
// Сначала дождаться, пока поле станет доступным
wait.until(ExpectedConditions.elementToBeClickable(By.id("inputField")))
    .sendKeys("текст");
```

### 2. Ввод кириллицы (или других юникодных символов)

Selenium корректно передаёт Unicode. Проблемы могут возникнуть, если:
- Кодировка страницы не UTF-8.
- Используется виртуальная клавиатура (например, на мобильных эмуляторах).

**Решение:** Убедитесь, что в проекте используется UTF-8, а в коде строки явно заданы в нужной кодировке.

### 3. Эмуляция физической клавиатуры (для сложных сценариев)

Если `sendKeys()` не работает (например, поле обрабатывает события `keydown/keyup`), можно использовать `Actions` или JavaScript для установки значения напрямую:

```java
JavascriptExecutor js = (JavascriptExecutor) driver;
js.executeScript("arguments[0].value = arguments[1];", field, "новое значение");
```

Однако это не генерирует события клавиатуры, поэтому не подходит для полей с авто-завершением или динамической валидацией.

### 4. Очистка поля перед вводом (если clear() не работает)

```java
field.sendKeys(Keys.CONTROL + "a"); // выделить всё
field.sendKeys(Keys.DELETE);       // удалить
// или
field.sendKeys(Keys.BACK_SPACE);   // удалять по одному символу (медленно)
```

---

##  Лучшие практики

1. **Ожидание доступности поля** перед вводом:
   ```java
   wait.until(ExpectedConditions.visibilityOfElementLocated(By.id("login")));
   // или
   wait.until(ExpectedConditions.elementToBeClickable(By.id("login")))
       .sendKeys("user");
   ```

2. **Всегда очищайте поле**, если не уверены, что оно пустое:
   ```java
   field.clear();
   field.sendKeys("new text");
   ```

3. **Для ввода паролей** используйте `sendKeys()` — он работает так же, как и для обычного текста.

4. **Если поле имеет ограничение по длине**, проверьте, что вводимый текст не превышает лимит.

5. **Используйте `Keys.chord()` для комбинаций** (удобно, если нужно передать несколько клавиш сразу):
   ```java
   field.sendKeys(Keys.chord(Keys.CONTROL, "a")); // выделить всё
   ```

6. **В Page Object инкапсулируйте ввод в методы**:
   ```java
   public void enterUsername(String username) {
       WebElement field = wait.until(ExpectedConditions.visibilityOfElementLocated(usernameInput));
       field.clear();
       field.sendKeys(username);
   }
   ```

---

##  Шпаргалка (быстрый поиск)

| Что нужно | Код |
|-----------|-----|
| Ввод текста | `element.sendKeys("текст");` |
| Ввод с очисткой | `element.clear(); element.sendKeys("текст");` |
| Нажать Enter | `element.sendKeys(Keys.ENTER);` |
| Нажать Tab | `element.sendKeys(Keys.TAB);` |
| Выделить всё (Ctrl+A) | `element.sendKeys(Keys.CONTROL, "a");` |
| Копировать (Ctrl+C) | `element.sendKeys(Keys.CONTROL, "c");` |
| Вставить (Ctrl+V) | `element.sendKeys(Keys.CONTROL, "v");` |
| Загрузить файл | `fileInput.sendKeys("/путь/к/файлу");` |
| Нажать Shift+Enter | `element.sendKeys(Keys.SHIFT, Keys.ENTER);` |
| Установить значение через JS | `js.executeScript("arguments[0].value='новое'", element);` |

---

##  Полезные ссылки

- [Selenium Docs — sendKeys](https://www.selenium.dev/documentation/webdriver/interactions/#sendkeys)
- [Selenium Docs — Keys API](https://www.selenium.dev/selenium/docs/api/java/org/openqa/selenium/Keys.html)
- [Selenium Docs — File Upload](https://www.selenium.dev/documentation/webdriver/actions_api/keyboard/#file-upload)

---

*Заметка готова. Используйте для стабильного ввода в ваших тестах.*