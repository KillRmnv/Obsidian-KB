![[Pasted image 20260114191520.png]]


Отлично! Это ключевые понятия многопоточности в Java. Разберем каждое подробно.

## 1. Race Condition (Состояние гонки)

### Что это?
**Race Condition** возникает, когда поведение программы зависит от относительного порядка выполнения потоков, который непредсказуем.

### Простой пример
```java
class Counter {
    private int count = 0;
    
    public void increment() {
        count++; // НЕ атомарная операция!
    }
    
    public int getCount() {
        return count;
    }
}

// Проблема: два потока одновременно вызывают increment()
// Ожидаем: 2000, но получаем меньше (например, 1873)
```

### Почему происходит?
Операция `count++` состоит из трех шагов:
1. Чтение значения из памяти
2. Увеличение значения
3. Запись обратно

```java
// Что может произойти:
// Поток 1: читает count=0
// Поток 2: читает count=0 (еще не записано!)
// Поток 1: увеличивает до 1, записывает 1
// Поток 2: увеличивает до 1, записывает 1 ← ПОТЕРЯ УВЕЛИЧЕНИЯ!
```

### Пример с коллекциями
```java
List<Integer> list = new ArrayList<>();

// Два потока одновременно добавляют элементы
Thread t1 = new Thread(() -> {
    for (int i = 0; i < 1000; i++) {
        list.add(i);
    }
});

Thread t2 = new Thread(() -> {
    for (int i = 0; i < 1000; i++) {
        list.add(i);
    }
});

t1.start();
t2.start();
t1.join();
t2.join();

// Ожидаем 2000 элементов, но может быть:
// - меньше элементов
// - ArrayIndexOutOfBoundsException
// - некорректные данные
```

### Проверка на Race Condition
```java
class RaceConditionDemo {
    private int shared = 0;
    private final int ITERATIONS = 10000;
    
    public void demonstrate() throws InterruptedException {
        Thread t1 = new Thread(() -> {
            for (int i = 0; i < ITERATIONS; i++) {
                shared++;
            }
        });
        
        Thread t2 = new Thread(() -> {
            for (int i = 0; i < ITERATIONS; i++) {
                shared++;
            }
        });
        
        t1.start();
        t2.start();
        t1.join();
        t2.join();
        
        System.out.println("Ожидаем: " + (2 * ITERATIONS));
        System.out.println("Получили: " + shared);
        System.out.println("Потеряно: " + (2 * ITERATIONS - shared));
    }
}
// Запустите несколько раз - результаты будут разными!
```

---



## Memory Model гарантии

### Happens-before отношения:
```java
// 1. Синхронизация
synchronized (lock) {
    // Все записи здесь видны следующему потоку, захватившему этот lock
}

// 2. volatile
volatile int x;
x = 42; // Запись happens-before чтением этого volatile

// 3. start() и join()
Thread t = new Thread(...);
t.start(); // Код в конструкторе happens-before коду в потоке t
t.join();  // Код в потоке t happens-before коду после join()

// 4. final поля
// Инициализация final поля happens-before любым доступом к объекту
```

## Практические тесты

### Тест на race condition
```java
class RaceConditionTest {
    private int counter = 0;
    private final Object lock = new Object();
    
    void unsafeIncrement() {
        counter++;
    }
    
    void safeIncrement() {
        synchronized (lock) {
            counter++;
        }
    }
    
    void test() throws InterruptedException {
        int threadCount = 100;
        int iterations = 1000;
        
        // Небезопасный тест
        counter = 0;
        List<Thread> unsafeThreads = new ArrayList<>();
        for (int i = 0; i < threadCount; i++) {
            Thread t = new Thread(() -> {
                for (int j = 0; j < iterations; j++) {
                    unsafeIncrement();
                }
            });
            unsafeThreads.add(t);
            t.start();
        }
        
        for (Thread t : unsafeThreads) t.join();
        System.out.println("Небезопасно: " + counter + 
                          " (ожидаем: " + (threadCount * iterations) + ")");
        
        // Безопасный тест  
        counter = 0;
        List<Thread> safeThreads = new ArrayList<>();
        for (int i = 0; i < threadCount; i++) {
            Thread t = new Thread(() -> {
                for (int j = 0; j < iterations; j++) {
                    safeIncrement();
                }
            });
            safeThreads.add(t);
            t.start();
        }
        
        for (Thread t : safeThreads) t.join();
        System.out.println("Безопасно: " + counter + 
                          " (ожидаем: " + (threadCount * iterations) + ")");
    }
}
```

### Тест на reordering
```java
class ReorderingTest {
    int a = 0, b = 0;
    int x = 0, y = 0;
    
    void test() throws InterruptedException {
        int iterations = 100000;
        int reorderCount = 0;
        
        for (int i = 0; i < iterations; i++) {
            a = b = x = y = 0;
            
            Thread t1 = new Thread(() -> {
                // Компилятор/процессор может переставить эти операции
                a = 1;
                x = b;
            });
            
            Thread t2 = new Thread(() -> {
                b = 1;
                y = a;
            });
            
            t1.start();
            t2.start();
            t1.join();
            t2.join();
            
            // Если бы не было reordering, это невозможно
            if (x == 0 && y == 0) {
                reorderCount++;
            }
        }
        
        System.out.println("Reordering detected: " + reorderCount + 
                          " out of " + iterations);
    }
}
```


