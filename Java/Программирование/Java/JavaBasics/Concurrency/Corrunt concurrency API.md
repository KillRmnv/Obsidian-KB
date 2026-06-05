Ниже приведён структурированный перечень методов современного API многопоточности (`java.util.concurrent`, `java.util.concurrent.locks`, `java.util.concurrent.atomic`, `java.lang.invoke`, `java.lang.ThreadLocal`). Описания даны строго по спецификации Java SE: сигнатура, назначение, точное поведение, гарантии видимости/атомарности.

---

### 🔒 `java.util.concurrent.locks.Lock`
| Метод | Поведение |
|-------|-----------|
| `void lock()` | Блокирует вызывающий поток до получения блокировки. Не прерывается. |
| `void lockInterruptibly() throws InterruptedException` | Захватывает блокировку. Если поток прерван во время ожидания, бросает `InterruptedException` и выходит, не захватывая lock. |
| `boolean tryLock()` | Немедленно пытается захватить блокировку. Возвращает `true` при успехе, `false` без блокировки. |
| `boolean tryLock(long time, TimeUnit unit) throws InterruptedException` | Ждёт захвата не дольше указанного времени. Возвращает `true`/`false`. Прерывание приводит к `InterruptedException`. |
| `void unlock()` | Освобождает блокировку. Должен вызываться только потоком-владельцем. |
| `Condition newCondition()` | Создаёт экземпляр `Condition`, привязанный к данной блокировке. |

---

### ⏱ `java.util.concurrent.locks.Condition`
| Метод | Поведение |
|-------|-----------|
| `void await() throws InterruptedException` | Атомарно освобождает lock, переводит поток в состояние ожидания до `signal()`/прерывания/ложного пробуждения. Перед возвратом повторно захватывает lock. |
| `void awaitUninterruptibly()` | Аналог `await()`, но игнорирует прерывания потока. |
| `long awaitNanos(long nanosTimeout) throws InterruptedException` | Ждёт до пробуждения или истечения таймаута (нс). Возвращает оставшиеся наносекунды. Отрицательное значение = таймаут истёк. |
| `boolean await(long time, TimeUnit unit) throws InterruptedException` | Ждёт с указанной точностью. Возвращает `true`, если условие выполнено, `false` при таймауте. |
| `boolean awaitUntil(Date deadline) throws InterruptedException` | Ждёт до абсолютного времени `deadline`. Возвращает `true`/`false`. |
| `void signal()` | Переводит один ожидающий на этом `Condition` поток в состояние блокировки (ожидание захвата lock). |
| `void signalAll()` | Переводит все ожидающие потоки в состояние блокировки. |

---

### 🏭 `java.util.concurrent.Executor` / `ExecutorService`
| Метод | Поведение |
|-------|-----------|
| `void execute(Runnable command)` | Передаёт задачу на асинхронное выполнение. Не возвращает результат. |
| `Future<T> submit(Callable<T> task)` | Подает задачу, возвращает `Future<T>` для получения результата/ожидания завершения. |
| `Future<T> submit(Runnable task, T result)` | Подает `Runnable`, `Future` вернёт переданный `result` после завершения. |
| `List<Future<T>> invokeAll(Collection<? extends Callable<T>> tasks) throws InterruptedException` | Выполняет все задачи, блокируется до завершения каждой. Возвращает список `Future` в порядке передачи. |
| `T invokeAny(Collection<? extends Callable<T>> tasks) throws InterruptedException, ExecutionException` | Блокируется до завершения первой задачи без исключения. Возвращает её результат. Остальные отменяются. |
| `void shutdown()` | Инициирует корректное завершение: новые задачи не принимаются, уже поданные выполняются. |
| `List<Runnable> shutdownNow()` | Пытается остановить все выполняющиеся задачи, возвращает список неподанных. |
| `boolean awaitTermination(long timeout, TimeUnit unit) throws InterruptedException` | Блокирует вызывающий поток до завершения всех задач или истечения таймаута после `shutdown()`. |
| `boolean isShutdown()` / `isTerminated()` / `isShutdown()` | Проверка состояния жизненного цикла пула. |

---

### 🧮 `java.util.concurrent.atomic.*` (ключевые методы)
| Метод | Поведение |
|-------|-----------|
| `T get()` | Читает текущее значение с семантикой `volatile`. |
| `void set(T newValue)` | Записывает значение с семантикой `volatile`. |
| `boolean compareAndSet(T expect, T update)` | Атомарно обновляет значение, если текущее равно `expect`. Возвращает `true`/`false`. Использует CAS-инструкции процессора. |
| `T getAndUpdate(UnaryOperator<T> updateFunction)` | Атомарно читает старое значение и применяет функцию. Возвращает старое. |
| `T updateAndGet(UnaryOperator<T> updateFunction)` | Аналогично, возвращает новое значение. |
| `T getAndSet(T newValue)` | Атомарно устанавливает новое, возвращает старое. |
| `T accumulateAndGet(T x, BinaryOperator<T> accumulatorFunction)` / `getAndAccumulate(...)` | Атомарно применяет аккумулятор к текущему и переданному значению. |
| `int incrementAndGet()`, `getAndIncrement()`, `decrementAndGet()`, `getAndDecrement()` | Атомарная арифметика `+1`/`-1`. Возвращают новое или старое значение. |
| `boolean weakCompareAndSet(...)` | CAS с ослабленными гарантиями порядка памяти. Может возвращать `false` даже при совпадении значений (зависит от платформы). |

---

### 📦 `java.util.concurrent.BlockingQueue`
| Метод | Поведение |
|-------|-----------|
| `boolean add(E e)` | Вставляет элемент. Бросает `IllegalStateException` при ограниченной ёмкости. |
| `boolean offer(E e)` | Вставляет элемент. Возвращает `false`, если очередь полна. Не блокирует. |
| `void put(E e) throws InterruptedException` | Вставляет элемент. Блокирует вызывающий поток до появления свободного места или прерывания. |
| `boolean offer(E e, long timeout, TimeUnit unit) throws InterruptedException` | Ждёт вставки до таймаута. Возвращает `true`/`false`. |
| `E take() throws InterruptedException` | Извлекает и удаляет головной элемент. Блокирует до появления элемента или прерывания. |
| `E poll()` | Извлекает головной элемент. Возвращает `null`, если очередь пуста. Не блокирует. |
| `E poll(long timeout, TimeUnit unit) throws InterruptedException` | Ждёт извлечения до таймаута. Возвращает `null` при истечении. |
| `int drainTo(Collection<? super E> c)` | Переносит все доступные элементы в указанную коллекцию. |
| `int drainTo(Collection<? super E> c, int maxElements)` | Переносит не более `maxElements`. |
| `int remainingCapacity()` | Возвращает идеальное оставшееся место (для ограниченных очередей). |

---

### 🚦 Синхронизаторы (`java.util.concurrent`)
#### `CountDownLatch`
| Метод | Поведение |
|-------|-----------|
| `void await() throws InterruptedException` | Блокирует до обнуления счётчика или прерывания. |
| `boolean await(long timeout, TimeUnit unit) throws InterruptedException` | Ждёт до таймаута. Возвращает `true` при обнулении, `false` при таймауте. |
| `void countDown()` | Уменьшает счётчик на 1. При достижении 0 пробуждает все ожидающие потоки. |
| `long getCount()` | Возвращает текущее значение счётчика. |

#### `Semaphore`
| Метод | Поведение |
|-------|-----------|
| `void acquire() throws InterruptedException` | Запрашивает один permit. Блокирует при отсутствии свободных. |
| `void acquire(int permits) throws InterruptedException` | Запрашивает указанное количество. |
| `void acquireUninterruptibly()` / `acquireUninterruptibly(int)` | Аналогично, но игнорирует прерывания. |
| `boolean tryAcquire()` / `tryAcquire(long timeout, TimeUnit unit)` / `tryAcquire(int permits, ...)` | Неблокирующий или с таймаутом запрос permits. Возвращает `true`/`false`. |
| `void release()` / `release(int permits)` | Возвращает permits в семафор. Пробуждает ожидающие потоки. |
| `int availablePermits()` | Возвращает количество доступных permits. |
| `int drainPermits()` | Забирает все доступные permits, возвращает их количество. |

#### `CyclicBarrier`
| Метод | Поведение |
|-------|-----------|
| `int await() throws InterruptedException, BrokenBarrierException` | Блокирует вызывающий поток до достижения заданного числа участников. |
| `int await(long timeout, TimeUnit unit) throws ...` | Ждёт с таймаутом. При истечении переводит барьер в состояние `broken`. |
| `void reset()` | Сбрасывает барьер. Ожидающие потоки получают `BrokenBarrierException`. |
| `boolean isBroken()` | Проверяет, был ли барьер сломан. |
| `int getNumberWaiting()` / `int getParties()` | Возвращает число ожидающих и требуемое число участников. |

#### `Phaser`
| Метод | Поведение |
|-------|-----------|
| `int register()` / `int bulkRegister(int parties)` | Регистрирует новые партии. Возвращает номер текущей фазы. |
| `int arrive()` | Уведомляет о прибытии, не ожидает других. Возвращает номер фазы. |
| `int arriveAndAwaitAdvance()` | Уведомляет и блокирует до завершения фазы всеми участниками. |
| `int arriveAndDeregister()` | Уведомляет и отменяет регистрацию. |
| `int awaitAdvance(int phase)` / `awaitAdvanceInterruptibly(int)` | Блокирует до перехода к указанной фазе. |
| `int getPhase()` / `getRegisteredParties()` / `getArrivedParties()` | Статистика текущей фазы. |
| `void forceTerminate()` / `boolean isTerminated()` | Принудительно завершает фазер. Все ожидающие потоки разблокируются. |

---

### ⚡ `java.util.concurrent.CompletableFuture`
| Метод | Поведение |
|-------|-----------|
| `boolean complete(T value)` | Завершает future значением, если ещё не завершён. |
| `boolean completeExceptionally(Throwable ex)` | Завершает future исключением. |
| `<U> CompletableFuture<U> thenApply(Function<? super T,? extends U> fn)` | Применяет функцию к результату после завершения. |
| `CompletableFuture<Void> thenAccept(Consumer<? super T> action)` | Выполняет побочный эффект с результатом. |
| `CompletableFuture<Void> thenRun(Runnable action)` | Выполняет действие, игнорируя результат. |
| `<U,V> CompletableFuture<V> thenCombine(CompletionStage<? extends U> other, BiFunction<? super T,? super U,? extends V> fn)` | Комбинирует результаты двух future. |
| `<U> CompletableFuture<Void> thenAcceptBoth(CompletionStage<? extends U> other, BiConsumer<? super T,? super U> action)` | Выполняет действие с результатами двух future. |
| `CompletableFuture<Void> runAfterBoth(CompletionStage<?> other, Runnable action)` | Выполняет action после завершения обоих. |
| `<U> CompletableFuture<T> applyToEither(CompletionStage<? extends T> other, Function<? super T, ? extends T> fn)` | Применяет функцию к результату первого завершившегося. |
| `CompletableFuture<T> exceptionally(Function<Throwable, ? extends T> fn)` | Выполняет fallback при исключении. |
| `<U> CompletableFuture<U> handle(BiFunction<? super T, Throwable, ? extends U> fn)` | Единый обработчик результата или исключения. |
| `CompletableFuture<T> whenComplete(BiConsumer<? super T, ? super Throwable> action)` | Выполняет действие при завершении, не меняет результат/исключение. |
| `T join()` | Блокирует до завершения, возвращает результат. При исключении бросает `CompletionException`. |
| `T get() throws InterruptedException, ExecutionException` | Стандартное блокирующее ожидание с checked exceptions. |
| `boolean cancel(boolean mayInterruptIfRunning)` | Пытается отменить вычисление. |
| `static CompletableFuture<Void> allOf(CompletableFuture<?>... cfs)` | Возвращает future, завершающийся после завершения всех переданных. |
| `static CompletableFuture<Object> anyOf(CompletableFuture<?>... cfs)` | Возвращает future, завершающийся после завершения первого. |

---

### 🌊 `java.util.concurrent.ForkJoinPool` & `ForkJoinTask`
| Метод | Поведение |
|-------|-----------|
| `static ForkJoinPool commonPool()` | Возвращает общий пул для параллельных стримов. |
| `void execute(ForkJoinTask<?> task)` | Асинхронно передаёт задачу в пул. |
| `<T> T invoke(ForkJoinTask<T> task)` | Блокирует вызывающий поток до завершения задачи, возвращает результат. |
| `<T> ForkJoinTask<T> submit(...)` | Асинхронный запуск, возвращает `ForkJoinTask<T>`. |
| `ForkJoinTask<T> fork()` | Ставит задачу в очередь пула для асинхронного выполнения. |
| `T join()` | Ожидает завершения задачи, возвращает результат. Блокирует только если задача не завершена. |
| `T invoke()` | Выполняет задачу напрямую или через `fork()`, если это оптимально. |
| `boolean cancel(boolean mayInterruptIfRunning)` | Пытается отменить выполнение. |
| `boolean isDone()` / `isCompletedNormally()` / `isCompletedAbnormally()` / `isCancelled()` | Проверка состояния завершения. |

---

### 🧲 `java.lang.invoke.VarHandle` (управление памятью и атомарностью)
| Метод | Поведение |
|-------|-----------|
| `T get(Object... args)` | Читает значение с семантикой `volatile`. |
| `void set(Object... args, T newValue)` | Записывает значение с семантикой `volatile`. |
| `boolean compareAndSet(Object... args, T expectedValue, T newValue)` | Атомарная CAS-операция. Возвращает `true` при успехе. |
| `T compareAndExchange(Object... args, T expectedValue, T newValue)` | CAS, но всегда возвращает фактическое значение до операции. |
| `T getAndSet(Object... args, T newValue)` | Атомарно читает старое, записывает новое. |
| `T getAndAdd(Object... args, T delta)` / `getAndBitwiseOr/And/Xor` | Атомарные read-modify-write для числовых/битовых операций. |
| `void setRelease(Object... args, T newValue)` / `T getAcquire(Object... args)` | Явные режимы памяти: `release` (запись), `acquire` (чтение). |
| `boolean weakCompareAndSet(...)` / `weakCompareAndSetPlain(...)` | CAS с ослабленными гарантиями видимости/упорядочивания. |

---

### 🧵 `java.lang.ThreadLocal` / `InheritableThreadLocal`
| Метод | Поведение |
|-------|-----------|
| `T get()` | Возвращает значение, привязанное к текущему потоку. |
| `void set(T value)` | Устанавливает значение для текущего потока. |
| `void remove()` | Удаляет привязку, освобождая ссылку для GC. |
| `protected T initialValue()` | Вызывается при первом `get()` для инициализации значения по умолчанию. |
| `static <S> ThreadLocal<S> withInitial(Supplier<? extends S> supplier)` | Фабричный метод с ленивой инициализацией. |
| `protected T childValue(T parentValue)` | Переопределяется в `InheritableThreadLocal` для передачи значения дочерним потокам. |

---

### 📌 Примечание
API `java.util.concurrent` содержит сотни методов в дополнительных утилитах (`Executors`, `CompletionService`, `StampedLock`, `Flow`/`Reactive Streams`, `ScheduledExecutorService` и др.). Выше приведён полный перечень **базовых примитивов синхронизации, управления потоками, атомарных операций и асинхронных конструкций**, определённых в спецификации Java SE. Если требуется детализация по конкретному классу (например, `StampedLock`, `Flow.Publisher/Subscriber`, `CompletionService`, `ScheduledExecutorService`) — укажите, распишу его методы в том же формате.