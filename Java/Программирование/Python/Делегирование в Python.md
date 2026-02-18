Чтобы избежать дублирования кода некоторые задачи дочернего класса можно делегировать базовому классу при помощи функции [[Функция super|super]].

Например, инициализацию объекта:
```python
class Human:
	def __init__(self, name, age):
		self.name = name
		self.age = age

class Man(Human):
	def __init__(self, name, age):
		super().__init__(name, age)
		self.sex = 'M'
```