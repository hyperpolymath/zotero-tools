# Property-Based Testing in Fogbinder

This document explains Fogbinder's property-based testing approach using fast-check.

## What is Property-Based Testing?

Unlike traditional **example-based testing**:
```typescript
// Example-based test
assertEquals(merge(stateA, stateB).certainty, "Vague");
```

**Property-based testing** verifies properties that should hold for **ALL** inputs:
```typescript
// Property-based test
fc.assert(
  fc.property(
    stateArbitrary,
    stateArbitrary,
    (a, b) => merge(a, b) === merge(b, a)  // Commutativity
  )
);
```

### Benefits

1. **Finds edge cases** - Generates hundreds of random test cases
2. **Automatic shrinking** - Finds minimal failing example
3. **Documents invariants** - Properties serve as executable specifications
4. **Complements formal verification** - Tests properties proven in TLA+

## Property Test Files

### Core Module Properties

#### `src/core/EpistemicState.property.test.ts`

Tests algebraic properties of epistemic state merging:

| Property | Description | Proven in TLA+ |
|----------|-------------|----------------|
| **Commutativity** | `merge(A, B) = merge(B, A)` | ✓ Yes |
| **Associativity** | `merge(merge(A,B),C) = merge(A,merge(B,C))` | ✓ Yes |
| **Identity** | `merge(A, A) = A` | ✓ Yes |
| **Evidence monotonicity** | Evidence never lost during merge | ✓ Yes |
| **Certainty preservation** | Merged certainty from inputs | ✓ Yes |

Example property:
```typescript
Deno.test("Property: merge is commutative", () => {
  fc.assert(
    fc.property(
      epistemicStateArbitrary,
      epistemicStateArbitrary,
      (state1, state2) => {
        const mergeAB = EpistemicState.merge(state1, state2);
        const mergeBA = EpistemicState.merge(state2, state1);

        assertEquals(mergeAB.certainty.TAG, mergeBA.certainty.TAG);
        return true;
      }
    ),
    { numRuns: 100 }
  );
});
```

#### `src/core/FamilyResemblance.property.test.ts`

Tests Wittgensteinian properties of family resemblance clustering:

| Property | Description | Proven in TLA+ |
|----------|-------------|----------------|
| **Resemblance symmetry** | `resemblance(A,B) = resemblance(B,A)` | ✓ Yes |
| **Self-resemblance** | `resemblance(A,A) = 1.0` | ✓ Yes |
| **No necessary features** | No feature required for ALL members | ✓ Yes |
| **Vague boundaries** | Boundaries are "vague" or "contested" | ✓ Yes |
| **Contested merge** | Merged clusters have contested boundaries | ✓ Yes |

Example property:
```typescript
Deno.test("Property: resemblance is symmetric", () => {
  fc.assert(
    fc.property(
      clusterArbitrary,
      fc.string(),
      fc.string(),
      (cluster, item1, item2) => {
        const strength1to2 = FamilyResemblance.resemblanceStrength(item1, item2, cluster);
        const strength2to1 = FamilyResemblance.resemblanceStrength(item2, item1, cluster);

        assertEquals(Math.abs(strength1to2 - strength2to1) < 0.0001, true);
        return true;
      }
    )
  );
});
```

### Engine Module Properties

#### `src/engine/ContradictionDetector.property.test.ts`

Tests invariants of contradiction detection:

| Property | Description | Proven in TLA+ |
|----------|-------------|----------------|
| **Determinism** | Same input → same output | - |
| **No self-contradictions** | Single source has no contradictions | ✓ Yes |
| **Severity bounds** | Severity in [0, 1] | ✓ Yes |
| **Valid conflict types** | One of 5 defined types | ✓ Yes |
| **Non-empty resolutions** | Suggestions always provided | - |

Example property:
```typescript
Deno.test("Property: severity is between 0 and 1", () => {
  fc.assert(
    fc.property(
      sourcesArbitrary,
      contextArbitrary,
      (sources, context) => {
        const contradictions = ContradictionDetector.detect(sources, context);

        for (const c of contradictions) {
          const severity = ContradictionDetector.getSeverity(c);
          assertEquals(severity >= 0 && severity <= 1, true);
        }

        return true;
      }
    )
  );
});
```

## Running Property Tests

### All property tests
```bash
deno test --allow-all "**/*.property.test.ts"
```

### Specific module
```bash
deno test --allow-all src/core/EpistemicState.property.test.ts
```

### Increase test runs for more confidence
```bash
# Edit test file to increase numRuns
fc.assert(fc.property(...), { numRuns: 1000 })
```

## Arbitraries (Test Data Generators)

fast-check uses **arbitraries** to generate random test data:

### Basic Arbitraries

```typescript
fc.string()                          // Any string
fc.string({ minLength: 1 })          // Non-empty string
fc.integer({ min: 0, max: 100 })     // Integer in range
fc.float({ min: 0, max: 1 })         // Float in range
fc.boolean()                         // true or false
fc.array(fc.string())                // Array of strings
```

### Custom Arbitraries

```typescript
// Generate random certainty values
const certaintyArbitrary = fc.oneof(
  fc.constant({ TAG: "Known" }),
  fc.record({
    TAG: fc.constant("Probable"),
    _0: fc.float({ min: 0, max: 1 })
  }),
  fc.constant({ TAG: "Vague" })
);

// Generate random contexts
const contextArbitrary = fc.record({
  domain: fc.string({ minLength: 1 }),
  conventions: fc.array(fc.string()),
  participants: fc.array(fc.string()),
  purpose: fc.string()
});

// Generate random epistemic states
const epistemicStateArbitrary = fc.tuple(
  certaintyArbitrary,
  contextArbitrary,
  fc.array(fc.string())
).map(([certainty, context, evidence]) =>
  EpistemicState.make(certainty, context, evidence, undefined)
);
```

## Shrinking

When a property fails, fast-check automatically **shrinks** to find the minimal counterexample:

```typescript
// Initial failing input (random)
{
  sources: [
    "aoeifuhaseofiuh aosiehf oasiehf",
    "xzcvmnxzvcm nzxcvm nzxcvm",
    "qpoiweu qpoiwue qpowieu"
  ],
  context: { domain: "asdfasdf", ... }
}

// After shrinking
{
  sources: ["a", "b"],
  context: { domain: "x", conventions: [], participants: [], purpose: "" }
}
```

This makes debugging much easier!

## Relationship to Formal Verification

Property tests **complement** TLA+ formal verification:

| TLA+ Formal Verification | Property-Based Testing |
|--------------------------|------------------------|
| Proves properties for ALL states | Tests properties on random sample |
| Requires formal spec | Tests actual implementation |
| Abstract model | Concrete code |
| Complete coverage (proven) | Statistical coverage (high confidence) |
| Slow (minutes to hours) | Fast (seconds) |
| Requires expertise | Easy to write |

**Best Practice**: Use TLA+ to prove critical properties, then use property tests to verify the implementation matches the spec.

### Correspondence Table

| TLA+ Invariant/Theorem | Property Test |
|------------------------|---------------|
| `Symmetry` (ContradictionDetection.tla) | `"Property: merge is commutative"` |
| `MergeCommutative` (EpistemicStateMerge.tla) | `"Property: merge is commutative"` |
| `NoNecessaryCondition` (FamilyResemblance.tla) | `"Property: no necessary features"` |
| `ResemblanceSymmetry` (FamilyResemblance.tla) | `"Property: resemblance is symmetric"` |

## Writing New Property Tests

### 1. Identify the property

Ask: "What should be true for ALL inputs?"

Examples:
- "Merging is commutative"
- "Severity is always between 0 and 1"
- "No source contradicts itself"

### 2. Create arbitraries

Generate random inputs:
```typescript
const myArbitrary = fc.record({
  field1: fc.string(),
  field2: fc.integer()
});
```

### 3. Write the property test

```typescript
Deno.test("Property: my property description", () => {
  fc.assert(
    fc.property(
      myArbitrary,
      (input) => {
        const result = myFunction(input);

        // Assert the property
        assertEquals(
          someCondition(result),
          true,
          "Property should hold"
        );

        return true;
      }
    ),
    { numRuns: 100 }
  );
});
```

### 4. Run and refine

```bash
deno test --allow-all my.property.test.ts
```

If the test fails:
- Check if the property is actually true
- Check if the arbitrary generates valid inputs
- Check if the implementation has a bug

## Advanced Features

### Preconditions

Skip invalid test cases:
```typescript
fc.property(
  stateArbitrary,
  stateArbitrary,
  (s1, s2) => {
    if (s1.context !== s2.context) {
      return true; // Skip this case
    }

    // Test only when contexts match
    const merged = merge(s1, s2);
    assertEquals(merged.context, s1.context);
    return true;
  }
);
```

### Custom Shrinking

Control how failures shrink:
```typescript
const myArbitrary = fc.integer().map(
  n => ({ value: n }),
  obj => obj.value  // Shrink by extracting value
);
```

### Stateful Testing

Test sequences of operations:
```typescript
fc.assert(
  fc.property(
    fc.commands([
      addMemberCommand,
      addFeatureCommand,
      mergeCommand
    ]),
    (commands) => {
      const model = { cluster: initialCluster };
      commands.forEach(cmd => cmd.run(model));
      // Check invariants after all commands
      return checkInvariants(model);
    }
  )
);
```

## Performance

Property tests run many iterations (default: 100), so:

1. **Keep properties fast** - Avoid expensive operations
2. **Adjust numRuns** - Use 1000+ for critical properties, 10 for slow ones
3. **Use timeouts** - Add timeout if needed:
   ```typescript
   { numRuns: 100, timeout: 5000 }
   ```

## Integration with CI

Property tests run in CI alongside regular tests:

```yaml
# .github/workflows/ci.yml
- name: Run property tests
  run: deno test --allow-all "**/*.property.test.ts"
```

## Further Reading

- [fast-check Documentation](https://fast-check.dev/)
- [Property-Based Testing Guide](https://fsharpforfunandprofit.com/posts/property-based-testing/)
- [Hypothesis (Python) Guide](https://hypothesis.readthedocs.io/) - Similar approach
- [QuickCheck (Haskell)](https://hackage.haskell.org/package/QuickCheck) - Original PBT library

---

**Last Updated:** 2025-11-23
**License:** GNU AGPLv3
**RSR Tier:** Platinum Requirement
