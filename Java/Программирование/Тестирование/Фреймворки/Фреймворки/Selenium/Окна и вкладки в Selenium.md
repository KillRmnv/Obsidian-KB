# Окна и вкладки в Selenium (Java)

> **Теги:** `#selenium` `#окна` `#вкладки` `#window_handles` `#java`  
> **Актуально для:** Selenium 4.x

##  Что такое окна и вкладки?

В Selenium **окно** (window) и **вкладка** (tab) — это по сути одно и то же с точки зрения API. Каждое окно или вкладка имеет уникальный идентификатор — **window handle** (строка). Этот дескриптор используется для переключения между контекстами.

Когда вы открываете новую вкладку (например, по ссылке с `target="_blank"`) или новое окно (через `window.open()`), Selenium не переключается на него автоматически. Нужно вручную получить список всех дескрипторов и переключиться на нужный.

---

##  Основные методы

### Получение дескрипторов

| Метод | Описание |
|-------|----------|
| `driver.getWindowHandle()` | Возвращает дескриптор текущего окна/вкладки |
| `driver.getWindowHandles()` | Возвращает набор дескрипторов всех открытых окон/вкладок |

### Переключение

| Метод | Описание |
|-------|----------|
| `driver.switchTo().window(String handle)` | Переключает контекст на указанный дескриптор |

### Закрытие

| Метод | Описание |
|-------|----------|
| `driver.close()` | Закрывает текущее окно/вкладку (не завершает драйвер) |
| `driver.quit()` | Завершает сессию драйвера, закрывает все окна |

---

##  Переключение между окнами/вкладками

### Получение дескриптора текущего окна

```java
String mainWindow = driver.getWindowHandle();
System.out.println("Дескриптор главного окна: " + mainWindow);
```

### Получение всех дескрипторов

```java
Set<String> allHandles = driver.getWindowHandles();
for (String handle : allHandles) {
    System.out.println("Handle: " + handle);
}
```

### Переключение на новую вкладку (после клика по ссылке)

```java
// Сохраняем текущее окно
String mainWindow = driver.getWindowHandle();

// Клик по ссылке, открывающей новую вкладку
driver.findElement(By.linkText("Открыть в новой вкладке")).click();

// Ожидаем появления новой вкладки (появления нового дескриптора)
WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(10));
wait.until(driver -> driver.getWindowHandles().size() > 1);

// Переключаемся на последнюю открытую вкладку
for (String handle : driver.getWindowHandles()) {
    if (!handle.equals(mainWindow)) {
        driver.switchTo().window(handle);
        break;
    }
}

// Теперь работаем в новой вкладке
System.out.println("Текущий URL: " + driver.getCurrentUrl());
```

### Переключение на вкладку по части URL или заголовку

```java
public void switchToWindowByTitle(String titlePart) {
    String currentHandle = driver.getWindowHandle();
    for (String handle : driver.getWindowHandles()) {
        driver.switchTo().window(handle);
        if (driver.getTitle().contains(titlePart)) {
            return; // нужное окно найдено
        }
    }
    // Если не нашли, возвращаемся на исходное
    driver.switchTo().window(currentHandle);
}
```

### Закрытие текущей вкладки и возврат на предыдущую

```java
// Закрыть текущую вкладку
driver.close();

// Переключиться обратно на исходную (если знаем дескриптор)
driver.switchTo().window(mainWindow);

// Или на любую другую открытую
Set<String> handles = driver.getWindowHandles();
if (!handles.isEmpty()) {
    driver.switchTo().window(handles.iterator().next());
}
```

---

##  Открытие новой вкладки или окна (Selenium 4)

В Selenium 4 появился метод `newWindow()` для создания нового окна или вкладки.

```java
// Открыть новую вкладку
driver.switchTo().newWindow(WindowType.TAB);
// Или новое окно
driver.switchTo().newWindow(WindowType.WINDOW);

// После создания контекст автоматически переключается на новое окно/вкладку
driver.get("https://example.com");
```

Это наиболее чистый и рекомендуемый способ для тестов, где нужно программно создать новую вкладку.

---

##  Открытие новой вкладки через Actions (Ctrl+клик)

Можно эмулировать клик с зажатым Ctrl (или Cmd на Mac) для открытия ссылки в новой вкладке.

```java
Actions actions = new Actions(driver);
WebElement link = driver.findElement(By.linkText("Открыть в новой вкладке"));

// Зажать Ctrl и кликнуть
actions.keyDown(Keys.CONTROL)
       .click(link)
       .keyUp(Keys.CONTROL)
       .perform();

// После этого нужно переключиться на новую вкладку, как в примере выше
```

**Примечание:** На Mac используйте `Keys.COMMAND` вместо `Keys.CONTROL`.

---

##  JavaScript для открытия нового окна

Если нужно открыть чистое окно без перехода по ссылке:

```java
JavascriptExecutor js = (JavascriptExecutor) driver;
js.executeScript("window.open('https://example.com', '_blank');");
// После этого необходимо переключиться на новое окно (как обычно)
```

---

##  Работа с несколькими окнами (продвинутые сценарии)

### Получение дескриптора последнего открытого окна

```java
Set<String> handles = driver.getWindowHandles();
// Преобразуем в список и берём последний
List<String> handlesList = new ArrayList<>(handles);
String latestHandle = handlesList.get(handlesList.size() - 1);
driver.switchTo().window(latestHandle);
```

### Переключение на окно по точному URL

```java
public boolean switchToWindowByUrl(String url) {
    for (String handle : driver.getWindowHandles()) {
        driver.switchTo().window(handle);
        if (driver.getCurrentUrl().equals(url)) {
            return true;
        }
    }
    return false;
}
```

### Обработка случая, когда окно закрыто (StaleElementReferenceException)

При закрытии окна его дескриптор становится недействительным. Если попытаться переключиться на него — получите исключение. Поэтому всегда проверяйте, что дескриптор всё ещё существует.

```java
public boolean isWindowOpen(String handle) {
    return driver.getWindowHandles().contains(handle);
}
```

---

##  Особенности и проблемы

1. **Порядок дескрипторов не гарантирован** — не полагайтесь на порядок в `Set`. Используйте сравнение с сохранённым дескриптором.
2. **После закрытия окна** контекст не переключается автоматически — нужно явно переключиться на другое открытое окно.
3. **При клике на ссылку с `target="_blank"`** не всегда создаётся новое окно сразу — может быть задержка. Используйте ожидание увеличения количества дескрипторов.
4. **Всплывающие окна** (например, рекламные popup) — это тоже окна, с ними работают так же.
5. **При использовании `driver.quit()`** все окна закрываются, и драйвер завершается — после этого нельзя выполнять команды.
6. **В некоторых браузерах** (особенно на мобильных) вкладки могут работать по-другому, но API унифицировано.

---

##  Цикл для работы со всеми вкладками (например, сбор данных)

```java
Set<String> handles = driver.getWindowHandles();
for (String handle : handles) {
    driver.switchTo().window(handle);
    // Делаем что-то с текущей вкладкой
    System.out.println(driver.getTitle());
    // Если нужно закрыть, то driver.close() — но тогда не забудьте выйти из цикла
}
```

---

##  Практические примеры

### Пример 1: Открыть ссылку в новой вкладке и вернуться назад

```java
String mainHandle = driver.getWindowHandle();

// Открыть новую вкладку через JS
((JavascriptExecutor) driver).executeScript("window.open('https://example.com', '_blank');");

// Переключиться на новую вкладку
for (String handle : driver.getWindowHandles()) {
    if (!handle.equals(mainHandle)) {
        driver.switchTo().window(handle);
        break;
    }
}

// Выполнить действия...
String title = driver.getTitle();

// Закрыть новую вкладку и вернуться на исходную
driver.close();
driver.switchTo().window(mainHandle);
```

### Пример 2: Переключение на окно, содержащее определённый текст в заголовке

```java
public void switchToWindowWithTitle(String expectedTitle) {
    for (String handle : driver.getWindowHandles()) {
        driver.switchTo().window(handle);
        if (driver.getTitle().contains(expectedTitle)) {
            return;
        }
    }
    throw new RuntimeException("Окно с заголовком '" + expectedTitle + "' не найдено");
}
```

### Пример 3: Открытие новой вкладки через newWindow() (Selenium 4)

```java
// Сохраняем текущий дескриптор (необязательно)
String originalHandle = driver.getWindowHandle();

// Открываем новую вкладку и сразу переключаемся
driver.switchTo().newWindow(WindowType.TAB);
driver.get("https://google.com");

// Можно переключиться обратно
driver.switchTo().window(originalHandle);
```

---

##  Лучшие практики

1. **Всегда сохраняйте дескриптор исходного окна** перед тем как открыть новое.
2. **Используйте ожидание** для появления нового дескриптора, особенно при AJAX-запросах.
3. **Не полагайтесь на порядок** в `Set<String>` — сравнивайте с сохранёнными дескрипторами.
4. **Закрывайте окна явно**, если они больше не нужны, чтобы не накапливать дескрипторы.
5. **Для Selenium 4 используйте `newWindow()`** — это надёжнее и проще.
6. **При работе с несколькими окнами** создавайте утилитарные методы в базовом классе.
7. **Проверяйте, что дескриптор ещё существует**, перед переключением, чтобы избежать `NoSuchWindowException`.

---

##  Шпаргалка (быстрый поиск)

| Сценарий | Код |
|----------|-----|
| Получить текущий дескриптор | `String handle = driver.getWindowHandle();` |
| Получить все дескрипторы | `Set<String> handles = driver.getWindowHandles();` |
| Переключиться на дескриптор | `driver.switchTo().window(handle);` |
| Открыть новую вкладку (Selenium 4) | `driver.switchTo().newWindow(WindowType.TAB);` |
| Открыть новое окно (Selenium 4) | `driver.switchTo().newWindow(WindowType.WINDOW);` |
| Открыть вкладку через JS | `js.executeScript("window.open('url', '_blank');");` |
| Ctrl+клик по ссылке | `actions.keyDown(Keys.CONTROL).click(link).keyUp(Keys.CONTROL).perform();` |
| Закрыть текущую вкладку | `driver.close();` |
| Закрыть все и завершить драйвер | `driver.quit();` |
| Переключиться на последнюю открытую вкладку | `for (String h : driver.getWindowHandles()) { if (!h.equals(mainHandle)) driver.switchTo().window(h); }` |
| Проверить существование дескриптора | `driver.getWindowHandles().contains(handle);` |

---

##  Полезные ссылки

- [Selenium Docs — Working with windows and tabs](https://www.selenium.dev/documentation/webdriver/browser/windows/)
- [Selenium Docs — Window Handles](https://www.selenium.dev/documentation/webdriver/browser/windows/#window-handles)
- [Selenium 4 newWindow() method](https://www.selenium.dev/documentation/webdriver/browser/windows/#creating-new-window)

---

*Заметка готова. Используйте для управления несколькими окнами и вкладками в ваших тестах.*