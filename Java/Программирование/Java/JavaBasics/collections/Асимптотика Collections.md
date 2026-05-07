Дам тебе “шпаргалку по асимптотике” для основных коллекций: List / Set / Map и очереди. Это усреднённые оценки, без учёта констант и редких worst-case сценариев.wiki.rakovets+4

## List

## ArrayList (динамический массив)

|Операция|Среднее|Худшее|Комментарий|
|---|---|---|---|
|`get(i)`|O(1)|O(1)|Прямой доступ по индексу codeflow+1|
|`set(i)`|O(1)|O(1)|Запись по индексу [codeflow](https://www.codeflow.site/ru/article/java-collections-complexity)|
|`add(e)` в конец|аморт. O(1)|O(n)|Иногда нужна перераспаковка массива codeflow+1|
|`add(i, e)` в середину/начало|O(n)|O(n)|Сдвиг хвоста массива [codeflow](https://www.codeflow.site/ru/article/java-collections-complexity)|
|`remove(i)`|O(n)|O(n)|Сдвиг элементов после i [codeflow](https://www.codeflow.site/ru/article/java-collections-complexity)|
|`remove(e)` по значению|O(n)|O(n)|Линейный поиск [codeflow](https://www.codeflow.site/ru/article/java-collections-complexity)|
|`contains(e)`|O(n)|O(n)|Линейный поиск [codeflow](https://www.codeflow.site/ru/article/java-collections-complexity)|
|итерация `for-each`|O(n)|O(n)|Последовательный обход массива [codeflow](https://www.codeflow.site/ru/article/java-collections-complexity)|

## LinkedList (двусвязный список)

|Операция|Среднее|Худшее|Комментарий|
|---|---|---|---|
|`get(i)`|O(n)|O(n)|Нужно пройти по узлам codeflow+1|
|`add(e)` в конец|O(1)|O(1)|Есть ссылка на хвост [codeflow](https://www.codeflow.site/ru/article/java-collections-complexity)|
|`add(0, e)` в начало|O(1)|O(1)|Есть ссылка на голову [codeflow](https://www.codeflow.site/ru/article/java-collections-complexity)|
|`add(i, e)` в середину|O(n)|O(n)|Найти позицию — линейно [codeflow](https://www.codeflow.site/ru/article/java-collections-complexity)|
|`removeFirst()/removeLast()`|O(1)|O(1)|Переброс ссылок [codeflow](https://www.codeflow.site/ru/article/java-collections-complexity)|
|`remove(i)`|O(n)|O(n)|Сначала найти узел [codeflow](https://www.codeflow.site/ru/article/java-collections-complexity)|
|`contains(e)`|O(n)|O(n)|Линейный обход [codeflow](https://www.codeflow.site/ru/article/java-collections-complexity)|
|итерация|O(n)|O(n)|Последовательный обход [codeflow](https://www.codeflow.site/ru/article/java-collections-complexity)|

**Интуиция:**

- много случайного доступа → **ArrayList**;
    
- много вставок/удалений с начала/середины и почти нет `get(i)` → можно думать про **LinkedList**.
    

## Set

## HashSet (на базе HashMap)

|Операция|Среднее|Худшее|Комментарий|
|---|---|---|---|
|`add(e)`|O(1)|O(n)|При хорошей хэш-функции — аморт. O(1) codeflow+1|
|`remove(e)`|O(1)|O(n)|Поиск бакета + поиск внутри него [zhukovsd.github](https://zhukovsd.github.io/java-backend-interview-prep/%D0%BE%D1%81%D0%BD%D0%BE%D0%B2%D1%8B-java/collections/)|
|`contains(e)`|O(1)|O(n)|То же самое [zhukovsd.github](https://zhukovsd.github.io/java-backend-interview-prep/%D0%BE%D1%81%D0%BD%D0%BE%D0%B2%D1%8B-java/collections/)|
|итерация|O(n)|O(n)|Обход всех бакетов [codeflow](https://www.codeflow.site/ru/article/java-collections-complexity)|

Худший случай — когда все ключи попали в один бакет (коллизии) и структура деградировала до списка/дерева: тогда поиск/вставка становится O(n).[zhukovsd.github](https://zhukovsd.github.io/java-backend-interview-prep/%D0%BE%D1%81%D0%BD%D0%BE%D0%B2%D1%8B-java/collections/)

## TreeSet (на базе TreeMap, красно-чёрное дерево)

|Операция|Среднее/худшее|Комментарий|
|---|---|---|
|`add(e)`|O(log n)|Вставка в самобалансирующееся дерево [codeflow](https://www.codeflow.site/ru/article/java-collections-complexity)|
|`remove(e)`|O(log n)|Удаление из дерева [codeflow](https://www.codeflow.site/ru/article/java-collections-complexity)|
|`contains(e)`|O(log n)|Поиск по дереву [codeflow](https://www.codeflow.site/ru/article/java-collections-complexity)|
|итерация (по возрастанию)|O(n)|Симметричный обход дерева [codeflow](https://www.codeflow.site/ru/article/java-collections-complexity)|

**Интуиция:**

- нужен порядок (сортировка, диапазонные запросы, `first/last/headSet`) → **TreeSet**;
    
- порядок не нужен, важна скорость `contains` → **HashSet**.
    

## Map

## HashMap (хэш-таблица + списки/деревья в бакетах)

|Операция|Среднее|Худшее|Комментарий|
|---|---|---|---|
|`put(k, v)`|O(1)|O(n)|В худшем: много коллизий в одном бакете codeflow+1|
|`get(k)`|O(1)|O(n)|Поиск по хэшу + внутри бакета codeflow+1|
|`remove(k)`|O(1)|O(n)|То же [zhukovsd.github](https://zhukovsd.github.io/java-backend-interview-prep/%D0%BE%D1%81%D0%BD%D0%BE%D0%B2%D1%8B-java/collections/)|
|`containsKey(k)`|O(1)|O(n)|То же [zhukovsd.github](https://zhukovsd.github.io/java-backend-interview-prep/%D0%BE%D1%81%D0%BD%D0%BE%D0%B2%D1%8B-java/collections/)|
|итерация по entrySet|O(n)|O(n)|Обход всех бакетов [codeflow](https://www.codeflow.site/ru/article/java-collections-complexity)|

С учётом treeification в Java 8+ внутри “тяжёлых” бакетов операции становятся ~O(log n) по числу элементов в бакете, но глобальная асимптотика по всей мапе так и остаётся O(1) в среднем.javarush+1

## TreeMap (красно-чёрное дерево)

|Операция|Среднее/худшее|Комментарий|
|---|---|---|
|`put(k, v)`|O(log n)|Вставка в дерево по ключу codeflow+1|
|`get(k)`|O(log n)|Поиск в дереве codeflow+1|
|`remove(k)`|O(log n)|Удаление из дерева [codeflow](https://www.codeflow.site/ru/article/java-collections-complexity)|
|`containsKey(k)`|O(log n)|То же [codeflow](https://www.codeflow.site/ru/article/java-collections-complexity)|
|итерация по ключам|O(n)|В отсортированном порядке [codeflow](https://www.codeflow.site/ru/article/java-collections-complexity)|
|операции диапазонов (`subMap`, `headMap`, `tailMap`)|O(log n + k)|k — размер результата [codeflow](https://www.codeflow.site/ru/article/java-collections-complexity)|

**Интуиция:**

- нужен **отсортированный** Map, диапазоны, `firstKey/lastKey` → **TreeMap**;
    
- важна максимальная скорость `get/put` без порядка → **HashMap**.
    

## Очереди / Deque (базовые)

## ArrayDeque

|Операция|Среднее|Комментарий|
|---|---|---|

|Операция|Среднее|Комментарий|
|---|---|---|
|`addFirst/addLast`|O(1)|Кольцевой буфер [habr](https://habr.com/ru/companies/otus/articles/660959/)|
|`removeFirst/removeLast`|O(1)|То же|
|`peekFirst/peekLast`|O(1)|Прямой доступ по индексам|
|итерация|O(n)|Последовательный обход|

## PriorityQueue (бинарная куча)

|Операция|Среднее/худшее|Комментарий|
|---|---|---|
|`add(e)` / `offer(e)`|O(log n)|Вставка в кучу habr+1|
|`poll()` (достать минимум)|O(log n)|Реструктуризация кучи [codeflow](https://www.codeflow.site/ru/article/java-collections-complexity)|
|`peek()`|O(1)|Корень кучи [codeflow](https://www.codeflow.site/ru/article/java-collections-complexity)|
|итерация|O(n)|Без гарантии порядка [codeflow](https://www.codeflow.site/ru/article/java-collections-complexity)|

---

Если нужно, могу сделать отдельную таблицу конкретно под “что лучше выбрать для задачи X” (например: “много чтения, мало записи”, “многопоточность”, “очень большой n” и т.п.).