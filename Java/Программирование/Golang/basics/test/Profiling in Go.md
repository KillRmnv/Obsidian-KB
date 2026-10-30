For more detailed performance analysis, Go provides profiling tools in the `runtime/pprof` and `net/http/pprof` packages.

### CPU Profiling

```golang
import "runtime/pprof"

func main() {
    // Create a CPU profile file
    f, _ := os.Create("cpu.prof")
    defer f.Close()
    
    // Start CPU profiling
    pprof.StartCPUProfile(f)
    defer pprof.StopCPUProfile()
    
    // Run your code
    ExpensiveOperation()
}
```

### Memory Profiling

```golang
import "runtime/pprof"

func main() {
    // Run your code first to generate allocations
    ExpensiveOperation()
    
    // Create a memory profile file
    f, _ := os.Create("mem.prof")
    defer f.Close()
    
    // Write memory profile
    pprof.WriteHeapProfile(f)
}
```

### Analyzing Profiles

Use the `go tool pprof` command to analyze profiles:

```bash
go tool pprof cpu.prof      # Interactive mode
go tool pprof -http=:8080 cpu.prof  # Web UI
```