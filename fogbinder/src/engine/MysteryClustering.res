// MysteryClustering.res
// Clusters content that RESISTS factual reduction
// Epistemic opacity as a positive feature to explore

open EpistemicState
open FamilyResemblance

// Mystery is what cannot be reduced to clear propositions
type mystery = {
  content: string,
  opacityLevel: opacityLevel,
  resistanceType: resistanceType,
  relatedConcepts: array<string>,
  epistemicState: EpistemicState.t,
}

and opacityLevel =
  | Translucent(float) // Partially unclear (0.0-1.0)
  | Opaque // Completely murky
  | Paradoxical // Self-contradictory
  | Ineffable // Cannot be put into words

and resistanceType =
  | ConceptualResistance // Resists clear definition
  | EvidentialResistance // Resists empirical verification
  | LogicalResistance // Resists logical formalization
  | LinguisticResistance // Resists clear expression

type mysteryCluster = {
  label: string,
  mysteries: array<mystery>,
  familyResemblance: FamilyResemblance.t,
  centralMystery: option<mystery>,
}

// Detect if content is mysterious
let isMystery = (state: EpistemicState.t): bool => {
  switch state.certainty {
  | Mysterious => true
  | Vague => true
  | Ambiguous(_) when Js.Array2.length(
      switch state.certainty {
      | Ambiguous(a) => a
      | _ => []
      },
    ) > 3 => true // Too many interpretations = mystery
  | _ => false
  }
}

// Create mystery from epistemic state
let make = (~content, ~state, ()): mystery => {
  // Determine opacity level
  let opacityLevel = switch state.certainty {
  | Mysterious => Opaque
  | Vague => Translucent(0.5)
  | Ambiguous(interps) when Js.Array2.length(interps) > 5 => Paradoxical
  | Contradictory(_) => Paradoxical
  | _ => Translucent(0.3)
  }

  // Determine resistance type (heuristic)
  let resistanceType = if Js.String.includes("ineffable", content) ||
    Js.String.includes("inexpressible", content) {
    LinguisticResistance
  } else if Js.String.includes("paradox", content) {
    LogicalResistance
  } else if Js.String.includes("unclear", content) ||
    Js.String.includes("ambiguous", content) {
    ConceptualResistance
  } else {
    EvidentialResistance
  }

  {
    content,
    opacityLevel,
    resistanceType,
    relatedConcepts: [],
    epistemicState: state,
  }
}

// Cluster mysteries by family resemblance
let cluster = (mysteries: array<mystery>): array<mysteryCluster> => {
  // Group mysteries with similar resistance types
  let grouped = Js.Dict.empty()

  Js.Array2.forEach(mysteries, m => {
    let key = switch m.resistanceType {
    | ConceptualResistance => "conceptual"
    | EvidentialResistance => "evidential"
    | LogicalResistance => "logical"
    | LinguisticResistance => "linguistic"
    }

    switch Js.Dict.get(grouped, key) {
    | Some(arr) => Js.Array2.push(arr, m)->ignore
    | None => Js.Dict.set(grouped, key, [m])
    }
  })

  // Convert to mystery clusters
  Js.Dict.entries(grouped)->Js.Array2.map(((label, mysts)) => {
    // Create family resemblance features
    let features = [
      {
        FamilyResemblance.name: "opacity",
        weight: 1.0,
        exemplars: Js.Array2.map(mysts, m => m.content),
      },
    ]

    let family = FamilyResemblance.make(
      ~label,
      ~features,
      ~members=Js.Array2.map(mysts, m => m.content),
      (),
    )

    {
      label,
      mysteries: mysts,
      familyResemblance: family,
      centralMystery: Js.Array2.unsafe_get(mysts, 0)->Some,
    }
  })
}

// Get opacity descriptor
let getOpacityDescriptor = (m: mystery): string => {
  switch m.opacityLevel {
  | Translucent(level) => `Translucent (${Belt.Float.toString(level)})`
  | Opaque => "Opaque"
  | Paradoxical => "Paradoxical"
  | Ineffable => "Ineffable"
  }
}

// Suggest exploration strategies
let suggestExploration = (m: mystery): string => {
  switch m.resistanceType {
  | ConceptualResistance => "Examine family resemblances and language games"
  | EvidentialResistance => "Acknowledge limits of empirical verification"
  | LogicalResistance => "Explore paralogical frameworks"
  | LinguisticResistance => "Consider showing rather than saying (Wittgenstein)"
  }
}
