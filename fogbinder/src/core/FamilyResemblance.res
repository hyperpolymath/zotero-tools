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
  let itemFeatures = Array.filter(family.features, f =>
    Array.includes(f.exemplars, item)
  )

  let overlapScore = Array.reduce(itemFeatures, 0.0, (acc, f) => acc +. f.weight)

  // Threshold is deliberately vague - that's the point!
  overlapScore > 0.5
}

// Find prototypical member (most features)
let findPrototype = (family: t): option<string> => {
  let scores = Array.map(family.members, member => {
    let score = Array.reduce(family.features, 0.0, (acc, f) => {
      if Array.includes(f.exemplars, member) {
        acc +. f.weight
      } else {
        acc
      }
    })
    (member, score)
  })

  let sorted = Array.toSorted(scores, ((_, s1), (_, s2)) =>
    if s1 > s2 { -1 } else if s1 < s2 { 1 } else { 0 }
  )

  switch Array.getUnsafe(sorted, 0) {
  | (member, _) => Some(member)
  | _ => None
  }
}

// Merge two family resemblance clusters
// Creates a new cluster with overlapping features
let merge = (f1: t, f2: t): t => {
  {
    label: `${f1.label} + ${f2.label}`,
    features: Array.concat(f1.features, f2.features),
    members: Array.concat(f1.members, f2.members),
    centerOfGravity: None,
    boundaries: "contested", // Merged clusters are usually contested
  }
}

// Calculate resemblance strength between two items
let resemblanceStrength = (item1: string, item2: string, family: t): float => {
  let features1 = Array.filter(family.features, f =>
    Array.includes(f.exemplars, item1)
  )
  let features2 = Array.filter(family.features, f =>
    Array.includes(f.exemplars, item2)
  )

  // Count overlapping features
  let overlap = Array.filter(features1, f1 =>
    Array.some(features2, f2 => f1.name == f2.name)
  )

  let overlapWeight = Array.reduce(overlap, 0.0, (acc, f) => acc +. f.weight)
  overlapWeight
}

// Visualize family structure as network
let toNetwork = (family: t): array<(string, string, float)> => {
  // Create edges between members based on resemblance strength
  let edges = []
  Array.forEach(family.members, m1 => {
    Array.forEach(family.members, m2 => {
      if m1 != m2 {
        let strength = resemblanceStrength(m1, m2, family)
        if strength > 0.0 {
          Array.push(edges, (m1, m2, strength))->ignore
        }
      }
    })
  })
  edges
}
