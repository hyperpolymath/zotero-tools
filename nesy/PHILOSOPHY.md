# Philosophical Foundation: NSAI and the Tractarian Approach

## The Tractatus and Research Validation

NSAI is grounded in the logical atomism of Wittgenstein's *Tractatus Logico-Philosophicus*. The early Wittgenstein provides the perfect framework for validation because:

> **"What can be said at all can be said clearly, and what we cannot speak about we must pass over in silence."**
> — Tractatus, Preface

### Core Principles

#### 1. **The World is the Totality of Facts** (Tractatus 1.1)

In NSAI:
- A research library is a totality of **bibliographic facts**
- Each citation is an **atomic fact**: Author(s), Title, Year, Publisher, DOI, etc.
- Complex research claims are **molecular facts**: combinations of atomic citations

#### 2. **Logical Structure and Pictorial Form** (Tractatus 2-3)

Research metadata has **logical form**:
- A citation *pictures* a source
- Validation checks whether the picture matches reality
- Incomplete citations are **malformed pictures** (missing components)
- Contradictory metadata represents **impossible states of affairs**

#### 3. **The Limits of Language** (Tractatus 5-7)

**What NSAI CAN validate** (within language):
- Structural completeness (are required fields present?)
- Formal consistency (does the date format make sense?)
- Logical coherence (is Author X cited consistently across sources?)
- Referential integrity (does this DOI resolve?)

**What NSAI CANNOT validate** (beyond language) → **Fogbinder's domain**:
- Epistemic quality (is this source reliable?)
- Contradiction between claims (does Author X contradict Author Y?)
- Ambiguity of interpretation (what did the author *really* mean?)
- Mystery and uncertainty (what is unknown or unknowable here?)

## The NSAI-Fogbinder Division

### NSAI: The Sayable (Tractarian Certainty)

NSAI operates in the realm of **formal logic and structure**:

```
1. The research library consists of facts (citations)
2. Facts have logical structure (required fields)
3. We can verify structure formally
4. What can be verified, we validate
5. What cannot be verified formally → hand to Fogbinder
```

**NSAI's mandate**: Ensure the *logical scaffolding* is sound.

### Fogbinder: The Unsayable (Wittgensteinian Ambiguity)

Fogbinder explores what lies *beyond* formal validation:

```
6. Some facts contradict each other
7. Some sources have ambiguous mood/tone
8. Some claims cluster into mysteries
9. The FogTrail visualizes epistemic uncertainty
10. Whereof we cannot validate, thereof we must explore
```

**Fogbinder's mandate**: Navigate the *epistemic fog* beyond certainty.

## Tractarian Validation Logic

### Atomic Propositions

A **valid citation** is an atomic proposition:

```typescript
// Tractarian atomic fact
interface AtomicCitation {
  author: string[]      // Object (who)
  title: string         // Predicate (what)
  year: number          // Time (when)
  publisher?: string    // Source (where)
  doi?: string          // Reference (unique identifier)
}
```

**Validation** = checking that atomic facts have required structure.

### Molecular Propositions

Citations combine into **molecular facts** (research arguments):

```typescript
// Molecular fact: A bibliography
interface Bibliography {
  citations: AtomicCitation[]
  relationships: CitationRelation[]  // logical connectives
}
```

**NSAI validates**: Are the atoms well-formed? Are relationships consistent?

**Fogbinder explores**: What do the relationships *mean*? Do they contradict?

### Truth-Functional Analysis

NSAI performs **truth-functional validation**:

- **TRUE**: Citation is structurally complete and consistent
- **FALSE**: Citation is malformed or inconsistent
- **UNCERTAIN**: Citation is ambiguous → **hand to Fogbinder**

## The Ladder: From Certainty to Uncertainty

> **"My propositions serve as elucidations in the following way: anyone who understands me eventually recognizes them as nonsensical, when he has used them—as steps—to climb up beyond them."**
> — Tractatus 6.54

NSAI is the **ladder**:
1. First, we validate structure (formal certainty)
2. Then we recognize the limits of validation
3. Finally, we **climb beyond** into Fogbinder's domain (uncertainty)

NSAI doesn't claim to validate *truth* or *meaning*—only *form*.

## Shared Ontology: What NSAI Passes to Fogbinder

When NSAI completes validation, it produces:

```typescript
interface NSAIOutput {
  validated: ValidCitation[]        // What is certain
  incomplete: IncompleteCitation[]  // What is malformed
  uncertain: AmbiguousCitation[]    // What needs exploration

  // Handoff to Fogbinder
  fogbinderPayload: {
    certainFacts: ValidCitation[]   // The foundation
    uncertainRegions: UncertaintyMarker[]  // Where to explore
    contradictionHints: ContradictionPair[]  // Potential conflicts
  }
}
```

## Late Wittgenstein Anticipation

While NSAI starts with **Tractarian certainty**, we acknowledge it will naturally evolve toward **late Wittgensteinian concerns**:

- **Language games**: How do researchers actually *use* citations?
- **Family resemblance**: Not all citations have the same "essence"
- **Forms of life**: Different disciplines have different citation practices

This is *intentional*: NSAI establishes the formal foundation, knowing the real work (Fogbinder) lies in the messy, ambiguous, uncertain practices of actual research.

## Conclusion: The Division of Labor

**NSAI** (Early Wittgenstein):
- "The world is all that is the case" → Validate what *is the case*
- Formal logic, structural verification
- Clear, certain, propositional

**Fogbinder** (Late Wittgenstein):
- "Meaning is use" → Explore how sources are *used*
- Pragmatics, uncertainty, contradiction
- Ambiguous, uncertain, exploratory

Together, they form a complete research epistemology: **certainty as foundation, uncertainty as exploration**.

---

*"Whereof one can validate clearly, thereof NSAI will speak. Whereof validation fails, thereof Fogbinder must explore."*
