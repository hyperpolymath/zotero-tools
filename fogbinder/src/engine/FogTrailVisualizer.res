// FogTrailVisualizer.res
// Network visualization of epistemic opacity
// Shows how research "clouds, contradicts, and clears"

open EpistemicState
open ContradictionDetector
open FamilyResemblance

// Node in the epistemic network
type node = {
  id: string,
  label: string,
  nodeType: nodeType,
  epistemicState: option<EpistemicState.t>,
  x: float,
  y: float,
}

and nodeType =
  | Source // Citation/source
  | Concept // Abstract concept
  | Mystery // Mystery cluster
  | Contradiction // Contradiction point

// Edge in the epistemic network
type edge = {
  source: string,
  target: string,
  edgeType: edgeType,
  weight: float,
  label: option<string>,
}

and edgeType =
  | Supports // Evidence supports claim
  | Contradicts // Language game conflict
  | Resembles // Family resemblance
  | Mystery // Mysterious connection

// The FogTrail network
type fogTrail = {
  nodes: array<node>,
  edges: array<edge>,
  metadata: trailMetadata,
}

and trailMetadata = {
  title: string,
  created: float,
  totalOpacity: float, // Overall epistemic opacity score
  fogDensity: float, // How much uncertainty
}

type t = fogTrail

// Create empty fog trail
let make = (~title, ()): t => {
  {
    nodes: [],
    edges: [],
    metadata: {
      title,
      created: Date.now(),
      totalOpacity: 0.0,
      fogDensity: 0.0,
    },
  }
}

// Add node to trail
let addNode = (trail: t, node: node): t => {
  {
    ...trail,
    nodes: Array.concat(trail.nodes, [node]),
  }
}

// Add edge to trail
let addEdge = (trail: t, edge: edge): t => {
  {
    ...trail,
    edges: Array.concat(trail.edges, [edge]),
  }
}

// Calculate fog density (0.0-1.0)
let calculateFogDensity = (trail: t): float => {
  let mysteryCount = Array.filter(trail.nodes, n =>
    switch n.nodeType {
    | Mystery => true
    | _ => false
    }
  )->Array.length->Int.toFloat

  let totalNodes = Array.length(trail.nodes)->Int.toFloat

  if totalNodes > 0.0 {
    mysteryCount /. totalNodes
  } else {
    0.0
  }
}

// Build trail from sources and contradictions
let buildFromAnalysis = (
  ~title,
  ~sources: array<string>,
  ~contradictions: array<ContradictionDetector.contradiction>,
  ~mysteries: array<MysteryClustering.mystery>,
  (),
): t => {
  let trail = make(~title, ())

  // Add source nodes
  let withSources = Array.reduce(sources, trail, (acc, source) => {
    addNode(
      acc,
      {
        id: source,
        label: source,
        nodeType: Source,
        epistemicState: None,
        x: Js.Math.random() *. 1000.0,
        y: Js.Math.random() *. 1000.0,
      },
    )
  })

  // Add contradiction edges
  let withContradictions = Array.reduce(
    contradictions,
    withSources,
    (acc, contradiction) => {
      addEdge(
        acc,
        {
          source: contradiction.utterance1.utterance,
          target: contradiction.utterance2.utterance,
          edgeType: Contradicts,
          weight: contradiction.severity,
          label: Some(ContradictionDetector.suggestResolution(contradiction)),
        },
      )
    },
  )

  // Add mystery nodes
  let withMysteries = Array.reduce(mysteries, withContradictions, (acc, mystery) => {
    addNode(
      acc,
      {
        id: mystery.content,
        label: mystery.content,
        nodeType: Mystery,
        epistemicState: Some(mystery.epistemicState),
        x: Js.Math.random() *. 1000.0,
        y: Js.Math.random() *. 1000.0,
      },
    )
  })

  // Calculate fog density
  let fogDensity = calculateFogDensity(withMysteries)

  {
    ...withMysteries,
    metadata: {
      ...withMysteries.metadata,
      fogDensity,
      totalOpacity: fogDensity,
    },
  }
}

// Export to JSON for visualization library (D3.js, Cytoscape, etc.)
let toJson = (trail: t): Js.Json.t => {
  open Js.Dict

  let nodesJson = Array.map(trail.nodes, node => {
    let nodeDict = empty()
    set(nodeDict, "id", Js.Json.string(node.id))
    set(nodeDict, "label", Js.Json.string(node.label))
    set(nodeDict, "x", Js.Json.number(node.x))
    set(nodeDict, "y", Js.Json.number(node.y))
    Js.Json.object_(nodeDict)
  })

  let edgesJson = Array.map(trail.edges, edge => {
    let edgeDict = empty()
    set(edgeDict, "source", Js.Json.string(edge.source))
    set(edgeDict, "target", Js.Json.string(edge.target))
    set(edgeDict, "weight", Js.Json.number(edge.weight))
    Js.Json.object_(edgeDict)
  })

  let metadataDict = empty()
  set(metadataDict, "title", Js.Json.string(trail.metadata.title))
  set(metadataDict, "fogDensity", Js.Json.number(trail.metadata.fogDensity))

  let trailDict = empty()
  set(trailDict, "nodes", Js.Json.array(nodesJson))
  set(trailDict, "edges", Js.Json.array(edgesJson))
  set(trailDict, "metadata", Js.Json.object_(metadataDict))

  Js.Json.object_(trailDict)
}

// Generate SVG visualization (basic)
let toSvg = (trail: t, ~width=1000.0, ~height=800.0, ()): string => {
  let nodesSvg = Array.map(trail.nodes, node => {
    let color = switch node.nodeType {
    | Source => "#4A90E2"
    | Concept => "#7B68EE"
    | Mystery => "#2C3E50"
    | Contradiction => "#E74C3C"
    }

    `<circle cx="${Float.toString(node.x)}" cy="${Float.toString(
        node.y,
      )}" r="10" fill="${color}" />
      <text x="${Float.toString(node.x)}" y="${Float.toString(
        node.y -. 15.0,
      )}" text-anchor="middle" font-size="10">${node.label}</text>`
  })->Array.join("\n")

  let edgesSvg = Array.map(trail.edges, edge => {
    // Find source and target nodes
    let sourceNode = Array.find(trail.nodes, n => n.id == edge.source)
    let targetNode = Array.find(trail.nodes, n => n.id == edge.target)

    switch (sourceNode, targetNode) {
    | (Some(s), Some(t)) =>
      `<line x1="${Float.toString(s.x)}" y1="${Float.toString(
          s.y,
        )}" x2="${Float.toString(t.x)}" y2="${Float.toString(
          t.y,
        )}" stroke="#95A5A6" stroke-width="${Float.toString(edge.weight)}" />`
    | _ => ""
    }
  })->Array.join("\n")

  `<svg width="${Float.toString(width)}" height="${Float.toString(height)}" xmlns="http://www.w3.org/2000/svg">
    <g id="edges">
      ${edgesSvg}
    </g>
    <g id="nodes">
      ${nodesSvg}
    </g>
  </svg>`
}
