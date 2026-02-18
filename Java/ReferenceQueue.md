

```java
import java.lang.ref.*;

public class AdvancedCleanup {
    private static final ReferenceQueue<Object> queue = new ReferenceQueue<>();
    private static final Map<PhantomReference<?>, Resource> resources = new ConcurrentHashMap<>();
    
    public static void track(Object obj, Resource resource) {
        PhantomReference<?> ref = new PhantomReference<>(obj, queue);
        resources.put(ref, resource);
    }
    
    // Фоновый поток очистки
    static {
        Thread cleaner = new Thread(() -> {
            while (true) {
                try {
                    PhantomReference<?> ref = (PhantomReference<?>) queue.remove();
                    Resource res = resources.remove(ref);
                    if (res != null) res.cleanup();
                    ref.clear();
                } catch (InterruptedException e) { break; }
            }
        });
        cleaner.setDaemon(true);
        cleaner.start();
    }
}
```

---