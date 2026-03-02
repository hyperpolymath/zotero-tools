

import * as ContradictionDetector$Fogbinder from "./ContradictionDetector.bs.js";

function make(title, param) {
  return {
    nodes: [],
    edges: [],
    metadata: {
      title: title,
      created: Date.now(),
      totalOpacity: 0.0,
      fogDensity: 0.0
    }
  };
}

function addNode(trail, node) {
  return {
    nodes: trail.nodes.concat([node]),
    edges: trail.edges,
    metadata: trail.metadata
  };
}

function addEdge(trail, edge) {
  return {
    nodes: trail.nodes,
    edges: trail.edges.concat([edge]),
    metadata: trail.metadata
  };
}

function calculateFogDensity(trail) {
  let mysteryCount = trail.nodes.filter(n => {
    let match = n.nodeType;
    return match === "Mystery";
  }).length;
  let totalNodes = trail.nodes.length;
  if (totalNodes > 0.0) {
    return mysteryCount / totalNodes;
  } else {
    return 0.0;
  }
}

function buildFromAnalysis(title, sources, contradictions, mysteries, param) {
  let trail = make(title, undefined);
  let withSources = sources.reduce((acc, source) => addNode(acc, {
    id: source,
    label: source,
    nodeType: "Source",
    epistemicState: undefined,
    x: Math.random() * 1000.0,
    y: Math.random() * 1000.0
  }), trail);
  let withContradictions = contradictions.reduce((acc, contradiction) => addEdge(acc, {
    source: contradiction.utterance1.utterance,
    target: contradiction.utterance2.utterance,
    edgeType: "Contradicts",
    weight: contradiction.severity,
    label: ContradictionDetector$Fogbinder.suggestResolution(contradiction)
  }), withSources);
  let withMysteries = mysteries.reduce((acc, mystery) => addNode(acc, {
    id: mystery.content,
    label: mystery.content,
    nodeType: "Mystery",
    epistemicState: mystery.epistemicState,
    x: Math.random() * 1000.0,
    y: Math.random() * 1000.0
  }), withContradictions);
  let fogDensity = calculateFogDensity(withMysteries);
  let init = withMysteries.metadata;
  return {
    nodes: withMysteries.nodes,
    edges: withMysteries.edges,
    metadata: {
      title: init.title,
      created: init.created,
      totalOpacity: fogDensity,
      fogDensity: fogDensity
    }
  };
}

function toJson(trail) {
  let nodesJson = trail.nodes.map(node => {
    let nodeDict = {};
    nodeDict["id"] = node.id;
    nodeDict["label"] = node.label;
    nodeDict["x"] = node.x;
    nodeDict["y"] = node.y;
    return nodeDict;
  });
  let edgesJson = trail.edges.map(edge => {
    let edgeDict = {};
    edgeDict["source"] = edge.source;
    edgeDict["target"] = edge.target;
    edgeDict["weight"] = edge.weight;
    return edgeDict;
  });
  let metadataDict = {};
  metadataDict["title"] = trail.metadata.title;
  metadataDict["fogDensity"] = trail.metadata.fogDensity;
  let trailDict = {};
  trailDict["nodes"] = nodesJson;
  trailDict["edges"] = edgesJson;
  trailDict["metadata"] = metadataDict;
  return trailDict;
}

function toSvg(trail, widthOpt, heightOpt, param) {
  let width = widthOpt !== undefined ? widthOpt : 1000.0;
  let height = heightOpt !== undefined ? heightOpt : 800.0;
  let nodesSvg = trail.nodes.map(node => {
    let match = node.nodeType;
    let color;
    switch (match) {
      case "Source" :
        color = "#4A90E2";
        break;
      case "Concept" :
        color = "#7B68EE";
        break;
      case "Mystery" :
        color = "#2C3E50";
        break;
      case "Contradiction" :
        color = "#E74C3C";
        break;
    }
    return `<circle cx="` + String(node.x) + `" cy="` + String(node.y) + `" r="10" fill="` + color + `" />
      <text x="` + String(node.x) + `" y="` + String(node.y - 15.0) + `" text-anchor="middle" font-size="10">` + node.label + `</text>`;
  }).join("\n");
  let edgesSvg = trail.edges.map(edge => {
    let sourceNode = trail.nodes.find(n => n.id === edge.source);
    let targetNode = trail.nodes.find(n => n.id === edge.target);
    if (sourceNode !== undefined && targetNode !== undefined) {
      return `<line x1="` + String(sourceNode.x) + `" y1="` + String(sourceNode.y) + `" x2="` + String(targetNode.x) + `" y2="` + String(targetNode.y) + `" stroke="#95A5A6" stroke-width="` + String(edge.weight) + `" />`;
    } else {
      return "";
    }
  }).join("\n");
  return `<svg width="` + String(width) + `" height="` + String(height) + `" xmlns="http://www.w3.org/2000/svg">
    <g id="edges">
      ` + edgesSvg + `
    </g>
    <g id="nodes">
      ` + nodesSvg + `
    </g>
  </svg>`;
}

export {
  make,
  addNode,
  addEdge,
  calculateFogDensity,
  buildFromAnalysis,
  toJson,
  toSvg,
}
/* No side effect */
