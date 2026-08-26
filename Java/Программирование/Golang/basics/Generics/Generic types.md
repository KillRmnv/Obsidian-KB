```go
package main

import "fmt"
// List represents a singly-linked list that holds
// values of any type.
type List[T any] struct {
	next *List[T]
	val  T
}

func main() {
	node:= List[int]{nil,2}
	fmt.Printf("value:%v\n",node.val)
	next:=&List[int]{nil,5}
	node.next=next
	fmt.Printf("value:%v\n",node.next.val)
}

```