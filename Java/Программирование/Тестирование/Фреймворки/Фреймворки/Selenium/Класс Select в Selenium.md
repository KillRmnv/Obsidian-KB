# Класс Select в Selenium (Java)

> **Теги:** `#selenium` `#select` `#dropdown` `#выпадающие_списки` `#java`  
> **Актуально для:** Selenium 4.x

##  Что такое Select?

Класс `Select` в Selenium предоставляет удобный API для работы с элементами HTML `<select>` (выпадающие списки). Он инкапсулирует сложную логику работы с опциями, включая выбор по тексту, значению и индексу, а также поддержку мульти-селектов.

```java
import org.openqa.selenium.support.ui.Select;
```

---

##  Инициализация Select

```java
WebElement dropdownElement = driver.findElement(By.id("country"));
Select dropdown = new Select(dropdownElement);
```

> **Важно:** Объект `Select` можно создать только для элемента `<select>`. Если элемент не является `<select>`, будет выброшено исключение `UnexpectedTagNameException`.

---

##  Основные методы выбора опции

| Метод | Описание |
|-------|----------|
| `selectByIndex(int index)` | Выбор по индексу (начинается с 0) |
| `selectByValue(String value)` | Выбор по атрибуту `value` |
| `selectByVisibleText(String text)` | Выбор по видимому тексту (полное совпадение) |

### Примеры

```java
Select dropdown = new Select(driver.findElement(By.id("country")));

// Выбор по индексу (третий элемент, индекс 2)
dropdown.selectByIndex(2);

// Выбор по значению атрибута value
dropdown.selectByValue("IN");

// Выбор по видимому тексту
dropdown.selectByVisibleText("India");
```

---

##  Методы для получения информации

| Метод | Описание |
|-------|----------|
| `getOptions()` | Возвращает все опции (List<WebElement>) |
| `getFirstSelectedOption()` | Возвращает первую выбранную опцию |
| `getAllSelectedOptions()` | Возвращает все выбранные опции (для мульти-селектов) |
| `isMultiple()` | Проверяет, поддерживает ли select множественный выбор |

### Примеры

```java
Select dropdown = new Select(driver.findElement(By.id("country")));

// Получить все опции
List<WebElement> options = dropdown.getOptions();
for (WebElement option : options) {
    System.out.println(option.getText());
}

// Получить выбранную опцию
WebElement selected = dropdown.getFirstSelectedOption();
System.out.println("Выбрано: " + selected.getText());

// Проверить, мульти-селект ли это
if (dropdown.isMultiple()) {
    System.out.println("Это мульти-селект");
}
```

---

##  Работа с мульти-селектами (multiple)

Если у `<select>` есть атрибут `multiple`, то можно выбирать несколько опций.

```java
Select multiSelect = new Select(driver.findElement(By.id("hobbies")));

// Выбор нескольких опций
multiSelect.selectByVisibleText("Reading");
multiSelect.selectByVisibleText("Music");
multiSelect.selectByValue("sports");

// Получить все выбранные опции
List<WebElement> selected = multiSelect.getAllSelectedOptions();

// Снять выбор со всех опций
multiSelect.deselectAll();

// Снять выбор с конкретной опции
multiSelect.deselectByVisibleText("Reading");
multiSelect.deselectByIndex(1);
```

---

##  Важные нюансы

1. **Регистрозависимость** — `selectByVisibleText()` чувствителен к регистру. `"India"` и `"india"` — это разные значения.

2. **Пробелы** — текст опции должен совпадать точно, включая пробелы в начале и конце (хотя `selectByVisibleText` немного триммит, но лучше быть точным).

3. **Динамические опции** — если опции загружаются через AJAX, перед выбором нужно дождаться их появления:
   ```java
   wait.until(ExpectedConditions.visibilityOfElementLocated(By.xpath("//select[@id='country']/option[1]")));
   ```

4. **Ошибка при отсутствии опции** — `selectByIndex` и `selectByValue` могут выбросить `NoSuchElementException` или `ElementNotSelectableException`.

---

##  Альтернативы Select

Если выпадающий список реализован не через тег `<select>`, а через кастомный элемент (например, Bootstrap или React-компонент), то нужно работать с ним как с обычными элементами:

```java
// Кликнуть по элементу, открывающему список
driver.findElement(By.id("custom-dropdown")).click();

// Выбрать нужный пункт
driver.findElement(By.xpath("//div[@class='dropdown-item' and text()='Option 1']")).click();
```

---

##  Шпаргалка (быстрый поиск)

| Сценарий | Код |
|----------|-----|
| Инициализация | `Select select = new Select(driver.findElement(By.id("id")));` |
| Выбор по индексу | `select.selectByIndex(2);` |
| Выбор по value | `select.selectByValue("value");` |
| Выбор по тексту | `select.selectByVisibleText("Текст");` |
| Получить все опции | `select.getOptions();` |
| Получить выбранную опцию | `select.getFirstSelectedOption();` |
| Проверка мульти-селекта | `select.isMultiple();` |
| Снять выбор (мульти) | `select.deselectAll();` |

---

##  Полезные ссылки

- [Selenium Docs — Select](https://www.selenium.dev/documentation/webdriver/support_features/select/)
- [MDN — HTMLSelectElement](https://developer.mozilla.org/en-US/docs/Web/API/HTMLSelectElement)

---

