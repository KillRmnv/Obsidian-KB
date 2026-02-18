A TreeSet is a collection class that stores unique elements in a sorted order. It is part of [java.util package](https://www.geeksforgeeks.org/java/java-util-package-java/) that implements the SortedSet interface, and internally uses a Red-Black tree to maintain sorting.

- Does not allow duplicates and null values. From JDK 7 onward, inserting null throws NullPointerException.
- Implements the [NavigableSet interface](https://www.geeksforgeeks.org/java/navigableset-java-examples/) and provides navigation methods like higher(), lower(), ceiling() and floor().
- TreeSet is not synchronized. it must be synchronized using [Collections.synchronizedSet()](https://www.geeksforgeeks.org/java/collections-synchronizedset-method-in-java-with-examples/).