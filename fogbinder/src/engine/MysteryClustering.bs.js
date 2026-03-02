

import * as Js_dict from "@rescript/runtime/lib/es6/Js_dict.js";
import * as Js_string from "@rescript/runtime/lib/es6/Js_string.js";
import * as FamilyResemblance$Fogbinder from "../core/FamilyResemblance.bs.js";

function isMystery(state) {
  let match = state.certainty;
  if (typeof match !== "object") {
    switch (match) {
      case "Vague" :
      case "Mysterious" :
        return true;
      default:
        return false;
    }
  } else {
    if (match.TAG !== "Ambiguous") {
      return false;
    }
    let a = state.certainty;
    let tmp;
    tmp = typeof a !== "object" ? [] : (
        a.TAG === "Ambiguous" ? a._0 : []
      );
    return tmp.length > 3;
  }
}

function make(content, state, param) {
  let interps = state.certainty;
  let opacityLevel;
  if (typeof interps !== "object") {
    switch (interps) {
      case "Known" :
        opacityLevel = {
          TAG: "Translucent",
          _0: 0.3,
          [Symbol.for("name")]: "Translucent"
        };
        break;
      case "Vague" :
        opacityLevel = {
          TAG: "Translucent",
          _0: 0.5,
          [Symbol.for("name")]: "Translucent"
        };
        break;
      case "Mysterious" :
        opacityLevel = "Opaque";
        break;
    }
  } else {
    switch (interps.TAG) {
      case "Probable" :
        opacityLevel = {
          TAG: "Translucent",
          _0: 0.3,
          [Symbol.for("name")]: "Translucent"
        };
        break;
      case "Ambiguous" :
        opacityLevel = interps._0.length > 5 ? "Paradoxical" : ({
            TAG: "Translucent",
            _0: 0.3,
            [Symbol.for("name")]: "Translucent"
          });
        break;
      case "Contradictory" :
        opacityLevel = "Paradoxical";
        break;
    }
  }
  let resistanceType = Js_string.includes("ineffable", content) || Js_string.includes("inexpressible", content) ? "LinguisticResistance" : (
      Js_string.includes("paradox", content) ? "LogicalResistance" : (
          Js_string.includes("unclear", content) || Js_string.includes("ambiguous", content) ? "ConceptualResistance" : "EvidentialResistance"
        )
    );
  return {
    content: content,
    opacityLevel: opacityLevel,
    resistanceType: resistanceType,
    relatedConcepts: [],
    epistemicState: state
  };
}

function cluster(mysteries) {
  let grouped = {};
  mysteries.forEach(m => {
    let match = m.resistanceType;
    let key;
    switch (match) {
      case "ConceptualResistance" :
        key = "conceptual";
        break;
      case "EvidentialResistance" :
        key = "evidential";
        break;
      case "LogicalResistance" :
        key = "logical";
        break;
      case "LinguisticResistance" :
        key = "linguistic";
        break;
    }
    let arr = Js_dict.get(grouped, key);
    if (arr !== undefined) {
      arr.push(m);
    } else {
      grouped[key] = [m];
    }
  });
  return Js_dict.entries(grouped).map(param => {
    let mysts = param[1];
    let label = param[0];
    let features = [{
        name: "opacity",
        weight: 1.0,
        exemplars: mysts.map(m => m.content)
      }];
    let family = FamilyResemblance$Fogbinder.make(label, features, mysts.map(m => m.content), undefined);
    return {
      label: label,
      mysteries: mysts,
      familyResemblance: family,
      centralMystery: mysts[0]
    };
  });
}

function getOpacityDescriptor(m) {
  let level = m.opacityLevel;
  if (typeof level === "object") {
    return `Translucent (` + String(level._0) + `)`;
  }
  switch (level) {
    case "Opaque" :
      return "Opaque";
    case "Paradoxical" :
      return "Paradoxical";
    case "Ineffable" :
      return "Ineffable";
  }
}

function suggestExploration(m) {
  let match = m.resistanceType;
  switch (match) {
    case "ConceptualResistance" :
      return "Examine family resemblances and language games";
    case "EvidentialResistance" :
      return "Acknowledge limits of empirical verification";
    case "LogicalResistance" :
      return "Explore paralogical frameworks";
    case "LinguisticResistance" :
      return "Consider showing rather than saying (Wittgenstein)";
  }
}

export {
  isMystery,
  make,
  cluster,
  getOpacityDescriptor,
  suggestExploration,
}
/* No side effect */
