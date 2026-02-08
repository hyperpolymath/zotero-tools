# NSAI → Fogbinder Handoff Documentation

## Overview

This document describes the interface between **NSAI** (validation/certainty) and **Fogbinder** (exploration/uncertainty).

## Philosophical Foundation

The handoff embodies Wittgenstein's ladder (Tractatus 6.54):

1. **NSAI climbs up**: Validates what can be validated formally
2. **NSAI reaches the limit**: Recognizes what cannot be validated
3. **NSAI throws away the ladder**: Hands uncertain regions to Fogbinder

> **"Whereof one cannot validate, thereof one must explore."**

## The Certainty Boundary

### What NSAI Validates (The Sayable)

NSAI operates in the realm of **formal logic and structure**:

- ✅ **Structural completeness**: Are required fields present?
- ✅ **Format consistency**: Are dates/DOIs/URLs well-formed?
- ✅ **Logical coherence**: Are creators properly structured?
- ✅ **Referential integrity**: Do identifiers follow standard formats?

**Certainty threshold**: ≥ 0.7 score = NSAI confidently validates

### What Fogbinder Explores (The Unsayable)

Fogbinder operates beyond formal validation:

- 🌫️ **Semantic contradictions**: Do sources make conflicting claims?
- 🌫️ **Mood/tone analysis**: What is the epistemic stance of sources?
- 🌫️ **Mystery clustering**: What patterns emerge in uncertainty?
- 🌫️ **FogTrail visualization**: How does uncertainty propagate?

**Uncertainty threshold**: < 0.4 score = Hand to Fogbinder

## Data Format: NSAIExport

### Structure

```typescript
{
  format: 'nsai-to-fogbinder',
  formatVersion: '1.0.0',
  exported: Date,
  payload: FogbinderPayload
}
```

### FogbinderPayload

```typescript
{
  version: '1.0.0',
  timestamp: Date,

  // What NSAI validated with confidence
  validatedCitations: ValidatedCitation[],

  // What failed validation or is uncertain
  invalidCitations: InvalidCitation[],

  // Regions requiring Fogbinder exploration
  uncertaintyRegions: UncertaintyRegion[],

  // Potential contradictions detected
  contradictionHints: ContradictionHint[],

  // Overall epistemic assessment
  epistemicSummary: EpistemicSummary
}
```

## Key Interfaces

### ValidatedCitation

Citations that passed NSAI validation:

```typescript
{
  citation: AtomicCitation,
  validationResult: ValidationResult,
  certainty: number,  // ≥ 0.7
  certainties: string[]  // What NSAI can say with certainty
}
```

**Example certainties**:
- "Structurally complete"
- "Internally consistent"
- "Has persistent identifier"
- "DOI: 10.1234/example"

### InvalidCitation

Citations that failed validation or are ambiguous:

```typescript
{
  citation: AtomicCitation,
  validationResult: ValidationResult,
  reason: string,
  uncertainties: string[]  // What's uncertain
}
```

**Example uncertainties**:
- "Missing required fields"
- "Low confidence in validation"
- "Contains ambiguities"

### UncertaintyRegion

A cluster of citations requiring Fogbinder exploration:

```typescript
{
  id: string,
  type: 'structural' | 'semantic' | 'relational' | 'temporal',
  citationIds: string[],
  description: string,

  // Suggested Fogbinder features to use
  suggestedExploration: {
    useContradictionDetection?: boolean,
    useMoodScoring?: boolean,
    useMystery Clustering?: boolean,
    useFogTrailVisualization?: boolean
  },

  uncertaintyLevel: number  // 0.0-1.0
}
```

**Common region types**:

1. **no-persistent-identifiers**: Citations lacking DOI/ISBN/URL
   - Suggests: Mystery Clustering
   - Uncertainty: 0.6

2. **temporal-uncertainties**: Unusual publication dates
   - Suggests: Mood Scoring, FogTrail Visualization
   - Uncertainty: 0.5

3. **low-certainty-region**: Citations with validation scores < 0.4
   - Suggests: All Fogbinder features
   - Uncertainty: 0.8

4. **contradictory-relations**: Citations with conflicting relationships
   - Suggests: Contradiction Detection, FogTrail
   - Uncertainty: 0.9

### ContradictionHint

Potential contradictions NSAI detected (structural only):

```typescript
{
  citationA: string,  // Citation ID
  citationB: string,  // Citation ID
  type: 'metadata' | 'temporal' | 'authorship' | 'semantic-hint',
  description: string,
  confidence: number,  // 0.0-1.0
  requiresSemanticAnalysis: boolean
}
```

**Contradiction types**:

- **authorship**: Same title, different authors → Likely semantic contradiction
- **temporal**: Same author/title, different years → Likely metadata error
- **metadata**: Inconsistent metadata → Validation issue
- **semantic-hint**: Marked contradictory in citation graph → Requires deep analysis

### EpistemicSummary

Overall assessment of the research corpus:

```typescript
{
  totalCitations: number,
  validatedCount: number,
  uncertainCount: number,
  overallCertainty: number,  // 0.0-1.0

  epistemicGaps: EpistemicGap[],
  recommendation: string
}
```

**Example recommendations**:
- ≥ 0.8 certainty: "Bibliography is well-structured. Minor uncertainties can be explored in Fogbinder."
- 0.5-0.8: "Bibliography needs improvement. Address incomplete citations, then explore uncertainties in Fogbinder."
- < 0.5: "Bibliography requires significant work. Complete missing metadata before exploring in Fogbinder."

### EpistemicGap

What's missing or unclear in the corpus:

```typescript
{
  type: 'missing-citations' | 'incomplete-metadata' | 'temporal-gap' |
        'contradictory-claims' | 'ambiguous-sources',
  severity: 'low' | 'medium' | 'high' | 'critical',
  description: string,
  suggestion: string,
  explorableInFogbinder: boolean
}
```

## Handoff Workflow

### 1. NSAI Validation

```typescript
// Validate citations
const validator = new TractarianValidator();
const results = validator.validateBatch(citations);

// Create Fogbinder export
const handoffManager = new FogbinderHandoffManager();
const exportPackage = handoffManager.exportToFogbinder(results);
```

### 2. Export to JSON

```typescript
// Save to file
const json = JSON.stringify(exportPackage, null, 2);
fs.writeFileSync('nsai-export.json', json);
```

### 3. Import to Fogbinder

Fogbinder receives the export and uses it to:

1. **Load validated citations** as the certain foundation
2. **Explore uncertainty regions** using suggested features
3. **Investigate contradiction hints** with semantic analysis
4. **Visualize FogTrail** showing certainty → uncertainty gradient
5. **Cluster mysteries** around epistemic gaps

### 4. Bidirectional Feedback (Future)

Fogbinder can send feedback to NSAI:

```typescript
{
  format: 'fogbinder-to-nsai',
  formatVersion: '1.0.0',
  discoveries: {
    resolvedContradictions: ContradictionHint[],
    mysteriesClustered: string[],
    moodAnalysis: MoodHint[]
  },
  revalidationRequests: string[]  // Citation IDs
}
```

## Example Handoff Scenario

### Input: Research Bibliography

10 citations about Wittgenstein's philosophy

### NSAI Validation

- 7 citations: **VALID** (complete metadata, DOIs present)
- 2 citations: **INCOMPLETE** (missing publishers)
- 1 citation: **UNCERTAIN** (unusual date: 1918, pre-Tractatus)

### Uncertainty Regions Detected

1. **temporal-uncertainties**: 1 citation from 1918
   - Suggests: Mood scoring (early vs late Wittgenstein?)
   - Uncertainty: 0.5

2. **low-certainty-region**: 2 incomplete citations
   - Suggests: Mystery clustering (why incomplete?)
   - Uncertainty: 0.7

### Contradiction Hints

- Citations #3 and #7: Same title "Philosophical Investigations"
  - Different publication years: 1953 vs 2009
  - Type: **temporal**
  - Hypothesis: One is original, one is re-edition
  - Requires Fogbinder investigation

### Epistemic Summary

- Total: 10 citations
- Validated: 7 (70%)
- Uncertain: 3 (30%)
- Overall certainty: 0.78

**Recommendation**: "Bibliography is well-structured. Explore 3 uncertain citations in Fogbinder, particularly the temporal contradiction between 1953 and 2009 editions."

### Handoff to Fogbinder

Fogbinder receives:
- 7 certain citations (foundation)
- 2 uncertainty regions (explore)
- 1 contradiction hint (investigate)
- Epistemic summary (context)

Fogbinder explores:
- **Contradiction Detection**: Analyzes 1953 vs 2009 editions
- **Mood Scoring**: Compares early (1918) vs later (1953) Wittgenstein
- **Mystery Clustering**: Groups incomplete citations
- **FogTrail**: Visualizes certainty gradient from validated → uncertain

## Shared Vocabulary

Both NSAI and Fogbinder use these terms consistently:

| Term | Definition |
|------|------------|
| **Atomic Citation** | A single bibliographic entry (Tractarian "atomic fact") |
| **Validation** | Formal verification of structure/consistency (NSAI domain) |
| **Exploration** | Semantic/epistemic investigation (Fogbinder domain) |
| **Certainty** | Confidence in validation (0.0-1.0) |
| **Uncertainty Region** | Cluster of citations requiring exploration |
| **Contradiction** | Conflicting metadata (NSAI) or claims (Fogbinder) |
| **Epistemic Gap** | Missing or unclear knowledge |
| **Handoff** | Transfer from NSAI validation → Fogbinder exploration |

## Integration Points

### File Format

- **Extension**: `.nsai.json`
- **MIME type**: `application/json`
- **Encoding**: UTF-8

### API (Future)

If NSAI and Fogbinder communicate via API:

```
POST /fogbinder/import
Content-Type: application/json

{
  format: 'nsai-to-fogbinder',
  formatVersion: '1.0.0',
  payload: { ... }
}
```

### Shared Neurosymbolic Core (Future)

If NSAI and Fogbinder share a neurosymbolic reasoning engine:

- **NSAI uses it for**: Formal verification (Lean 4), structure validation
- **Fogbinder uses it for**: Semantic analysis, contradiction detection
- **Shared models**: Citation embeddings (ONNX), logical constraints

## Best Practices

### For NSAI Developers

1. **Always export uncertainties**: Even if validation passes, export low-confidence citations
2. **Provide rich context**: Include reasoning for certainty scores
3. **Suggest appropriate features**: Map uncertainty types to Fogbinder features
4. **Maintain compatibility**: Follow semver for format versions

### For Fogbinder Developers

1. **Respect the certainty boundary**: Don't re-validate what NSAI validated
2. **Explore uncertainties deeply**: Use NSAI hints as starting points
3. **Provide feedback**: Send discoveries back to NSAI for re-validation
4. **Visualize the handoff**: Show where certainty ends and exploration begins

## Versioning

Format version follows semantic versioning:

- **1.0.0**: Initial stable release
- **1.x.x**: Backward-compatible additions
- **2.0.0**: Breaking changes

Changes that require major version bump:
- Removing required fields
- Changing field types
- Renaming fields

Changes that allow minor version bump:
- Adding optional fields
- Adding new uncertainty region types
- Adding new contradiction types

## Conclusion

The NSAI → Fogbinder handoff embodies a complete epistemology:

- **NSAI**: The ladder we climb (formal validation)
- **Handoff**: The point where we recognize the ladder's limits
- **Fogbinder**: Throwing away the ladder and exploring beyond

Together, they form a system that respects both the **sayable** (what we can validate clearly) and the **unsayable** (what we must explore carefully).

---

*"What we cannot speak about we must pass over in silence" — but Fogbinder explores that silence.*
