

```java
import java.lang.ref.Cleaner;

public class NativeResource implements AutoCloseable {
    private static final Cleaner cleaner = Cleaner.create();
    
    private final ResourceState state;
    private final Cleaner.Cleanable cleanable;
    
    // Состояние НЕ должно ссылаться на сам объект!
    private static class ResourceState implements Runnable {
        private long nativePtr; // Нативный указатель
        
        ResourceState(long nativePtr) {
            this.nativePtr = nativePtr;
        }
        
        @Override
        public void run() {
            // Вызывается когда объект становится unreachable
            // ИЛИ при явном вызове clean()
            if (nativePtr != 0) {
                releaseNative(nativePtr);
                nativePtr = 0;
            }
        }
    }
    
    public NativeResource(long nativePtr) {
        this.state = new ResourceState(nativePtr);
        this.cleanable = cleaner.register(this, state);
    }
    
    @Override
    public void close() {
        cleanable.clean(); // Явная очистка
    }
    
    private static native void releaseNative(long ptr);
}
```

**Преимущества Cleaner:**

- Не блокирует GC
    
- Можно зарегистрировать несколько действий
    
- Явный вызов через `clean()`
    

---
