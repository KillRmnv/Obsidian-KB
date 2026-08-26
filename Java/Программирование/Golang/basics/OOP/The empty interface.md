The interface type that specifies zero methods is known as the _empty interface_:

interface{}

An empty interface may hold values of any type. (Every type implements at least zero methods.)

`any` is an alias for `interface{}`, and the two are completely equivalent.

Empty interfaces are used by code that handles values of unknown type. For example, `fmt.Print` takes any number of arguments of type `any`.

```go
package main

import "fmt"

func main() {
	var i interface{}
	describe(i)

	i = 42
	describe(i)

	i = "hello"
	describe(i)
}

func describe(i interface{}) {
	fmt.Printf("(%v, %T)\n", i, i)
}
(<nil>, <nil>)
(42, int)
(hello, string)
```