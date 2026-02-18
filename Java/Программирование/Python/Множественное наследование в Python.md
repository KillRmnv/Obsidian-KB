При множественном наследовании дочерний объект получит атрибут всех его базовых классов.

**Важно:** Порядок указания базовых классов при наследовании имеет значение!

```python
class Doctor:
	def can_cure(self):
		print("Я доктор, я умею лечить")
		
class Builder:
	def can_build(self):
		print("Я строитель, я умею строить")
		
class Person(Doctor, Builder):
	pass
```
