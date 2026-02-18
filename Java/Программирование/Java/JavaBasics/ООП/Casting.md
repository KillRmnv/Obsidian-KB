[[Программирование/Java/JavaBasics/Fundamentals/Java]]
## Виды casting'а

### 1. Приведение примитивов

java

Copy

```java
// Неявное (widening) — безопасно
int i = 100;
long l = i;        // int → long
double d = l;      // long → double

// Явное (narrowing) — возможна потеря данных
double d = 123.456;
int i = (int) d;   // 123 (дробная часть отбрасывается!)
byte b = (byte) 1000; // -24 (переполнение!)
```

### 2. Приведение ссылочных типов (Casting объектов)

java

Copy

```java
// Upcasting (вверх по иерархии) — неявно, безопасно
Dog dog = new Dog();
Animal animal = dog;  // Неявный upcast

// Downcasting (вниз по иерархии) — явно, опасно!
Animal animal = new Dog();
Dog dog = (Dog) animal;  // Явный downcast

// ❌ Опасно:
Animal animal = new Cat();
Dog dog = (Dog) animal;  // ClassCastException!
```

---

## ClassCastException: когда возникает

Исключение `ClassCastException` бросается при попытке привести объект к несовместимому типу во время выполнения.

### Сценарии возникновения

#### 1. Неправильный downcasting

java

Copy

```java
public class Animal { }
public class Dog extends Animal { }
public class Cat extends Animal { }

Animal animal = new Cat();  // Создали кошку
Dog dog = (Dog) animal;     // ❌ ClassCastException! Это не собака!
```

#### 2. Приведение несовместимых классов

java

Copy

```java
String text = "Hello";
Integer num = (Integer) text;  // ❌ ClassCastException! Нет связи наследования
```

#### 3. Raw types и generics

java

Copy

```java
List rawList = new ArrayList();
rawList.add("string");
rawList.add(123);

for (Object obj : rawList) {
    String s = (String) obj;  // ❌ ClassCastException на второй итерации!
}
```

#### 4. Массивы

java

Copy

```java
Object[] objects = new String[10];
objects[0] = "text";
objects[1] = 123;  // ❌ ArrayStoreException (родственная проблема)

Object obj = objects;
Integer[] ints = (Integer[]) obj;  // ❌ ClassCastException!
```

#### 5. Проблемы с generics (type erasure)

java

Copy

```java
List<Integer> intList = new ArrayList<>();
intList.add(42);

// Type erasure: в runtime List<Integer> = List
Object obj = intList;
List<String> strList = (List<String>) obj;  // ⚠️ Предупреждение, но компилируется

for (String s : strList) {  // ❌ ClassCastException! Integer не String
    System.out.println(s);
}
```

---

## Безопасное приведение: instanceof

java

Copy

```java
public void process(Animal animal) {
    // Проверка перед casting'ом
    if (animal instanceof Dog) {
        Dog dog = (Dog) animal;  // ✅ Безопасно
        dog.bark();
    } else if (animal instanceof Cat) {
        Cat cat = (Cat) animal;  // ✅ Безопасно
        cat.meow();
    }
}
```

### Pattern matching (Java 16+)

java

Copy

```java
// Упрощённый синтаксис
public void process(Animal animal) {
    if (animal instanceof Dog dog) {  // Проверка + casting в одном выражении
        dog.bark();  // dog уже типа Dog, видна в этом блоке
    }
    
    // Java 17+ в switch
    switch (animal) {
        case Dog d -> d.bark();
        case Cat c -> c.meow();
        default -> throw new IllegalArgumentException();
    }
}
```

---