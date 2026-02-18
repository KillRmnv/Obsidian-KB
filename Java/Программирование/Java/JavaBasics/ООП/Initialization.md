```java
public class Test {
    
    static int staticVariable;
    int nonStaticVariable;        

    // Static initialization block:
    // Runs once (when the class is initialized)
    static {
        System.out.println("Static initalization.");
        staticVariable = 5;
    }
    
    // Instance initialization block:
    // Runs each time you instantiate an object
    {
        System.out.println("Instance initialization.");
        nonStaticVariable = 7;
    }
    
    public Test() {
        System.out.println("Constructor.");
    }
    
    public static void main(String[] args) {
        new Test();
        new Test();
    }
}
```

```java
Static initalization.
Instance initialization.
Constructor.
Instance initialization.
Constructor.
```

Order of execution:

1. static initialization blocks of super classes
    
2. static initialization blocks of the class
    
3. instance initialization blocks of super classes
    
4. **constructors of super classes**
    
5. instance initialization blocks of the class
    
6. constructor of the class.
    

A couple of additional points to keep in mind (point 1 is reiteration of @aioobe's answer):

1. The code in static initialization block will be executed at class load time (and yes, that means only once per class load), before any instances of the class are constructed and before any static methods are called.
    
2. The instance initialization block is actually copied by the Java compiler into every constructor the class has. So every time the code in instance initialization block is executed **exactly** before the code in constructor.