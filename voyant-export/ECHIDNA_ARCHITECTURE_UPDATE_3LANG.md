# ECHIDNA Architecture Update: 3-Language Stack

<!-- SPDX-License-Identifier: MIT AND Palimpsest-0.6 -->

**Date:** 2025-12-27
**Change:** Dropped Mercury/Logtalk "logic reservoir" concept
**Result:** 3 core languages (down from 4)
**Rationale:** True neurosymbolic integration instead of adding non-neural logic programming

---

## Decision: Drop Mercury/Logtalk

### Problems Identified

❌ **Not neurosymbolic** - Pure logic programming, no neural component
❌ **Redundant** - 12 provers already do proof search/tactics
❌ **Small community** - ~100s of users, maintenance risk
❌ **Language bloat** - Adds complexity for marginal gain
❌ **Wrong abstraction** - Overlaps with prover-specific tactics (Lean, Isabelle)

### Better Alternatives (Already Planned!)

✅ **DeepProbLog** - Actually neurosymbolic (neural + probabilistic logic), trainable
✅ **Prover tactics** - Lean 4 metaprogramming, Isabelle Sledgehammer, Coq Ltac
✅ **GNN + Aspect Tagging** - Already provides intelligent routing
✅ **OpenCyc** - Common-sense reasoning (already planned)

---

## Final Language Stack: 3 Languages

| # | Language | Purpose | Replaces | Justification |
|---|----------|---------|----------|---------------|
| 1 | **Julia 1.10+** | ML/GNN (Flux.jl, GraphNeuralNetworks.jl) | Python | ML ecosystem, FFI, already present |
| 2 | **Rust 1.75+** | Core, API, FFI, WASM, prover abstraction | Haskell, Zig, Ada, Mercury/Logtalk | Memory safety, speed, universal bridge |
| 3 | **ReScript 11+ → Deno 1.40+** | Type-safe UI, secure runtime | TypeScript, Node.js | Type safety without TS complexity |

**Total:** 3 languages (perfect!)

**Removed:** Python (user requirement), Haskell (Rust traits), Zig (Rust unsafe), Ada (Rust borrow checker), **Mercury/Logtalk (redundant with provers + DeepProbLog)**

---

## Neurosymbolic Architecture (Revised)

### What "Logic Reservoir" Should Actually Be

Instead of adding Mercury/Logtalk, use components we already have or planned:

```
┌─────────────────────────────────────────────────────────────────┐
│                  ECHIDNA NEUROSYMBOLIC LAYERS                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  NEURAL COMPONENT (Julia):                                     │
│  ├─ GNN (Flux.jl) - Learns proof patterns from dependency graphs│
│  ├─ DeepProbLog - Probabilistic logic + neural networks        │
│  └─ Embeddings - Similarity search (HNSW in Rust)              │
│                                                                 │
│  SYMBOLIC COMPONENT (Rust + External Provers):                 │
│  ├─ 12 Theorem Provers (Agda, Coq, Lean, Isabelle, HOL, etc.)  │
│  ├─ OpenCyc - Common-sense knowledge (239K concepts)           │
│  └─ Prover-specific tactics (Lean 4, Isabelle Sledgehammer)    │
│                                                                 │
│  BRIDGE (Rust):                                                │
│  ├─ Aspect Tagging - Intelligent routing (8 dimensions)        │
│  ├─ Innervation System - Weighted voting across modalities     │
│  └─ Universal IR - Prover-agnostic representation              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Key Insight

**We don't need another logic programming language.** We have:

1. **12 theorem provers** (already symbolic reasoning)
2. **DeepProbLog** (already probabilistic logic + neural)
3. **GNN** (already learns patterns)
4. **Aspect tagging** (already routes intelligently)

Adding Mercury/Logtalk would just duplicate this with **pure logic** (no neural component).

---

## Optional: Scallop (If Needed)

**Scallop** - Differentiable Datalog (Rust-based)

**Pros:**
- ✅ **Truly neurosymbolic** - Gradients flow through logic
- ✅ **Rust-based** - Fits existing stack (not a new language!)
- ✅ **Active development** (2023-2025)
- ✅ **Differentiable proof search** - Learned heuristics

**Use Case:** If you need differentiable logic programming (beyond what DeepProbLog provides)

**Decision:** Optional - add only if needed. Start without it.

---

## Updated Neurosymbolic Components

### 1. DeepProbLog (Priority: High)

**What:** Probabilistic logic programming + neural networks (PyTorch)

**Use Cases:**
- Probabilistic premise selection
- Learning from successful proofs
- Ranking lemma suggestions by probability
- Analogical transfer between domains

**Implementation:**
```julia
# Julia ↔ DeepProbLog bridge (PyCall)
using PyCall

const deepproblog = pyimport("deepproblog")

function probabilistic_premise_selection(goal, candidates)
    # Define ProbLog program with neural predicates
    program = deepproblog.Program()

    # Neural predicate: similarity between goal and premise
    for candidate in candidates
        prob = neural_similarity(goal, candidate)
        program.add_clause("$prob::relevant($candidate)")
    end

    # Query and rank by probability
    results = program.query("relevant(X)")
    return sort(results, by=x->x.probability, rev=true)
end
```

**Timeline:** Month 4-5 (parallel with multi-prover work)

### 2. GNN + Aspect Tagging (Already Planned)

**GNN (Flux.jl):** Learns from dependency graphs across all 12 provers

**Aspect Tagging (Rust):** 8 dimensions:
- Difficulty: trivial → research-level
- Domain: algebra, logic, topology, etc.
- Reasoning: deductive, inductive, abductive
- Certainty: certain, probable, speculative
- Common sense: required, helpful, irrelevant
- Stochastic: deterministic, probabilistic
- Dependency: local, global, external
- Explainability: black-box, interpretable, formal

**Routing Logic:**
```rust
fn route_to_solver(aspects: &AspectTag) -> SolverChoice {
    match aspects {
        AspectTag { difficulty: Trivial, .. } => SolverChoice::SMT(Z3),
        AspectTag { common_sense: Required, .. } => SolverChoice::OpenCyc,
        AspectTag { stochastic: Probabilistic, .. } => SolverChoice::DeepProbLog,
        AspectTag { difficulty: Hard, .. } => SolverChoice::GNN,
        _ => SolverChoice::ProverSpecific(select_best_prover(aspects))
    }
}
```

### 3. Prover-Specific Tactics (Leverage What We Have)

**Lean 4:**
- Metaprogramming (custom tactics in Lean itself)
- `simp`, `rw`, `apply`, `exact` - automated reasoning
- 210K+ theorems in mathlib for learning

**Isabelle:**
- **Sledgehammer** - Calls external ATPs (E, Vampire, SPASS, CVC4, Z3)
- `auto`, `blast`, `force` - powerful automation
- Archive of Formal Proofs (AFP)

**Coq:**
- Ltac/Ltac2 - Tactic language
- `omega`, `ring`, `field` - decision procedures
- `auto`, `eauto` - proof search

**Why this is better than Mercury/Logtalk:**
- Already integrated with provers
- Domain-specific (designed for that prover)
- Mature, well-tested
- No new language to learn

---

## What We Removed vs. What We Kept

### ❌ Removed: Mercury/Logtalk "Logic Reservoir"

**Was supposed to:** Optimize proof pathways, recommend tactics

**Why removed:**
- Not neurosymbolic (pure logic)
- Redundant with prover tactics
- Small community
- Adds 5th language

### ✅ Kept/Strengthened: True Neurosymbolic Stack

**DeepProbLog:** Probabilistic logic + neural (trainable)
**GNN:** Learns patterns from all 12 provers
**Aspect Tagging:** Intelligent routing
**Prover Tactics:** Lean 4, Isabelle Sledgehammer, Coq Ltac
**OpenCyc:** Common-sense reasoning

---

## Architecture Comparison

### Before (4 languages + logic reservoir)

```
Julia (ML) + Rust (core) + ReScript/Deno (UI) + Mercury/Logtalk (logic)
                                                  ↑
                                              Not neural!
                                           Overlaps with provers
```

### After (3 languages + true neurosymbolic)

```
Julia (ML + DeepProbLog) + Rust (core + aspect tagging) + ReScript/Deno (UI)
      ↑                          ↑
   Neural + Logic            Intelligent routing
   (truly hybrid!)          (bridges neural + symbolic)

Connected to:
- 12 provers (symbolic)
- OpenCyc (common-sense)
- Prover tactics (automated reasoning)
```

---

## Benefits of This Change

1. **Fewer languages:** 3 instead of 4 (easier to maintain, hire for)
2. **True neurosymbolic:** DeepProbLog is trainable, Mercury/Logtalk was not
3. **Leverage provers:** Use Lean/Isabelle/Coq tactics instead of rebuilding
4. **Simpler architecture:** No need to bridge Rust ↔ Mercury/Logtalk
5. **Better community:** DeepProbLog has active research, Mercury has ~100 users
6. **More focused:** Neural-symbolic hybrid, not neural + symbolic + pure logic

---

## Implementation Priority

### Phase 1: Core (Months 2-4)
- ✅ Rust prover abstraction (12 provers)
- ✅ Julia GNN training
- ✅ Aspect tagging system

### Phase 2: Neurosymbolic (Months 4-6)
- ⭐ **DeepProbLog integration** (probabilistic premise selection)
- ⭐ **OpenCyc integration** (common-sense reasoning)
- ⭐ **Innervation layer** (weighted voting)

### Phase 3: Advanced (Months 7-12)
- Prover-specific tactic integration (Lean 4, Isabelle)
- User feedback loop (update DeepProbLog probabilities)
- **(Optional) Scallop** if differentiable logic needed

---

## Updated Technology Stack

### Core Languages (3)

| Language | Version | Purpose | Libraries |
|----------|---------|---------|-----------|
| **Julia** | 1.10+ | ML, GNN, DeepProbLog bridge | Flux.jl, GraphNeuralNetworks.jl, PyCall.jl |
| **Rust** | 1.75+ | Core, API, FFI, WASM, provers | Axum, Tokio, Serde, async-trait |
| **ReScript** | 11+ | Type-safe UI | React bindings |
| **Deno** | 1.40+ | Secure runtime | Built-in TypeScript |

### External Systems (Not Languages)

| System | Purpose | Interface |
|--------|---------|-----------|
| **12 Provers** | Symbolic reasoning | Subprocess, FFI |
| **DeepProbLog** | Probabilistic logic + neural | PyCall (Julia) |
| **OpenCyc** | Common-sense knowledge | HTTP API |
| **Scallop** | Differentiable Datalog (optional) | Rust crate |

---

## Migration from 4-Language Plan

### Old Plan (Rejected)
```
Julia + Rust + ReScript/Deno + Mercury/Logtalk
```

### New Plan (Adopted)
```
Julia + Rust + ReScript/Deno
```

### Changes to Documentation

Files that need updating (in correct repository):
- ✏️ `ECHIDNA_SIMPLIFIED_ARCHITECTURE.md` - Change from 4 to 3 languages
- ✏️ `ECHIDNA_PROJECT_SPEC.md` - Remove Mercury/Logtalk section
- ✏️ `ECHIDNA_PROJECT_STATUS.md` - Update language stack table
- ✏️ `README.md.quill-template` - Update tech stack

### Changes to Code

Files that need updating:
- ✏️ `echidna_provers.rs` - Remove Mercury/Logtalk prover references
- ✏️ `docker-compose.yml` - Remove `logic-reservoir` service
- ✏️ `.tool-versions` - Remove Mercury/Logtalk versions

---

## Conclusion

**Decision:** Drop Mercury/Logtalk entirely. Use 3-language stack.

**Rationale:**
- Mercury/Logtalk is **pure logic** (not neurosymbolic)
- We already have **12 provers** for symbolic reasoning
- We already have **DeepProbLog** for probabilistic logic + neural
- Prover-specific tactics (Lean, Isabelle, Coq) are more mature

**Result:**
- ✅ Simpler architecture (3 languages vs. 4)
- ✅ True neurosymbolic integration (not just symbolic)
- ✅ Easier to maintain and hire for
- ✅ Leverages existing prover ecosystems

**Next Step:** Update all architecture documents in correct repository to reflect 3-language stack.

---

**SPDX-License-Identifier: MPL-2.0-or-later
**Author:** Claude Code (Anthropic)
**Date:** 2025-12-27
