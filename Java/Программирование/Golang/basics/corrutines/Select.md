The `select` statement lets a goroutine wait on multiple communication operations.

A `select` blocks until one of its cases can run, then it executes that case. It chooses one at random if multiple are ready.

```go
package main

import "fmt"

func fibonacci(c, quit chan int) {
	x, y := 0, 1
	for {
		select {
		case c <- x:
			x, y = y, x+y
		case <-quit:
			fmt.Println("quit")
			return
		}
	}
}

func main() {
	c := make(chan int)
	quit := make(chan int)
	go func() {
		for i := 0; i < 10; i++ {
			fmt.Println(<-c)
		}
		quit <- 0
	}()
	fibonacci(c, quit)
}

0
1
1
2
3
5
8
13
21
34
quit
Program exited.
```

The `default` case in a `select` is run if no other case is ready.

Use a `default` case to try a send or receive without blocking:

select {
case i := <-c:
    // use i
default:
    // receiving from c would block
}

```go
package main

import (
	"fmt"
	"time"
)

func main() {
	start := time.Now()
	tick := time.Tick(100 * time.Millisecond)
	boom := time.After(500 * time.Millisecond)
	elapsed := func() time.Duration {
		return time.Since(start).Round(time.Millisecond)
	}
	for {
		select {
		case <-tick:
			fmt.Printf("[%6s] tick.\n", elapsed())
		case <-boom:
			fmt.Printf("[%6s] BOOM!\n", elapsed())
			return
		default:
			fmt.Printf("[%6s]     .\n", elapsed())
			time.Sleep(50 * time.Millisecond)
		}
	}
}
[    0s]     .
[  50ms]     .
[ 100ms] tick.
[ 100ms]     .
[ 150ms]     .
[ 200ms] tick.
[ 200ms]     .
[ 250ms]     .
[ 300ms] tick.
[ 300ms]     .
[ 350ms]     .
[ 400ms] tick.
[ 400ms]     .
[ 450ms]     .
[ 500ms] BOOM!
Program exited.
```