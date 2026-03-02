# Fogbinder Development Guide

Complete guide for developers working on Fogbinder.

## Architecture Overview

```
fogbinder/
├── src/
│   ├── core/              # Philosophical foundations (ReScript)
│   │   ├── EpistemicState.res      # Epistemic modalities
│   │   ├── SpeechAct.res           # J.L. Austin speech acts
│   │   └── FamilyResemblance.res   # Wittgenstein clustering
│   │
│   ├── engine/            # Analysis engines (ReScript)
│   │   ├── ContradictionDetector.res  # Language game conflicts
│   │   ├── MoodScorer.res             # Speech act analysis
│   │   ├── MysteryClustering.res      # Epistemic resistance
│   │   └── FogTrailVisualizer.res     # Network visualization
│   │
│   ├── zotero/            # Zotero integration
│   │   ├── ZoteroBindings.res      # ReScript bindings
│   │   └── zotero_api.js           # JS shim
│   │
│   ├── Fogbinder.res      # Main orchestrator
│   └── main.ts            # TypeScript entry point
│
├── scripts/
│   ├── build.ts           # Build orchestration
│   └── build_wasm.ts      # WASM compilation (future)
│
├── tests/                 # Test suites
├── examples/              # Usage examples
└── docs/                  # Documentation
```

## Tech Stack

### Core Technologies

1. **ReScript** - Primary implementation language
   - Why: Type safety + functional programming + JS interop
   - Compiles to readable JavaScript
   - Excellent for modeling philosophical concepts as types

2. **Deno** - JavaScript runtime and tooling
   - Why: Modern, secure, TypeScript-native
   - No npm dependency hell
   - Built-in testing, formatting, linting

3. **TypeScript** - External API surface
   - Why: Familiar to most developers
   - Type definitions for library consumers
   - Bridge between ReScript and Deno

4. **WASM** (future) - Performance acceleration
   - Why: O(n²) algorithms need speed
   - Family resemblance clustering
   - Graph layout algorithms

### NOT Using

- ❌ JavaScript (minimized - ReScript compiles to it)
- ❌ webpack/rollup (Deno bundles natively)
- ❌ npm/Node.js (Deno only)
- ❌ External NLP libraries (yet - keeping it pure for now)

## Setup

### Prerequisites

- [Deno](https://deno.land/) >= 1.40
- [Node.js](https://nodejs.org/) >= 18 (for ReScript compiler only)
- [ReScript](https://rescript-lang.org/) >= 11.0

### Installation

```bash
# Clone repository
git clone https://github.com/your-username/fogbinder
cd fogbinder

# Install ReScript
npm install

# Build
npm run build

# Run tests
deno task test

# Run examples
deno run --allow-all examples/basic_usage.ts
```

## Development Workflow

### File Organization

**ReScript modules** (`*.res`)
- Live in `src/`
- Compile to `*.bs.js` files (in-source)
- Strong type system enforces philosophical commitments

**TypeScript files** (`*.ts`)
- Entry points and external API
- Import compiled ReScript modules
- Provide familiar interface for consumers

**JavaScript shims** (`*.js`)
- Minimal - only for Zotero API bindings
- Should be replaced with ReScript bindings when possible

### Build Process

```bash
# Development build (watch mode)
npm run dev

# Production build
npm run build

# Build steps:
# 1. Compile ReScript → JavaScript (.bs.js)
# 2. Bundle with Deno
# 3. Generate TypeScript definitions
# 4. Copy assets
```

### Testing

```bash
# Run all tests
deno task test

# Run specific test
deno test src/core/EpistemicState.test.ts

# Watch mode
deno test --watch
```

**Testing strategy:**
- Unit tests for core modules (ReScript)
- Integration tests for engines
- End-to-end tests for full pipeline
- No mocking - test real behavior

### Linting & Formatting

```bash
# Format code
deno fmt

# Lint code
deno lint

# ReScript format
npx rescript format

# Type check
npx rescript build
```

## ReScript Development

### Type-Driven Design

Fogbinder's architecture is **type-first**. Types encode philosophical commitments.

**Example:** `EpistemicState.certainty` is NOT Bayesian probability.

```rescript
// WRONG (Bayesian):
type certainty = float  // 0.0-1.0 probability

// RIGHT (Wittgensteinian):
type certainty =
  | Known
  | Probable(float)
  | Vague
  | Ambiguous(array<string>)
  | Mysterious
  | Contradictory(array<string>)
```

### Pattern Matching

Use exhaustive pattern matching to handle all cases:

```rescript
let analyzeState = (state: EpistemicState.t): string => {
  switch state.certainty {
  | Known => "Clear"
  | Probable(p) => `${Belt.Float.toString(p * 100.0)}% confident`
  | Vague => "Fuzzy boundaries"
  | Ambiguous(interps) => `${Belt.Int.toString(Js.Array2.length(interps))} interpretations`
  | Mysterious => "Resists reduction"
  | Contradictory(conflicts) => "Language game conflict"
  }
}
```

### Avoid `any` / `'a` (generics)

Be specific. Generics hide philosophical commitments.

```rescript
// WRONG:
let analyze: 'a => 'b  // What does this even mean?

// RIGHT:
let analyze: (~sources: array<string>, ~context: languageGame) => analysisResult
```

### Documentation

All public functions MUST have comments:

```rescript
/**
 * Detect if two speech acts contradict
 * NOTE: This is NOT logical contradiction!
 * We detect language game conflicts (Wittgenstein)
 */
let detectContradiction: (SpeechAct.t, SpeechAct.t) => option<contradiction>
```

## TypeScript Development

### Type Definitions

Keep TypeScript types in sync with ReScript:

```typescript
// main.ts
export interface AnalysisResult {
  contradictions: any[];  // TODO: Better types from gentype
  moods: any[];
  // ...
}
```

**Future:** Use ReScript's `gentype` for automatic type generation.

### Minimal JS

Keep TypeScript layer thin:

```typescript
// WRONG (logic in TypeScript):
export function analyze(sources: string[]) {
  const result = { /* complex logic */ };
  return result;
}

// RIGHT (delegate to ReScript):
export function analyze(sources: string[], context: LanguageGame) {
  return Fogbinder.analyze(sources, context, undefined);
}
```

## Adding New Features

### 1. Define Types (ReScript)

```rescript
// src/core/NewConcept.res

type newType = {
  field1: string,
  field2: option<int>,
}

type t = newType

let make = (~field1, ~field2=?, ()): t => {
  { field1, field2 }
}
```

### 2. Implement Logic (ReScript)

```rescript
let analyze = (data: t): result => {
  // Implementation
}
```

### 3. Add Tests

```typescript
// src/core/NewConcept.test.ts

import * as NewConcept from './NewConcept.bs.js';
import { assertEquals } from "https://deno.land/std@0.208.0/assert/mod.ts";

Deno.test("NewConcept - basic functionality", () => {
  const instance = NewConcept.make("test", undefined, undefined);
  assertEquals(instance.field1, "test");
});
```

### 4. Expose TypeScript API (if needed)

```typescript
// main.ts

export function newFeature(input: string) {
  return NewConcept.analyze(input);
}
```

### 5. Document

- Add to `API.md`
- Add example to `examples/`
- Update `README.md` if user-facing

## Performance Optimization

### Current Performance

- Small collections (<100): <100ms
- Medium collections (100-1000): <1s
- Large collections (>1000): TBD

### Hot Paths

1. **Family resemblance clustering** - O(n²) pairwise comparisons
2. **Graph layout** - Force-directed layout for FogTrail
3. **Pattern matching** - Speech act detection

### WASM Candidates

```rescript
// CANDIDATE for WASM:
let resemblanceStrength = (item1: string, item2: string, family: t): float => {
  // O(n²) algorithm - good candidate for WASM
}
```

### Profiling

```bash
# Deno has built-in profiling
deno test --allow-all --v8-flags=--prof

# Analyze profile
deno run --allow-all --v8-flags=--prof-process isolate-*.log
```

## Common Pitfalls

### 1. Over-Formalization

**Problem:** Trying to formalize everything

```rescript
// WRONG:
type meaning =
  | Referential(object)
  | Functional(inputType => outputType)

// RIGHT:
type meaning =
  | UseInLanguageGame(languageGame)  // Wittgenstein would approve
```

**Fix:** Remember the philosophy - not everything reduces to logic.

### 2. Ignoring Context

**Problem:** Analyzing texts without language game context

```rescript
// WRONG:
let analyze = (text: string) => { /* ... */ }

// RIGHT:
let analyze = (~text: string, ~context: languageGame) => { /* ... */ }
```

**Fix:** Context is not optional - it's constitutive of meaning.

### 3. Treating Ambiguity as Error

**Problem:** Rushing to resolve ambiguity

```rescript
// WRONG:
let disambiguate = (ambiguous: array<string>): string => {
  Js.Array2.unsafe_get(ambiguous, 0)  // Pick first?!
}

// RIGHT:
let explore = (ambiguous: array<string>): analysis => {
  { interpretations: ambiguous, resolution: None }
}
```

**Fix:** Ambiguity is a feature, not a bug.

### 4. Brittle Type Casts

**Problem:** Using `Obj.magic` or unsafe operations

```rescript
// WRONG:
let hack = Obj.magic(value)

// RIGHT:
// Redesign types to avoid need for unsafe operations
```

**Fix:** If you need `Obj.magic`, your types are wrong.

## Debugging

### ReScript Debugging

```bash
# Check compiled output
cat src/core/EpistemicState.bs.js

# Type errors are your friend
npx rescript build
```

### Deno Debugging

```bash
# Run with inspector
deno run --inspect-brk --allow-all src/main.ts

# Connect Chrome DevTools to localhost:9229
```

### Logging

```rescript
// ReScript logging
Js.log("Debug message")
Js.log2("Variable:", value)

// TypeScript logging
console.log("Debug message");
console.dir(object, { depth: null });
```

## Contributing

### Git Workflow

```bash
# Create feature branch
git checkout -b feature/new-concept

# Make changes
# ...

# Run tests
deno task test

# Commit
git commit -m "Add NewConcept module for X"

# Push
git push origin feature/new-concept
```

### Commit Messages

Follow Conventional Commits:

```
feat: Add mystery clustering algorithm
fix: Correct speech act felicity conditions
docs: Update PHILOSOPHY.md with Austin references
refactor: Simplify family resemblance types
test: Add tests for contradiction detection
```

### Code Review Checklist

- [ ] Types accurately represent philosophical concepts
- [ ] All pattern matches are exhaustive
- [ ] Tests cover core functionality
- [ ] Documentation updated
- [ ] No `Obj.magic` or unsafe operations
- [ ] Accessibility maintained (if UI changes)
- [ ] Build succeeds
- [ ] Examples still work

## Resources

### ReScript

- [ReScript Language Manual](https://rescript-lang.org/docs/manual/latest/introduction)
- [ReScript Forum](https://forum.rescript-lang.org/)
- [Belt stdlib docs](https://rescript-lang.org/docs/manual/latest/api/belt)

### Deno

- [Deno Manual](https://deno.land/manual)
- [Deno Standard Library](https://deno.land/std)
- [Deno Deploy](https://deno.com/deploy)

### Philosophy

- See [PHILOSOPHY.md](./PHILOSOPHY.md)

## License

GNU AGPLv3 - See [LICENSE](./LICENSE)

All contributions must be compatible with AGPLv3.

---

**Maintainer:** Jonathan
**Version:** 0.1.0
**Last Updated:** 2025-11-21
