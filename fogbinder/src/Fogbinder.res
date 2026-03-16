// Fogbinder.res — Main Orchestrator.
//
// This module ties together the various philosophical and linguistic 
// engines of the Fogbinder project. It implements a high-assurance 
// pipeline for navigating "Epistemic Ambiguity" in research data.
//
//! ANALYSIS PHASES:
//! 1. **Epistemic State**: Categorizes sources as Vague, Mysterious, or Known.
//! 2. **Speech Act**: Analyzes the force and intent of utterances.
//! 3. **Contradiction**: Identifies logical conflicts between sources.
//! 4. **Mystery Clustering**: Groups similar unknown or ambiguous data points.
//! 5. **FogTrail**: Generates a spatial visualization of data "opacity".

open EpistemicState
open SpeechAct
open ContradictionDetector
open MoodScorer
open MysteryClustering
open FogTrailVisualizer
open ZoteroBindings
open OrphanAdoption

// SCHEMA: The consolidated report from an analysis run.
type analysisResult = {
  contradictions: array<ContradictionDetector.contradiction>,
  moods: array<MoodScorer.moodScore>,
  mysteries: array<MysteryClustering.mysteryCluster>,
  fogTrail: FogTrailVisualizer.t,
  metadata: analysisMetadata,
}

/**
 * PIPELINE: Ingests raw source text and produces a structured epistemic map.
 * Uses a heuristic-based certainty detector to seed the initial states.
 */
let analyze = (~sources: array<string>, ~context: EpistemicState.languageGame, ()): analysisResult => {
  // ... [Implementation of the 6-stage analysis pipeline]
  {
    contradictions,
    moods,
    mysteries: mysteryClusters,
    fogTrail,
    metadata: {
      analyzed: Date.now(),
      totalSources: Array.length(sources),
      totalContradictions: Array.length(contradictions),
      totalMysteries: Array.length(mysteries),
      overallOpacity: fogTrail.metadata.fogDensity,
    },
  }
}

/**
 * ZOTERO INTEGRATION: Orchestrates analysis specifically for Zotero collections.
 * 1. EXTRACT: Pulls citations from the target collection.
 * 2. ANALYZE: Runs the epistemic pipeline.
 * 3. TAG: Marks analyzed items in the Zotero database via FFI bindings.
 */
let analyzeZoteroCollection = async (collectionId: string): analysisResult => {
  // ... [Asynchronous collection retrieval and tagging logic]
}

// ---------------------------------------------------------------------------
// Orphan Adoption — convenience re-exports for the Fogbinder menu
// ---------------------------------------------------------------------------

/// Adopt all orphan attachments (create parent items). One-click fix for the
/// "some files have no parent item" frustration after bulk imports.
let adoptOrphanAttachments = OrphanAdoption.adoptAll

/// Preview orphan attachments without adopting them.
let previewOrphanAttachments = OrphanAdoption.previewOrphans

/// Adopt with extra skip patterns (e.g. for plugin-specific attachment types
/// beyond the built-in BetterNotes filter).
let adoptOrphanAttachmentsWithSkips = OrphanAdoption.adoptAllWithSkips
