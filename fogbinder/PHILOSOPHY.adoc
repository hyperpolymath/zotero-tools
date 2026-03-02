# Philosophical Foundations of Fogbinder

## Introduction

Fogbinder is not merely a technical tool - it embodies a specific philosophical stance toward knowledge, language, and uncertainty. This document explains the theoretical foundations that inform every design decision.

## Core Philosophical Framework

### Late Wittgenstein: Language Games and Family Resemblance

**Philosophical Investigations** (1953) marks a radical departure from the early Wittgenstein of the *Tractatus*. The later Wittgenstein abandons the picture theory of meaning for a view of language as embedded in forms of life.

#### Key Concepts Implemented in Fogbinder:

1. **Language Games** (`src/core/EpistemicState.res`)
   - Meaning is not fixed correspondence to reality
   - Meaning emerges from use in specific contexts
   - Different "games" have different rules
   - Implementation: Every epistemic state has a `languageGame` context

2. **Family Resemblance** (`src/core/FamilyResemblance.res`)
   - No strict necessary/sufficient conditions for concepts
   - Overlapping similarities, like family members
   - Boundaries are deliberately vague
   - Implementation: Clustering without rigid definitions

3. **Showing vs. Saying** (Tractatus 7)
   - Some things cannot be said, only shown
   - Mystery is not ignorance, but ineffability
   - Implementation: `MysteryClustering` distinguishes linguistic resistance

**Relevant Passages:**

> "For a large class of cases—though not for all—in which we employ the word 'meaning' it can be defined thus: the meaning of a word is its use in the language." (PI §43)

> "Don't think, but look!" (PI §66) - On family resemblances

> "What we cannot speak about we must pass over in silence." (Tractatus 7) - But also *show*

### J.L. Austin: Speech Act Theory

**How to Do Things With Words** (1962) revolutionized philosophy of language by showing that utterances *do* things, not just describe things.

#### Key Concepts Implemented in Fogbinder:

1. **Illocutionary Force** (`src/core/SpeechAct.res`)
   - Utterances have force: asserting, commanding, promising, etc.
   - "Mood" is not sentiment - it's what you're *doing* with words
   - Implementation: `illocutionaryForce` type with five categories

2. **Felicity Conditions** (`src/core/SpeechAct.res`)
   - Speech acts can be "happy" (felicitous) or "unhappy" (infelicitous)
   - Success depends on conventions, context, sincerity
   - Implementation: `felicityConditions` record

3. **Performative vs. Constative** (`src/core/SpeechAct.res`)
   - Some utterances *perform* actions (declarations, promises)
   - Others *state* facts (assertions)
   - Implementation: `performative` boolean flag

**Relevant Passages:**

> "To say something is to do something." (Austin, p. 94)

> "The total speech act in the total speech situation is the only actual phenomenon which, in the last resort, we are engaged in elucidating." (Austin, p. 148)

## Why This Matters for Research Tools

### Traditional Citation Managers (Zotero, Mendeley, etc.)

**Assumption:** Knowledge is accumulation of facts
**Model:** Citations as data points
**Goal:** Organize and retrieve

### Fogbinder's Departure

**Assumption:** Knowledge is navigating ambiguity
**Model:** Citations as moves in language games
**Goal:** Illuminate uncertainty, contradiction, ineffability

## Epistemic Modalities

Fogbinder models six epistemic states:

1. **Known** - Clear, unambiguous (rare in actual research)
2. **Probable** - Statistical confidence (frequentist)
3. **Vague** - Fuzzy boundaries (Wittgenstein's family resemblance)
4. **Ambiguous** - Multiple valid interpretations (language games)
5. **Mysterious** - Resists factual reduction (ineffable)
6. **Contradictory** - Conflicting language games

### Why Not Just "Uncertain"?

Traditional epistemology collapses these into "uncertainty" or "lack of knowledge." Fogbinder treats each as a *positive feature* of inquiry:

- **Vagueness** is not imprecision - it's how concepts actually work
- **Ambiguity** is not confusion - it's multiple coherent interpretations
- **Mystery** is not ignorance - it's what resists propositional knowledge

## Contradiction Detection

### Not Logical Contradiction

Fogbinder does **not** detect logical contradiction (¬(P ∧ ¬P)).

Instead, it detects **language game conflicts**:
- Same words used in different games
- Incommensurable frameworks (Kuhn, Feyerabend)
- Context-dependent ambiguity

**Example:**

> "Light is a wave" (19th century optics)
> "Light is a particle" (quantum mechanics)

Not a logical contradiction - different language games.

**Implementation:** `src/engine/ContradictionDetector.res`

## Mood Scoring

### Not Sentiment Analysis

Fogbinder does **not** do sentiment analysis (positive/negative/neutral).

Instead, it analyzes **illocutionary force**:
- What is the speaker *doing* with these words?
- Asserting? Directing? Expressing? Declaring? Committing?

**Example:**

> "I promise to finish this paper."

Not neutral sentiment - it's a **commissive** speech act that creates an obligation.

**Implementation:** `src/engine/MoodScorer.res`

## Mystery Clustering

### Not Missing Data

Fogbinder does **not** treat mystery as missing information.

Instead, it categorizes **types of epistemic resistance**:
- **Conceptual** - Resists clear definition
- **Evidential** - Resists empirical verification
- **Logical** - Resists formalization
- **Linguistic** - Resists expression (ineffable)

**Example:**

> "What is it like to be a bat?" (Nagel)

Not a gap in zoological knowledge - linguistic/conceptual resistance.

**Implementation:** `src/engine/MysteryClustering.res`

## FogTrail Visualization

### Not a Knowledge Graph

FogTrail is **not** a knowledge graph (entities + relations).

Instead, it's a **network of epistemic opacity**:
- Nodes: Sources, concepts, mysteries, contradictions
- Edges: Supports, contradicts, resembles, mystifies
- Metrics: Fog density, opacity, ambiguity

**Goal:** Show how research "clouds, contradicts, and clears"

**Implementation:** `src/engine/FogTrailVisualizer.res`

## Relationship to NSAI

### NSAI: Tractatus Wittgenstein
- World of facts
- Propositions picture reality
- Logic is universal
- Verification and validation

### Fogbinder: Investigations Wittgenstein
- World of language games
- Meaning is use in context
- Logic is one game among many
- Navigation of ambiguity

### Complementary, Not Contradictory

NSAI validates claims. Fogbinder explores uncertainty.

Like early vs. late Wittgenstein - not a contradiction, but different projects.

## Practical Implications

### For Users

1. **Embrace Contradiction**
   - Don't rush to resolve conflicts
   - Explore what different language games reveal

2. **Recognize Vagueness**
   - Concepts don't need sharp boundaries
   - Family resemblances are how we actually think

3. **Value Mystery**
   - Not everything reduces to facts
   - Some questions are invitations to wonder

### For Developers

1. **No Universal Metrics**
   - Context determines what counts as "good"
   - Different language games, different success criteria

2. **Types Encode Philosophy**
   - ReScript types embody epistemic commitments
   - `EpistemicState.certainty` is not Bayesian probability

3. **Resist Over-Formalization**
   - Not everything needs to be algorithmic
   - Some patterns are shown, not computed

## Further Reading

### Primary Sources

- Wittgenstein, L. (1953). *Philosophical Investigations*. Blackwell.
- Wittgenstein, L. (1921). *Tractatus Logico-Philosophicus*. Routledge.
- Austin, J.L. (1962). *How to Do Things With Words*. Harvard University Press.
- Austin, J.L. (1956). "A Plea for Excuses". *Proceedings of the Aristotelian Society*.

### Secondary Sources

- Baker, G.P. & Hacker, P.M.S. (1980). *Wittgenstein: Understanding and Meaning*. Blackwell.
- Cavell, S. (1979). *The Claim of Reason*. Oxford University Press.
- Hacker, P.M.S. (1996). *Wittgenstein's Place in Twentieth-Century Analytic Philosophy*. Blackwell.
- Searle, J.R. (1969). *Speech Acts*. Cambridge University Press.

### Related Philosophical Traditions

- **Ordinary Language Philosophy** - Ryle, Strawson, Grice
- **Pragmatism** - Peirce, James, Dewey (influence on late Wittgenstein)
- **Phenomenology** - Husserl, Heidegger (alternative to analytic tradition)
- **Kuhn/Feyerabend** - Incommensurability of paradigms

## Conclusion

Fogbinder is an experiment in taking late Wittgenstein and Austin seriously in software design. If meaning is use, then research tools should help us navigate *contexts* of use. If language does things, then citations are not just data but *moves* in scholarly conversation.

The fog is not an obstacle. It's the medium of inquiry.

---

**Author:** Jonathan
**License:** GNU AGPLv3
**Version:** 0.1.0 (Philosophical foundations stable, implementation experimental)
