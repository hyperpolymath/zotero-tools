// Fogbinder.res
// Main orchestrator - ties all philosophical engines together

open EpistemicState
open SpeechAct
open ContradictionDetector
open MoodScorer
open MysteryClustering
open FogTrailVisualizer
open ZoteroBindings

// Analysis metadata
type analysisMetadata = {
  analyzed: float,
  totalSources: int,
  totalContradictions: int,
  totalMysteries: int,
  overallOpacity: float,
}

// Analysis result from Fogbinder
type analysisResult = {
  contradictions: array<ContradictionDetector.contradiction>,
  moods: array<MoodScorer.moodScore>,
  mysteries: array<MysteryClustering.mysteryCluster>,
  fogTrail: FogTrailVisualizer.t,
  metadata: analysisMetadata,
}

// Main analysis pipeline
let analyze = (~sources: array<string>, ~context: EpistemicState.languageGame, ()): analysisResult => {
  // 1. Create epistemic states for each source
  let epistemicStates = Js.Array2.map(sources, source => {
    // Determine certainty (simplified heuristic)
    let certainty = if Js.String.includes("unclear", source) ||
      Js.String.includes("ambiguous", source) {
      EpistemicState.Vague
    } else if Js.String.includes("mysterious", source) {
      EpistemicState.Mysterious
    } else if Js.String.includes("contradicts", source) {
      EpistemicState.Contradictory(["self-contradiction"])
    } else {
      EpistemicState.Known
    }

    EpistemicState.make(~certainty, ~context, ~evidence=[source], ())
  })

  // 2. Analyze speech acts
  let speechActs = Js.Array2.map(sources, source => {
    let mood = MoodScorer.analyze(source, context)
    SpeechAct.make(~utterance=source, ~force=mood.primary, ~context, ())
  })

  let moods = Js.Array2.map(speechActs, act => MoodScorer.score(act))

  // 3. Detect contradictions
  let contradictions = ContradictionDetector.detectMultiple(speechActs)

  // 4. Cluster mysteries
  let mysteryStates = Js.Array2.filter(epistemicStates, state =>
    MysteryClustering.isMystery(state)
  )

  let mysteries = Js.Array2.map(mysteryStates, state => {
    // Extract content from evidence
    let content = switch Js.Array2.unsafe_get(state.evidence, 0) {
    | content => content
    | exception _ => "Unknown"
    }

    MysteryClustering.make(~content, ~state, ())
  })

  let mysteryClusters = MysteryClustering.cluster(mysteries)

  // 5. Build FogTrail visualization
  let fogTrail = FogTrailVisualizer.buildFromAnalysis(
    ~title="Epistemic Analysis",
    ~sources,
    ~contradictions,
    ~mysteries,
    (),
  )

  // 6. Compile results
  {
    contradictions,
    moods,
    mysteries: mysteryClusters,
    fogTrail,
    metadata: {
      analyzed: Js.Date.now(),
      totalSources: Js.Array2.length(sources),
      totalContradictions: Js.Array2.length(contradictions),
      totalMysteries: Js.Array2.length(mysteries),
      overallOpacity: fogTrail.metadata.fogDensity,
    },
  }
}

// Analyze Zotero collection
let analyzeZoteroCollection = async (collectionId: string): analysisResult => {
  let collections = await ZoteroBindings.getCollections()

  let targetCollection = Js.Array2.find(collections, c => c.id == collectionId)

  switch targetCollection {
  | Some(coll) => {
      let sources = ZoteroBindings.extractCitations(coll)

      let context = {
        EpistemicState.domain: coll.name,
        conventions: [],
        participants: [],
        purpose: "Research analysis",
      }

      let result = analyze(~sources, ~context, ())

      // Tag items with results
      let _ = Js.Array2.forEach(coll.items, item => {
        let _ = ZoteroBindings.tagWithAnalysis(item.id, "analyzed")
        ()
      })

      result
    }
  | None => {
      Js.log("Collection not found")
      // Return empty result
      {
        contradictions: [],
        moods: [],
        mysteries: [],
        fogTrail: FogTrailVisualizer.make(~title="Empty", ()),
        metadata: {
          analyzed: Js.Date.now(),
          totalSources: 0,
          totalContradictions: 0,
          totalMysteries: 0,
          overallOpacity: 0.0,
        },
      }
    }
  }
}

// Export results to JSON
let toJson = (result: analysisResult): Js.Json.t => {
  open Js.Dict

  let metadata = empty()
  set(metadata, "totalSources", Js.Json.number(Belt.Int.toFloat(result.metadata.totalSources)))
  set(
    metadata,
    "totalContradictions",
    Js.Json.number(Belt.Int.toFloat(result.metadata.totalContradictions)),
  )
  set(
    metadata,
    "totalMysteries",
    Js.Json.number(Belt.Int.toFloat(result.metadata.totalMysteries)),
  )
  set(metadata, "overallOpacity", Js.Json.number(result.metadata.overallOpacity))

  let resultDict = empty()
  set(resultDict, "metadata", Js.Json.object_(metadata))
  set(resultDict, "fogTrail", FogTrailVisualizer.toJson(result.fogTrail))

  Js.Json.object_(resultDict)
}

// Generate human-readable report
let generateReport = (result: analysisResult): string => {
  let header = `# Fogbinder Analysis Report

Analyzed: ${Js.Date.toISOString(Js.Date.fromFloat(result.metadata.analyzed))}
Total Sources: ${Belt.Int.toString(result.metadata.totalSources)}
Overall Epistemic Opacity: ${Belt.Float.toString(result.metadata.overallOpacity)}

`

  let contradictionsSection = if Js.Array2.length(result.contradictions) > 0 {
    let items = Js.Array2.map(result.contradictions, c =>
      `- ${c.utterance1.utterance} ⚔️ ${c.utterance2.utterance}\n  Resolution: ${ContradictionDetector.suggestResolution(
          c,
        )}\n`
    )->Js.Array2.joinWith("")

    `## Contradictions (${Belt.Int.toString(Js.Array2.length(result.contradictions))})

${items}

`
  } else {
    ""
  }

  let mysteriesSection = if Js.Array2.length(result.mysteries) > 0 {
    let items = Js.Array2.map(result.mysteries, cluster =>
      `- **${cluster.label}** (${Belt.Int.toString(
          Js.Array2.length(cluster.mysteries),
        )} mysteries)\n`
    )->Js.Array2.joinWith("")

    `## Mystery Clusters

${items}

`
  } else {
    ""
  }

  `${header}${contradictionsSection}${mysteriesSection}---

*Generated by Fogbinder - Navigating Epistemic Ambiguity*`
}
