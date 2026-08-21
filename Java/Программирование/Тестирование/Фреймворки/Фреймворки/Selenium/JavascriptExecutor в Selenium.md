# JavascriptExecutor в Selenium (Java)

> **Теги:** `#selenium` `#javascriptexecutor` `#js` `#java`  
> **Актуально для:** Selenium 4.x

##  Что такое JavascriptExecutor?

`JavascriptExecutor` — это интерфейс в Selenium, который позволяет выполнять произвольный JavaScript-код в контексте текущего браузера. Это мощный инструмент, который решает проблемы там, где стандартные методы Selenium бессильны.

```java
import org.openqa.selenium.JavascriptExecutor;
```

---

##  Инициализация

```java
JavascriptExecutor js = (JavascriptExecutor) driver;
```

> **Важно:** Приводите `WebDriver` к `JavascriptExecutor` — это работает для всех основных драйверов (Chrome, Firefox, Edge, etc.).

---

##  Основные методы

| Метод | Описание |
|-------|----------|
| `executeScript(String script, Object... args)` | Выполняет JavaScript и возвращает результат |
| `executeAsyncScript(String script, Object... args)` | Выполняет асинхронный JavaScript (с коллбэком) |

---

##  Часто используемые сценарии

### 1. Прокрутка страницы

```java
JavascriptExecutor js = (JavascriptExecutor) driver;

// Прокрутить в конец страницы
js.executeScript("window.scrollTo(0, document.body.scrollHeight);");

// Прокрутить в начало
js.executeScript("window.scrollTo(0, 0);");

// Прокрутить до элемента (плавно)
WebElement element = driver.findElement(By.id("target"));
js.executeScript("arguments[0].scrollIntoView({behavior: 'smooth', block: 'center'});", element);

// Прокрутить на 500 пикселей вниз
js.executeScript("window.scrollBy(0, 500);");
```

### 2. Клик по элементу (обход перекрытия)

Используйте, когда стандартный `click()` не работает из-за перекрытия или невидимости.

```java
WebElement hiddenElement = driver.findElement(By.id("submit"));
js.executeScript("arguments[0].click();", hiddenElement);
```

### 3. Изменение атрибутов элемента

```java
// Сделать элемент видимым (был display:none)
js.executeScript("arguments[0].style.display = 'block';", element);

// Изменить текст на кнопке
js.executeScript("arguments[0].innerText = 'Новый текст';", button);

// Добавить класс
js.executeScript("arguments[0].classList.add('highlight');", element);
```

### 4. Получение информации с страницы

```java
// Заголовок страницы
String title = (String) js.executeScript("return document.title;");

// URL
String url = (String) js.executeScript("return document.URL;");

// Текст всей страницы
String text = (String) js.executeScript("return document.documentElement.innerText;");

// Значение атрибута
String value = (String) js.executeScript("return arguments[0].value;", element);
```

### 5. Загрузка файлов без элемента input (эмуляция)

```java
js.executeScript(
    "document.querySelector('input[type=file]').files = null; " +
    "const file = new File([''], 'filename.txt', {type: 'text/plain'}); " +
    "const dt = new DataTransfer(); dt.items.add(file); " +
    "document.querySelector('input[type=file]').files = dt.files; " +
    "document.querySelector('input[type=file]').dispatchEvent(new Event('change'));"
);
```

### 6. Работа с фокусами

```java
// Установить фокус на элемент
js.executeScript("arguments[0].focus();", element);

// Снять фокус
js.executeScript("arguments[0].blur();", element);
```

### 7. Генерация событий (для тестирования)

```java
// Симулировать событие click через JavaScript (если нужно)
js.executeScript(
    "var event = new MouseEvent('click', {bubbles: true, cancelable: true}); " +
    "arguments[0].dispatchEvent(event);",
    element
);
```

### 8. Работа с модальными окнами (alert)

```java
// Открыть alert
js.executeScript("alert('Сообщение');");

// Закрыть alert (через Selenium)
Alert alert = driver.switchTo().alert();
alert.accept();
```

---

##  Асинхронный JavaScript (executeAsyncScript)

Используется для выполнения JavaScript, который требует время (например, AJAX-запросы). Selenium дождётся завершения скрипта.

```java
js.executeAsyncScript(
    "var callback = arguments[arguments.length - 1]; " +
    "setTimeout(function() { " +
        "callback('Результат через 2 секунды'); " +
    "}, 2000);"
);
```

**Пример с реальным использованием:**

```java
// Подождать, пока элемент станет видимым через JS
js.executeAsyncScript(
    "var callback = arguments[arguments.length - 1]; " +
    "var element = document.getElementById('dynamic'); " +
    "var check = setInterval(function() { " +
        "if (element && element.offsetParent !== null) { " +
            "clearInterval(check); " +
            "callback('visible'); " +
        "} " +
    "}, 100);"
);
```

---

##  Ограничения и важные нюансы

1. **Возвращаемые значения** — JavaScript может возвращать только примитивные типы (`String`, `Long`, `Boolean`, `List<Object>`, `Map<String, Object>`). `WebElement` не может быть возвращён из JS, только найден в Selenium.

2. **Приведение типов** — результат `executeScript` всегда `Object`, поэтому нужно явно приводить к нужному типу.

3. **Передача аргументов** — используйте `arguments` для передачи элементов в JavaScript:
   ```java
   js.executeScript("arguments[0].style.border = '3px solid red';", element);
   ```

4. **Безопасность** — будьте осторожны с выполнением невалидного или опасного кода.

5. **Производительность** — JS-выполнение обычно медленнее, чем стандартные методы Selenium, поэтому используйте его только в случае необходимости.

---

##  Шпаргалка (быстрый поиск)

| Сценарий | Код |
|----------|-----|
| Прокрутка в конец | `js.executeScript("window.scrollTo(0, document.body.scrollHeight);");` |
| Прокрутка до элемента | `js.executeScript("arguments[0].scrollIntoView(true);", element);` |
| Клик через JS | `js.executeScript("arguments[0].click();", element);` |
| Изменить атрибут | `js.executeScript("arguments[0].setAttribute('disabled', 'true');", element);` |
| Сделать элемент видимым | `js.executeScript("arguments[0].style.display='block';", element);` |
| Получить заголовок | `String title = (String) js.executeScript("return document.title;");` |
| Получить URL | `String url = (String) js.executeScript("return document.URL;");` |
| Установить значение | `js.executeScript("arguments[0].value = 'новое';", element);` |
| Фокус на элемент | `js.executeScript("arguments[0].focus();", element);` |
| Асинхронный таймер | `js.executeAsyncScript("var cb = arguments[arguments.length-1]; setTimeout(cb, 2000);");` |

---

##  Полезные ссылки

- [Selenium Docs — JavascriptExecutor](https://www.selenium.dev/documentation/webdriver/interactions/javascript/)
- [MDN — JavaScript](https://developer.mozilla.org/en-US/docs/Web/JavaScript)
