

import * as SpeechAct$Fogbinder from "../core/SpeechAct.bs.js";

function detectContradiction(act1, act2) {
  let differentGames = act1.mood.context.domain !== act2.mood.context.domain;
  let forcesConflict = SpeechAct$Fogbinder.conflicts(act1, act2);
  if (differentGames && forcesConflict) {
    return {
      utterance1: act1,
      utterance2: act2,
      conflictType: "SameWordsDifferentGames",
      severity: 0.8,
      resolution: "Recognize different contexts of use"
    };
  } else if (differentGames) {
    return {
      utterance1: act1,
      utterance2: act2,
      conflictType: "DisciplinaryClash",
      severity: 0.5,
      resolution: "Acknowledge different disciplinary frameworks"
    };
  } else if (forcesConflict) {
    return {
      utterance1: act1,
      utterance2: act2,
      conflictType: "ContextualAmbiguity",
      severity: 0.6,
      resolution: "Clarify context of utterance"
    };
  } else {
    return;
  }
}

function detectMultiple(acts) {
  let contradictions = [];
  acts.forEach(act1 => {
    acts.forEach(act2 => {
      if (act1.timestamp >= act2.timestamp) {
        return;
      }
      let c = detectContradiction(act1, act2);
      if (c !== undefined) {
        contradictions.push(c);
        return;
      }
    });
  });
  return contradictions;
}

function toEdge(c) {
  let match = c.conflictType;
  let label;
  switch (match) {
    case "SameWordsDifferentGames" :
      label = "Different Games";
      break;
    case "IncommensurableFrameworks" :
      label = "Incommensurable";
      break;
    case "ContextualAmbiguity" :
      label = "Context-Dependent";
      break;
    case "TemporalShift" :
      label = "Temporal Shift";
      break;
    case "DisciplinaryClash" :
      label = "Disciplinary";
      break;
  }
  return [
    c.utterance1.utterance,
    c.utterance2.utterance,
    label
  ];
}

function suggestResolution(c) {
  let res = c.resolution;
  if (res !== undefined) {
    return res;
  }
  let match = c.conflictType;
  if (match === "IncommensurableFrameworks") {
    return "No resolution possible - acknowledge incommensurability";
  } else {
    return "Investigate language games in play";
  }
}

export {
  detectContradiction,
  detectMultiple,
  toEdge,
  suggestResolution,
}
/* No side effect */
