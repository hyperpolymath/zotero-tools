


function make(certainty, context, evidence, param) {
  return {
    certainty: certainty,
    context: context,
    evidence: evidence,
    timestamp: Date.now()
  };
}

function isGenuinelyAmbiguous(state) {
  let match = state.certainty;
  if (typeof match === "object") {
    return match.TAG !== "Probable";
  }
  switch (match) {
    case "Known" :
      return false;
    default:
      return true;
  }
}

function getInterpretations(state) {
  let interps = state.certainty;
  if (typeof interps !== "object") {
    return [];
  }
  switch (interps.TAG) {
    case "Ambiguous" :
    case "Contradictory" :
      return interps._0;
    default:
      return [];
  }
}

function merge(s1, s2) {
  let match = s1.certainty;
  let match$1 = s2.certainty;
  let newCertainty;
  let exit = 0;
  if (typeof match !== "object") {
    switch (match) {
      case "Known" :
        if (typeof match$1 !== "object") {
          switch (match$1) {
            case "Known" :
              newCertainty = "Known";
              break;
            case "Mysterious" :
              exit = 1;
              break;
            default:
              newCertainty = {
                TAG: "Ambiguous",
                _0: ["Multiple interpretations from different contexts"],
                [Symbol.for("name")]: "Ambiguous"
              };
          }
        } else {
          newCertainty = {
            TAG: "Ambiguous",
            _0: ["Multiple interpretations from different contexts"],
            [Symbol.for("name")]: "Ambiguous"
          };
        }
        break;
      case "Vague" :
        exit = 1;
        break;
      case "Mysterious" :
        newCertainty = "Mysterious";
        break;
    }
  } else {
    switch (match.TAG) {
      case "Probable" :
        if (typeof match$1 !== "object") {
          if (match$1 === "Mysterious") {
            exit = 1;
          } else {
            newCertainty = {
              TAG: "Ambiguous",
              _0: ["Multiple interpretations from different contexts"],
              [Symbol.for("name")]: "Ambiguous"
            };
          }
        } else {
          newCertainty = match$1.TAG === "Probable" ? ({
              TAG: "Probable",
              _0: (match._0 + match$1._0) / 2.0,
              [Symbol.for("name")]: "Probable"
            }) : ({
              TAG: "Ambiguous",
              _0: ["Multiple interpretations from different contexts"],
              [Symbol.for("name")]: "Ambiguous"
            });
        }
        break;
      case "Ambiguous" :
        if (typeof match$1 !== "object") {
          if (match$1 === "Mysterious") {
            exit = 1;
          } else {
            newCertainty = {
              TAG: "Ambiguous",
              _0: ["Multiple interpretations from different contexts"],
              [Symbol.for("name")]: "Ambiguous"
            };
          }
        } else {
          newCertainty = match$1.TAG === "Ambiguous" ? ({
              TAG: "Ambiguous",
              _0: match._0.concat(match$1._0),
              [Symbol.for("name")]: "Ambiguous"
            }) : ({
              TAG: "Ambiguous",
              _0: ["Multiple interpretations from different contexts"],
              [Symbol.for("name")]: "Ambiguous"
            });
        }
        break;
      case "Contradictory" :
        if (typeof match$1 !== "object") {
          if (match$1 === "Mysterious") {
            exit = 1;
          } else {
            newCertainty = {
              TAG: "Ambiguous",
              _0: ["Multiple interpretations from different contexts"],
              [Symbol.for("name")]: "Ambiguous"
            };
          }
        } else {
          newCertainty = match$1.TAG === "Contradictory" ? ({
              TAG: "Contradictory",
              _0: match._0.concat(match$1._0),
              [Symbol.for("name")]: "Contradictory"
            }) : ({
              TAG: "Ambiguous",
              _0: ["Multiple interpretations from different contexts"],
              [Symbol.for("name")]: "Ambiguous"
            });
        }
        break;
    }
  }
  if (exit === 1) {
    newCertainty = typeof match$1 !== "object" ? (
        match$1 === "Mysterious" ? "Mysterious" : ({
            TAG: "Ambiguous",
            _0: ["Multiple interpretations from different contexts"],
            [Symbol.for("name")]: "Ambiguous"
          })
      ) : ({
        TAG: "Ambiguous",
        _0: ["Multiple interpretations from different contexts"],
        [Symbol.for("name")]: "Ambiguous"
      });
  }
  return {
    certainty: newCertainty,
    context: s1.context,
    evidence: s1.evidence.concat(s2.evidence),
    timestamp: Date.now()
  };
}

function toJson(state) {
  let dict = {};
  let p = state.certainty;
  let certaintyStr;
  if (typeof p !== "object") {
    switch (p) {
      case "Known" :
        certaintyStr = "known";
        break;
      case "Vague" :
        certaintyStr = "vague";
        break;
      case "Mysterious" :
        certaintyStr = "mysterious";
        break;
    }
  } else {
    switch (p.TAG) {
      case "Probable" :
        certaintyStr = `probable:` + String(p._0);
        break;
      case "Ambiguous" :
        certaintyStr = "ambiguous";
        break;
      case "Contradictory" :
        certaintyStr = "contradictory";
        break;
    }
  }
  dict["certainty"] = certaintyStr;
  dict["timestamp"] = state.timestamp;
  return dict;
}

export {
  make,
  isGenuinelyAmbiguous,
  getInterpretations,
  merge,
  toJson,
}
/* No side effect */
