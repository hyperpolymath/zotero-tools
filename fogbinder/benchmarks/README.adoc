# Fogbinder Performance Benchmarks

Performance benchmarks for Fogbinder's critical operations.

## Purpose

These benchmarks help:
1. **Track performance over time** - Detect regressions
2. **Identify bottlenecks** - Find slow operations
3. **Guide optimization** - Measure improvement impact
4. **Set performance budgets** - Define acceptable limits
5. **RSR Platinum compliance** - Required for highest tier

## Benchmark Suites

### 1. Epistemic State Operations (`epistemic_state.bench.ts`)

Measures performance of epistemic state creation and merging.

**Key Metrics:**
- State creation (Known, Probable, Vague, Ambiguous, Mysterious, Contradictory)
- Merge operations (various combinations)
- Chain merges (5 states)
- `isUncertain` checks
- Large evidence arrays (100+ items)

**Typical Performance (baseline):**
```
Create Known state:           0.01 ms/op
Create Probable state:        0.01 ms/op
Merge Known + Probable:       0.02 ms/op
Chain merge (5 states):       0.10 ms/op
Check isUncertain:            0.001 ms/op
```

### 2. Contradiction Detection (`contradiction_detection.bench.ts`)

Measures performance of language game contradiction detection.

**Key Metrics:**
- Small dataset (2 sources)
- Medium dataset (10 sources)
- Large dataset (50 sources)
- Very large dataset (200 sources)
- Severity calculation
- Resolution suggestions
- Scaling behavior

**Typical Performance (baseline):**
```
2 sources:      0.5 ms/op
10 sources:     5 ms/op
50 sources:     50 ms/op
200 sources:    500 ms/op
```

**Scaling:** O(n²) in worst case (pairwise comparison)

### 3. Full Pipeline (`full_pipeline.bench.ts`)

Measures end-to-end analysis performance.

**Key Metrics:**
- Complete analysis (3, 10, 50 sources)
- FogTrail generation
- SVG visualization
- JSON export
- Complete workflow (analysis + viz)
- Memory stress test (100 sources)
- Throughput test
- Scaling analysis

**Typical Performance (baseline):**
```
Full analysis (3 sources):     5 ms/op
Full analysis (10 sources):    15 ms/op
Full analysis (50 sources):    150 ms/op
Build FogTrail:                2 ms/op
Generate SVG:                  5 ms/op
Complete workflow:             25 ms/op
```

## Running Benchmarks

### All benchmarks
```bash
just bench
# or manually:
deno run --allow-all benchmarks/run_all.ts
```

### Individual benchmark
```bash
deno run --allow-all benchmarks/epistemic_state.bench.ts
deno run --allow-all benchmarks/contradiction_detection.bench.ts
deno run --allow-all benchmarks/full_pipeline.bench.ts
```

### Save results
```bash
just bench > benchmarks/results/$(date +%Y-%m-%d).txt
```

## Interpreting Results

### Absolute Performance

Compare results to baseline:
- **Green** (faster): < 90% of baseline
- **Yellow** (similar): 90-110% of baseline
- **Red** (slower): > 110% of baseline

### Scaling Behavior

Check how performance scales with input size:
- **Linear O(n)**: Ideal for most operations
- **Quadratic O(n²)**: Expected for pairwise comparisons
- **Exponential O(2ⁿ)**: Problem - needs optimization

### Regression Detection

Compare current run to previous runs:
```bash
# Run and save results
deno run --allow-all benchmarks/full_pipeline.bench.ts > current.txt

# Compare to previous
diff previous.txt current.txt
```

Significant regression: > 20% slowdown on same hardware

## Performance Budgets

Target performance budgets for common operations:

| Operation | Budget | Critical? |
|-----------|--------|-----------|
| Create epistemic state | < 0.1 ms | No |
| Merge two states | < 0.1 ms | No |
| Analyze 10 sources | < 50 ms | Yes |
| Analyze 100 sources | < 1000 ms | Yes |
| Generate FogTrail | < 10 ms | No |
| Generate SVG | < 20 ms | No |
| Complete workflow (10 sources) | < 100 ms | Yes |

**Critical operations** directly impact user experience.

## Optimization Guidelines

When optimizing:

1. **Measure first** - Profile before optimizing
2. **Focus on hot paths** - Optimize critical operations
3. **Benchmark after** - Verify improvement
4. **Check correctness** - Run tests after optimization
5. **Document changes** - Explain what was optimized

### Common Optimizations

**Caching:**
```typescript
// Before
function expensiveComputation(input) {
  // Recomputes every time
}

// After
const cache = new Map();
function expensiveComputation(input) {
  if (cache.has(input)) return cache.get(input);
  const result = // compute
  cache.set(input, result);
  return result;
}
```

**Lazy Evaluation:**
```typescript
// Before
const allResults = sources.map(expensive);
return allResults[0];  // Computed everything, used only first

// After
for (const source of sources) {
  const result = expensive(source);
  if (condition(result)) return result;  // Early exit
}
```

**Batch Processing:**
```typescript
// Before
for (const item of items) {
  await processOne(item);  // Serial
}

// After
await Promise.all(items.map(processOne));  // Parallel
```

## Continuous Tracking

### Local Development

Run benchmarks before/after significant changes:
```bash
# Before changes
just bench > before.txt

# Make changes...

# After changes
just bench > after.txt

# Compare
diff before.txt after.txt
```

### CI Integration

Benchmarks run automatically in CI:
```yaml
# .github/workflows/ci.yml
- name: Run benchmarks
  run: deno run --allow-all benchmarks/run_all.ts
```

Results are stored as artifacts for comparison.

### Performance Dashboard (Future)

Track performance over time:
- Line charts showing trends
- Alerts for regressions
- Comparison across versions

## Hardware Considerations

Benchmark results depend on hardware:

**Reference System:**
- CPU: Intel Core i7 / AMD Ryzen 7
- RAM: 16 GB
- OS: Linux / macOS
- Deno: 1.40+

**Adjust expectations** for different hardware:
- Lower-end: 2-3x slower
- Higher-end: 50% faster
- Mobile/embedded: 5-10x slower

## Known Performance Characteristics

### Fast Operations (< 1 ms)
- State creation
- State merging (2 states)
- `isUncertain` checks
- Fog density calculation

### Moderate Operations (1-10 ms)
- Contradiction detection (< 20 sources)
- FogTrail generation
- JSON export

### Slow Operations (10-100 ms)
- Contradiction detection (50+ sources)
- SVG generation (complex graphs)
- Complete analysis (50+ sources)

### Very Slow Operations (> 100 ms)
- Analysis of 100+ sources
- Complex FogTrail visualization

## Future Improvements

Potential optimizations:

1. **WASM compilation** - Faster ReScript → WASM
2. **Parallel processing** - Use Web Workers for large datasets
3. **Incremental analysis** - Only analyze new/changed sources
4. **Smart caching** - Cache contradiction detection results
5. **Sampling** - Approximate results for very large datasets

## Further Reading

- [Deno Performance Best Practices](https://deno.land/manual/runtime/performance)
- [Web Performance Working Group](https://www.w3.org/webperf/)
- [Benchmark.js](https://benchmarkjs.com/) - Alternative benchmarking library

---

**Last Updated:** 2025-11-23
**License:** GNU AGPLv3
**RSR Tier:** Platinum Requirement
