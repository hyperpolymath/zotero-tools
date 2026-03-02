# Fogbinder Intermediate Cookbook

**Working with Core Concepts and Integrations**
Last updated: 2025-11-23

This cookbook contains intermediate recipes for users familiar with basic Fogbinder analysis.

---

## Table of Contents

1. [Zotero Integration](#recipe-1-zotero-integration)
2. [Epistemic States](#recipe-2-epistemic-states)
3. [Speech Acts](#recipe-3-speech-acts)
4. [Mood Scoring](#recipe-4-mood-scoring)

---

## Recipe 1: Zotero Integration

**Difficulty:** Intermediate
**Time:** 15 minutes
**Prerequisites:** Basic Fogbinder analysis, Zotero installed

### Overview

Learn how to extract citations from Zotero collections and analyze them with Fogbinder, then save results back to Zotero as tags and notes.

### Code

```typescript
import * as ZoteroBindings from './src/zotero/ZoteroBindings.bs.js';
import * as Fogbinder from './src/Fogbinder.bs.js';
import * as FogTrailVisualizer from './src/engine/FogTrailVisualizer.bs.js';

async function analyzeZoteroCollection(collectionId: string) {
  // 1. Fetch all collections
  const collections = await ZoteroBindings.getCollections();

  // 2. Find your target collection
  const collection = collections.find(c => c.id === collectionId);

  if (!collection) {
    throw new Error("Collection not found");
  }

  // 3. Extract citation text from all items
  const citations = ZoteroBindings.extractCitations(collection);
  console.log(`Extracted ${citations.length} citations`);

  // 4. Define analysis context based on collection
  const context = {
    domain: collection.name,
    conventions: ["academic"],
    participants: ["researchers"],
    purpose: "Literature review"
  };

  // 5. Run Fogbinder analysis
  const result = Fogbinder.analyze(citations, context, undefined);

  // 6. Tag items with analysis results
  if (result.contradictions.length > 0) {
    // Tag all items in collections with contradictions
    for (const item of collection.items) {
      await ZoteroBindings.tagWithAnalysis(item.id, "contradiction");
    }
  }

  if (result.mysteries.length > 0) {
    for (const item of collection.items) {
      await ZoteroBindings.tagWithAnalysis(item.id, "mystery");
    }
  }

  // 7. Create FogTrail visualization
  const trail = FogTrailVisualizer.buildFromAnalysis(
    collection.name,
    citations,
    result.contradictions,
    result.mysteries,
    undefined
  );

  // 8. Export as SVG
  const svg = FogTrailVisualizer.toSvg(trail, 1200, 800, undefined);

  // 9. Save visualization as Zotero note
  await ZoteroBindings.createFogTrailNote(
    collection.items[0].id,
    svg
  );

  return {
    citations,
    result,
    trail
  };
}

// Usage
const collectionId = "YOUR_COLLECTION_ID";
analyzeZoteroCollection(collectionId).then(({ result }) => {
  console.log("Analysis complete!");
  console.log("Contradictions:", result.contradictions.length);
  console.log("Mysteries:", result.mysteries.length);
  console.log("Check Zotero for tags and FogTrail note");
});
```

### Key Points

- **Tags format:** `fogbinder:{analysisType}` (e.g., `fogbinder:contradiction`)
- **Notes:** FogTrail SVG visualizations are saved as HTML notes
- **Collection context:** Use collection name as domain for relevant analysis
- **Batch processing:** Process multiple collections by iterating over collection IDs

### See Also

- [Recipe 4: FogTrail Visualization (Advanced)](./ADVANCED_COOKBOOK.md#recipe-3-fogtrail-visualization)

---

## Recipe 2: Epistemic States

**Difficulty:** Intermediate
**Time:** 10 minutes
**Prerequisites:** Understanding of uncertainty types

### Overview

Model different types of uncertainty and ambiguity using Fogbinder's epistemic state system.

### The Six Epistemic States

1. **Known** - Confident, well-established facts
2. **Probable** - Likely but not certain (with probability)
3. **Vague** - Unclear or imprecise
4. **Ambiguous** - Multiple valid interpretations (4+)
5. **Mysterious** - Fundamentally resistant to explanation
6. **Contradictory** - Self-contradicting claims

### Code Examples

```typescript
import * as EpistemicState from './src/core/EpistemicState.bs.js';

const context = {
  domain: "Quantum Mechanics",
  conventions: ["Copenhagen interpretation"],
  participants: ["physicists"],
  purpose: "Understanding measurement"
};

// Example 1: Known state
const knownState = EpistemicState.make(
  { TAG: "Known" },
  context,
  ["Wave function collapses upon measurement"],
  undefined
);

console.log("Is known state uncertain?", EpistemicState.isUncertain(knownState));
// Output: false

// Example 2: Probable state (with 75% confidence)
const probableState = EpistemicState.make(
  { TAG: "Probable", _0: 0.75 },
  context,
  ["Decoherence explains apparent collapse"],
  undefined
);

// Example 3: Vague state
const vagueState = EpistemicState.make(
  { TAG: "Vague" },
  context,
  ["The measurement process is somewhat unclear"],
  undefined
);

console.log("Is vague state uncertain?", EpistemicState.isUncertain(vagueState));
// Output: true

// Example 4: Ambiguous state (4+ interpretations required)
const ambiguousState = EpistemicState.make(
  { TAG: "Ambiguous", _0: [
    "Many-worlds interpretation",
    "Copenhagen interpretation",
    "Pilot wave theory",
    "Objective collapse theory"
  ]},
  context,
  ["Measurement has multiple explanations"],
  undefined
);

// Example 5: Mysterious state
const mysteriousState = EpistemicState.make(
  { TAG: "Mysterious" },
  context,
  ["What causes wave function collapse?"],
  undefined
);

// Example 6: Contradictory state
const contradictoryState = EpistemicState.make(
  { TAG: "Contradictory", _0: [
    "Measurement is observer-independent",
    "Measurement requires conscious observer"
  ]},
  context,
  ["Contradictory claims about measurement"],
  undefined
);

// Merging states
const merged = EpistemicState.merge(mysteriousState, probableState);
console.log("Merged certainty:", merged.certainty.TAG);
console.log("Combined evidence:", merged.evidence);
```

### Practical Applications

**1. Literature Review:** Track certainty levels across papers

```typescript
const papers = [
  { text: "Climate sensitivity is 2-4°C", certainty: { TAG: "Probable", _0: 0.8 } },
  { text: "Future trajectories remain unclear", certainty: { TAG: "Vague" } },
  { text: "Tipping points are poorly understood", certainty: { TAG: "Mysterious" } }
];

for (const paper of papers) {
  const state = EpistemicState.make(paper.certainty, context, [paper.text], undefined);
  console.log(`"${paper.text}"`);
  console.log(`  Uncertain: ${EpistemicState.isUncertain(state)}`);
}
```

**2. Argument Mapping:** Track how certainty evolves

```typescript
// Initial uncertain state
let currentState = EpistemicState.make(
  { TAG: "Mysterious" },
  context,
  ["Origin of life unknown"],
  undefined
);

// New evidence makes it ambiguous
const newEvidence = EpistemicState.make(
  { TAG: "Ambiguous", _0: ["RNA world", "Metabolism first", "Clay hypothesis", "Panspermia"] },
  context,
  ["Multiple competing hypotheses"],
  undefined
);

// Merge to update understanding
currentState = EpistemicState.merge(currentState, newEvidence);
```

### See Also

- [Recipe 3: Mystery Clustering (Advanced)](./ADVANCED_COOKBOOK.md#recipe-2-mystery-clustering)
- [PHILOSOPHY.md](../PHILOSOPHY.md) - Epistemic state theory

---

## Recipe 3: Speech Acts

**Difficulty:** Intermediate
**Time:** 10 minutes
**Prerequisites:** Understanding of pragmatics

### Overview

Use J.L. Austin's speech act theory to analyze what text is *doing* (not just saying).

### The Five Illocutionary Forces

1. **Assertive** - Stating facts, making claims
2. **Directive** - Commanding, requesting, instructing
3. **Commissive** - Promising, committing, pledging
4. **Expressive** - Expressing attitudes, emotions, gratitude
5. **Declaration** - Creating new states of affairs by saying them

### Code Examples

```typescript
import * as SpeechAct from './src/core/SpeechAct.bs.js';

const context = {
  domain: "Academic Discourse",
  conventions: ["peer review", "citation norms"],
  participants: ["researchers", "reviewers"],
  purpose: "Knowledge production"
};

// 1. Assertive (making claims)
const assertive = SpeechAct.make(
  "The results demonstrate a significant correlation.",
  { TAG: "Assertive", _0: "empirical claim" },
  context,
  undefined
);

console.log("Is assertive felicitous?", SpeechAct.isFelicitous(assertive));
// Felicity = did the speech act succeed in its purpose?

// 2. Commissive (making promises)
const commissive = SpeechAct.make(
  "We will replicate these findings in future work.",
  { TAG: "Commissive", _0: "research promise" },
  context,
  undefined
);

// 3. Directive (giving commands/requests)
const directive = SpeechAct.make(
  "Reviewers must disclose conflicts of interest.",
  { TAG: "Directive", _0: "ethical requirement" },
  context,
  undefined
);

// 4. Expressive (expressing attitudes)
const expressive = SpeechAct.make(
  "We thank the reviewers for their insightful comments.",
  { TAG: "Expressive", _0: "gratitude" },
  context,
  undefined
);

// 5. Declaration (creating reality through speech)
const declaration = SpeechAct.make(
  "I hereby declare this paper accepted for publication.",
  { TAG: "Declaration", _0: "editorial decision" },
  context,
  undefined
);

// Check for conflicts
const hasConflict = SpeechAct.conflicts(assertive, directive);
console.log("Do assertive and directive conflict?", hasConflict);
```

### Practical Applications

**1. Analyzing Academic Writing**

```typescript
const sentences = [
  { text: "Previous studies have shown...", force: "Assertive" },
  { text: "Researchers should consider...", force: "Directive" },
  { text: "We commit to open data sharing.", force: "Commissive" },
  { text: "This breakthrough is remarkable.", force: "Expressive" }
];

for (const s of sentences) {
  const act = SpeechAct.make(
    s.text,
    { TAG: s.force as any, _0: s.text },
    context,
    undefined
  );

  console.log(`"${s.text}"`);
  console.log(`  Force: ${s.force}`);
  console.log(`  Felicitous: ${SpeechAct.isFelicitous(act)}`);
}
```

**2. Detecting Rhetorical Shifts**

```typescript
const introduction = SpeechAct.make(
  "This paper argues that...",
  { TAG: "Assertive", _0: "thesis" },
  context,
  undefined
);

const conclusion = SpeechAct.make(
  "Future research must address...",
  { TAG: "Directive", _0: "research agenda" },
  context,
  undefined
);

if (SpeechAct.conflicts(introduction, conclusion)) {
  console.log("Rhetorical shift detected: Assertive → Directive");
}
```

### See Also

- [Recipe 4: Mood Scoring](#recipe-4-mood-scoring)
- [PHILOSOPHY.md](../PHILOSOPHY.md) - J.L. Austin's speech act theory

---

## Recipe 4: Mood Scoring

**Difficulty:** Intermediate
**Time:** 10 minutes
**Prerequisites:** Understanding speech acts

### Overview

Analyze the argumentative and emotional mood of text using speech act theory (NOT sentiment analysis).

### Key Difference: Mood vs. Sentiment

- **Sentiment analysis:** Positive/negative/neutral
- **Mood scoring:** What is the text *doing*? (asserting, commanding, expressing, etc.)

### Code Examples

```typescript
import * as MoodScorer from './src/engine/MoodScorer.bs.js';

const context = {
  domain: "Literary Criticism",
  conventions: ["close reading"],
  participants: ["critics", "scholars"],
  purpose: "Textual interpretation"
};

// Example 1: Assertive mood (stating facts/arguments)
const text1 = "The novel demonstrates a critique of industrial capitalism.";
const mood1 = MoodScorer.analyze(text1, context);

console.log("Mood:", MoodScorer.getDescriptor(mood1));
console.log("Primary force:", mood1.primary.TAG);  // "Assertive"
console.log("Confidence:", mood1.confidence);

// Example 2: Expressive mood (conveying emotion/attitude)
const text2 = "This passage evokes a profound sense of melancholy.";
const mood2 = MoodScorer.analyze(text2, context);

console.log("Mood:", MoodScorer.getDescriptor(mood2));
console.log("Emotional tone:", mood2.emotionalTone);  // "melancholic"

// Example 3: Directive mood (instructing readers)
const text3 = "Readers must consider the historical context.";
const mood3 = MoodScorer.analyze(text3, context);

console.log("Mood:", MoodScorer.getDescriptor(mood3));
console.log("Primary force:", mood3.primary.TAG);  // "Directive"

// Compare moods
const comparison = MoodScorer.compare(mood1, mood2);
console.log("Comparison:", comparison);
```

### Advanced Usage: Tracking Mood Across Document

```typescript
const paragraphs = [
  "The protagonist begins in a state of naïve optimism.",
  "Gradually, disillusionment sets in.",
  "By the end, cynicism pervades every interaction.",
  "Yet readers must resist simplistic interpretations."
];

console.log("Mood progression:\n");

for (let i = 0; i < paragraphs.length; i++) {
  const mood = MoodScorer.analyze(paragraphs[i], context);

  console.log(`Paragraph ${i + 1}:`);
  console.log(`  Text: "${paragraphs[i]}"`);
  console.log(`  Mood: ${MoodScorer.getDescriptor(mood)}`);
  console.log(`  Confidence: ${mood.confidence.toFixed(2)}`);

  if (mood.emotionalTone) {
    console.log(`  Emotional tone: ${mood.emotionalTone}`);
  }

  console.log();
}
```

### Emotional Tones

Fogbinder can detect these emotional tones:
- `melancholic` - Sad, sorrowful
- `enthusiastic` - Excited, energetic
- `skeptical` - Doubtful, questioning
- `neutral` - No strong emotion

### Felicity Conditions

A mood is "felicitous" if the speech act succeeds in its purpose:

```typescript
const promise = "I promise to finish this work.";
const mood = MoodScorer.analyze(promise, context);

if (mood.felicitous) {
  console.log("Promise is sincere and achievable");
} else {
  console.log("Promise may be insincere or impossible");
}
```

### See Also

- [Recipe 3: Speech Acts](#recipe-3-speech-acts)
- [Complete Cookbook](./COMPLETE_COOKBOOK.md#recipe-6-mood-scoring)

---

## Next Steps

Once you've mastered these intermediate recipes:

1. Move to [Advanced Cookbook](./ADVANCED_COOKBOOK.md) for contradiction detection, mystery clustering, and visualization
2. Try combining multiple recipes in [Full Pipeline (Advanced)](./ADVANCED_COOKBOOK.md#recipe-4-full-analysis-pipeline)
3. Explore [API Reference](../API.md) for complete function documentation

---

**License:** GNU AGPLv3
**Project:** Fogbinder v0.1.0
