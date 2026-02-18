Cпециальный атрибут класса на [[Язык программирования Python|Python]], который содержит кортеж с порядком наследования для данного класса. Согласно этому порядку выполняется поиск атрибутов и методов у дочернего класса.
***
```python
class A:
    def method(self):
        print("Метод класса A")

class B(A):
    def method(self):
        print("Метод класса B")

class C(A):
    def method(self):
        print("Метод класса C")

class D(B, C):
    pass

# Смотрим MRO для класса D
print(D.__mro__)
# Вывод: (<class '__main__.D'>, <class '__main__.B'>, <class '__main__.C'>, <class '__main__.A'>, <class 'object'>)
```