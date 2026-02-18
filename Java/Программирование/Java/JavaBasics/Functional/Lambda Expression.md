```java
@FunctionalInterface
interface Functional {
    int operation(int a, int b);
}

public class Test {

    public static void main(String[] args) {
        
        // Using lambda expressions to define the operations
        Functional add = (a, b) -> a + b;
        Functional multiply = (a, b) -> a * b;

        // Using the operations
        System.out.println(add.operation(6, 3));  
        System.out.println(multiply.operation(4, 5));  
    }
}
```


![[Pasted image 20260113133152.png]]

![[Pasted image 20260113133417.png]]
![[Pasted image 20260113133558.png]]
![[Pasted image 20260113133856.png]]
![[Pasted image 20260113134046.png]]
![[Pasted image 20260113134154.png]]
![[Pasted image 20260113134317.png]]
![[Pasted image 20260113134443.png]]
![[Pasted image 20260113134921.png]]
![[Pasted image 20260113140302.png]]