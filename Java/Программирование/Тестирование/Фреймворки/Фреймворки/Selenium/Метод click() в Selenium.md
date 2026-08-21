# Метод click() в Selenium (Java)

> **Теги:** `#selenium` `#click` `#действия` `#java`  
> **Актуально для:** Selenium 4.x

##  Что такое `click()`?

Метод `click()` в Selenium WebDriver предназначен для эмуляции клика левой кнопкой мыши по веб-элементу. Он является основным способом взаимодействия с кнопками, ссылками, чекбоксами, радиокнопками и другими интерактивными элементами.

```java
WebElement button = driver.findElement(By.id("submit"));
button.click();
```

На первый взгляд всё просто, но на практике клик — одна из самых частых причин нестабильных тестов. Связано это с динамикой страниц, асинхронной загрузкой, перекрытием элементов и другими факторами.

---

##  Основные исключения при клике

| Исключение | Причина | Решение |
|------------|---------|---------|
| `NoSuchElementException` | Элемент отсутствует в DOM | Проверить локатор, добавить ожидание `presenceOfElementLocated` |
| `ElementNotVisibleException` | Элемент существует, но скрыт (display:none, visibility:hidden) | Использовать `visibilityOfElementLocated` или `elementToBeClickable` |
| `ElementNotInteractableException` | Элемент есть, но с ним нельзя взаимодействовать (например, перекрыт другим элементом) | Использовать `elementToBeClickable` или JavaScript-клик |
| `ElementClickInterceptedException` | Клик перехвачен другим элементом (например, модальным окном) | Дождаться исчезновения перекрывающего элемента или кликнуть через JS |
| `StaleElementReferenceException` | Элемент был в DOM, но страница обновилась (перезагрузка, AJAX-подмена) | Заново найти элемент перед кликом |

---

##  Правильный подход: ожидание кликабельности

**Золотое правило:** перед кликом всегда проверяйте, что элемент **кликабелен** — то есть он видим, не скрыт, не disabled и не перекрыт.

```java
import org.openqa.selenium.support.ui.WebDriverWait;
import org.openqa.selenium.support.ui.ExpectedConditions;
import java.time.Duration;

WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(10));

// Лучший способ: ожидание кликабельности и клик в одной строке
wait.until(ExpectedConditions.elementToBeClickable(By.id("submit"))).click();
```

`ExpectedConditions.elementToBeClickable()` проверяет:
- Элемент присутствует в DOM
- Элемент видим (visible)
- Элемент включён (не имеет атрибута `disabled`)
- Элемент не перекрыт другими элементами (проверяется пересечение с другими элементами)

---

##  Альтернативные способы клика

### 1. Клик через Actions (для сложных сценариев)

`Actions` позволяет эмулировать более сложные взаимодействия, включая клик с зажатыми клавишами, двойной клик, клик правой кнопкой и перемещение мыши.

```java
import org.openqa.selenium.interactions.Actions;

Actions actions = new Actions(driver);
WebElement element = driver.findElement(By.id("menu"));
actions.moveToElement(element).click().perform(); // наведение + клик
```

Особенности:
- Лучше эмулирует реальное поведение пользователя
- Позволяет добавить задержки между действиями
- Часто решает проблемы с перекрытием (двигает мышь к элементу перед кликом)

### 2. Клик через JavaScript (обходной путь)

Используйте JavaScript, когда элемент недоступен для обычного клика из-за перекрытия или нестандартного поведения.

```java
import org.openqa.selenium.JavascriptExecutor;

WebElement element = driver.findElement(By.id("submit"));
JavascriptExecutor js = (JavascriptExecutor) driver;
js.executeScript("arguments[0].click();", element);
```

**Когда использовать:**
- Элемент перекрыт модальным окном или баннером
- Элемент находится вне видимой области (за пределами viewport) — хотя Selenium сам скроллит, иногда не помогает
- Элемент с атрибутом `disabled` — но JS-клик может сработать, хотя это не соответствует поведению пользователя (используйте с осторожностью)

** Важно:** JS-клик не эмулирует реальное взаимодействие (не генерирует события `mouseover`, `mousedown` и т.д.). Используйте только как fallback.

---

##  Обработка исключений и повторные попытки

В нестабильных средах (например, при медленной загрузке или фоновых AJAX-запросах) можно реализовать повторные попытки клика.

```java
public void safeClick(By locator) {
    int attempts = 0;
    while (attempts < 3) {
        try {
            WebElement element = driver.findElement(locator);
            element.click();
            return;
        } catch (ElementClickInterceptedException e) {
            // Перекрывающий элемент — возможно, модальное окно, ждём
            wait.until(ExpectedConditions.invisibilityOfElementLocated(By.className("modal-overlay")));
        } catch (StaleElementReferenceException e) {
            // Элемент обновился, пробуем снова
        } catch (Exception e) {
            // Логируем и пробуем ещё
        }
        attempts++;
        try { Thread.sleep(500); } catch (InterruptedException ignored) {}
    }
    throw new RuntimeException("Не удалось кликнуть по элементу: " + locator);
}
```

Более элегантный вариант — использовать **Fluent Wait** с игнорированием исключений:

```java
import org.openqa.selenium.support.ui.FluentWait;
import org.openqa.selenium.TimeoutException;

FluentWait<WebDriver> wait = new FluentWait<>(driver)
    .withTimeout(Duration.ofSeconds(10))
    .pollingEvery(Duration.ofMillis(200))
    .ignoring(ElementClickInterceptedException.class)
    .ignoring(StaleElementReferenceException.class);

try {
    wait.until(d -> {
        WebElement el = d.findElement(By.id("submit"));
        el.click();
        return true;
    });
} catch (TimeoutException e) {
    // Логируем, что клик не удался
}
```

---

##  Клик по координатам (менее предпочтительно)

Иногда клик нужно выполнить по определённым координатам на странице, не привязываясь к элементу (например, для карт или canvas).

```java
Actions actions = new Actions(driver);
actions.moveByOffset(100, 200).click().perform();
```

Или с использованием `Robot` (AWT) — но это вне Selenium и требует координат на экране, что ненадёжно.

---

##  Практические примеры

### Клик по кнопке после появления спиннера

```java
// Ждём, пока пропадёт загрузка
wait.until(ExpectedConditions.invisibilityOfElementLocated(By.id("spinner")));
// Кликаем по кнопке
wait.until(ExpectedConditions.elementToBeClickable(By.id("save-btn"))).click();
```

### Клик по элементу внутри фрейма

```java
driver.switchTo().frame("iframe-name");
wait.until(ExpectedConditions.elementToBeClickable(By.id("button-inside-frame"))).click();
driver.switchTo().defaultContent();
```

### Клик по ссылке, которая открывается в новой вкладке

```java
WebElement link = wait.until(ExpectedConditions.elementToBeClickable(By.linkText("Открыть в новой вкладке")));
link.click();
// Можно переключиться на новую вкладку
for (String handle : driver.getWindowHandles()) {
    driver.switchTo().window(handle);
}
```

---

##  Best Practices

1. **Всегда используйте явные ожидания** перед кликом (`elementToBeClickable`).
2. **Не кликайте по элементам, которые не должны быть кликабельны** (например, заголовки, div-контейнеры).
3. **Если клик не срабатывает**, проверьте:
   - Не перекрыт ли элемент другим слоем (модалка, баннер, cookie-уведомление).
   - Не находится ли элемент вне видимой области (Selenium обычно скроллит, но не всегда корректно).
   - Не является ли элемент `disabled` (серым) — тогда клик должен быть заблокирован, но JS-клик может его обойти (и это может быть ошибкой в тесте).
4. **Для мобильных эмуляций** используйте `Actions` с `click()` — он лучше эмулирует тап.
5. **После клика** часто требуется ожидание изменения страницы (переход, появление нового элемента) — добавьте соответствующее ожидание.
6. **Не злоупотребляйте JavaScript-кликом** — он скрывает реальные проблемы взаимодействия.
7. **Если клик вызывает загрузку новой страницы**, после клика добавьте `wait.until(ExpectedConditions.titleContains(...))` или `urlContains(...)`.
8. **В Page Object Model** инкапсулируйте логику клика в методах страницы:

```java
public class LoginPage {
    private WebDriver driver;
    private WebDriverWait wait;
    
    private By loginButton = By.id("login-btn");
    
    public LoginPage(WebDriver driver) {
        this.driver = driver;
        this.wait = new WebDriverWait(driver, Duration.ofSeconds(10));
    }
    
    public void clickLogin() {
        wait.until(ExpectedConditions.elementToBeClickable(loginButton)).click();
        // после клика можно сразу добавить ожидание перехода
        wait.until(ExpectedConditions.urlContains("dashboard"));
    }
}
```

---

##  Шпаргалка (быстрый поиск)

| Сценарий | Решение |
|----------|---------|
| Простой клик | `driver.findElement(By.id("btn")).click();` |
| Клик с ожиданием кликабельности | `wait.until(ExpectedConditions.elementToBeClickable(By.id("btn"))).click();` |
| Клик с наведением | `new Actions(driver).moveToElement(element).click().perform();` |
| Клик через JavaScript (fallback) | `((JavascriptExecutor)driver).executeScript("arguments[0].click();", element);` |
| Клик по координатам | `new Actions(driver).moveByOffset(x, y).click().perform();` |
| Игнорировать перехват клика | Использовать `FluentWait` с `ignoring(ElementClickInterceptedException.class)` |
| Клик после смены фрейма | `driver.switchTo().frame(...);` затем клик |
| Клик по невидимому элементу | Сначала сделать его видимым через JS: `js.executeScript("arguments[0].style.display='block';", element);` (не рекомендуется) |

---

##  Полезные ссылки

- [Selenium Docs — Click](https://www.selenium.dev/documentation/webdriver/actions_api/mouse/#click)
- [Selenium Docs — WebDriverWait](https://www.selenium.dev/documentation/webdriver/waits/)
- [ElementClickInterceptedException — примеры](https://www.selenium.dev/documentation/webdriver/troubleshooting/errors/#element-click-intercepted-exception)

---

*Заметка готова. Используйте её как руководство для стабильных кликов в ваших тестах.*