# @Qualifier в Spring

## Зачем нужен @Qualifier

Когда **несколько Bean'ов одного типа**, Spring не знает какой выбрать. `@Qualifier` указывает конкретный Bean по имени.

```
┌─────────────────────────────────────────┐
│           Application Context           │
│                                         │
│  ┌─────────────┐   ┌─────────────┐     │
│  │  MasterCard │   │    Visa     │     │
│  │  (бин №1)   │   │  (бин №2)   │     │
│  │ @Component  │   │ @Component  │     │
│  │("master")   │   │  ("visa")   │     │
│  └─────────────┘   └─────────────┘     │
│         ▲                 ▲             │
│         └─────────────────┘             │
│              |                          │
│    @Autowired + @Qualifier("master")   │
│              → выбирает MasterCard      │
└─────────────────────────────────────────┘
```

---

## Проблема: неоднозначность

```java
// Интерфейс
public interface ПлатёжнаяСистема {
    void оплатить(double сумма);
}

// Два Bean'а одного типа
@Component
public class MasterCard implements ПлатёжнаяСистема {
    public void оплатить(double сумма) {
        System.out.println("Оплата MasterCard: " + сумма);
    }
}

@Component
public class Visa implements ПлатёжнаяСистема {
    public void оплатить(double сумма) {
        System.out.println("Оплата Visa: " + сумма);
    }
}
```

### ❌ Ошибка: Spring не знает что выбрать

```java
@Service
public class СервисОплаты {
    
    @Autowired
    private ПлатёжнаяСистема система;  // ❌ ОШИБКА! Два бина: MasterCard и Visa
    
    // NoUniqueBeanDefinitionException: 
    // expected single matching bean but found 2
}
```

---

## Решение: @Qualifier

### Вариант 1: На классе + при внедрении

```java
// 1. Помечаем бины именами
@Component
@Qualifier("master")  // имя для MasterCard
public class MasterCard implements ПлатёжнаяСистема { }

@Component
@Qualifier("visa")    // имя для Visa
public class Visa implements ПлатёжнаяСистема { }

// 2. Указываем нужный при внедрении
@Service
public class СервисОплаты {
    
    @Autowired
    @Qualifier("visa")  // ✅ Берём конкретно Visa
    private ПлатёжнаяСистема система;
}
```

### Вариант 2: Через @Bean (в конфигурации)

```java
@Configuration
public class КонфигурацияПлатежей {
    
    @Bean
    @Qualifier("электронный")  // имя бина
    public ПлатёжнаяСистема payPal() {
        return new PayPal();
    }
    
    @Bean
    @Qualifier("крипто")
    public ПлатёжнаяСистема bitcoin() {
        return new Bitcoin();
    }
}

// Внедрение
@Service
public class ИнтернетМагазин {
    
    @Autowired
    @Qualifier("электронный")
    private ПлатёжнаяСистема система;
}
```

---

## Все способы использования

### Способ 1: Поле + @Qualifier

```java
@Service
public class Магазин {
    
    @Autowired
    @Qualifier("visa")
    private ПлатёжнаяСистема основнаяСистема;
    
    @Autowired
    @Qualifier("master")
    private ПлатёжнаяСистема резервнаяСистема;
}
```

### Способ 2: Конструктор (рекомендуется) ⭐

```java
@Service
public class Магазин {
    
    private final ПлатёжнаяСистема основная;
    private final ПлатёжнаяСистема резервная;
    
    // @Qualifier указывается на ПАРАМЕТРАХ конструктора
    public Магазин(
            @Qualifier("visa") ПлатёжнаяСистема основная,
            @Qualifier("master") ПлатёжнаяСистема резервная) {
        this.основная = основная;
        this.резервная = резервная;
    }
}
```

### Способ 3: Сеттер

```java
@Service
public class Магазин {
    
    private ПлатёжнаяСистема система;
    
    @Autowired
    @Qualifier("visa")
    public void setСистема(ПлатёжнаяСистема система) {
        this.система = система;
    }
}
```

---

## Продвинутый пример: список всех бинов

```java
// Получить ВСЕ бины типа (без @Qualifier)
@Service
public class ПлатёжныйШлюз {
    
    private final List<ПлатёжнаяСистема> всеСистемы;
    private final Map<String, ПлатёжнаяСистема> системыПоИмени;
    
    public ПлатёжныйШлюз(
            List<ПлатёжнаяСистема> всеСистемы,  // все бины типа
            Map<String, ПлатёжнаяСистема> системыПоИмени) {  // имя → бин
        this.всеСистемы = всеСистемы;
        this.системыПоИмени = системыПоИмени;
    }
    
    public void оплатитьЛюбой(double сумма) {
        // Перебираем все системы
        for (ПлатёжнаяСистема система : всеСистемы) {
            try {
                система.оплатить(сумма);
                return;  // успех
            } catch (Exception e) {
                continue;  // пробуем следующую
            }
        }
    }
    
    public void оплатитьКонкретно(String тип, double сумма) {
        ПлатёжнаяСистема система = системыПоИмени.get(тип);
        система.оплатить(сумма);
    }
}
```

---

## Альтернатива @Qualifier: @Primary

```java
// Помечаем один бин как "основной"
@Component
@Primary  // ✅ Этот бин будет выбран по умолчанию
public class Visa implements ПлатёжнаяСистема { }

@Component
public class MasterCard implements ПлатёжнаяСистема { }

@Service
public class Магазин {
    
    @Autowired
    private ПлатёжнаяСистема система;  // ✅ Автоматически Visa (Primary)
    
    @Autowired
    @Qualifier("masterCard")  // Явно просим MasterCard
    private ПлатёжнаяСистема альтернатива;
}
```

| | @Primary | @Qualifier |
|--|----------|------------|
| **Когда использовать** | Есть "главный" бин | Нужно явно выбирать |
| **Сколько можно** | Один на тип | Любое количество |
| **Гибкость** | Меньше | Больше |

---

## Полный рабочий пример

```java
// === ИНТЕРФЕЙС ===
public interface Уведомление {
    void отправить(String сообщение, String получатель);
}

// === РЕАЛИЗАЦИИ ===
@Component
@Qualifier("email")
public class EmailУведомление implements Уведомление {
    public void отправить(String сообщение, String получатель) {
        System.out.println("📧 Email to " + получатель + ": " + сообщение);
    }
}

@Component
@Qualifier("sms")
public class SmsУведомление implements Уведомление {
    public void отправить(String сообщение, String получатель) {
        System.out.println("📱 SMS to " + получатель + ": " + сообщение);
    }
}

@Component
@Qualifier("push")
public class PushУведомление implements Уведомление {
    public void отправить(String сообщение, String получатель) {
        System.out.println("🔔 Push to " + получатель + ": " + сообщение);
    }
}

// === СЕРВИС, ИСПОЛЬЗУЮЩИЙ ВСЕ ===
@Service
public class СервисУведомлений {
    
    private final Уведомление emailСервис;
    private final Уведомление smsСервис;
    
    public СервисУведомлений(
            @Qualifier("email") Уведомление email,
            @Qualifier("sms") Уведомление sms) {
        this.emailСервис = email;
        this.smsСервис = sms;
    }
    
    public void уведомитьОРегистрации(String пользователь) {
        emailСервис.отправить("Добро пожаловать!", пользователь);
    }
    
    public void уведомитьОСрочном(String пользователь) {
        smsСервис.отправить("Срочное действие требуется!", пользователь);
    }
    
    public void уведомитьВсемиСпособами(String пользователь) {
        emailСервис.отправить("Важно!", пользователь);
        smsСервис.отправить("Важно!", пользователь);
    }
}
```

---

## Итог

| Ситуация | Решение |
|---------|---------|
| Один бин типа | Просто `@Autowired` |
| Несколько бинов, есть "главный" | `@Primary` на главном |
| Несколько бинов, нужен конкретный | `@Qualifier("имя")` |
| Нужны все бины | `List<Тип>` или `Map<String, Тип>` |

**@Qualifier = "возьми именно этот бин"**