

import * as Js_string from "@rescript/runtime/lib/es6/Js_string.js";
import * as SpeechAct$Fogbinder from "./core/SpeechAct.bs.js";
import * as MoodScorer$Fogbinder from "./engine/MoodScorer.bs.js";
import * as EpistemicState$Fogbinder from "./core/EpistemicState.bs.js";
import * as ZoteroBindings$Fogbinder from "./zotero/ZoteroBindings.bs.js";
import * as MysteryClustering$Fogbinder from "./engine/MysteryClustering.bs.js";
import * as FogTrailVisualizer$Fogbinder from "./engine/FogTrailVisualizer.bs.js";
import * as ContradictionDetector$Fogbinder from "./engine/ContradictionDetector.bs.js";

function analyze(sources, context, param) {
  let epistemicStates = sources.map(source => {
    let certainty = Js_string.includes("unclear", source) || Js_string.includes("ambiguous", source) ? "Vague" : (
        Js_string.includes("mysterious", source) ? "Mysterious" : (
            Js_string.includes("contradicts", source) ? ({
                TAG: "Contradictory",
                _0: ["self-contradiction"],
                [Symbol.for("name")]: "Contradictory"
              }) : "Known"
          )
      );
    return EpistemicState$Fogbinder.make(certainty, context, [source], undefined);
  });
  let speechActs = sources.map(source => {
    let mood = MoodScorer$Fogbinder.analyze(source, context);
    return SpeechAct$Fogbinder.make(source, mood.primary, context, undefined);
  });
  let moods = speechActs.map(MoodScorer$Fogbinder.score);
  let contradictions = ContradictionDetector$Fogbinder.detectMultiple(speechActs);
  let mysteryStates = epistemicStates.filter(MysteryClustering$Fogbinder.isMystery);
  let mysteries = mysteryStates.map(state => {
    let content;
    try {
      content = state.evidence[0];
    } catch (exn) {
      content = "Unknown";
    }
    return MysteryClustering$Fogbinder.make(content, state, undefined);
  });
  let mysteryClusters = MysteryClustering$Fogbinder.cluster(mysteries);
  let fogTrail = FogTrailVisualizer$Fogbinder.buildFromAnalysis("Epistemic Analysis", sources, contradictions, mysteries, undefined);
  return {
    contradictions: contradictions,
    moods: moods,
    mysteries: mysteryClusters,
    fogTrail: fogTrail,
    metadata: {
      analyzed: Date.now(),
      totalSources: sources.length,
      totalContradictions: contradictions.length,
      totalMysteries: mysteries.length,
      overallOpacity: fogTrail.metadata.fogDensity
    }
  };
}

async function analyzeZoteroCollection(collectionId) {
  let collections = await ZoteroBindings$Fogbinder.getCollections();
  let targetCollection = collections.find(c => c.id === collectionId);
  if (targetCollection !== undefined) {
    let sources = ZoteroBindings$Fogbinder.extractCitations(targetCollection);
    let context_domain = targetCollection.name;
    let context_conventions = [];
    let context_participants = [];
    let context = {
      domain: context_domain,
      conventions: context_conventions,
      participants: context_participants,
      purpose: "Research analysis"
    };
    let result = analyze(sources, context, undefined);
    targetCollection.items.forEach(item => {
      ZoteroBindings$Fogbinder.tagWithAnalysis(item.id, "analyzed");
    });
    return result;
  }
  console.log("Collection not found");
  return {
    contradictions: [],
    moods: [],
    mysteries: [],
    fogTrail: FogTrailVisualizer$Fogbinder.make("Empty", undefined),
    metadata: {
      analyzed: Date.now(),
      totalSources: 0,
      totalContradictions: 0,
      totalMysteries: 0,
      overallOpacity: 0.0
    }
  };
}

function toJson(result) {
  let metadata = {};
  metadata["totalSources"] = result.metadata.totalSources;
  metadata["totalContradictions"] = result.metadata.totalContradictions;
  metadata["totalMysteries"] = result.metadata.totalMysteries;
  metadata["overallOpacity"] = result.metadata.overallOpacity;
  let resultDict = {};
  resultDict["metadata"] = metadata;
  resultDict["fogTrail"] = FogTrailVisualizer$Fogbinder.toJson(result.fogTrail);
  return resultDict;
}

function generateReport(result) {
  let header = `# Fogbinder Analysis Report

Analyzed: ` + new Date(result.metadata.analyzed).toISOString() + `
Total Sources: ` + String(result.metadata.totalSources) + `
Overall Epistemic Opacity: ` + String(result.metadata.overallOpacity) + `

`;
  let contradictionsSection;
  if (result.contradictions.length !== 0) {
    let items = result.contradictions.map(c => `- ` + c.utterance1.utterance + ` ⚔️ ` + c.utterance2.utterance + `\n  Resolution: ` + ContradictionDetector$Fogbinder.suggestResolution(c) + `\n`).join("");
    contradictionsSection = `## Contradictions (` + String(result.contradictions.length) + `)

` + items + `

`;
  } else {
    contradictionsSection = "";
  }
  let mysteriesSection;
  if (result.mysteries.length !== 0) {
    let items$1 = result.mysteries.map(cluster => `- **` + cluster.label + `** (` + String(cluster.mysteries.length) + ` mysteries)\n`).join("");
    mysteriesSection = `## Mystery Clusters

` + items$1 + `

`;
  } else {
    mysteriesSection = "";
  }
  return header + contradictionsSection + mysteriesSection + `---

*Generated by Fogbinder - Navigating Epistemic Ambiguity*`;
}

export {
  analyze,
  analyzeZoteroCollection,
  toJson,
  generateReport,
}
/* ZoteroBindings-Fogbinder Not a pure module */
