![[IterablePic.png]]

Iterator<String> iterator = list.iterator();
The methods used while traversing the collections using Iterator to perform the operations are:

- **hasNext()**: It returns false if we have reached the end of the collection, otherwise returns true.
- **next()**: Returns the next element in a collection.
- **remove()**: Removes the last element returned by the iterator from the collection.
- **forEachRemaining()**: Performs the given action for each remaining element in a collection, in sequential order.



list.forEach(
            (element) -> { System.out.println(element); });
}
for( String element : list ){
          System.out.println( element );
}


