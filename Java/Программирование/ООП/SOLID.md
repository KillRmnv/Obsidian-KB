Принципы **SOLID** — это набор из пяти объектно-ориентированных правил проектирования, сформулированных Робертом Мартином (дядюшкой Бобом) в начале 2000-х. Они помогают создавать код, который легко расширять, тестировать, рефакторить и поддерживать.

Ниже подробный разбор каждого принципа с примерами нарушения, объяснением последствий и исправленным вариантом. Для наглядности используется Python, но концепции применимы к любому ООП-языку.

---
###  SRP: Single Responsibility Principle (Принцип единственной ответственности)
**Суть:** Класс должен иметь только одну причину для изменения. Иными словами, он должен решать ровно одну задачу или отвечать за одну область функциональности.

####  Нарушение
```python
class User:
    def __init__(self, name: str, email: str):
        self.name = name
        self.email = email

    def validate(self) -> bool:
        # логика валидации
        return "@" in self.email

    def save_to_db(self):
        # логика работы с БД
        print(f"Saving {self.name} to database...")

    def send_welcome_email(self):
        # логика отправки почты
        print(f"Sending email to {self.email}...")
```
**Почему это плохо:**
- Класс смешивает доменную модель, валидацию, доступ к данным и интеграцию с внешними сервисами.
- Изменение формата БД, переход на другой SMTP-сервер или ужесточение правил валидации потребуют правок в одном и том же файле.
- Сложно тестировать: для проверки валидации нужно мокать БД и почтовый клиент.

####  Исправление
```python
class User:
    def __init__(self, name: str, email: str):
        self.name = name
        self.email = email

class UserValidator:
    def is_valid(self, user: User) -> bool:
        return "@" in user.email

class UserRepository:
    def save(self, user: User):
        print(f"Saving {user.name} to database...")

class EmailService:
    def send_welcome(self, email: str):
        print(f"Sending email to {email}...")
```
**Результат:** Каждый класс имеет одну зону ответственности. Изменения изолированы, тесты пишутся независимо, код легче переиспользовать.

---
###  OCP: Open/Closed Principle (Принцип открытости/закрытости)
**Суть:** Программные сущности должны быть **открыты для расширения**, но **закрыты для модификации**. Новый функционал добавляется без изменения уже протестированного кода.

####  Нарушение
```python
class ShapeCalculator:
    def calculate_area(self, shape_type: str, **kwargs) -> float:
        if shape_type == "circle":
            return 3.1415 * kwargs["radius"] ** 2
        elif shape_type == "rectangle":
            return kwargs["width"] * kwargs["height"]
        elif shape_type == "triangle":
            return 0.5 * kwargs["base"] * kwargs["height"]
        # Добавление новой фигуры требует правки этого метода!
```
**Почему это плохо:**
- Каждая новая фигура ломает принцип: мы вынуждены лезть в уже работающий и оттестированный код.
- Риск регрессионных багов растёт экспоненциально.
- Нарушает инкапсуляцию логики фигур: всё свалено в один метод.

####  Исправление (полиморфизм)
```python
from abc import ABC, abstractmethod

class Shape(ABC):
    @abstractmethod
    def area(self) -> float: ...

class Circle(Shape):
    def __init__(self, radius: float): self.radius = radius
    def area(self) -> float: return 3.1415 * self.radius ** 2

class Rectangle(Shape):
    def __init__(self, width: float, height: float):
        self.width = width
        self.height = height
    def area(self) -> float: return self.width * self.height

class ShapeCalculator:
    def calculate_area(self, shape: Shape) -> float:
        return shape.area()  # Никаких if/else!
```
**Результат:** Чтобы добавить `Triangle`, вы просто создаёте новый класс. `ShapeCalculator` не меняется. Код открыт для расширения, закрыт для правок.

---
###  LSP: Liskov Substitution Principle (Принцип подстановки Лисков)
**Суть:** Объекты базового класса должны быть заменяемы объектами его наследников **без изменения корректности программы**. Наследник не должен нарушать контракт базового класса.

####  Нарушение (классический пример Square/Rectangle)
```python
class Rectangle:
    def set_width(self, w: float): self.width = w
    def set_height(self, h: float): self.height = h
    def area(self) -> float: return self.width * self.height

class Square(Rectangle):
    def set_width(self, s: float):
        self.width = s
        self.height = s  # нарушает ожидаемое поведение Rectangle!
    def set_height(self, s: float):
        self.width = s
        self.height = s
```
Проверка, которая работает для `Rectangle`, ломается для `Square`:
```python
def resize_and_test(rect: Rectangle):
    rect.set_width(5)
    rect.set_height(10)
    assert rect.area() == 50  #  AssertionError для Square!
```
**Почему это плохо:**
- Наследование используется ради повторного использования кода, а не из-за отношения `is-a` с сохранением поведения.
- Клиентский код не может полагаться на контракт базового класса → полиморфизм становится опасным.

####  Исправление
```python
from abc import ABC, abstractmethod

class Shape(ABC):
    @abstractmethod
    def area(self) -> float: ...

class Rectangle(Shape):
    def __init__(self, width: float, height: float):
        self.width = width
        self.height = height
    def area(self) -> float: return self.width * self.height

class Square(Shape):
    def __init__(self, side: float): self.side = side
    def area(self) -> float: return self.side ** 2
```
**Результат:** И `Rectangle`, и `Square` реализуют общий контракт `Shape`. Никто не ожидает, что у фигуры есть отдельные сеттеры ширины/высоты. Поведение предсказуемо, подстановка безопасна.

>  **Правило проверки:** Если вы переопределяете метод и меняете его предусловия, постусловия или побочные эффекты, скорее всего, LSP нарушен.

---
###  ISP: Interface Segregation Principle (Принцип разделения интерфейса)
**Суть:** Клиенты не должны зависеть от методов, которые они не используют. Лучше много специализированных интерфейсов, чем один универсальный.

####  Нарушение
```python
from abc import ABC, abstractmethod

class Worker(ABC):
    @abstractmethod
    def work(self): ...
    @abstractmethod
    def eat(self): ...
    @abstractmethod
    def sleep(self): ...

class HumanWorker(Worker):
    def work(self): print("Human works")
    def eat(self): print("Human eats")
    def sleep(self): print("Human sleeps")

class RobotWorker(Worker):
    def work(self): print("Robot works")
    def eat(self): raise NotImplementedError("Robots don't eat")   # 
    def sleep(self): raise NotImplementedError("Robots don't sleep") # 
```
**Почему это плохо:**
- `RobotWorker` вынужден реализовывать нерелевантные методы.
- Выброс исключений в контракте нарушает принцип наименьшего удивления.
- При добавлении нового метода в `Worker` придётся править все реализации, даже те, которым он не нужен.

####  Исправление
```python
class Workable(ABC):
    @abstractmethod
    def work(self): ...

class Eatable(ABC):
    @abstractmethod
    def eat(self): ...

class Sleepable(ABC):
    @abstractmethod
    def sleep(self): ...

class HumanWorker(Workable, Eatable, Sleepable):
    def work(self): print("Human works")
    def eat(self): print("Human eats")
    def sleep(self): print("Human sleeps")

class RobotWorker(Workable):
    def work(self): print("Robot works")
```
**Результат:** Каждый класс реализует только те интерфейсы, которые ему нужны. Контракты чистые, зависимости минимальны.

---
###  DIP: Dependency Inversion Principle (Принцип инверсии зависимостей)
**Суть:** 
1. Модули верхнего уровня не должны зависеть от модулей нижнего уровня. Оба должны зависеть от **абстракций**.
2. Абстракции не должны зависеть от деталей. Детали должны зависеть от абстракций.

####  Нарушение
```python
class MySQLDatabase:
    def query(self, sql: str): print(f"Executing: {sql}")

class UserService:
    def __init__(self):
        self.db = MySQLDatabase()  # прямая зависимость от реализации!

    def get_user(self, user_id: int):
        return self.db.query(f"SELECT * FROM users WHERE id={user_id}")
```
**Почему это плохо:**
- `UserService` жёстко привязан к `MySQLDatabase`. Заменить БД на PostgreSQL или Redis без правки сервиса невозможно.
- Тестирование требует реальной БД или сложных хаков.
- Нарушена инверсия: высокоуровневая бизнес-логика зависит от низкоуровневого драйвера.

####  Исправление (инъекция зависимостей через абстракцию)
```python
from abc import ABC, abstractmethod

class Database(ABC):
    @abstractmethod
    def query(self, sql: str): ...

class MySQLDatabase(Database):
    def query(self, sql: str): print(f"[MySQL] {sql}")

class PostgreSQLDatabase(Database):
    def query(self, sql: str): print(f"[PostgreSQL] {sql}")

class UserService:
    def __init__(self, db: Database):  # зависимость от абстракции
        self.db = db

    def get_user(self, user_id: int):
        return self.db.query(f"SELECT * FROM users WHERE id={user_id}")

# Использование
db = PostgreSQLDatabase()
service = UserService(db)
service.get_user(1)
```
**Результат:** `UserService` ничего не знает о конкретной БД. Абстракцию `Database` определяет высокоуровневый модуль. Детали (`MySQLDatabase`, `PostgreSQLDatabase`) зависят от неё. Код легко тестируется (можно подсунуть `FakeDatabase`), заменяется и расширяется.

---
##  Важные нюансы применения SOLID

| Принцип | Частая ошибка | Как избежать |
|--------|---------------|--------------|
| SRP | Дробить классы до абсурда (1 метод = 1 класс) | Следите за **семантической** ответственностью, а не за количеством методов |
| OCP | Писать "вечные" классы, которые нельзя править даже при багах | OCP касается **новой функциональности**, а не исправлений ошибок |
| LSP | Использовать наследование только ради reuse кода | Наследуйте только если дочерний класс **полностью** совместим по поведению |
| ISP | Создавать интерфейсы с 1 методом | Объединяйте методы, которые **логически меняются вместе** |
| DIP | Путать с DI (Dependency Injection) | DIP — это архитектурный принцип, DI — одна из техник его реализации |

###  Когда не стоит слепо следовать SOLID?
- В небольших скриптах, утилитах или прототипах избыточная абстракция замедляет разработку.
- В функциональном или событийно-ориентированном подходе некоторые принципы трансформируются или теряют актуальность.
- SOLID — это **набор рекомендаций**, а не догма. Баланс между чистотой архитектуры и time-to-market решает разработчик/архитектор.

---
##  Итог
SOLID помогает:
- Снизить связность (coupling) и повысить связность внутри модулей (cohesion)
- Делать код устойчивым к изменениям
- Упрощать юнит-тестирование и рефакторинг
- Готовить архитектуру к масштабированию и работе в команде

Если хотите, могу показать, как эти принципы применяются в конкретном фреймворке (Spring, ASP.NET, FastAPI, etc.) или разобрать реальный кейс рефакторинга legacy-кода с помощью SOLID.