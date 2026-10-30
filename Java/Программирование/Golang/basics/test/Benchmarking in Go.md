Go provides excellent built-in support for benchmarking through the `testing` package. Benchmarks are functions that start with the word `Benchmark` followed by a name, take a parameter of type `*testing.B`, and are run by the `go test` command with the `-bench` flag.

```golang
func BenchmarkMyFunction(b *testing.B) {
    // Run the target function b.N times
    for i := 0; i < b.N; i++ {
        MyFunction()
    }
}
```

### Running Benchmarks

To run benchmarks, use the `go test` command with the `-bench` flag:

```bash
go test -bench=.                 # Run all benchmarks
go test -bench=BenchmarkMyFunction  # Run a specific benchmark
```

Add the `-benchmem` flag to also measure memory allocations:

```bash
go test -bench=. -benchmem
```

### Understanding Benchmark Results

The output of a benchmark looks like this:

```
BenchmarkMyFunction-8   	10000000	       118 ns/op	      16 B/op	       1 allocs/op
```

This means:

- The benchmark ran on 8 CPU cores (`-8`)
- It ran 10,000,000 iterations
- Each operation took about 118 nanoseconds
- Each operation allocated 16 bytes
- Each operation performed 1 allocation

### Comparing Benchmarks

To compare benchmark results, you can use the `benchstat` tool:

```bash
go test -bench=. -count=5 > old.txt
# Make changes to the code
go test -bench=. -count=5 > new.txt
benchstat old.txt new.txt
```