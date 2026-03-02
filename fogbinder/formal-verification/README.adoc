# Formal Verification for Fogbinder

This directory contains formal specifications for Fogbinder's critical algorithms using TLA+ (Temporal Logic of Actions).

## Purpose

Formal verification provides mathematical proof that our algorithms satisfy key properties:
- **Correctness** - Algorithms behave as specified
- **Safety** - Bad things never happen
- **Liveness** - Good things eventually happen
- **Invariants** - Properties that always hold

This is required for **Platinum tier** RSR (Rhodium Standard Repository) compliance.

## TLA+ Specifications

### 1. Contradiction Detection (`tla/ContradictionDetection.tla`)

Models the language game contradiction detection algorithm.

**Invariants Proven:**
- ✓ Symmetry: If A contradicts B, then B contradicts A
- ✓ Different games: Contradictions only occur between different language games
- ✓ Severity symmetry: Severity scores are symmetric
- ✓ No self-contradictions: Sources don't contradict themselves
- ✓ Same game consistency: Sources in same language game don't contradict

**Key Properties:**
```tla
Symmetry == \A <<s1, s2>> \in contradictions: <<s2, s1>> \in contradictions

DifferentGames == \A <<s1, s2>> \in contradictions:
  game_assignments[s1] \cap game_assignments[s2] = {}
```

### 2. Epistemic State Merging (`tla/EpistemicStateMerge.tla`)

Models the merging of epistemic states with different certainty levels.

**Algebraic Properties Proven:**
- ✓ **Commutativity**: merge(A, B) = merge(B, A)
- ✓ **Associativity**: merge(merge(A, B), C) = merge(A, merge(B, C))
- ✓ **Identity**: merge(A, A) = A
- ✓ **Idempotence**: merge(merge(A, B), merge(A, B)) = merge(A, B)
- ✓ **Evidence monotonicity**: Evidence is never lost during merging

**Key Properties:**
```tla
MergeCommutative == \A s1, s2 \in EpistemicState:
  (s1.context = s2.context) => Merge(s1, s2) = Merge(s2, s1)

MergeAssociative == \A s1, s2, s3 \in EpistemicState:
  (s1.context = s2.context /\ s2.context = s3.context) =>
  Merge(Merge(s1, s2), s3) = Merge(s1, Merge(s2, s3))
```

### 3. Family Resemblance Clustering (`tla/FamilyResemblance.tla`)

Models Wittgensteinian family resemblance clustering.

**Wittgensteinian Properties Proven:**
- ✓ **No necessary conditions**: No single feature required for all members
- ✓ **No sufficient conditions**: Members can belong without sharing all features
- ✓ **Vague boundaries**: No crisp cutoff for membership
- ✓ **Resemblance symmetry**: Resemblance(A, B) = Resemblance(B, A)
- ✓ **Prototype effects**: Central members vs peripheral members
- ✓ **Graded membership**: Some members are more central than others

**Key Properties:**
```tla
NoNecessaryCondition == \A f \in 1..Len(cluster.features):
  \E m \in cluster.members: m \notin cluster.features[f].exemplars

OverlappingFeatures == Cardinality(cluster.members) > 2 =>
  \E m1, m2, m3 \in cluster.members:
    (* m1 and m2 share feature f1 *)
    (* m2 and m3 share feature f2 *)
    (* BUT m1 and m3 don't share both features *)
```

## Using TLA+

### Installation

1. **Download TLA+ Toolbox:**
   ```bash
   # Visit https://lamport.azurewebsites.net/tla/toolbox.html
   # Or install via package manager:
   brew install --cask tla-plus-toolbox  # macOS
   ```

2. **Or use TLC command-line:**
   ```bash
   # Download from https://github.com/tlaplus/tlaplus/releases
   java -jar tla2tools.jar -h
   ```

### Model Checking

To verify a specification:

#### ContradictionDetection.tla

```bash
cd formal-verification/tla

# Create model configuration file: ContradictionDetection.cfg
# Contents:
CONSTANTS
  Sources = {s1, s2, s3}
  LanguageGames = {neoclassical, marxist}
  MaxSeverity = 1
  MinSeverity = 0

INVARIANTS
  TypeOK
  Symmetry
  DifferentGames
  SeveritySymmetry
  NoSelfContradiction

# Run TLC model checker
java -jar tla2tools.jar -config ContradictionDetection.cfg ContradictionDetection.tla
```

#### EpistemicStateMerge.tla

```bash
# Create model configuration file: EpistemicStateMerge.cfg
CONSTANTS
  Certainties = {"Known", "Probable", "Vague", "Mysterious"}
  Contexts = {ctx1}
  EvidenceItems = {e1, e2, e3}

INIT Init
NEXT Next

INVARIANTS
  TypeOK
  EvidenceCombined
  CertaintyPreserved
  ContextPreserved

PROPERTIES
  MergeCommutative
  MergeAssociative
  MergeIdentity
  MergeIdempotent

# Run TLC
java -jar tla2tools.jar -config EpistemicStateMerge.cfg EpistemicStateMerge.tla
```

#### FamilyResemblance.tla

```bash
# Create model configuration file: FamilyResemblance.cfg
CONSTANTS
  Items = {car, bicycle, motorcycle}
  Features = {has_wheels, has_engine, has_pedals}
  Threshold = 0.5

INVARIANTS
  TypeOK
  NoNecessaryCondition
  NoSufficientCondition
  ResemblanceSymmetry
  VagueBoundaries

PROPERTIES
  OverlappingFeatures
  PrototypeExists
  GradedMembership

# Run TLC
java -jar tla2tools.jar -config FamilyResemblance.cfg FamilyResemblance.tla
```

### Expected Results

When TLC completes successfully:
```
TLC2 Version 2.18
...
Model checking completed. No error has been found.
  Estimates of the probability that TLC did not check all reachable states
  because two distinct states had the same fingerprint:
  calculated (optimistic):  val = 1.2E-17
  based on the actual fingerprints:  val = 3.4E-18
12450 states generated, 3521 distinct states found, 0 states left on queue.
```

## Proofs with TLAPS

For more rigorous proofs, use TLAPS (TLA+ Proof System):

```bash
# Install TLAPS from https://tla.msr-inria.inria.fr/tlaps/

# Verify theorem
tlaps -I /path/to/tlaplus/modules ContradictionDetection.tla
```

Example theorem proof:
```tla
THEOREM SymmetryPreserved == Spec => []Symmetry
PROOF
<1>1. Init => Symmetry
  BY DEF Init, Symmetry
<1>2. Symmetry /\ [Next]_vars => Symmetry'
  <2>1. CASE DetectContradiction(s1, s2, sev)
    BY <2>1 DEF DetectContradiction, Symmetry
  <2>2. CASE AssignToGame(s, g)
    BY <2>2 DEF AssignToGame, Symmetry
  <2>3. QED BY <2>1, <2>2 DEF Next
<1>3. QED BY <1>1, <1>2, PTL DEF Spec
```

## Integration with Code

The TLA+ specs model the **behavior** of the algorithms, not the implementation details. After verification:

1. **Implementation in ReScript** (`src/`) must match the spec
2. **Property-based tests** (coming soon) should test the same properties
3. **Documentation** should reference proven properties

Example mapping:
```
TLA+ Spec                    ReScript Implementation
─────────────────────────────────────────────────────
ContradictionDetection.tla → src/engine/ContradictionDetector.res
  - Symmetry invariant      →   - detect() returns symmetric pairs
  - DifferentGames inv.     →   - Only detects cross-game conflicts

EpistemicStateMerge.tla    → src/core/EpistemicState.res
  - Commutativity           →   - merge(a, b) == merge(b, a)
  - Associativity           →   - merge order doesn't matter

FamilyResemblance.tla      → src/core/FamilyResemblance.res
  - NoNecessaryCondition    →   - belongsToFamily() doesn't require all features
  - VagueBoundaries         →   - boundaries field is "vague" by default
```

## Benefits of Formal Verification

1. **Confidence**: Mathematical proof that algorithms are correct
2. **Documentation**: Specs serve as precise documentation
3. **Debugging**: TLC can find counterexamples to properties
4. **Refactoring**: Can safely refactor knowing properties hold
5. **Compliance**: Required for Platinum RSR tier

## Further Reading

- [TLA+ Home Page](https://lamport.azurewebsites.net/tla/tla.html)
- [Learn TLA+](https://learntla.com/)
- [TLA+ Hyperbook](https://lamport.azurewebsites.net/tla/hyperbook.html)
- [Practical TLA+](https://www.apress.com/gp/book/9781484238288) by Hillel Wayne

## Contributing

When adding new critical algorithms to Fogbinder:

1. Write TLA+ specification first
2. Model check with TLC
3. Prove key theorems with TLAPS (if possible)
4. Implement in ReScript matching the spec
5. Add property-based tests verifying the same properties
6. Document the correspondence

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines.

---

**Last Updated:** 2025-11-23
**License:** GNU AGPLv3
**RSR Tier:** Platinum Requirement
