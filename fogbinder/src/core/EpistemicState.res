// EpistemicState.res
// Models epistemic uncertainty as a feature, not a bug
// Based on late Wittgenstein: meaning emerges from use, not correspondence to facts

// Core epistemic modalities
type certainty =
  | Known // Clear, unambiguous
  | Probable(float) // Statistical confidence
  | Vague // Fuzzy boundaries (Wittgenstein's "family resemblance")
  | Ambiguous(array<string>) // Multiple valid interpretations (language games)
  | Mysterious // Resists factual reduction
  | Contradictory(array<string>) // Conflicting language games

// Context of use (Wittgenstein's "language game")
type languageGame = {
  domain: string, // Academic discipline, cultural context, etc.
  conventions: array<string>, // Rules of use in this game
  participants: array<string>, // Who's playing?
  purpose: string, // What are they doing with these words?
}

// Epistemic state combines modality with context
type t = {
  certainty: certainty,
  context: languageGame,
  evidence: array<string>, // Supporting citations/passages
  timestamp: float,
}

// Create a new epistemic state
let make = (~certainty, ~context, ~evidence, ()): t => {
  {
    certainty,
    context,
    evidence,
    timestamp: Js.Date.now(),
  }
}

// Check if state represents genuine uncertainty (not just lack of data)
let isGenuinelyAmbiguous = (state: t): bool => {
  switch state.certainty {
  | Ambiguous(_) | Mysterious | Contradictory(_) => true
  | Vague => true
  | Known | Probable(_) => false
  }
}

// Extract all possible interpretations from ambiguous state
let getInterpretations = (state: t): array<string> => {
  switch state.certainty {
  | Ambiguous(interps) => interps
  | Contradictory(conflicts) => conflicts
  | _ => []
  }
}

// Merge two epistemic states (may increase ambiguity!)
let merge = (s1: t, s2: t): t => {
  // When different language games clash, we get contradiction or ambiguity
  let newCertainty = switch (s1.certainty, s2.certainty) {
  | (Known, Known) => Known
  | (Probable(p1), Probable(p2)) => Probable((p1 +. p2) /. 2.0)
  | (Ambiguous(a1), Ambiguous(a2)) => Ambiguous(Js.Array2.concat(a1, a2))
  | (Contradictory(c1), Contradictory(c2)) => Contradictory(Js.Array2.concat(c1, c2))
  | (_, Mysterious) | (Mysterious, _) => Mysterious
  | _ => Ambiguous([
      "Multiple interpretations from different contexts",
    ])
  }

  {
    certainty: newCertainty,
    context: s1.context, // Preserve primary context
    evidence: Js.Array2.concat(s1.evidence, s2.evidence),
    timestamp: Js.Date.now(),
  }
}

// Convert to JSON for serialization
let toJson = (state: t): Js.Json.t => {
  open Js.Dict
  let dict = empty()

  let certaintyStr = switch state.certainty {
  | Known => "known"
  | Probable(p) => `probable:${Belt.Float.toString(p)}`
  | Vague => "vague"
  | Ambiguous(_) => "ambiguous"
  | Mysterious => "mysterious"
  | Contradictory(_) => "contradictory"
  }

  set(dict, "certainty", Js.Json.string(certaintyStr))
  set(dict, "timestamp", Js.Json.number(state.timestamp))

  Js.Json.object_(dict)
}
