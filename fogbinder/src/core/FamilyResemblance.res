// FamilyResemblance.res
// Wittgenstein's "family resemblance" - no strict definitions, overlapping similarities
// Philosophical Investigations §66-67: "Don't think, but look!"

// A concept is a network of overlapping features, not a strict definition
type feature = {
  name: string,
  weight: float, // How important is this feature?
  exemplars: array<string>, // Examples that have this feature
}

// Family resemblance cluster - no necessary/sufficient conditions
type cluster = {
  label: string,
  features: array<feature>, // Overlapping features
  members: array<string>, // Items in this family
  centerOfGravity: option<string>, // Prototypical member (if any)
  boundaries: string, // "vague" | "sharp" | "contested"
}

type t = cluster

// Create a new family resemblance cluster
let make = (~label, ~features, ~members, ()): t => {
  {
    label,
    features,
    members,
    centerOfGravity: None,
    boundaries: "vague", // Most concepts have vague boundaries
  }
}

// Check if item belongs to family (no strict definition!)
// An item belongs if it shares "enough" features with other members
let belongsToFamily = (item: string, features: array<string>, family: t): bool => {
  // Count overlapping features
  let itemFeatures = Js.Array2.filter(family.features, f =>
    Js.Array2.includes(f.exemplars, item)
  )

  let overlapScore = Js.Array2.reduce(itemFeatures, 0.0, (acc, f) => acc +. f.weight)

  // Threshold is deliberately vague - that's the point!
  overlapScore > 0.5
}

// Find prototypical member (most features)
let findPrototype = (family: t): option<string> => {
  let scores = Js.Array2.map(family.members, member => {
    let score = Js.Array2.reduce(family.features, 0.0, (acc, f) => {
      if Js.Array2.includes(f.exemplars, member) {
        acc +. f.weight
      } else {
        acc
      }
    })
    (member, score)
  })

  let sorted = Js.Array2.sortInPlaceWith(scores, ((_, s1), (_, s2)) =>
    if s1 > s2 { -1 } else if s1 < s2 { 1 } else { 0 }
  )

  switch Js.Array2.unsafe_get(sorted, 0) {
  | (member, _) => Some(member)
  | _ => None
  }
}

// Merge two family resemblance clusters
// Creates a new cluster with overlapping features
let merge = (f1: t, f2: t): t => {
  {
    label: `${f1.label} + ${f2.label}`,
    features: Js.Array2.concat(f1.features, f2.features),
    members: Js.Array2.concat(f1.members, f2.members),
    centerOfGravity: None,
    boundaries: "contested", // Merged clusters are usually contested
  }
}

// Calculate resemblance strength between two items
let resemblanceStrength = (item1: string, item2: string, family: t): float => {
  let features1 = Js.Array2.filter(family.features, f =>
    Js.Array2.includes(f.exemplars, item1)
  )
  let features2 = Js.Array2.filter(family.features, f =>
    Js.Array2.includes(f.exemplars, item2)
  )

  // Count overlapping features
  let overlap = Js.Array2.filter(features1, f1 =>
    Js.Array2.some(features2, f2 => f1.name == f2.name)
  )

  let overlapWeight = Js.Array2.reduce(overlap, 0.0, (acc, f) => acc +. f.weight)
  overlapWeight
}

// Visualize family structure as network
let toNetwork = (family: t): array<(string, string, float)> => {
  // Create edges between members based on resemblance strength
  let edges = []
  Js.Array2.forEach(family.members, m1 => {
    Js.Array2.forEach(family.members, m2 => {
      if m1 != m2 {
        let strength = resemblanceStrength(m1, m2, family)
        if strength > 0.0 {
          Js.Array2.push(edges, (m1, m2, strength))->ignore
        }
      }
    })
  })
  edges
}
