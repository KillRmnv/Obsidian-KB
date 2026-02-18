![[Pasted image 20260114185547.png]]
**УСТАРЕВШИЙ ВАРИАНТ**
![[Pasted image 20260114215248.png]]
**Анонимный класс**
![[Pasted image 20260114215329.png]]
## Создание и запуск потоков

### 1. **`start()`** - запуск потока
```java
Thread thread = new Thread(() -> {
    System.out.println("Поток выполняется");
});
thread.start(); // Запускает новый поток
// НЕ thread.run() - это выполнит код в текущем потоке!
```

### 2. **`run()`** - точка входа потока
```java
// 1. Через наследование
class MyThread extends Thread {
    @Override
    public void run() {
        System.out.println("Мой поток");
    }
}

// 2. Через Runnable (предпочтительнее)
Thread thread = new Thread(() -> {
    System.out.println("Выполняю задачу");
});
```

---

## Управление выполнением

### 3. **`sleep(long millis)`** - приостановка потока
```java
try {
    Thread.sleep(1000); // Пауза 1 секунда
    Thread.sleep(1000, 500000); // 1.5 секунды (миллисекунды + наносекунды)
} catch (InterruptedException e) {
    Thread.currentThread().interrupt(); // Восстанавливаем флаг
}
```

### 4. **`yield()`** - уступить процессорное время
```java
Thread.yield(); // "Может быть, стоит выполнить другой поток"
// Совет планировщику, не гарантия!
```

### 5. **`join()`** - ожидание завершения потока
```java
Thread worker = new Thread(() -> {
    try {
        Thread.sleep(2000);
        System.out.println("Работа завершена");
    } catch (InterruptedException e) {
        Thread.currentThread().interrupt();
    }
});

worker.start();
System.out.println("Ждем завершения worker...");
worker.join(); // Блокирует текущий поток до завершения worker
System.out.println("Можно продолжать");

// С таймаутом
worker.join(1000); // Ждем максимум 1 секунду
```

---

## Информация о потоке

### 6. **`currentThread()`** - текущий поток
```java
Thread current = Thread.currentThread();
System.out.println("Имя потока: " + current.getName());
System.out.println("ID: " + current.getId());
System.out.println("Приоритет: " + current.getPriority());
System.out.println("Состояние: " + current.getState());
```

### 7. **`getName()` / `setName()`** - имя потока
```java
Thread thread = new Thread(() -> {
    System.out.println("Я поток: " + Thread.currentThread().getName());
});
thread.setName("МойРабочийПоток");
thread.start();
```

### 8. **`getId()`** - уникальный ID
```java
long id = thread.getId(); // Уникальный, не переиспользуется
```

### 9. **`getState()`** - состояние потока
```java
Thread.State state = thread.getState();
// Возможные состояния:
// NEW, RUNNABLE, BLOCKED, WAITING, TIMED_WAITING, TERMINATED
```

### 10. **`isAlive()`** - проверка активности
```java
if (thread.isAlive()) {
    System.out.println("Поток еще работает");
} else {
    System.out.println("Поток завершен");
}
```

---

## Приоритеты

### 11. **`getPriority()` / `setPriority()`**
```java
thread.setPriority(Thread.MAX_PRIORITY);    // 10
thread.setPriority(Thread.NORM_PRIORITY);   // 5 (по умолчанию)
thread.setPriority(Thread.MIN_PRIORITY);    // 1

// Только совет планировщику, не гарантия!
```

---

## Daemon потоки

### 12. **`isDaemon()` / `setDaemon()`** - фоновые потоки
```java
Thread daemonThread = new Thread(() -> {
    while (true) {
        System.out.println("Daemon работает...");
        try {
            Thread.sleep(1000);
        } catch (InterruptedException e) {
            break;
        }
    }
});

daemonThread.setDaemon(true); // Должен быть установлен ДО start()
daemonThread.start();

// Daemon потоки автоматически завершаются, когда все обычные потоки завершены
```

---

## Прерывание потоков

### 13. **`interrupt()`** - прервать поток
```java
Thread thread = new Thread(() -> {
    while (!Thread.currentThread().isInterrupted()) {
        try {
            Thread.sleep(1000);
            System.out.println("Работаю...");
        } catch (InterruptedException e) {
            System.out.println("Поток прерван во время сна");
            Thread.currentThread().interrupt(); // Восстанавливаем флаг
            break;
        }
    }
    System.out.println("Поток завершает работу");
});

thread.start();
Thread.sleep(3000);
thread.interrupt(); // Отправляем запрос на прерывание
```

### 14. **`isInterrupted()`** - проверка флага прерывания
```java
// Проверяет флаг, НЕ сбрасывает его
if (thread.isInterrupted()) {
    System.out.println("Поток был прерван");
}
```

### 15. **`interrupted()`** - статический метод
```java
// Проверяет и СБРАСЫВАЕТ флаг прерывания текущего потока
if (Thread.interrupted()) {
    // Флаг был установлен, но теперь сброшен
    throw new InterruptedException();
}
```

---

## Группы потоков

### 16. **`getThreadGroup()`** - группа потока
```java
ThreadGroup group = thread.getThreadGroup();
System.out.println("Группа: " + group.getName());
```

### 17. **Работа с группой**
```java
ThreadGroup workerGroup = new ThreadGroup("Workers");

Thread worker1 = new Thread(workerGroup, () -> {
    System.out.println("Я в группе: " + 
        Thread.currentThread().getThreadGroup().getName());
});

Thread worker2 = new Thread(workerGroup, () -> {
    System.out.println("Я тоже в группе Workers");
});

worker1.start();
worker2.start();

// Можно прервать все потоки в группе
workerGroup.interrupt();
```

---

## Stack trace и дампы

### 18. **`getStackTrace()`** - трассировка стека
```java
StackTraceElement[] stackTrace = Thread.currentThread().getStackTrace();
for (StackTraceElement element : stackTrace) {
    System.out.println(element.getClassName() + "." + 
                       element.getMethodName() + ":" + 
                       element.getLineNumber());
}
```

### 19. **`getAllStackTraces()`** - все потоки
```java
Map<Thread, StackTraceElement[]> allTraces = Thread.getAllStackTraces();
allTraces.forEach((thread, stack) -> {
    System.out.println("Поток: " + thread.getName());
    System.out.println("Состояние: " + thread.getState());
    System.out.println("Стек: " + stack.length + " элементов");
});
```

### 20. **`dumpStack()`** - дамп стека в stderr
```java
Thread.dumpStack(); // Выводит стек текущего потока в System.err
```

---

## Ожидание и уведомление (wait/notify)

### 21. **`wait()`, `notify()`, `notifyAll()`**
```java
class SharedResource {
    private boolean ready = false;
    
    public synchronized void waitForReady() throws InterruptedException {
        while (!ready) {
            wait(); // Освобождает монитор и ждет
        }
    }
    
    public synchronized void makeReady() {
        ready = true;
        notifyAll(); // Будит все ожидающие потоки
        // или notify() - будит один случайный поток
    }
}
```

---

## Не рекомендуемые методы (Deprecated)

### 22. **`stop()`** - опасная остановка
```java
// НИКОГДА НЕ ИСПОЛЬЗУЙТЕ!
thread.stop(); // Может оставить объекты в некорректном состоянии
```

### 23. **`suspend()` / `resume()`** - приостановка/возобновление
```java
// ТОЖЕ НЕ ИСПОЛЬЗУЙТЕ!
thread.suspend(); // Может привести к deadlock
thread.resume();
```

### 24. **`destroy()`** - уничтожение
```java
// Не реализован, бросает исключение
// thread.destroy(); // UnsupportedOperationException
```

---

## Практические примеры

### Пример 1: Graceful shutdown
```java
class Worker extends Thread {
    private volatile boolean running = true;
    
    @Override
    public void run() {
        while (running && !isInterrupted()) {
            try {
                // Полезная работа
                System.out.println("Работаю...");
                Thread.sleep(500);
            } catch (InterruptedException e) {
                System.out.println("Получен запрос на прерывание");
                Thread.currentThread().interrupt();
            }
        }
        System.out.println("Аккуратно завершаюсь");
    }
    
    public void shutdown() {
        running = false;
        interrupt(); // На случай если поток спит
    }
}

Worker worker = new Worker();
worker.start();
Thread.sleep(2000);
worker.shutdown();
worker.join();
```

### Пример 2: Обработка нескольких задач
```java
class TaskProcessor {
    public void processConcurrently(List<Runnable> tasks) {
        List<Thread> threads = new ArrayList<>();
        
        for (Runnable task : tasks) {
            Thread thread = new Thread(task);
            thread.setUncaughtExceptionHandler((t, e) -> {
                System.err.println("Исключение в потоке " + t.getName() + ": " + e);
            });
            threads.add(thread);
            thread.start();
        }
        
        // Ждем завершения всех потоков
        for (Thread thread : threads) {
            try {
                thread.join();
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                // Прерываем все оставшиеся потоки
                threads.forEach(Thread::interrupt);
                break;
            }
        }
    }
}
```

### Пример 3: ThreadLocal для потокобезопасности
```java
class TransactionManager {
    private static final ThreadLocal<Connection> connectionHolder = 
        ThreadLocal.withInitial(() -> createConnection());
    
    public static Connection getConnection() {
        return connectionHolder.get();
    }
    
    public static void closeConnection() {
        Connection conn = connectionHolder.get();
        if (conn != null) {
            try {
                conn.close();
            } catch (SQLException e) {
                // Логирование
            }
        }
        connectionHolder.remove(); // Важно для очистки!
    }
}
```

---

## Методы для отладки и мониторинга

### 25. **`holdsLock(Object obj)`** - проверка блокировки
```java
Object lock = new Object();

Thread thread = new Thread(() -> {
    synchronized (lock) {
        System.out.println("Держу блокировку? " + 
            Thread.holdsLock(lock)); // true
    }
    System.out.println("Держу блокировку? " + 
        Thread.holdsLock(lock)); // false
});
```

### 26. **`getContextClassLoader()` / `setContextClassLoader()`**
```java
// Для загрузки классов в контексте потока
ClassLoader customLoader = new CustomClassLoader();
Thread.currentThread().setContextClassLoader(customLoader);
ClassLoader current = Thread.currentThread().getContextClassLoader();
```

### 27. **`getUncaughtExceptionHandler()` / `setUncaughtExceptionHandler()`**
```java
thread.setUncaughtExceptionHandler((t, e) -> {
    System.err.println("Непойманное исключение в потоке " + t.getName());
    e.printStackTrace();
});

// Глобальный обработчик
Thread.setDefaultUncaughtExceptionHandler((t, e) -> {
    System.err.println("Глобальный обработчик для " + t.getName());
});
```

---

## Современные альтернативы (с Java 5+)

### Вместо Thread API лучше использовать:
```java
// 1. ExecutorService вместо ручного управления потоками
ExecutorService executor = Executors.newFixedThreadPool(10);
Future<?> future = executor.submit(() -> {
    // Задача
});
executor.shutdown();

// 2. CompletableFuture для асинхронных операций
CompletableFuture.supplyAsync(() -> "Результат")
    .thenApply(String::toUpperCase)
    .thenAccept(System.out::println);

// 3. ForkJoinPool для divide-and-conquer задач
ForkJoinPool pool = new ForkJoinPool();
pool.invoke(new RecursiveTask<>() {
    protected Integer compute() {
        // Реализация
        return null;
    }
});
```

---

## Best Practices

### 1. **Всегда используйте `Thread.currentThread().interrupt()`**
```java
try {
    Thread.sleep(1000);
} catch (InterruptedException e) {
    // Восстанавливаем флаг
    Thread.currentThread().interrupt();
    // Решаем: завершать поток или продолжить
    return;
}
```

### 2. **Предпочитайте `Runnable` наследованию от `Thread`**
```java
// ЛУЧШЕ (разделение ответственности):
Thread thread = new Thread(() -> {
    // логика
});

// ХУЖЕ (наследование не для повторного использования):
class MyThread extends Thread {
    public void run() { /* логика */ }
}
```

### 3. **Именуйте потоки для отладки**
```java
Thread worker = new Thread(() -> {...}, "Database-Worker-1");
```

### 4. **Используйте daemon для фоновых задач**
```java
Thread cleanup = new Thread(() -> {
    while (true) {
        cleanupResources();
        Thread.sleep(60000);
    }
});
cleanup.setDaemon(true); // Не блокирует завершение JVM
```

### 5. **Избегайте `synchronized` методов, используйте блоки**
```java
// ПЛОХО:
public synchronized void method() { ... }

// ЛУЧШЕ:
private final Object lock = new Object();
public void method() {
    synchronized(lock) {
        // только критическая секция
    }
}
```

---

## Ключевые выводы

1. **`start()`** запускает поток, **`run()`** определяет логику
2. **`sleep()`**, **`yield()`**, **`join()`** для управления выполнением
3. **`interrupt()`** для кооперативной отмены задач
4. **`wait()`/`notify()`** для межпоточного взаимодействия
5. **Избегайте deprecated методов** (`stop()`, `suspend()`, `resume()`)
6. **Используйте ExecutorService** для современных многопоточных приложений
7. **Всегда обрабатывайте `InterruptedException`** правильно

Thread API — это фундамент, но в современных приложениях чаще используют высокоуровневые API (`ExecutorService`, `ForkJoinPool`, `CompletableFuture`).