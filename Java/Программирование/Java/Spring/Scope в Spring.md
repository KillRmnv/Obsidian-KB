## Что такое Scope

**Scope (область видимости)** определяет, **сколько экземпляров Bean'а** создаётся и **как долго они живут**.

```
┌─────────────────────────────────────────┐
│           singleton (1 экземпляр)       │
│    ┌─────────┐                          │
│    │  Bean   │ ←── Все используют один  │
│    │         │     и тот же объект        │
│    └─────────┘                          │
│         ↑                               │
│    ┌────┴────┐                          │
│    ▼         ▼                          │
│ [Клиент1]  [Клиент2]  [Клиент3]         │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│          prototype (много экземпляров)  │
│    ┌─────────┐  ┌─────────┐  ┌────────┐ │
│    │  Bean   │  │  Bean   │  │  Bean  │ │
│    │   #1    │  │   #2    │  │  #3    │ │
│    └─────────┘  └─────────┘  └────────┘ │
│         ↑            ↑           ↑      │
│    [Клиент1]    [Клиент2]   [Клиент3]   │
│   (свой бин)   (свой бин)  (свой бин)   │
└─────────────────────────────────────────┘
```

---

## Типы Scope в Spring

| Scope | Описание | Когда создаётся | Когда уничтожается |
|-------|---------|---------------|-------------------|
| **singleton** | Один экземпляр на весь контейнер | При старте или первом запросе | При остановке контейнера |
| **prototype** | Новый экземпляр каждый раз | При каждом запросе | Сборщиком мусора (Spring не следит) |
| **request** | Один на HTTP-запрос | При HTTP-запросе | После обработки запроса |
| **session** | Один на HTTP-сессию | При создании сессии | При истечении сессии |
| **application** | Один на ServletContext | При старте веб-приложения | При остановке |
| **websocket** | Один на WebSocket-сессию | При подключении WebSocket | При отключении |

---

## 1. Singleton (по умолчанию)

```java
import org.springframework.stereotype.Service;

@Service  // = @Scope("singleton") по умолчанию
public class КешПродуктов {
    
    private final Map<Long, Продукт> кеш = new HashMap<>();
    
    public void добавить(Продукт продукт) {
        кеш.put(продукт.getId(), продукт);
    }
    
    public Продукт получить(Long id) {
        return кеш.get(id);
    }
}
```

**Поведение:**
```java
@Service
public class ТестSingleton {
    
    @Autowired
    private КешПродуктов кеш1;
    
    @Autowired
    private КешПродуктов кеш2;
    
    public void проверить() {
        // ✅ Один и тот же объект!
        System.out.println(kеш1 == кеш2);  // true
        
        кеш1.добавить(new Продукт(1L, "Яблоко"));
        
        // Видно во всех "внедрениях"
        System.out.println(кеш2.получить(1L));  // "Яблоко"
    }
}
```

---

## 2. Prototype

```java
import org.springframework.context.annotation.Scope;
import org.springframework.stereotype.Component;

@Component
@Scope("prototype")  // Каждый раз НОВЫЙ объект
public class ГенераторОтчёта {
    
    private final LocalDateTime создан = LocalDateTime.now();
    private final List<String> данные = new ArrayList<>();
    
    public void добавитьДанные(String данные) {
        this.данные.add(данные);
    }
    
    public String сформировать() {
        return "Отчёт от " + создан + ": " + данные;
    }
}
```

**Поведение:**
```java
@Service
public class ТестPrototype {
    
    @Autowired
    private ГенераторОтчёта отчёт1;
    
    @Autowired
    private ГенераторОтчёта отчёт2;
    
    public void проверить() {
        // ❌ Разные объекты!
        System.out.println(отчёт1 == отчёт2);  // false
        
        отчёт1.добавитьДанные("Продажи января");
        отчёт2.добавитьДанные("Продажи февраля");
        
        // Данные не смешиваются
        System.out.println(отчёт1.сформировать());  // Только январь
        System.out.println(отчёт2.сформировать());  // Только февраль
    }
}
```

---

## 3. Request (веб)

```java
import org.springframework.context.annotation.Scope;
import org.springframework.stereotype.Component;
import org.springframework.web.context.WebApplicationContext;

@Component
@Scope(WebApplicationContext.SCOPE_REQUEST)  // или @Scope("request")
public class ДанныеЗапроса {
    
    private String idЗапроса = UUID.randomUUID().toString();
    private LocalDateTime начало = LocalDateTime.now();
    private Map<String, Object> атрибуты = new HashMap<>();
    
    public void добавитьАтрибут(String ключ, Object значение) {
        атрибуты.put(ключ, значение);
    }
    
    public String getИнфо() {
        return "Запрос #" + idЗапроса + " начат в " + начало;
    }
}
```

**Использование в контроллере:**
```java
@RestController
@RequestMapping("/api")
public class Контроллер {
    
    @Autowired
    private ДанныеЗапроса данныеЗапроса;  // Новый для каждого HTTP-запроса
    
    @GetMapping("/test")
    public String test() {
        данныеЗапроса.добавитьАтрибут("пользователь", "Иван");
        данныеЗапроса.добавитьАтрибут("время", LocalDateTime.now());
        
        // Этот же объект виден во всех сервисах в рамках одного HTTP-запроса
        return данныеЗапроса.getИнфо();
    }
}
```

---

## 4. Session (веб)

```java
@Component
@Scope(WebApplicationContext.SCOPE_SESSION)  // или @Scope("session")
public class КорзинаПокупок {
    
    private final List<Товар> товары = new ArrayList<>();
    
    public void добавить(Товар товар) {
        товары.add(товар);
    }
    
    public List<Товар> getТовары() {
        return new ArrayList<>(товары);
    }
    
    public double getСумма() {
        return товары.stream().mapToDouble(Товар::getЦена).sum();
    }
}
```

**Живёт в рамках пользовательской сессии:**
```java
@RestController
public class МагазинКонтроллер {
    
    @Autowired
    private КорзинаПокупок корзина;  // Своя для каждого пользователя
    
    @PostMapping("/корзина/добавить")
    public void добавить(@RequestBody Товар товар) {
        // У пользователя А своя корзина, у пользователя Б — своя
        корзина.добавить(товар);
    }
    
    @GetMapping("/корзина")
    public КорзинаИнфо получить() {
        return new КорзинаИнфо(
            корзина.getТовары(),
            корзина.getСумма()
        );
    }
}
```

---

## Сравнение в таблице

```
┌─────────────┬─────────────┬─────────────┬─────────────┐
│  singleton  │  prototype  │   request   │   session   │
├─────────────┼─────────────┼─────────────┼─────────────┤
│      1      │    много    │  1/запрос   │  1/сессия   │
│  контейнер  │   запрос    │   запрос    │   сессия    │
│   eager     │    lazy     │    lazy     │    lazy     │
│  контейнер  │     JVM     │  контейнер  │  контейнер  │
│  управляет  │   GC        │  управляет  │  управляет  │
└─────────────┴─────────────┴─────────────┴─────────────┘
```

---

## Важный нюанс: Prototype в Singleton

```java
@Service  // singleton по умолчанию
public class СервисОбработки {
    
    @Autowired
    private ГенераторОтчёта генератор;  // prototype, но...
    
    public void обработать() {
        // ❌ Проблема: один и тот же генератор!
        // Spring внедрил prototype ОДИН РАЗ при создании singleton
        генератор.добавитьДанные("...");
    }
}
```

### Решение: ObjectFactory или @Lookup

```java
import org.springframework.beans.factory.ObjectFactory;

@Service
public class СервисОбработки {
    
    private final ObjectFactory<ГенераторОтчёта> фабрика;
    
    public СервисОбработки(ObjectFactory<ГенераторОтчёта> фабрика) {
        this.фабрика = фабрика;
    }
    
    public void обработать() {
        // ✅ Каждый раз НОВЫЙ prototype-бин
        ГенераторОтчёта генератор = фабрика.getObject();
        генератор.добавитьДанные("...");
    }
}
```

**Или через @Lookup (только для классов, не для интерфейсов):**
```java
@Service
public abstract class СервисОбработки {
    
    public void обработать() {
        ГенераторОтчёта генератор = создатьГенератор();
        генератор.добавитьДанные("...");
    }
    
    @Lookup  // Spring переопределит этот метод
    protected abstract ГенераторОтчёта создатьГенератор();
}
```

---

## Практический пример: фабрика отчётов

```java
// === НАСТРОЙКИ ОТЧЁТА (prototype) ===
@Component
@Scope("prototype")
public class НастройкиОтчёта {
    private String формат = "PDF";
    private boolean вклГрафики = true;
    private String тема = "Светлая";
    
    // геттеры/сеттеры...
}

// === ФАБРИКА (singleton) ===
@Service
public class ФабрикаОтчётов {
    
    private final ObjectFactory<НастройкиОтчёта> фабрикаНастроек;
    
    public ФабрикаОтчётов(ObjectFactory<НастройкиОтчёта> фабрика) {
        this.фабрикаНастроек = фабрика;
    }
    
    public Отчёт создатьОтчёт(String тип) {
        // Новые настройки для каждого отчёта
        НастройкиОтчёта настройки = фабрикаНастроек.getObject();
        
        switch (тип) {
            case "финансовый":
                настройки.setТема("Корпоративная");
                настройки.setВклГрафики(true);
                break;
            case "простой":
                настройки.setВклГрафики(false);
                break;
        }
        
        return new Отчёт(настройки);
    }
}
```

---

## Итог

| Scope | Используйте когда |
|-------|-------------------|
| **singleton** | Состояние общее для всех (кеши, пулы, настройки) |
| **prototype** | Нужен новый объект каждый раз (генераторы, билдеры) |
| **request** | Данные в рамках одного HTTP-запроса |
| **session** | Данные пользователя (корзина, авторизация) |

**По умолчанию — singleton, потому что это эффективно. Меняйте только если нужно!**