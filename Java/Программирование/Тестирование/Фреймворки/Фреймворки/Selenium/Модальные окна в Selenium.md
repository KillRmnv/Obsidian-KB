# Модальные окна в Selenium (Java)

> **Теги:** `#selenium` `#модальные_окна` `#alert` `#popup` `#java`  
> **Актуально для:** Selenium 4.x

##  Что такое модальное окно?

Модальное окно (modal window / popup) — это элемент интерфейса, который блокирует взаимодействие с остальной частью страницы до тех пор, пока пользователь не выполнит необходимое действие (закрытие, подтверждение, ввод данных). В веб-тестировании модальные окна делятся на два типа:

1. **Нативные JavaScript-диалоги** (alert, confirm, prompt) — системные окна браузера.
2. **HTML-модальные окна** (Bootstrap, jQuery UI, кастомные) — элементы DOM, стилизованные под модальные окна.

---

##  Типы модальных окон

### 1. JavaScript Alert / Confirm / Prompt

Это встроенные в браузер диалоги. Selenium предоставляет специальный интерфейс `Alert` для работы с ними.

| Тип | Описание | Метод получения |
|-----|----------|-----------------|
| `alert` | Простое уведомление с кнопкой OK | `driver.switchTo().alert()` |
| `confirm` | Диалог с OK и Отмена | `driver.switchTo().alert()` |
| `prompt` | Диалог с полем ввода и кнопками OK/Отмена | `driver.switchTo().alert()` |

**Особенности:**
- Не являются частью DOM → нельзя найти через `findElement`.
- Блокируют выполнение JavaScript до закрытия.
- Автоматически закрываются при переходе на другую страницу (в некоторых браузерах).

### 2. HTML-модальные окна (Bootstrap, jQuery UI, кастомные)

Это обычные HTML-элементы (обычно `div` с высоким `z-index`), которые имитируют модальное поведение. Они являются частью DOM, поэтому с ними работают как с обычными элементами.

**Особенности:**
- Присутствуют в DOM, можно использовать `findElement`.
- Часто скрываются/показываются через CSS-классы (`display: none` / `block`).
- Могут содержать интерактивные элементы (кнопки, поля ввода, iframe).

---

##  Работа с JavaScript Alert / Confirm / Prompt

### Основные методы интерфейса Alert

| Метод | Описание |
|-------|----------|
| `accept()` | Нажать кнопку OK |
| `dismiss()` | Нажать кнопку Отмена (или закрыть крестиком) |
| `getText()` | Получить текст сообщения |
| `sendKeys(String text)` | Ввести текст (только для prompt) |

### Примеры

#### Принять alert

```java
Alert alert = driver.switchTo().alert();
String message = alert.getText();
System.out.println("Сообщение: " + message);
alert.accept(); // нажать OK
```

#### Отклонить confirm

```java
Alert confirm = driver.switchTo().alert();
confirm.dismiss(); // нажать Отмена
```

#### Ввод текста в prompt

```java
Alert prompt = driver.switchTo().alert();
prompt.sendKeys("Введённый текст");
prompt.accept(); // или prompt.dismiss() для отмены
```

### Ожидание появления alert

Alert может появляться не мгновенно. Используйте `ExpectedConditions.alertIsPresent()`.

```java
import org.openqa.selenium.support.ui.WebDriverWait;
import org.openqa.selenium.support.ui.ExpectedConditions;
import java.time.Duration;

WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(10));
Alert alert = wait.until(ExpectedConditions.alertIsPresent());
alert.accept();
```

### Обработка отсутствия alert

Если alert не появился, `wait.until` выбросит `TimeoutException`. Обработайте это:

```java
try {
    Alert alert = wait.until(ExpectedConditions.alertIsPresent());
    alert.accept();
} catch (TimeoutException e) {
    System.out.println("Alert не появился за отведённое время");
}
```

---

##  Работа с HTML-модальными окнами

HTML-модалки — это обычные элементы DOM, поэтому их можно искать через `By` и взаимодействовать с ними стандартными методами. Однако есть несколько нюансов.

### 1. Ожидание появления модального окна

Модальное окно может добавляться в DOM динамически или появляться после анимации. Используйте ожидания видимости.

```java
By modalLocator = By.id("modal");
WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(10));

// Ждём, пока модалка станет видимой
WebElement modal = wait.until(ExpectedConditions.visibilityOfElementLocated(modalLocator));
```

### 2. Взаимодействие с элементами внутри модалки

Все элементы внутри модалки можно найти как обычно, но иногда они находятся внутри дополнительных контейнеров. Используйте относительные локаторы:

```java
WebElement modal = driver.findElement(By.id("myModal"));
WebElement button = modal.findElement(By.cssSelector(".btn-close"));
button.click(); // закрыть модалку
```

Или сразу через глобальный поиск:

```java
driver.findElement(By.cssSelector("#myModal .btn-submit")).click();
```

### 3. Ожидание закрытия модального окна

Часто нужно дождаться, пока модалка исчезнет (например, после нажатия OK). Используйте ожидание невидимости:

```java
wait.until(ExpectedConditions.invisibilityOfElementLocated(By.id("myModal")));
```

или конкретного элемента:

```java
WebElement modal = driver.findElement(By.id("myModal"));
wait.until(ExpectedConditions.invisibilityOf(modal));
```

### 4. Модальные окна с iframe

Некоторые модалки содержат iframe (например, виджеты оплаты). Перед взаимодействием с содержимым нужно переключиться на фрейм.

```java
// Ждём появления iframe внутри модалки
WebElement iframe = wait.until(ExpectedConditions.presenceOfElementLocated(By.tagName("iframe")));
driver.switchTo().frame(iframe);

// Работаем с элементами внутри iframe
driver.findElement(By.id("card-number")).sendKeys("4111111111111111");

// Возвращаемся к основному контенту
driver.switchTo().defaultContent();
```

### 5. Работа с несколькими модалками (очередь)

Иногда модалки появляются последовательно. Используйте циклы или последовательные ожидания для каждой.

```java
// Первая модалка
WebElement modal1 = wait.until(ExpectedConditions.visibilityOfElementLocated(By.id("modal1")));
modal1.findElement(By.id("closeBtn")).click();
wait.until(ExpectedConditions.invisibilityOfElementLocated(By.id("modal1")));

// Вторая модалка
WebElement modal2 = wait.until(ExpectedConditions.visibilityOfElementLocated(By.id("modal2")));
modal2.findElement(By.id("confirmBtn")).click();
```

---

##  Особенности Bootstrap и jQuery UI модалок

### Bootstrap модальные окна

- Появляются с классом `.show` и атрибутом `aria-modal="true"`.
- Закрываются по клику на затемнение (backdrop) — можно отключить, добавив `data-backdrop="static"`.
- Для проверки видимости используйте класс `.show` или проверку `style.display != 'none'`.

Пример ожидания открытия:

```java
wait.until(ExpectedConditions.visibilityOfElementLocated(By.cssSelector(".modal.show")));
```

### jQuery UI модалки

- Часто используют `dialog` виджет.
- Открываются добавлением класса `ui-dialog`.
- Закрываются по клику на `ui-dialog-titlebar-close`.

```java
// Открыть диалог
driver.findElement(By.id("openDialog")).click();
wait.until(ExpectedConditions.visibilityOfElementLocated(By.cssSelector(".ui-dialog")));

// Закрыть
driver.findElement(By.cssSelector(".ui-dialog .ui-dialog-titlebar-close")).click();
```

---

##  Обработка всплывающих окон браузера (не alert)

Некоторые браузерные уведомления (например, запрос геолокации, камеры, уведомлений) не относятся к Alert и не могут быть обработаны через Selenium. Для их управления используйте настройки ChromeOptions / FirefoxOptions (например, `--disable-notifications`), либо используйте автоматизацию через Robot класс (редко).

```java
ChromeOptions options = new ChromeOptions();
options.addArguments("--disable-notifications");
WebDriver driver = new ChromeDriver(options);
```

---

##  Проблемы и их решение

1. **Alert появляется, но Selenium не может его перехватить** — убедитесь, что нет других модалок, которые блокируют alert. Иногда alert появляется в iframe — переключитесь на нужный фрейм перед вызовом `switchTo().alert()`.

2. **StaleElementReferenceException** для элементов внутри модалки после её обновления — переищите элемент перед каждым использованием.

3. **Модалка не закрывается** — проверьте, не блокирует ли её JavaScript-обработчик. Попробуйте закрыть через JavaScript:

   ```java
   JavascriptExecutor js = (JavascriptExecutor) driver;
   js.executeScript("arguments[0].style.display='none';", modalElement);
   ```
   (используйте только как fallback).

4. **Модалка с iframe исчезает при переключении** — убедитесь, что вы работаете в правильном контексте.

---

##  Best Practices

1. **Всегда используйте явные ожидания** для появления/исчезновения модалок.
2. **Для нативных alert** используйте `ExpectedConditions.alertIsPresent()`.
3. **Для HTML-модалок** используйте `visibilityOfElementLocated` и `invisibilityOfElementLocated`.
4. **Не забывайте про iframe** — если модалка содержит iframe, переключайтесь на него.
5. **Инкапсулируйте работу с модалками в отдельные классы-страницы** (Page Object).
6. **При тестировании модалок проверяйте не только их появление, но и исчезновение** (чтобы убедиться, что UI корректно обновляется).
7. **Для сложных цепочек модалок** используйте `FluentWait` с игнорированием `NoSuchElementException`.

---

##  Шпаргалка (быстрый поиск)

| Сценарий | Решение |
|----------|---------|
| Появление alert | `wait.until(ExpectedConditions.alertIsPresent()).accept();` |
| Получить текст alert | `driver.switchTo().alert().getText();` |
| Отклонить confirm | `driver.switchTo().alert().dismiss();` |
| Ввести текст в prompt | `driver.switchTo().alert().sendKeys("текст");` |
| Ожидание HTML-модалки | `wait.until(ExpectedConditions.visibilityOfElementLocated(By.id("modal")));` |
| Закрыть модалку (клик по кнопке) | `driver.findElement(By.cssSelector(".modal .close")).click();` |
| Ожидание закрытия модалки | `wait.until(ExpectedConditions.invisibilityOfElementLocated(By.id("modal")));` |
| Модалка внутри iframe | `driver.switchTo().frame(iframe);` затем взаимодействие |
| Отключить браузерные уведомления | `options.addArguments("--disable-notifications");` |

---

##  Полезные ссылки

- [Selenium Docs — Alert Interface](https://www.selenium.dev/documentation/webdriver/interactions/alerts/)
- [Selenium Docs — Switching Frames](https://www.selenium.dev/documentation/webdriver/browser/frames/)
- [Bootstrap Modals Documentation](https://getbootstrap.com/docs/5.3/components/modal/)
- [jQuery UI Dialog](https://jqueryui.com/dialog/)

---

*Заметка готова. Используйте для стабильной работы с любыми модальными окнами.*