[[Программирование/Java/JavaBasics/Fundamentals/Java]]
```

ublic String toString()
{
return getClass().getName()
+ "[name=" + name
+ ",salary=" + salary
+ ",hireDay=" + hireDay
+ "]";
}
public class Manager extends Employee
{
. . .
public String toString()
{
return super.toString()
+ "[bonus=" + bonus
+ "]";
}
}
```


```
var p = new Point(10, 20);
String message = "The current position is " + p;
// automatically invokes p.toString()
```