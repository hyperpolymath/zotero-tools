

import * as Js_string from "@rescript/runtime/lib/es6/Js_string.js";
import * as SpeechAct$Fogbinder from "../core/SpeechAct.bs.js";

function analyze(text, context) {
  let lower = text.toLowerCase();
  let primary = Js_string.includes("promise", lower) || Js_string.includes("vow", lower) ? ({
      TAG: "Commissive",
      _0: "commitment",
      [Symbol.for("name")]: "Commissive"
    }) : (
      Js_string.includes("command", lower) || Js_string.includes("request", lower) || Js_string.includes("must", lower) ? ({
          TAG: "Directive",
          _0: "directive",
          [Symbol.for("name")]: "Directive"
        }) : (
          Js_string.includes("declare", lower) || Js_string.includes("pronounce", lower) ? ({
              TAG: "Declaration",
              _0: "declaration",
              [Symbol.for("name")]: "Declaration"
            }) : (
              Js_string.includes("thank", lower) || Js_string.includes("apologize", lower) || Js_string.includes("congratulate", lower) ? ({
                  TAG: "Expressive",
                  _0: "gratitude/apology",
                  [Symbol.for("name")]: "Expressive"
                }) : ({
                  TAG: "Assertive",
                  _0: "statement",
                  [Symbol.for("name")]: "Assertive"
                })
            )
        )
    );
  let emotionalTone = Js_string.includes("melancholy", lower) || Js_string.includes("sad", lower) ? "melancholic" : (
      Js_string.includes("anxious", lower) || Js_string.includes("worried", lower) ? "anxious" : (
          Js_string.includes("ecstatic", lower) || Js_string.includes("joyful", lower) ? "ecstatic" : undefined
        )
    );
  return {
    primary: primary,
    secondary: undefined,
    felicitous: true,
    emotionalTone: emotionalTone,
    confidence: 0.7
  };
}

function score(act) {
  return {
    primary: act.mood.force,
    secondary: undefined,
    felicitous: SpeechAct$Fogbinder.isHappy(act),
    emotionalTone: SpeechAct$Fogbinder.getEmotionalTone(act),
    confidence: SpeechAct$Fogbinder.isHappy(act) ? 0.9 : 0.5
  };
}

function getDescriptor(mood) {
  let match = mood.primary;
  let primary;
  switch (match.TAG) {
    case "Assertive" :
      primary = "Stating";
      break;
    case "Directive" :
      primary = "Directing";
      break;
    case "Commissive" :
      primary = "Committing";
      break;
    case "Expressive" :
      primary = "Expressing";
      break;
    case "Declaration" :
      primary = "Declaring";
      break;
  }
  let felicity = mood.felicitous ? "" : " (infelicitous)";
  let e = mood.emotionalTone;
  let emotion = e !== undefined ? ` [` + e + `]` : "";
  return primary + emotion + felicity;
}

function compare(m1, m2) {
  let match = m1.primary;
  let match$1 = m2.primary;
  let same;
  switch (match.TAG) {
    case "Assertive" :
      same = match$1.TAG === "Assertive";
      break;
    case "Directive" :
      same = match$1.TAG === "Directive";
      break;
    case "Commissive" :
      same = match$1.TAG === "Commissive";
      break;
    case "Expressive" :
      same = match$1.TAG === "Expressive";
      break;
    case "Declaration" :
      same = match$1.TAG === "Declaration";
      break;
  }
  if (same) {
    return "Similar illocutionary force";
  } else {
    return "Different speech acts";
  }
}

function toJson(mood) {
  let dict = {};
  dict["descriptor"] = getDescriptor(mood);
  dict["felicitous"] = mood.felicitous;
  dict["confidence"] = mood.confidence;
  return dict;
}

export {
  analyze,
  score,
  getDescriptor,
  compare,
  toJson,
}
/* No side effect */
