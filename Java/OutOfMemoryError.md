 **OutOfMemoryError** — это ошибка в Java, возникающая когда виртуальная машина Java (JVM) не может выделить память для объекта в куче (heap), а сборщик мусора не может освободить достаточно места.

## Основные типы OutOfMemoryError

### 1. **Java heap space**
```java
// Самый распространённый случай
Exception in thread "main" java.lang.OutOfMemoryError: Java heap space
```
Происходит когда:
- Создаётся слишком много объектов
- Объекты слишком большие (например, загрузка огромного файла в память)
- Утечки памяти (не удаляются ссылки на ненужные объекты)

### 2. **GC overhead limit exceeded**
```java
java.lang.OutOfMemoryError: GC overhead limit exceeded
```
JVM тратит слишком много времени (98%) на сборку мусора, но освобождает мало памяти (менее 2%).

### 3. **PermGen space** (Java 7 и ранее) / **Metaspace** (Java 8+)
```java
// До Java 8
java.lang.OutOfMemoryError: PermGen space

// Java 8+
java.lang.OutOfMemoryError: Metaspace
```
Нехватка памяти для:
- Метаданных классов
- Строк в пуле (String pool)
- Загруженных классов (особенно при динамической генерации)

### 4. **Unable to create new native thread**
```java
java.lang.OutOfMemoryError: unable to create new native thread
```
Операционная система не может выделить ресурсы для нового потока.

### 5. **Direct buffer memory**
```java
java.lang.OutOfMemoryError: Direct buffer memory
```
Исчерпана память для NIO direct ByteBuffers (вне кучи JVM).

### 6. **Requested array size exceeds VM limit**
Попытка создать массив размером больше, чем позволяет JVM (обычно ~2^31-1 элементов).

## Примеры кода, вызывающие OOM

```java
// Пример 1: Бесконечное добавление в коллекцию
List<byte[]> list = new ArrayList<>();
while (true) {
    list.add(new byte[1024 * 1024]); // 1 МБ за итерацию
}

// Пример 2: Утечка памяти через статическую коллекцию
public class Cache {
    private static Map<String, Object> map = new HashMap<>();
    
    public void add(String key, Object value) {
        map.put(key, value); // Никогда не очищается!
    }
}

// Пример 3: Большие объекты
byte[] hugeArray = new byte[Integer.MAX_VALUE]; // Почти наверняка OOM
```

## Диагностика и решение

### 1. **Анализ дампа памяти (Heap Dump)**
```bash
# Генерация дампа при OOM
java -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/path/to/dump.hprof MyApp

# Анализ через VisualVM, Eclipse MAT, или jhat
```

### 2. **Мониторинг в реальном времени**
```bash
jvisualvm  # GUI мониторинг
jconsole   # Консольный мониторинг
```

### 3. **Увеличение памяти**
```bash
java -Xms512m -Xmx2g MyApp  # Начальная 512МБ, максимальная 2ГБ
java -XX:MaxMetaspaceSize=256m  # Для Java 8+ (вместо PermGen)
```

### 4. **Оптимизация кода**
```java
// Вместо загрузки всего файла в память
// Плохо:
byte[] data = Files.readAllBytes(Path.of("huge.zip"));

// Хорошо — потоковая обработка:
try (InputStream is = Files.newInputStream(Path.of("huge.zip"))) {
    // Обработка порциями
}

// Использование WeakReference для кэшей
Map<String, WeakReference<BigObject>> cache = new HashMap<>();
```

### 5. **Профилирование**
Используйте:
- **VisualVM** — бесплатно, в комплекте JDK
- **JProfiler** — коммерческий
- **YourKit** — коммерческий
- **Async-profiler** — лёгкий, для production

## Предотвращение

| Проблема | Решение |
|----------|---------|
| Утечки памяти | Анализировать ссылки, использовать weak/soft references |
| Большие коллекции | Пагинация, кэширование с eviction policy (Caffeine, Guava) |
| Много строк | Использовать StringBuilder, избегать конкатенации в циклах |
| Загрузка файлов | NIO, memory-mapped files, потоковая обработка |
| Многопоточность | Ограничивать размер пула потоков |

## Ключевое различие: Error vs Exception

```java
// OutOfMemoryError — это Error, а не Exception!
try {
    // код
} catch (Exception e) {
    // НЕ поймает OutOfMemoryError!
} catch (Error e) {
    // Поймает, но обычно не рекомендуется
} catch (Throwable t) {
    // Поймает всё, но антипаттерн
}
```

**Важно:** Ловить `OutOfMemoryError` обычно бессмысленно — приложение уже в критическом состоянии. Лучше настроить мониторинг и перезапуск при OOM.