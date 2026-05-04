allows to manage Threads
```java
import java.util.concurrent.ExecutorService;  
import java.util.concurrent.Executors;  
  
public class ExecutorExample {  
public static void main(String[] args) {  
ExecutorService executor = Executors.newFixedThreadPool(3); // Create a thread pool with 3 threads  
  
for (int i = 0; i < 5; i++) {  
executor.submit(new Task());  
}  
  
executor.shutdown(); // Shut down the executor  
}  
}  
  
class Task implements Runnable {  
public void run() {  
System.out.println("Executing task: " + Thread.currentThread().getName());  
}  
}
```