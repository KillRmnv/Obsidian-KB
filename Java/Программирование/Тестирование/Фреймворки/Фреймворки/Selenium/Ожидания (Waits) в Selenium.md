# Ожидания (Waits) в Selenium

> **Теги:** `#selenium` `#ожидания` `#waits` `#java`  
> **Актуально для:** Selenium 4.x

##  Зачем нужны ожидания?

Веб-приложения динамически загружают контент с помощью JavaScript, AJAX и других асинхронных технологий. Элементы могут появляться, исчезать или становиться доступными с задержкой.

Если Selenium попытается взаимодействовать с элементом до того, как он будет готов, тест упадёт с ошибкой. Это одна из главных причин **нестабильных (flaky) тестов**.

> **Золотое правило:**  **Никогда не используйте `Thread.sleep()`** для ожиданий. Всегда используйте явные ожидания с `WebDriverWait` и `ExpectedConditions`.

---

##  Почему `Thread.sleep()` — это плохо?

| Проблема | Последствие |
|----------|-------------|
| Фиксированная задержка | Тратит время, даже если элемент готов раньше |
| Нестабильность | Падает, если элемент загружается дольше |
| Нет проверки условий | Ожидание слепое, не проверяет состояние элемента |
| Непредсказуемость | На разных машинах время загрузки отличается |
| Трудно поддерживать | Магические числа разбросаны по всему коду |

```java
//  НИКОГДА ТАК НЕ ДЕЛАЙТЕ
Thread.sleep(3000);
driver.findElement(By.id("submit")).click();

//  ВСЕГДА ДЕЛАЙТЕ ТАК
WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(10));
wait.until(ExpectedConditions.elementToBeClickable(By.id("submit"))).click();
```

---

##  Типы ожиданий в Selenium

Selenium предоставляет три основные стратегии ожидания:

| Тип | Область действия | Гибкость | Когда использовать |
|-----|------------------|----------|-------------------|
| **Implicit Wait** | Глобальная (весь драйвер) | Низкая | Простые сценарии, статичные страницы |
| **Explicit Wait** | Локальная (конкретный элемент) | Высокая | Динамические страницы, AJAX-приложения |
| **Fluent Wait** | Локальная (конкретный элемент) | Максимальная | Сложные условия, кастомная логика |

---

### 1⃣ Implicit Wait (Неявное ожидание)

Глобальная настройка для всего драйвера. Selenium опрашивает DOM в течение указанного времени, пытаясь найти элемент. По умолчанию значение равно 0 секунд.

```java
// Установка неявного ожидания
driver.manage().timeouts().implicitlyWait(Duration.ofSeconds(10));

// Теперь все findElement() будут ждать до 10 секунд
WebElement element = driver.findElement(By.id("username"));
```

**Особенности:**
- Применяется к каждому вызову `findElement()` или `findElements()`
- Как только элемент найден, выполнение продолжается сразу
- Действует в течение всей сессии браузера
- Время опроса зависит от реализации драйвера (обычно ~500 мс)

>  **Важно:** Не смешивайте неявные и явные ожидания — это может привести к непредсказуемым таймаутам.

---

### 2⃣ Explicit Wait (Явное ожидание)

Локальное ожидание для конкретного условия. Это цикл, который опрашивает приложение с заданной периодичностью, пока условие не станет истинным или не истечёт таймаут.

```java
import org.openqa.selenium.support.ui.WebDriverWait;
import org.openqa.selenium.support.ui.ExpectedConditions;
import java.time.Duration;

// Базовый WebDriverWait
WebDriverWait wait = new WebDriverWait(driver, Duration.ofSeconds(10));

// Ожидание видимости элемента
WebElement element = wait.until(
    ExpectedConditions.visibilityOfElementLocated(By.id("username"))
);

// Ожидание кликабельности (непосредственный клик)
wait.until(ExpectedConditions.elementToBeClickable(By.id("submit"))).click();
```

**Настройка интервала опроса:**
```java
// С кастомным интервалом опроса (по умолчанию 500 мс)
WebDriverWait wait = new WebDriverWait(
    driver,
    Duration.ofSeconds(15),     // таймаут
    Duration.ofMillis(250)      // интервал опроса
);
```

---

### 3⃣ Fluent Wait (Гибкое ожидание)

Расширенная версия явного ожидания, позволяющая настраивать:
- Интервал опроса (polling frequency)
- Игнорируемые исключения
- Кастомные сообщения об ошибках

В Java `WebDriverWait` является наследником `FluentWait`, поэтому стандартное явное ожидание уже является Fluent Wait с интервалом опроса 500 мс по умолчанию.

```java
import org.openqa.selenium.support.ui.FluentWait;
import org.openqa.selenium.NoSuchElementException;
import java.time.Duration;

Wait<WebDriver> wait = new FluentWait<WebDriver>(driver)
    .withTimeout(Duration.ofSeconds(30))           // максимальное время ожидания
    .pollingEvery(Duration.ofSeconds(1))           // интервал опроса
    .ignoring(NoSuchElementException.class)        // игнорируемые исключения
    .withMessage("Элемент не найден за 30 секунд");

// Использование
WebElement element = wait.until(
    ExpectedConditions.visibilityOfElementLocated(By.id("dynamicElement"))
);
```

**Когда использовать Fluent Wait:**
- Нужен нестандартный интервал опроса
- Требуется игнорировать специфические исключения
- Сложные условия с кастомной логикой

---

##  ExpectedConditions (справочник)

`ExpectedConditions` — это набор готовых условий для явных ожиданий.

### Поиск элементов

| Метод | Описание |
|-------|----------|
| `presenceOfElementLocated(By locator)` | Элемент присутствует в DOM (не обязательно видим) |
| `visibilityOfElementLocated(By locator)` | Элемент присутствует в DOM и видим |
| `visibilityOf(WebElement element)` | Конкретный элемент видим |
| `visibilityOfAllElementsLocatedBy(By locator)` | Все элементы из локатора видимы |
| `invisibilityOfElementLocated(By locator)` | Элемент невидим или отсутствует в DOM |

### Взаимодействие

| Метод | Описание |
|-------|----------|
| `elementToBeClickable(By locator)` | Элемент видим и активен (можно кликнуть) |
| `elementToBeClickable(WebElement element)` | То же для конкретного элемента |
| `elementToBeSelected(WebElement element)` | Элемент выбран (для checkbox/radio) |

### Текст и атрибуты

| Метод | Описание |
|-------|----------|
| `textToBePresentInElementLocated(By, String)` | Элемент содержит указанный текст |
| `textToBePresentInElement(WebElement, String)` | То же для конкретного элемента |
| `attributeContains(By, String, String)` | Атрибут содержит значение |
| `attributeToBe(WebElement, String, String)` | Атрибут имеет точное значение |

### Страница

| Метод | Описание |
|-------|----------|
| `titleIs(String title)` | Точное совпадение заголовка страницы |
| `titleContains(String title)` | Заголовок содержит подстроку |
| `urlToBe(String url)` | Точное совпадение URL |
| `urlContains(String fraction)` | URL содержит подстроку |
| `frameToBeAvailableAndSwitchToIt(String)` | Фрейм доступен, переключиться на него |

### Логические операции

| Метод | Описание |
|-------|----------|
| `and(ExpectedCondition<?>... conditions)` | Логическое И для нескольких условий |
| `or(ExpectedCondition<?>... conditions)` | Логическое ИЛИ для нескольких условий |
| `not(ExpectedCondition<?> condition)` | Отрицание условия |

---

##  Практические примеры

### Настройка в базовом классе Page Object

```java
public abstract class BasePage {
    protected final WebDriver driver;
    protected final WebDriverWait wait;
    protected final WebDriverWait shortWait;
    protected final WebDriverWait longWait;
    
    private static final Duration DEFAULT_TIMEOUT = Duration.ofSeconds(15);
    private static final Duration SHORT_TIMEOUT = Duration.ofSeconds(5);
    private static final Duration LONG_TIMEOUT = Duration.ofSeconds(30);
    
    protected BasePage(WebDriver driver) {
        this.driver = driver;
        this.wait = new WebDriverWait(driver, DEFAULT_TIMEOUT);
        this.shortWait = new WebDriverWait(driver, SHORT_TIMEOUT);
        this.longWait = new WebDriverWait(driver, LONG_TIMEOUT);
    }
}
```


### Ожидание загрузки (спиннер)

```java
// Ждём, пока спиннер исчезнет
wait.until(ExpectedConditions.invisibilityOfElementLocated(By.id("loading-spinner")));

// Или ждём, пока не появится контент
wait.until(ExpectedConditions.visibilityOfElementLocated(By.id("content")));
```

### Ожидание с логическим ИЛИ

```java
// Ждём, когда появится хотя бы один из элементов
wait.until(ExpectedConditions.or(
    ExpectedConditions.visibilityOfElementLocated(By.id("success")),
    ExpectedConditions.visibilityOfElementLocated(By.id("error"))
));
```

### Обработка TimeoutException

```java
try {
    wait.until(ExpectedConditions.visibilityOfElementLocated(By.id("modal")));
} catch (TimeoutException e) {
    // Логируем ошибку, делаем скриншот
    System.out.println("Модальное окно не появилось за отведённое время");
    // Дополнительные действия: скриншот, повтор, fallback
}
```

---

##  Сравнение стратегий

| Критерий | Implicit Wait | Explicit Wait | Fluent Wait |
|----------|---------------|---------------|-------------|
| Область действия | Глобальная | Локальная | Локальная |
| Условие ожидания | Только наличие элемента | Любое (ExpectedConditions) | Любое + кастомное |
| Интервал опроса | Фиксированный (зависит от драйвера) | 500 мс (по умолчанию) | Настраиваемый |
| Игнорирование исключений | Нет | Нет | Да |
| Гибкость | Низкая | Высокая | Максимальная |

---

##  Лучшие практики

1. **Никогда не используйте `Thread.sleep()`** — всегда используйте явные ожидания
2. **Не смешивайте неявные и явные ожидания** — это может вызвать непредсказуемые таймауты
3. **Устанавливайте разные таймауты** для разных ситуаций (быстрый/средний/долгий)
4. **Используйте Page Object паттерн** — инкапсулируйте логику ожиданий в базовом классе
5. **Обрабатывайте `TimeoutException`** — логируйте ошибки и делайте скриншоты
6. **Для AJAX-приложений используйте явные ожидания** — они наиболее надёжны

---

##  Шпаргалка (быстрый поиск)

| Сценарий | Решение |
|----------|---------|
| Элемент должен появиться | `wait.until(ExpectedConditions.presenceOfElementLocated(By))` |
| Элемент должен стать видимым | `wait.until(ExpectedConditions.visibilityOfElementLocated(By))` |
| Элемент должен исчезнуть | `wait.until(ExpectedConditions.invisibilityOfElementLocated(By))` |
| Кнопка должна стать кликабельной | `wait.until(ExpectedConditions.elementToBeClickable(By)).click()` |
| Заголовок страницы содержит текст | `wait.until(ExpectedConditions.titleContains("текст"))` |
| Появился Alert | `wait.until(ExpectedConditions.alertIsPresent())` |
| Кастомный интервал опроса | `new WebDriverWait(driver, timeout, polling)` |
| Игнорировать исключения | `new FluentWait<>(driver).ignoring(NoSuchElementException.class)` |
| Несколько условий (И) | `wait.until(ExpectedConditions.and(cond1, cond2))` |
| Несколько условий (ИЛИ) | `wait.until(ExpectedConditions.or(cond1, cond2))` |

---

##  Полезные ссылки

- [Selenium Docs — Waiting Strategies](https://www.selenium.dev/documentation/webdriver/waits/)
- [Selenium Docs — ExpectedConditions API](https://www.selenium.dev/selenium/docs/api/java/org/openqa/selenium/support/ui/ExpectedConditions.html)
- [BrowserStack — Understanding Selenium Timeouts](https://www.browserstack.com/guide/understanding-selenium-timeouts)

---

*Заметка готова. Дополняйте своими примерами по мере накопления опыта.*