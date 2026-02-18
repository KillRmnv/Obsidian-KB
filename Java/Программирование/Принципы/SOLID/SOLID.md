Набор пяти принципов объектно-ориентированного проектирования, направленных на создание **гибких, расширяемых и легко сопровождаемых систем**.

Каждый принцип определяет правило, как строить классы и модули, чтобы минимизировать зависимость между ними и повысить качество кода.
***
## Принципы

![[SRP]]
***
![[OCP]]
***
![[LSP]]
***
![[ISP]]
***
![[DIP]]

## Примеры несоблюдения принципов SOLID

### SRP

```python
class Report:
    def __init__(self, data):
        self.data = data

    def calculate(self):
        return sum(self.data)

    def save_to_file(self, filename):
        with open(filename, 'w') as f:
            f.write(str(self.data))

# Один класс делает две вещи одновременно - вычисляет данные
# и сохраняет их, что усложняет сопровождение.

# Стоило разделить обязанности на два класса - один для расчёта отчёта,
# другой для его сохранения.
```
***
### OCP

```python
class Shape:
    def __init__(self, type):
        self.type = type

class AreaCalculator:
    def area(self, shape):
        if shape.type == 'circle':
            return 3.14 * shape.radius ** 2
        elif shape.type == 'rectangle':
            return shape.width * shape.height

# При добавлении новой фигуры нужно менять код AreaCalculator.

# Стоило использовать наследование и полиморфизм — каждому классу фигуры
# реализовать свой метод area, AreaCalculator вызывать метод объекта.
```
***
### LSP

```python
class Bird:
    def fly(self):
        print("Flying")

class Penguin(Bird):
    def fly(self):
        raise Exception("Penguins can't fly!")

# Подкласс не может заменить базовый класс без ошибок.

# Надо было разделить иерархию птиц на летающих и нелетающих,
# либо добавить абстрактный метод move и реализовать его по-разному.
```
***
### ISP

```python
class Worker:
    def work(self):
        pass

    def eat(self):
        pass

class Robot(Worker):
    def work(self):
        print("Working")

    def eat(self):
        raise Exception("Robots don't eat")

# Класс Robot вынужден реализовывать метод, который не нужен.

# Необходимо разделить интерфейсы на Workable и Eatable,
# чтобы Robot зависел только от нужного интерфейса.
```
***
### DIP

```python
class MySQLDatabase:
    def connect(self):
        print("Connecting to MySQL")

class UserService:
    def __init__(self):
        self.db = MySQLDatabase()  # прямое создание зависимости

# Проблема: UserService зависит от конкретной реализации базы данных.

# Стоило зависимость вводить через абстракцию (интерфейс Database)
# и передавать объект базы извне (через конструктор или метод),
# чтобы можно было менять реализацию.
```

##
![[Over-SOLID]]