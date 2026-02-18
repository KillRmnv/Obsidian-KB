
## 1. Single Responsibility Principle (SRP) — нарушение

**Нарушение:** Класс отвечает за слишком много.

// ПЛОХО: класс отвечает за логику, сохранение и отправку писем
class User {
    private String name;
    private String email;
    
    public void register() {
        // бизнес-логика регистрации
        validateEmail();
        saveToDatabase();  // ответственность 1
        sendWelcomeEmail();  // ответственность 2
        logActivity();  // ответственность 3
    }
    
    private void validateEmail() { }
    
    private void saveToDatabase() {
        // SQL запрос
    }
    
    private void sendWelcomeEmail() {
        // SMTP логика
    }
    
    private void logActivity() {
        // логирование в файл
    }
}


**Проблема:** Если нужно изменить способ отправки почты, нужно менять класс User. Если нужно изменить БД, снова User. Класс становится нестабильным.

**Правильно:**

// ХОРОШО: каждый класс отвечает за одно
class User {
    private String name;
    private String email;
    
    public void register() {
        validateEmail();
    }
    
    private void validateEmail() { }
}

class UserRepository {
    public void save(User user) {
        // только логика работы с БД
    }
}

class EmailService {
    public void sendWelcomeEmail(User user) {
        // только логика отправки email
    }
}

class ActivityLogger {
    public void log(String action) {
        // только логирование
    }
}


---

## 2. Open/Closed Principle (OCP) — нарушение

**Нарушение:** Нужно менять существующий код при добавлении нового функционала.

// ПЛОХО: нужно менять класс при каждом новом типе скидки
class DiscountCalculator {
    public double calculate(Order order) {
        if (order.getCustomerType().equals("REGULAR")) {
            return order.getTotal() * 0.05;  // 5% скидка
        } else if (order.getCustomerType().equals("VIP")) {
            return order.getTotal() * 0.15;  // 15% скидка
        } else if (order.getCustomerType().equals("GOLD")) {
            return order.getTotal() * 0.25;  // 25% скидка
        }
        // завтра добавится PLATINUM, и нужно менять метод
        return 0;
    }
}


**Проблема:** Каждый новый тип требует изменения класса. Открыто для модификации, закрыто для расширения.

**Правильно:**

// ХОРОШО: открыто для расширения, закрыто для модификации
interface DiscountStrategy {
    double calculate(Order order);
}

class RegularCustomerDiscount implements DiscountStrategy {
    @Override
    public double calculate(Order order) {
        return order.getTotal() * 0.05;
    }
}

class VIPCustomerDiscount implements DiscountStrategy {
    @Override
    public double calculate(Order order) {
        return order.getTotal() * 0.15;
    }
}

// Добавить новый тип скидки? Просто новый класс:
class GoldCustomerDiscount implements DiscountStrategy {
    @Override
    public double calculate(Order order) {
        return order.getTotal() * 0.25;
    }
}

class DiscountCalculator {
    private DiscountStrategy strategy;
    
    public DiscountCalculator(DiscountStrategy strategy) {
        this.strategy = strategy;
    }
    
    public double calculate(Order order) {
        return strategy.calculate(order);  // Одна строка, не меняется
    }
}


---

## 3. Liskov Substitution Principle (LSP) — нарушение

**Нарушение:** Подкласс нарушает контракт суперкласса.

// ПЛОХО: подкласс меняет поведение суперкласса несовместимо
class Bird {
    public void fly() {
        System.out.println("Bird is flying");
    }
}

class Sparrow extends Bird {
    @Override
    public void fly() {
        System.out.println("Sparrow flies fast");
    }
}

class Penguin extends Bird {
    @Override
    public void fly() {
        throw new UnsupportedOperationException("Penguins cannot fly!");
    }
}

// Клиентский код:
public void makeBirdFly(Bird bird) {
    bird.fly();  // Работает для всех? Нет! Для Penguin будет exception
}


**Проблема:** Penguin нарушает контракт Bird. Клиент ожидает, что все Bird могут летать.

**Правильно:**

// ХОРОШО: правильная иерархия
interface Bird { }

interface FlyingBird extends Bird {
    void fly();
}

interface SwimmingBird extends Bird {
    void swim();
}

class Sparrow implements FlyingBird {
    @Override
    public void fly() {
        System.out.println("Sparrow flies fast");
    }
}

class Penguin implements SwimmingBird {
    @Override
    public void swim() {
        System.out.println("Penguin swims well");
    }
}

// Теперь контракт чёткий
public void makeBirdFly(FlyingBird bird) {
    bird.fly();  // Гарантия: это будет работать
}


---

## 4. Interface Segregation Principle (ISP) — нарушение

**Нарушение:** Класс вынужден реализовывать методы, которые ему не нужны.

// ПЛОХО: жирный интерфейс с множеством методов
interface Worker {
    void work();
    void eat();
    void sleep();
    void manage();
    void code();
}

class Developer implements Worker {
    @Override
    public void work() { /* кодирование */ }
    
    @Override
    public void code() { /* специфика разработчика */ }
    
    @Override
    public void eat() { /* есть */ }
    
    @Override
    public void sleep() { /* спать */ }
    
    @Override
    public void manage() {
        throw new UnsupportedOperationException("Developer doesn't manage!");
    }
}

class Manager implements Worker {
    @Override
    public void work() { /* менеджмент */ }
    
    @Override
    public void manage() { /* управление */ }
    
    @Override
    public void code() {
        throw new UnsupportedOperationException("Manager doesn't code!");
    }
    
    @Override
    public void eat() { }
    
    @Override
    public void sleep() { }
}


**Проблема:** Интерфейс слишком жирный. Developer не должен реализовывать manage(). Manager не должен реализовывать code().

**Правильно:**

// ХОРОШО: тонкие, специализированные интерфейсы
interface Workable {
    void work();
}

interface Eatable {
    void eat();
}

interface Sleepable {
    void sleep();
}

interface Codable {
    void code();
}

interface Manageable {
    void manage();
}

class Developer implements Workable, Eatable, Sleepable, Codable {
    @Override
    public void work() { }
    
    @Override
    public void code() { }
    
    @Override
    public void eat() { }
    
    @Override
    public void sleep() { }
}

class Manager implements Workable, Eatable, Sleepable, Manageable {
    @Override
    public void work() { }
    
    @Override
    public void manage() { }
    
    @Override
    public void eat() { }
    
    @Override
    public void sleep() { }
}

---

## 5. Dependency Inversion Principle (DIP) — нарушение

**Нарушение:** Высокоуровневые модули зависят от низкоуровневых деталей реализации.

// ПЛОХО: высокоуровневый класс зависит от конкретной реализации
class MySQLDatabase {
    public void save(String data) {
        System.out.println("Saving to MySQL: " + data);
    }
}

class UserService {
    private MySQLDatabase database = new MySQLDatabase();  // ЖЁСТКАЯ ЗАВИСИМОСТЬ
    
    public void registerUser(String name) {
        // логика регистрации
        database.save(name);
    }
}

// Завтра нужна PostgreSQL вместо MySQL? Переписываем UserService


**Проблема:** UserService жёстко привязан к MySQLDatabase. Тесты невозможны. Смена БД требует переписания.

**Правильно:**

// ХОРОШО: зависимость от абстракции
interface Database {
    void save(String data);
}

class MySQLDatabase implements Database {
    @Override
    public void save(String data) {
        System.out.println("Saving to MySQL: " + data);
    }
}

class PostgreSQLDatabase implements Database {
    @Override
    public void save(String data) {
        System.out.println("Saving to PostgreSQL: " + data);
    }
}

class UserService {
    private Database database;  // ЗАВИСИМОСТЬ ОТ АБСТРАКЦИИ
    
    public UserService(Database database) {  // Инъекция зависимости
        this.database = database;
    }
    
    public void registerUser(String name) {
        database.save(name);
    }
}

// Использование:
Database mysql = new MySQLDatabase();
UserService service1 = new UserService(mysql);  // работает

Database postgres = new PostgreSQLDatabase();
UserService service2 = new UserService(postgres);  // работает

// Для тестирования:
class MockDatabase implements Database {
    @Override
    public void save(String data) {
        // тестовая реализация
    }
}
UserService testService = new UserService(new MockDatabase());


---

## Вывод

Нарушения SOLID приводят к:

- **Сложности тестирования** (нельзя подменить зависимости)
    
- **Высокой связанности** (изменение в одном месте ломает другое)
    
- **Сложности расширения** (нужно менять старый код)
    
- **Дублированию кода** (невозможно переиспользовать)
    

SOLID — это не просто "правила хорошего тона", это инструменты управления сложностью системы.

1. [https://ppl-ai-file-upload.s3.amazonaws.com/web/direct-files/attachments/154751835/c2af870f-eb94-463c-8d90-b25f5cff4457/3-2_analysis.pdf](https://ppl-ai-file-upload.s3.amazonaws.com/web/direct-files/attachments/154751835/c2af870f-eb94-463c-8d90-b25f5cff4457/3-2_analysis.pdf)