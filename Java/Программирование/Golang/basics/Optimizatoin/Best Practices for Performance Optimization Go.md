- **Measure First**: Always benchmark before and after optimization to confirm improvements
- **80/20 Rule**: Focus on the 20% of the code that causes 80% of the performance issues
- **Start Simple**: Use efficient algorithms and data structures before optimizing at a lower level
- **Readability vs. Performance**: Balance performance gains against code maintainability
- **Profile in Production-like Environments**: Performance characteristics can vary between environments
- **Test Case Sizes**: Test with different input sizes to understand algorithmic complexity

## Memory Management Optimization

### Slice Capacity

Pre-allocate slices when you know the approximate size:

```golang
// Inefficient - may cause multiple allocations and copies
data := []int{}
for i := 0; i < 10000; i++ {
    data = append(data, i)
}

// Efficient - allocates once with the right capacity
data := make([]int, 0, 10000)
for i := 0; i < 10000; i++ {
    data = append(data, i)
}
```

### Reducing Pointer Indirection

Prefer value types over pointer types when dealing with small objects:

```golang
// More allocations, more GC pressure
type Point struct {
    X, Y float64
}

points := make([]*Point, 1000)
for i := 0; i < 1000; i++ {
    points[i] = &Point{X: float64(i), Y: float64(i)}
}

// Fewer allocations, better cache locality
type Point struct {
    X, Y float64
}

points := make([]Point, 1000)
for i := 0; i < 1000; i++ {
    points[i] = Point{X: float64(i), Y: float64(i)}
}
```

### Sync.Pool for Frequent Allocations

Use `sync.Pool` to reuse temporary objects:

```golang
var bufferPool = sync.Pool{
    New: func() interface{} {
        return make([]byte, 4096)
    },
}

func ProcessData(data []byte) []byte {
    // Get a buffer from the pool
    buffer := bufferPool.Get().([]byte)
    defer bufferPool.Put(buffer)
    
    // Use the buffer for processing
    buffer = buffer[:0]
    // ... processing logic ...
    
    return result
}
```

## Concurrency Optimizations

### Utilizing Multiple Cores

Use goroutines and channels to parallelize independent work:

```golang
func ProcessItems(items []Item) []Result {
    numCPU := runtime.NumCPU()
    numWorkers := numCPU
    
    // Create channels
    jobs := make(chan Item, len(items))
    results := make(chan Result, len(items))
    
    // Start workers
    var wg sync.WaitGroup
    for i := 0; i < numWorkers; i++ {
        wg.Add(1)
        go func() {
            defer wg.Done()
            for item := range jobs {
                result := ProcessItem(item)
                results <- result
            }
        }()
    }
    
    // Send jobs
    for _, item := range items {
        jobs <- item
    }
    close(jobs)
    
    // Wait for workers and close results
    go func() {
        wg.Wait()
        close(results)
    }()
    
    // Collect results
    var finalResults []Result
    for result := range results {
        finalResults = append(finalResults, result)
    }
    
    return finalResults
}
```

### Avoiding Goroutine Overhead

Beware of creating too many goroutines for small tasks:

```golang
// Inefficient for small items
for _, item := range items {
    go ProcessItem(item) // Goroutine overhead may exceed benefits
}

// More efficient for small items - process in batches
batchSize := 1000
for i := 0; i < len(items); i += batchSize {
    end := i + batchSize
    if end > len(items) {
        end = len(items)
    }
    
    batch := items[i:end]
    go func(batch []Item) {
        for _, item := range batch {
            ProcessItem(item)
        }
    }(batch)
}
```

## Additional Optimization Techniques

### Loop Unrolling

For tight loops with simple operations, unrolling can improve performance:

```golang
// Before unrolling
sum := 0
for i := 0; i < len(data); i++ {
    sum += data[i]
}

// After unrolling
sum := 0
remainder := len(data) % 4
for i := 0; i < remainder; i++ {
    sum += data[i]
}
for i := remainder; i < len(data); i += 4 {
    sum += data[i] + data[i+1] + data[i+2] + data[i+3]
}
```

### Reducing Interface Conversions

Avoid frequent type assertions or interface conversions in hot paths:

```golang
// Inefficient - type assertion in loop
func ProcessItems(items []interface{}) int {
    sum := 0
    for _, item := range items {
        if val, ok := item.(int); ok {
            sum += val
        }
    }
    return sum
}

// More efficient - use concrete types when possible
func ProcessItems(items []int) int {
    sum := 0
    for _, item := range items {
        sum += item
    }
    return sum
}
```

### Function Inlining

Small, frequently called functions may be inlined by the compiler, but you can help:

```golang
// May be inlined automatically if small enough
func add(a, b int) int {
    return a + b
}

// Suggest inlining with the "go:inline" directive
//go:inline
func add(a, b int) int {
    return a + b
}

// Prevent inlining of large functions with "go:noinline"
//go:noinline
func complexFunction(data []int) int {
    // Complex logic...
}
```