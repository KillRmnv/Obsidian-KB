![[Pasted image 20260114205034.png]]
sufficientFunds.await()--разблокирует bankLock
signalAll() говорит остальным тредам на await() проснуться.При выходе из awit() захватывается bankLock.lock()(выстраивается очередь)
![[Pasted image 20260114205523.png]]
![[Pasted image 20260114205653.png]]

гыг, await() может проснуться в любой момент, поэтому цикл while обязателен

Вот классический, но **максимально показательный пример**: ограниченный буфер задач (Producer-Consumer). Он наглядно демонстрирует, как работают `while`, `await()` и `signal()`, и почему `Condition` эффективнее старых `wait()/notify()`.

###  Код: `BoundedTaskQueue`
```java
import java.util.LinkedList;
import java.util.Queue;
import java.util.concurrent.locks.Condition;
import java.util.concurrent.locks.Lock;
import java.util.concurrent.locks.ReentrantLock;

public class BoundedTaskQueue {
    private final Lock lock = new ReentrantLock();
    // Две отдельные очереди ожидания на ОДИН lock
    private final Condition notFull = lock.newCondition();   // Ждут производители
    private final Condition notEmpty = lock.newCondition();  // Ждут потребители
    private final Queue<String> queue = new LinkedList<>();
    private final int capacity;

    public BoundedTaskQueue(int capacity) {
        this.capacity = capacity;
    }

    public void put(String task) throws InterruptedException {
        lock.lock();
        try {
            while (queue.size() == capacity) {
                notFull.await(); // 1. Отпускаем lock и засыпаем
            }
            queue.add(task);
            // 2. Будим РОВНО ОДНОГО ждущего потребителя
            notEmpty.signal(); 
        } finally {
            lock.unlock(); // 3. Освобождаем lock (разбуженный поток подхватит его)
        }
    }

    public String take() throws InterruptedException {
        lock.lock();
        try {
            while (queue.isEmpty()) {
                notEmpty.await(); // Ждём появления задачи
            }
            String task = queue.poll();
            notFull.signal(); // Будим РОВНО ОДНОГО ждущего производителя
            return task;
        } finally {
            lock.unlock();
        }
    }
}
```

---

###  Пошаговый разбор: "что да как"

#### Сценарий: Очередь заполнена, приходит `put()`, затем `take()`
1. `Thread-Producer` вызывает `put("A")`. Queue полна (`size == capacity`).
2. Заходит в `while (queue.size() == capacity)` → условие `true`.
3. Вызывает `notFull.await()`:
   -  **Атомарно отпускает `lock`** (другие потоки могут войти).
   -  Поток переходит в состояние `WAITING` и помещается в очередь `notFull`.
4. `Thread-Consumer` вызывает `take()`:
   - Захватывает `lock` (он свободен).
   - `queue` не пуст → `while` ложно → пропускается.
   - Забирает элемент через `queue.poll()`.
   - Вызывает `notFull.signal()` → **будит один поток** из очереди `notFull` (нашего `Producer`).
5. `Producer` просыпается, но **не продолжает сразу**. Он встаёт в очередь на захват `lock`.
6. `Consumer` доходит до `finally { lock.unlock(); }` → освобождает монитор.
7. `Producer` захватывает `lock`, **снова проверяет условие в `while`** → теперь `size < capacity` → выходит из цикла.
8. Кладёт задачу, будит следующего потребителя, отпускает lock.

---

###  Почему именно `while`, а не `if`?
Замените мысленно `while` на `if` и представьте многопоточный сценарий:
```java
if (queue.isEmpty()) { //  ПЛОХО
    notEmpty.await();
}
String task = queue.poll(); //  NPE или NoSuchElementException!
```
**Что сломается:**
1. **Ложные пробуждения** (spurious wakeup): JVM может разбудить поток без `signal()`. `if` пропустит проверку → `poll()` на пустой очереди.
2. **Гонка между потребителями**: Двое ждут в `notEmpty.await()`. Приходит `signal()`, будит одного. Он забирает lock, выходит из `if`, забирает элемент. Второй тоже просыпается (например, от `signalAll()` или ложно), проходит `if` (он не проверяет состояние повторно!), пытается забрать элемент → падает.
3. `while` гарантирует: **поток выйдет из цикла только тогда, когда условие объективно выполнено в текущий момент**, а не когда-то в прошлом.

---

###  В чём выигрыш `Condition` перед `wait()/notify()`?
| Ситуация | `wait()/notify()` | `Condition.await()/signal()` |
|----------|-------------------|------------------------------|
| Все потоки (P и C) ждут на `this` | `notify()` будит **случайный** поток. Может разбудить производителя, когда очередь пуста → он проверит `while`, не пройдёт и снова уснёт. Лишнее переключение контекста. | `notEmpty.signal()` будит **только** тех, кто ждал именно на `notEmpty`. Точное попадание. |
| Нужно разбудить всех | `notifyAll()` → "thundering herd". Все 10 потоков просыпаются, 9 проверяют `while` и снова засыпают. CPU впустую. | `signalAll()` на нужном Condition, или разные Conditions для разных групп. Контролируемый wake-up. |
| Таймауты / прерываемость | Только `wait(timeout)`. Нельзя прервать ожидание без выхода из `synchronized`. | `await(2, TimeUnit.SECONDS)`, `awaitUninterruptibly()`, `awaitNanos()`. |

**Простыми словами:** `Condition` заменяет одну общую "комнату ожидания" (`Object.wait()`) на несколько отдельных, с табличками на дверях. `signal()` стучит в конкретную дверь, а не будит всех подряд.

---

###  Как это используется в Java SDK?
Именно так реализованы под капотом:
- `ArrayBlockingQueue`, `LinkedBlockingQueue`
- `ReentrantLock` (его `await()/signal()` внутри используют `Condition`)
- `ThreadPoolExecutor` (очередь задач)
- `java.util.concurrent` примитивы

В 95% новых задач **не нужно писать это вручную**. Используйте готовые:
```java
BlockingQueue<String> queue = new ArrayBlockingQueue<>(10);
// put() и take() уже содержат всю логику while/await/signal внутри
queue.put("task");
String task = queue.take();
```

Но понимание этого паттерна критично, когда:
- Пишете низкоуровневый фреймворк / пул ресурсов
- Нужна нестандартная логика пробуждения (например, приоритетные очереди, read-write locks с starvation prevention)
- Отлаживаете deadlock/livelock в legacy коде

Если нужно, могу показать, как превратить этот пример в **приоритетную очередь** с тремя `Condition` (`highPriority`, `normalPriority`, `notFull`) и объяснить, почему `notify()` там вообще не справится.