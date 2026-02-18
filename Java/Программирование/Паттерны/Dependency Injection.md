Dependency Injection (DI) is a design pattern where objects receive their dependencies from external sources rather than creating them themselves. This means a class doesn't have to worry about how to obtain the objects it needs to function; instead, those objects are "injected" into the class, usually through its constructor, setter methods, or interface. This promotes loose coupling and makes code more testable and maintainable.
### Why do we need to inject dependencies through some external agent?
When you inject dependencies through an external agent, your code becomes less tightly coupled to the specific implementations of those dependencies.
- We can easily swap out different implementations of the same dependency without having to modify your main code. This makes your code more modular and easier to maintain.
- Ultimately, the best way to decide whether or not to use dependency injection is to consider the specific needs of your application.
- If you are writing code that is likely to change or that needs to be easily tested and reused, then dependency injection can be a valuable tool.
  
  ![[Pasted image 20251002200656.png]]
![[Pasted image 20251002200816.png]]
****Code Implementation for the above Problem:****

We will make use of the Spring's ****@Autowired**** annotation that will enable the instance variables of our classes to be initialized through the Spring framework at run time of our application, without the need for us to manually hard code it.
```java
import org.springframework.context.annotation.Bean;

import org.springframework.context.annotation.Configuration;

​

@Configuration

public class BeanConfig

{

    @Bean

    public Engine getEngineBean()

    {

        /** Changing the old engine to the new engine dependency

              Engine engine = new LegacyEngine();

         **/

        Engine engine = new NewEngine();

        return engine;

    }

​

}
```


  
In the above code snippet:

- ****@Configuration**** annotation denotes the BeanConfig class as the Spring's Configuration class. This is the class into which we will configure and define all the beans that will be used by our application.
- ****@Bean**** annotation marks the result returned by the getEngineBean() method to be initialized for the instance variable Engine interface used by our application code.
- Inside the ****getEngineBean()**** method, we replace the Engine object that was previously initialized to the ****LegacyEngine()**** object changing it to the ****NewEngine()**** object.  
    
```java
import org.springframework.beans.factory.annotation.Autowired;

​

public class Car 

{

     /** Using the @Autowired annotation to intialize the 

         instance variable Engine from Spring's 

         Configuration Class

     **/

     @Autowired

     public Engine engine;

}
```

![[Pasted image 20260116002947.png]]

![[Pasted image 20260116002958.png]]