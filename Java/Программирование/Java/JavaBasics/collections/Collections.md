![[Pasted image 20251027161846.png]]
![[Pasted image 20251027155556.png]]
![[Pasted image 20251027160514.png]]
![[Pasted image 20251027160629.png]]
![[Pasted image 20251027160641.png]]
![[Pasted image 20251027160653.png]]
![[Pasted image 20251027160928.png]]
## List Implementations

Lists represent ordered collections that allow duplicate elements and positional access. They include dynamic arrays, linked structures and legacy classes designed for sequential storage.

- [ArrayList](https://www.geeksforgeeks.org/java/arraylist-in-java/)
- [LinkedList](https://www.geeksforgeeks.org/java/linked-list-in-java/)
- [Vector](https://www.geeksforgeeks.org/java/java-util-vector-class-java/)(- **Vector:** только если нужен потокобезопасный список без внешней синхронизации (редко, современные альтернативы: `Collections.synchronizedList()` или `CopyOnWriteArrayList`).
- **ArrayList:** большинство случаев, быстрее и современнее.)
- [Stack](https://www.geeksforgeeks.org/java/stack-class-in-java/)
- [AbstractList](https://www.geeksforgeeks.org/java/abstractlist-in-java-with-examples/)(meant to be extended by ArrayList,LinkedList)
- [AbstractSequentialList](https://www.geeksforgeeks.org/java/abstractsequentiallist-in-java-with-examples/)
## Set Implementations

Sets represent collections of unique elements, disallowing duplicates. They provide implementations with different ordering strategies like hashing, insertion order or sorting.

- [HashSet](https://www.geeksforgeeks.org/java/hashset-in-java/)
- [Linked HashSet](https://www.geeksforgeeks.org/java/linkedhashset-in-java-with-examples/)
- [[TreeSet]](https://www.geeksforgeeks.org/java/treeset-in-java-with-examples/)
- [[EnumSet]](https://www.geeksforgeeks.org/java/enumset-class-java/)
- [SortedSet Interface](https://www.geeksforgeeks.org/java/sortedset-java-examples/)
- [NavigableSet](https://www.geeksforgeeks.org/java/navigableset-java-examples/)
- [ConcurrentSkipListSet](https://www.geeksforgeeks.org/java/concurrentskiplistset-in-java-with-examples/)
## Queue / Deque Implementations

Queues store elements in a FIFO manner, while Deques allow operations at both ends. They are used for scheduling, buffering and producer-consumer applications.

- [Abstract Queue](https://www.geeksforgeeks.org/java/abstractqueue-in-java-with-examples/)
- [Priority Queue](https://www.geeksforgeeks.org/java/priority-queue-in-java/)
- [ConcurrentLinked Queue](https://www.geeksforgeeks.org/java/concurrentlinkedqueue-in-java-with-examples/)
- [Array Deque](https://www.geeksforgeeks.org/java/arraydeque-in-java/)
- [Priority Queue](https://www.geeksforgeeks.org/java/priority-queue-in-java/)
## Map Implementations

Maps store data as key-value pairs where keys are unique. Different implementations provide hashing, ordering, reference-based and concurrent behaviors.

- [HashMap](https://www.geeksforgeeks.org/java/java-util-hashmap-in-java-with-examples/)
- [LinkedHashMap](https://www.geeksforgeeks.org/java/linkedhashmap-class-in-java/)
- [TreeMap](https://www.geeksforgeeks.org/java/treemap-in-java/)
- [WeakHashMap](https://www.geeksforgeeks.org/java/java-util-weakhashmap-class-java/)
- [IdentityHashMap](https://www.geeksforgeeks.org/java/identityhashmap-class-java/)
- [HashTable](https://www.geeksforgeeks.org/java/hashtable-in-java/)
##  Utility and Supporting Classes

Java provides helper classes and interfaces to enhance collection usage. They include Collections, Iterator, Comparator and other tools for iteration and sorting.

- [Collections Class](https://www.geeksforgeeks.org/java/collections-class-in-java/)
- [[Iterable interface]](https://www.geeksforgeeks.org/java/iterable-interface-in-java/)
- [ListIterator](https://www.geeksforgeeks.org/java/listiterator-in-java/)
- [Enumeration](https://www.geeksforgeeks.org/java/enumeration-interface-in-java/)(- `Enumeration<E>` — интерфейс **для перебора элементов коллекции**, аналог современного `Iterator<E>`.
- Определён ещё в **Java 1.0**, до появления коллекций `Collection` и `Iterator`)
- [[Comparator]](https://www.geeksforgeeks.org/java/java-comparator-interface/)
- [Comparable](https://www.geeksforgeeks.org/java/comparable-interface-in-java-with-examples/)
## Concurrency Collections

Concurrent collections are designed for multi-threaded environments. They ensure thread-safe access without compromising performance.

- [ConcurrentHashMap](https://www.geeksforgeeks.org/java/concurrenthashmap-in-java/)
- [CopyOnWriteArrayList](https://www.geeksforgeeks.org/java/copyonwritearraylist-in-java/)
- [ConcurrentLinkedQueue](https://www.geeksforgeeks.org/java/concurrentlinkedqueue-in-java-with-examples/)
- [BlockingQueue](https://www.geeksforgeeks.org/java/blockingqueue-interface-in-java/) ([ArrayBlockingQueue](https://www.geeksforgeeks.org/java/arrayblockingqueue-class-in-java/), [LinkedBlockingQueue](https://www.geeksforgeeks.org/java/linkedblockingqueue-class-in-java/) )