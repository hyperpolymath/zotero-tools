## Fogbinder API Documentation

Complete API reference for the Fogbinder epistemic analysis engine.

## Installation

```bash
# Clone repository
git clone https://github.com/your-username/fogbinder
cd fogbinder

# Install dependencies
npm install

# Build
npm run build

# Test
npm run test
```

## Quick Start

```typescript
import Fogbinder from './dist/fogbinder.js';

const sources = [
  "The meaning of a word is its use in the language.",
  "Meaning is determined by truth conditions.",
];

const context = {
  domain: "Philosophy of Language",
  conventions: ["academic discourse"],
  participants: ["philosophers"],
  purpose: "Understanding meaning",
};

const result = Fogbinder.analyze(sources, context);
console.log(Fogbinder.generateReport(result));
```

## Core Types

### LanguageGame

Represents a Wittgensteinian language game - context of use for utterances.

```typescript
interface LanguageGame {
  domain: string;        // Academic discipline, cultural context
  conventions: string[]; // Rules of use in this game
  participants: string[]; // Who's playing this game?
  purpose: string;       // What are they doing?
}
```

**Example:**

```typescript
const mathematicalGame: LanguageGame = {
  domain: "Mathematics",
  conventions: ["formal proof", "axiomatic reasoning"],
  participants: ["mathematicians", "logicians"],
  purpose: "Proving theorems",
};
```

### AnalysisResult

Complete analysis output from Fogbinder.

```typescript
interface AnalysisResult {
  contradictions: Contradiction[];
  moods: MoodScore[];
  mysteries: MysteryCluster[];
  fogTrail: FogTrail;
  metadata: {
    analyzed: number;          // Timestamp
    totalSources: number;
    totalContradictions: number;
    totalMysteries: number;
    overallOpacity: number;    // 0.0-1.0
  };
}
```

## Main Functions

### analyze()

Analyzes array of source texts for epistemic patterns.

```typescript
function analyze(
  sources: string[],
  context: LanguageGame
): AnalysisResult
```

**Parameters:**
- `sources` - Array of citation texts or research notes
- `context` - Language game context for analysis

**Returns:** Complete analysis result

**Example:**

```typescript
const sources = [
  "Consciousness is a biological phenomenon.",
  "Consciousness is irreducible to physical properties.",
  "The hard problem of consciousness remains mysterious.",
];

const context = {
  domain: "Philosophy of Mind",
  conventions: ["analytical philosophy"],
  participants: ["philosophers", "cognitive scientists"],
  purpose: "Understanding consciousness",
};

const result = analyze(sources, context);

// Access results
console.log(`Found ${result.contradictions.length} contradictions`);
console.log(`Overall opacity: ${result.metadata.overallOpacity}`);
```

### analyzeZoteroCollection()

Analyzes a Zotero collection by ID.

```typescript
async function analyzeZoteroCollection(
  collectionId: string
): Promise<AnalysisResult>
```

**Parameters:**
- `collectionId` - Zotero collection identifier

**Returns:** Promise resolving to analysis result

**Example:**

```typescript
const result = await analyzeZoteroCollection("coll_abc123");

// Automatically tags Zotero items with results
```

### generateReport()

Generates human-readable Markdown report.

```typescript
function generateReport(result: AnalysisResult): string
```

**Parameters:**
- `result` - Analysis result from `analyze()`

**Returns:** Markdown-formatted report

**Example:**

```typescript
const result = analyze(sources, context);
const report = generateReport(result);

console.log(report);
// # Fogbinder Analysis Report
//
// Analyzed: 2024-01-01T00:00:00.000Z
// Total Sources: 3
// Overall Epistemic Opacity: 0.67
//
// ## Contradictions (2)
// ...
```

### toJson()

Exports analysis to JSON format.

```typescript
function toJson(result: AnalysisResult): any
```

**Parameters:**
- `result` - Analysis result

**Returns:** JSON object

**Example:**

```typescript
const result = analyze(sources, context);
const json = toJson(result);

await Deno.writeTextFile("analysis.json", JSON.stringify(json, null, 2));
```

### generateVisualization()

Generates SVG visualization of FogTrail network.

```typescript
function generateVisualization(
  result: AnalysisResult,
  width?: number,
  height?: number
): string
```

**Parameters:**
- `result` - Analysis result
- `width` - Canvas width (default: 1000)
- `height` - Canvas height (default: 800)

**Returns:** SVG string

**Example:**

```typescript
const result = analyze(sources, context);
const svg = generateVisualization(result, 1200, 900);

await Deno.writeTextFile("fogtrail.svg", svg);
```

## Advanced Usage

### Working with Contradictions

```typescript
const result = analyze(sources, context);

result.contradictions.forEach(c => {
  console.log(`Contradiction: ${c.utterance1} ⚔️ ${c.utterance2}`);
  console.log(`Type: ${c.conflictType}`);
  console.log(`Severity: ${c.severity}`);
  console.log(`Resolution: ${c.resolution}`);
});
```

**Contradiction Types:**
- `SameWordsDifferentGames` - Same words, different language games
- `IncommensurableFrameworks` - Utterly different frameworks
- `ContextualAmbiguity` - Depends on interpretation
- `TemporalShift` - Meaning changed over time
- `DisciplinaryClash` - Different academic disciplines

### Working with Mood Scores

```typescript
const result = analyze(sources, context);

result.moods.forEach(mood => {
  console.log(`Illocutionary force: ${mood.primary}`);
  console.log(`Felicitous: ${mood.felicitous}`);
  console.log(`Emotional tone: ${mood.emotionalTone}`);
  console.log(`Confidence: ${mood.confidence}`);
});
```

**Illocutionary Forces** (J.L. Austin):
- `Assertive` - Stating, claiming, asserting
- `Directive` - Commanding, requesting, advising
- `Commissive` - Promising, threatening, offering
- `Expressive` - Apologizing, thanking, congratulating
- `Declaration` - Declaring, pronouncing, naming

### Working with Mystery Clusters

```typescript
const result = analyze(sources, context);

result.mysteries.forEach(cluster => {
  console.log(`Cluster: ${cluster.label}`);
  console.log(`Mysteries: ${cluster.mysteries.length}`);

  cluster.mysteries.forEach(m => {
    console.log(`  - ${m.content}`);
    console.log(`    Opacity: ${m.opacityLevel}`);
    console.log(`    Resistance: ${m.resistanceType}`);
  });
});
```

**Opacity Levels:**
- `Translucent(float)` - Partially unclear (0.0-1.0)
- `Opaque` - Completely murky
- `Paradoxical` - Self-contradictory
- `Ineffable` - Cannot be put into words

**Resistance Types:**
- `ConceptualResistance` - Resists clear definition
- `EvidentialResistance` - Resists empirical verification
- `LogicalResistance` - Resists logical formalization
- `LinguisticResistance` - Resists clear expression

### Working with FogTrail

```typescript
const result = analyze(sources, context);

console.log(`Fog density: ${result.fogTrail.metadata.fogDensity}`);
console.log(`Nodes: ${result.fogTrail.nodes.length}`);
console.log(`Edges: ${result.fogTrail.edges.length}`);

// Export to visualization library (D3.js, Cytoscape, etc.)
const json = toJson(result);
const fogTrailData = json.fogTrail;

// Use with D3.js, Cytoscape.js, Vis.js, etc.
```

## ReScript Core Modules

For advanced users working directly with ReScript:

### EpistemicState

```rescript
type certainty =
  | Known
  | Probable(float)
  | Vague
  | Ambiguous(array<string>)
  | Mysterious
  | Contradictory(array<string>)

let make: (~certainty, ~context, ~evidence, ()) => t
let isGenuinelyAmbiguous: t => bool
let merge: (t, t) => t
```

### SpeechAct

```rescript
type illocutionaryForce =
  | Assertive(string)
  | Directive(string)
  | Commissive(string)
  | Expressive(string)
  | Declaration(string)

let make: (~utterance, ~force, ~context, ()) => t
let isHappy: t => bool
let conflicts: (t, t) => bool
```

### FamilyResemblance

```rescript
type cluster = {
  label: string,
  features: array<feature>,
  members: array<string>,
  centerOfGravity: option<string>,
  boundaries: string,
}

let make: (~label, ~features, ~members, ()) => t
let belongsToFamily: (string, array<string>, t) => bool
let resemblanceStrength: (string, string, t) => float
```

## Error Handling

Fogbinder uses ReScript's type system to prevent many errors at compile time. Runtime errors are minimal:

```typescript
try {
  const result = await analyzeZoteroCollection("invalid_id");
} catch (error) {
  console.error("Analysis failed:", error);
}
```

## Performance Notes

- **Small collections** (<100 sources): Instant analysis
- **Medium collections** (100-1000 sources): <1 second
- **Large collections** (>1000 sources): Consider batching

**Future optimization:** WASM compilation for O(n²) algorithms (family resemblance, graph layout)

## Accessibility

All UI components follow WCAG 2.1 Level AA:

- Semantic HTML with ARIA labels
- Keyboard navigation
- High contrast mode support
- Screen reader compatible

See `assets/styles.css` for accessibility CSS.

## License

GNU AGPLv3 - See [LICENSE](./LICENSE)

## Support

- GitHub Issues: [Report bugs](https://github.com/your-username/fogbinder/issues)
- Documentation: [PHILOSOPHY.md](./PHILOSOPHY.md)
- Development: [CLAUDE.md](./CLAUDE.md)

---

**Version:** 0.1.0
**Last Updated:** 2025-11-21
