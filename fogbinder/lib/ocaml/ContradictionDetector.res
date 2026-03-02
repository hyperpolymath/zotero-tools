// ContradictionDetector.res
// Detects contradictions as LANGUAGE GAME CONFLICTS, not logical oppositions
// Late Wittgenstein: "A contradiction is a different kind of thing than you think"

open EpistemicState
open SpeechAct

// Conflict types for contradictions
type conflictType =
  | SameWordsDifferentGames // Same words, different language games
  | IncommensurableFrameworks // Utterly different frameworks
  | ContextualAmbiguity // Depends on interpretation context
  | TemporalShift // Meaning changed over time
  | DisciplinaryClash // Different academic disciplines

// A contradiction is when different language games clash over the same utterance
type contradiction = {
  utterance1: SpeechAct.t,
  utterance2: SpeechAct.t,
  conflictType: conflictType,
  severity: float, // 0.0-1.0: how serious is this clash?
  resolution: option<string>, // Possible way to resolve (if any)
}

// Detect if two speech acts contradict
let detectContradiction = (act1: SpeechAct.t, act2: SpeechAct.t): option<contradiction> => {
  // Check if they're playing different language games
  let differentGames = act1.mood.context.domain != act2.mood.context.domain

  // Check if illocutionary forces conflict
  let forcesConflict = SpeechAct.conflicts(act1, act2)

  if differentGames && forcesConflict {
    Some({
      utterance1: act1,
      utterance2: act2,
      conflictType: SameWordsDifferentGames,
      severity: 0.8,
      resolution: Some("Recognize different contexts of use"),
    })
  } else if differentGames {
    Some({
      utterance1: act1,
      utterance2: act2,
      conflictType: DisciplinaryClash,
      severity: 0.5,
      resolution: Some("Acknowledge different disciplinary frameworks"),
    })
  } else if forcesConflict {
    Some({
      utterance1: act1,
      utterance2: act2,
      conflictType: ContextualAmbiguity,
      severity: 0.6,
      resolution: Some("Clarify context of utterance"),
    })
  } else {
    None
  }
}

// Batch detect contradictions across multiple sources
let detectMultiple = (acts: array<SpeechAct.t>): array<contradiction> => {
  let contradictions = []

  Js.Array2.forEach(acts, act1 => {
    Js.Array2.forEach(acts, act2 => {
      if act1.timestamp < act2.timestamp {
        // Avoid duplicate pairs
        switch detectContradiction(act1, act2) {
        | Some(c) => Js.Array2.push(contradictions, c)->ignore
        | None => ()
        }
      }
    })
  })

  contradictions
}

// Visualize contradiction as network edge
let toEdge = (c: contradiction): (string, string, string) => {
  let label = switch c.conflictType {
  | SameWordsDifferentGames => "Different Games"
  | IncommensurableFrameworks => "Incommensurable"
  | ContextualAmbiguity => "Context-Dependent"
  | TemporalShift => "Temporal Shift"
  | DisciplinaryClash => "Disciplinary"
  }

  (c.utterance1.utterance, c.utterance2.utterance, label)
}

// Suggest resolution strategies
let suggestResolution = (c: contradiction): string => {
  switch c.resolution {
  | Some(res) => res
  | None =>
    switch c.conflictType {
    | IncommensurableFrameworks => "No resolution possible - acknowledge incommensurability"
    | _ => "Investigate language games in play"
    }
  }
}
