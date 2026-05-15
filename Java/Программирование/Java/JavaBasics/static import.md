**Static import** — это механизм Java, позволяющий импортировать **статические члены** (поля и методы) класса и использовать их без указания имени класса.

---

## Синтаксис

java

Copy

```java
// Обычный импорт класса
import java.lang.Math;

// Статический импорт всех статических членов
import static java.lang.Math.*;

// Статический импорт конкретного члена
import static java.lang.Math.PI;
import static java.lang.Math.pow;
import static java.lang.System.out;
```

---

## Примеры использования

### Без static import (многословно)

java

Copy

```java
public class Circle {
    public double area(double radius) {
        return Math.PI * Math.pow(radius, 2);
    }
    
    public void printResult(double result) {
        System.out.println("Result: " + result);
    }
}
```

### С static import (лаконично)

java

Copy

```java
import static java.lang.Math.PI;
import static java.lang.Math.pow;
import static java.lang.System.out;

public class Circle {
    public double area(double radius) {
        return PI * pow(radius, 2);  // Без Math. и System.
    }
    
    public void printResult(double result) {
        out.println("Result: " + result);  // Без System.
    }
}
```