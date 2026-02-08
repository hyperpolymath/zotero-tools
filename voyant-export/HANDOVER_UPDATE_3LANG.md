# ECHIDNA Handover Update - 3-Language Architecture

## Critical Change Made

**Dropped Mercury/Logtalk from architecture** → Now **3 languages** (Julia, Rust, ReScript/Deno)

## Rationale

Mercury/Logtalk was:
- ❌ Not neurosymbolic (pure logic, no neural component)
- ❌ Redundant (12 provers already do proof search/tactics)
- ❌ Small community (~100 users)
- ❌ Added 5th language for minimal gain

## Better Alternatives (Already Planned)

✅ **DeepProbLog** - Actually neurosymbolic (neural + probabilistic logic), trainable
✅ **Prover tactics** - Lean 4 metaprogramming, Isabelle Sledgehammer, Coq Ltac
✅ **GNN + Aspect Tagging** - Intelligent routing across provers
✅ **OpenCyc** - Common-sense reasoning

## Final Stack

| Language | Purpose |
|----------|---------|
| **Julia** | ML/GNN (Flux.jl), DeepProbLog bridge |
| **Rust** | Core, API, FFI, WASM, all 12 prover plugins |
| **ReScript + Deno** | Type-safe UI, secure runtime |

**Optional (not a language):** Scallop (Rust crate) for differentiable Datalog if needed

## Files to Update in Correct Repo

1. `ECHIDNA_SIMPLIFIED_ARCHITECTURE.md` - Change 4 → 3 languages
2. `ECHIDNA_PROJECT_SPEC.md` - Remove Mercury/Logtalk section
3. `ECHIDNA_PROJECT_STATUS.md` - Update language table
4. `echidna_provers.rs` - No Mercury/Logtalk references
5. `README.md.quill-template` - Update tech stack

## Key Insight

We don't need another logic programming language. We have:
- **12 theorem provers** (symbolic reasoning)
- **DeepProbLog** (probabilistic logic + neural)
- **GNN** (learns patterns)
- **Prover tactics** (Lean 4, Isabelle, Coq automation)

This gives us **true neurosymbolic integration** without language bloat.

---

**See:** `ECHIDNA_ARCHITECTURE_UPDATE_3LANG.md` for detailed rationale
