Класс `Object` — корневой класс в Java. Все классы неявно наследуются от него. Вот все его методы (всего **11 методов** в Java 17+):

## Методы класса Object

### 1. `toString()`

java

Copy

```java
public String toString()
```

Возвращает строковое представление объекта. По умолчанию: `класс@хешкод`.

java

Copy

```java
@Override
public String toString() {
    return "Person{name='" + name + "', age=" + age + "}";
}
```

---

### 2. `equals(Object obj)`

java

Copy

```java
public boolean equals(Object obj)
```

Сравнение объектов по содержимому. По умолчанию — сравнение ссылок (`==`).

java

Copy

```java
@Override
public boolean equals(Object o) {
    if (this == o) return true;
    if (o == null || getClass() != o.getClass()) return false;
    Person person = (Person) o;
    return age == person.age && Objects.equals(name, person.name);
}
```

**Контракт:** рефлексивность, симметричность, транзитивность, консистентность, non-null.

---

### 3. `hashCode()`

java

Copy

```java
public native int hashCode()
```

Возвращает хеш-код объекта. **Обязательно переопределять вместе с `equals()`**.

java

Copy

```java
@Override
public int hashCode() {
    return Objects.hash(name, age);
}
```

---

### 4. `getClass()`

java

Copy

```java
public final native Class<?> getClass()
```

Возвращает объект `Class` во время выполнения. Нельзя переопределить.

java

Copy

```java
Class<?> clazz = obj.getClass();
System.out.println(clazz.getSimpleName()); // "String"
```

---

### 5. `clone()`

java

Copy

```java
protected native Object clone() throws CloneNotSupportedException
```

Создаёт поверхную копию объекта. Требует implements `Cloneable`.

java

Copy

```java
@Override
protected Object clone() throws CloneNotSupportedException {
    return super.clone();
}
```

**Проблемы:** нарушает инкапсуляцию, лучше использовать **конструктор копирования** или **сериализацию**.

---

### 6. `finalize()` — **УСТАРЕВШИЙ (deprecated с Java 9, удалён в Java 18)**

java

Copy

```java
@Deprecated(since="9")
protected void finalize() throws Throwable
```

Вызывался перед удалением объекта сборщиком мусора. Ненадёжный, непредсказуемый.

**Замена:** `Cleaner`, `PhantomReference`, `try-with-resources`.

---

### 7. `wait()` — перегружен

java

Copy

```java
public final void wait() throws InterruptedException
public final void wait(long timeout) throws InterruptedException
public final void wait(long timeout, int nanos) throws InterruptedException
```

Заставляет текущий поток ждать, пока другой поток не вызовет `notify()`/`notifyAll()`.

java

Copy

```java
synchronized (lock) {
    while (!condition) {
        lock.wait(); // Освобождает монитор и ждёт
    }
}
```

---

### 8. `notify()`

java

Copy

```java
public final native void notify()
```

Пробуждает **один** случайный поток, ожидающий на этом мониторе.

---

### 9. `notifyAll()`

java

Copy

```java
public final native void notifyAll()
```

Пробуждает **все** потоки, ожидающие на этом мониторе.

java

Copy

```java
synchronized (lock) {
    condition = true;
    lock.notifyAll(); // Все ждущие потоки просыпаются
}
```

---

### 10. `wait(long timeout, int nanos)` — точная версия

Дополнительная наносекундная точность к `wait(long)`.
