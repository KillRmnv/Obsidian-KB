Аннотации в **Java** — это **специальные метки (метаданные)**, которые можно прикреплять к классам, методам, полям, параметрам и другим элементам кода.  
Они не влияют напрямую на работу программы, но используются компилятором, средой выполнения (JVM) или фреймворками (например, Spring, Hibernate) для управления поведением кода.

## Встроенные аннотации в Java

- `@Override` — метод переопределяет метод родителя.
    
- `@Deprecated` — помечает метод/класс устаревшим.
    
- `@SuppressWarnings("unchecked")` — подавляет предупреждения компилятора.
  
  ```java
  import java.lang.annotation.*;

@Retention(RetentionPolicy.RUNTIME) // доступна во время выполнения
@Target(ElementType.METHOD)         // можно вешать только на методы
public @interface MyAnnotation {
    String value();
    int version() default 1;
}

  ```
  
    
Аннотация [@Documented](http://docs.oracle.com/javase/7/docs/api/java/lang/annotation/Documented.html)указывает, что помеченная таким образом аннотация должна быть добавлена в javadoc поля/метода и т.д.


Аннотация [@Inherited](http://docs.oracle.com/javase/7/docs/api/java/lang/annotation/Inherited.html) помечает аннотацию, которая будет унаследована потомком класса, отмеченного такой аннотацией.  
Сделаем для примера пару аннотаций и пометим ими класс.  
  

```
@Inherited
@interface PublicAnnotate { }
 
@interface PrivateAnnotate { }
 
@PublicAnnotate
@PrivateAnnotate
class ParentClass { }
 
class ChildClass extends ParentClass { }
```

![[Pasted image 20260115161339.png]]

![[Pasted image 20260115161808.png]]
![[Pasted image 20260115161940.png]]
![[Pasted image 20260115162547.png]]