 Best Practices

### 1. **Используйте готовые thread-safe классы**
```java
// Вместо ручной синхронизации
ConcurrentHashMap<String, Integer> map = new ConcurrentHashMap<>();
AtomicInteger counter = new AtomicInteger();
CopyOnWriteArrayList<String> list = new CopyOnWriteArrayList<>();
```

### 2. **Локальные переменные потокобезопасны**
```java
public void method() {
    int local = 42; // Безопасно - каждый поток имеет свою копию в стеке
    // ...
}
```

### 3. **Не публикуйте ссылки на mutable объекты**
```java
class MutableHolder {
    private List<String> list = new ArrayList<>();
    
    // ОПАСНО! Публикуем внутреннее состояние
    public List<String> getList() {
        return list; // Нарушение инкапсуляции
    }
    
    // БЕЗОПАСНО
    public List<String> getSafeList() {
        return Collections.unmodifiableList(list);
    }
    
    // ИЛИ возвращаем копию
    public List<String> getCopy() {
        return new ArrayList<>(list);
    }
}
```

### 4. **Используйте неизменяемые объекты**
```java
// Immutable классы потокобезопасны по своей природе
public final class ImmutablePoint {
    private final int x;
    private final int y;
    
    public ImmutablePoint(int x, int y) {
        this.x = x;
        this.y = y;
    }
    
    public int getX() { return x; }
    public int getY() { return y; }
    
    // Создаем новый объект вместо изменения
    public ImmutablePoint withX(int newX) {
        return new ImmutablePoint(newX, this.y);
    }
}
```

### 5. **Правильная синхронизация при доступе к shared mutable state**
```java
class ThreadSafeCounter {
    private long count = 0;
    
    // synchronized на уровне метода
    public synchronized void increment() {
        count++;
    }
    
    // synchronized блок с кастомным lock
    public void add(long value) {
        synchronized (this) {
            count += value;
        }
    }
    
    // Чтение тоже должно быть synchronized
    public synchronized long getCount() {
        return count;
    }
}
```
