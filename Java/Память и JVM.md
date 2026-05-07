По этому блоку на собесе спрашивают в основном три вещи: модель памяти (stack/heap + GC), контракт `equals/hashCode` и семантику строк. Ниже — концентрат теории и подводных камней.

---

## Stack vs Heap

- **Stack** — память для _кадров вызовов методов_ текущего потока: параметры методов, локальные переменные и ссылки на объекты, но не сами объекты.geeksforgeeks+1
    
- У каждого потока свой **отдельный стек**; данные стека не видны другим потокам (thread-confined). Это даёт простую модель и отсутствие гонок данных внутри одного стека.github+1
    
- Память стека управляется не GC, а механизмом вызова/возврата: метод завершился — его кадр автоматически убирается, локальные переменные уничтожаются.codingshuttle+1
    
- **Heap** — общая куча для _объектов_ и их полей: всё, что создаётся через `new`, а также строки, массивы и т.п.geeksforgeeks+1
    
- Heap общий для всех потоков, поэтому нужен Java Memory Model, `synchronized`, `volatile` и т.д. для видимости и атомарности.stackademic+1
    
- Управляется **Garbage Collector**: объект живёт, пока на него есть сильные ссылки; как только достижимость теряется, он становится кандидатом на сборку.stackademic+1
    

Подводные моменты:

- Примитивы как _поля объектов_ живут в куче, как часть объекта; в стеке лежат только локальные примитивы и ссылки.[geeksforgeeks](https://www.geeksforgeeks.org/java/java-stack-vs-heap-memory-allocation/)
    
- `StackOverflowError` — переполнение стека (глубокая рекурсия), `OutOfMemoryError: Java heap space` — переполнение кучи.github+1
    

---

## [[Garbage Collector]]: поколения и основные алгоритмы


Современный GC в Java — **поколенческий, stop-the-world, но часто частично параллельный/конкурентный**.opensource+1

## Поколения

Классическая схема (HotSpot):

- **Young Generation**:
    
    - Eden + два Survivor-спейса (S0/S1).
        
    - Большинство объектов умирают молодыми; минорные сборки (Minor GC) работают чаще и быстрее.[stackademic](https://blog.stackademic.com/the-ultimate-guide-to-java-memory-stack-heap-garbage-collection-8aef2c5cf446)
        
- **Old (Tenured) Generation**:
    
    - Долгоживущие объекты, пережившие несколько сборок young.
        
    - Major/Full GC — реже, но дороже.[stackademic](https://blog.stackademic.com/the-ultimate-guide-to-java-memory-stack-heap-garbage-collection-8aef2c5cf446)
        
- (Metaspace — отдельная область для метаданных классов с Java 8, не в куче.)
    

Основная идея: оптимизировать под то, что _“большинство объектов живут недолго”_.

## Классические алгоритмы (очень кратко)

- **Mark-Sweep**: пометить достижимые → удалить недостижимые; минус — фрагментация.[stackademic](https://blog.stackademic.com/the-ultimate-guide-to-java-memory-stack-heap-garbage-collection-8aef2c5cf446)
    
- **Mark-Compact**: пометить → сдвинуть живые объекты, уплотнив память (меньше фрагментации, но дороже).[stackademic](https://blog.stackademic.com/the-ultimate-guide-to-java-memory-stack-heap-garbage-collection-8aef2c5cf446)
    
- **Copying** (в young): копирование живых объектов из Eden+S0 в S1, потом роли спейсов меняются.[stackademic](https://blog.stackademic.com/the-ultimate-guide-to-java-memory-stack-heap-garbage-collection-8aef2c5cf446)
    

## Современные реализации (Java 8+ / 11+)

- **Parallel GC** (по умолчанию в старых версиях): ориентирован на throughput, stop-the-world, но фазы выполняются несколькими GC-потоками.[stackoverflow](https://stackoverflow.com/questions/54615916/when-to-choose-serialgc-parallelgc-over-cms-g1-in-java)
    
- **CMS** (Concurrent Mark-Sweep, deprecated): минимизация пауз, большинство работы делается параллельно с приложением, но возможна фрагментация.opensource+1
    
- **G1 (Garbage-First)** — дефолт в Java 9+:
    
    - Делит кучу на равные **region**’ы, а не жёстко на Eden/Old; каждый регион логически может быть Eden/Survivor/Old.slideshare+1
        
    - Делает глобальный mark, оценивает "наиболее мусорные" регионы и сперва чистит их (garbage-first), стараясь вписаться в целевой `maxGCPauseMillis`.stackoverflow+1
        
    - Параллельный, инкрементально-компактирующий, с низкими паузами.
        

Собес-формулировка:

> GC — это комбинация mark-sweep/mark-compact + поколенческий подход; G1 дополнительно делит кучу на регионы и сначала чистит самые мусорные, чтобы ограничить паузы.
![[image-19.png]]
---

## `equals` / `hashCode` контракт

## Контракт `equals` (из `Object`)

Метод `equals` обязан быть:

- **Рефлексивным**: `x.equals(x)` всегда `true`.
    
- **Симметричным**: `x.equals(y)` → `y.equals(x)`.
    
- **Транзитивным**: `x=y`, `y=z` → `x=z`.
    
- **Консистентным**: при неизменённом состоянии `x.equals(y)` всегда даёт один и тот же результат.
    
- И при `x != null` — `x.equals(null)` всегда `false`.[javarevisited.blogspot](https://javarevisited.blogspot.com/2013/08/10-equals-and-hashcode-interview.html)
    

## Контракт `hashCode` и связь с `equals`

Правила:linkedin+2

1. Если `x.equals(y) == true`, **обязательно** `x.hashCode() == y.hashCode()`.
    
2. Обратное не обязательно: одинаковый hashCode не гарантирует `equals == true` (коллизии возможны).
    
3. Если переопределяешь `equals()`, **обязан** переопределить `hashCode()`, иначе HashMap/HashSet начнут вести себя некорректно ("дубликаты" в Set, невозможность найти ключ в Map).
    

Подводные моменты:

- `hashCode` должен быть **консистентным**: пока объект "логически" не меняется, `hashCode` должен оставаться тем же.[javarevisited.blogspot](https://javarevisited.blogspot.com/2013/08/10-equals-and-hashcode-interview.html)
    
- Использование _изменяемых полей_ в `equals/hashCode` опасно, если объект используется как ключ в HashMap/элемент HashSet: изменение поля после вставки ломает структуру (элемент "пропадает").linkedin+1
    

---

## `==` vs `equals`

- `==` для **объектов** сравнивает **ссылки** (один и тот же объект в памяти?). Для примитивов — фактическое значение.[linkedin](https://www.linkedin.com/posts/satyamraikwar_java-javadeveloper-javaprogramming-activity-7365699208718278658-Fwnq)
    
- `equals()` по умолчанию (из `Object`) тоже сравнивает ссылки; классы вроде `String`, `Integer`, `BigDecimal`, коллекции переопределяют его для **логического равенства по содержимому**.[javarevisited.blogspot](https://javarevisited.blogspot.com/2013/08/10-equals-and-hashcode-interview.html)
    

Типичные вопросы/ловушки:

- `new Integer(128) == new Integer(128)` → `false` (разные объекты), но `equals()` → `true`.
    
- Для `String`:
    
    - Литеральные строки из пула (`"abc"`) при одинаковом содержимом часто дают `== true`, а строки, созданные через `new String("abc")`, — нет, хотя `equals` всё равно `true`.[linkedin](https://www.linkedin.com/pulse/interview-289-java-what-string-constant-pool-vhhjf)[youtube](https://www.youtube.com/watch?v=Ay4lG9bHkOw)
        
- **Collections** (`ArrayList`, `HashSet` и т.д.) реализуют `equals()` как сравнение элементов/пар, а не ссылок.[javarevisited.blogspot](https://javarevisited.blogspot.com/2013/08/10-equals-and-hashcode-interview.html)
    

---

## String pool (String Constant Pool)

## Что это

**String Constant Pool** (intern pool) — специальная область в heap, где JVM хранит **единственные экземпляры строковых литералов** и явно "интернированных" строк.[youtube](https://www.youtube.com/watch?v=Ay4lG9bHkOw)[linkedin](https://www.linkedin.com/pulse/interview-289-java-what-string-constant-pool-vhhjf)

- Все строковые **литералы** в коде (`"abc"`) при загрузке класса попадают в пул.
    
- При повторном использовании литерала `"abc"` JVM использует **уже существующий** объект из пула.[linkedin](https://www.linkedin.com/pulse/interview-289-java-what-string-constant-pool-vhhjf)
    
- Метод `intern()` явно помещает строку в пул (или возвращает уже существующую):
    
    - Если в пуле нет строки с таким содержимым — добавляет и возвращает ссылку на новый пуловый объект.
        
    - Если есть — просто возвращает ссылку на него.[youtube](https://www.youtube.com/watch?v=Ay4lG9bHkOw)[linkedin](https://www.linkedin.com/pulse/interview-289-java-what-string-constant-pool-vhhjf)
        

## Зачем нужен pool

- **Экономия памяти**: вместо сотен одинаковых строк ("OK", "ERROR", "USD" и т.д.) хранится один объект.[linkedin](https://www.linkedin.com/pulse/interview-289-java-what-string-constant-pool-vhhjf)
    
- **Быстрые сравнения `==`** для часто используемых констант (например, при сравнении с литералами), т.к. ссылки совпадают.[youtube](https://www.youtube.com/watch?v=Ay4lG9bHkOw)[linkedin](https://www.linkedin.com/pulse/interview-289-java-what-string-constant-pool-vhhjf)
    

## Иммутабельность строк и pool

Причины, почему `String` **final и immutable**, тесно связаны с пулом:[linkedin](https://www.linkedin.com/pulse/interview-289-java-what-string-constant-pool-vhhjf)[youtube](https://www.youtube.com/watch?v=Ay4lG9bHkOw)

- Одна и та же строка может использоваться в разных частях приложения; если её можно было бы изменить, замена у одного потребителя ломала бы всех.
    
- Иммутабельность делает безопасным кеширование и интернирование: объект в пуле не меняется, ссылку можно раздавать.
    

---

## GC и String pool: важные детали

- String pool находится в heap (раньше — в PermGen, теперь в обычной куче; CPermGen исчезла в Java 8).linkedin+1
    
- Интернированные строки собираются GC, если на них больше **нет сильных ссылок** (включая ссылку из пула). Pool не магический "вечный" storage.[linkedin](https://www.linkedin.com/pulse/interview-289-java-what-string-constant-pool-vhhjf)
    
- Агрессивное использование `intern()` на динамических строках (особенно уникальных) может **увеличить** расход памяти и нагрузку на GC, а не уменьшить.linkedin+1
    

---

Если хочешь, могу отдельно расписать:

- эволюцию GC (Serial/Parallel/CMS/G1/ZGC/Shenandoah) или
    
- именно вопросники по `equals/hashCode` и `String` (типа “что выведет этот код?”) для практики.

![[image-18.png]]

Metaspace хрнаит статическую информацию(методы, переменные) и байткод

Code Cache-код JIT компилятора(наиболее частые куски кода переводит в байт код и хранит именно тут)

Trhead Stack –стек вызовов потоков(все методы что вызывал поток, переменные примитвных типов, ссылки на переменные объектов)
Со стеком (Stack) сборщик мусора **не работает**. Стек управляется автоматически самой виртуальной машиной Java (JVM). Когда поток вызывает метод, для этого метода в стеке создается фрейм, в который помещаются локальные примитивы и ссылки. Когда метод завершает свою работу, этот фрейм просто удаляется вместе со всем содержимым (по принципу "последним пришел — первым ушел") без какого-либо участия сборщика мусора.

## Особенности Heap памяти

Куча (Heap) — это общая для всех потоков область памяти, где физически размещаются все созданные через оператор `new` объекты и массивы. Если примитивный тип является полем класса (например, переменная `int age` внутри класса `User`), то этот примитив будет храниться **в куче** как составная часть самого объекта, а не в стеке. Управление памятью в этой области осуществляется сборщиком мусора (Garbage Collector), который освобождает ресурсы, удаляя объекты без активных ссылок