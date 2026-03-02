# Fogbinder Beginner's Cookbook

**Getting Started with Epistemic Ambiguity Analysis**
Last updated: 2025-11-23

This cookbook contains beginner-friendly recipes for using Fogbinder.

---

## Recipe: Basic Analysis

**Difficulty:** Beginner
**Time:** 5 minutes

### What You'll Learn

- How to perform a basic Fogbinder analysis
- Understanding language game contexts
- Interpreting analysis results

### What You'll Need

- Array of source texts (strings)
- Language game context (domain, conventions, participants, purpose)

### Instructions

**Step 1:** Import the Fogbinder module

```typescript
import * as Fogbinder from './src/Fogbinder.bs.js';
```

**Step 2:** Define your language game context

The context tells Fogbinder what "language game" your sources are playing. This is crucial because the same words can mean different things in different contexts.

```typescript
const context = {
  domain: "Philosophy of Mind",  // What field are you studying?
  conventions: ["phenomenological", "analytic"],  // What approaches are used?
  participants: ["philosophers", "cognitive scientists"],  // Who's involved?
  purpose: "Understanding consciousness"  // What's the goal?
};
```

**Step 3:** Prepare your sources

```typescript
const sources = [
  "Consciousness is fundamentally mysterious and may resist scientific explanation.",
  "Neural correlates provide a complete account of conscious experience.",
  "The hard problem of consciousness remains unsolved."
];
```

**Step 4:** Run the analysis

```typescript
const result = Fogbinder.analyze(sources, context, undefined);
```

**Step 5:** Inspect the results

```typescript
// See what contradictions were found
console.log("Contradictions:", result.contradictions);

// See what mysteries were identified
console.log("Mysteries:", result.mysteries);

// See the overall emotional/argumentative tone
console.log("Overall mood:", result.overallMood);

// See how certain/uncertain each source is
console.log("Epistemic states:", result.epistemicStates);
```

### Understanding the Results

**Epistemic States** tell you how certain or uncertain each source is:
- `Known`: Confident, factual claim
- `Probable`: Likely but not certain
- `Vague`: Unclear or imprecise
- `Ambiguous`: Multiple interpretations
- `Mysterious`: Fundamentally uncertain
- `Contradictory`: Self-contradictory

**Contradictions** are not just logical contradictions - they're language game conflicts. The same words might mean different things in different frameworks.

**Mysteries** are things that resist clear explanation. Fogbinder treats these as features, not bugs!

**Mood** is based on speech act theory (not sentiment). It tells you what the text is *doing* (asserting, commanding, promising, etc.), not just what it's saying.

### Complete Example

```typescript
import * as Fogbinder from './src/Fogbinder.bs.js';

// Define context
const context = {
  domain: "Climate Science",
  conventions: ["empirical", "peer-reviewed"],
  participants: ["climate scientists", "policymakers"],
  purpose: "Understanding climate change"
};

// Sources
const sources = [
  "Global temperatures have risen 1.1°C since pre-industrial times.",
  "Future warming trajectories remain highly uncertain.",
  "We must reduce emissions immediately.",
  "Economic models suggest gradual transition is more feasible."
];

// Analyze
const result = Fogbinder.analyze(sources, context, undefined);

// Print summary
console.log(`\nAnalyzed ${sources.length} sources`);
console.log(`Found ${result.contradictions.length} contradictions`);
console.log(`Identified ${result.mysteries.length} mysteries`);
console.log(`Overall mood: ${result.overallMood.primary.TAG}`);
```

### Tips for Beginners

1. **Start small**: Try analyzing 3-5 sources first
2. **Context matters**: Take time to define an accurate language game context
3. **Embrace uncertainty**: Contradictions and mysteries are valuable insights
4. **Experiment**: Try the same sources with different contexts and see how results change

### Common Mistakes

❌ **Don't:** Use generic context like "general" or "misc"
✅ **Do:** Be specific about domain, conventions, and participants

❌ **Don't:** Expect Fogbinder to resolve contradictions for you
✅ **Do:** Use contradictions as starting points for deeper analysis

❌ **Don't:** Treat mysteries as errors
✅ **Do:** Recognize that some things are genuinely mysterious

### Next Steps

Once you're comfortable with basic analysis:

1. Try [Epistemic States](../COMPLETE_COOKBOOK.md#recipe-3-epistemic-states) to understand uncertainty better
2. Explore [Speech Acts](../COMPLETE_COOKBOOK.md#recipe-4-speech-acts) to understand mood analysis
3. Move on to [Intermediate Cookbook](./INTERMEDIATE_COOKBOOK.md)

---

## Additional Resources

- [Complete Cookbook](./COMPLETE_COOKBOOK.md) - All 9 recipes
- [API Reference](../API.md) - Detailed API documentation
- [Philosophy Guide](../PHILOSOPHY.md) - Theoretical foundations
- [Development Guide](../DEVELOPMENT.md) - For contributors

---

**License:** GNU AGPLv3
**Project:** Fogbinder v0.1.0
