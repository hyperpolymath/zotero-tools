


function make(utterance, force, context, param) {
  let performative;
  switch (force.TAG) {
    case "Commissive" :
    case "Declaration" :
      performative = true;
      break;
    default:
      performative = false;
  }
  return {
    utterance: utterance,
    mood: {
      force: force,
      felicity: {
        conventionalProcedure: true,
        appropriateCircumstances: true,
        executedCorrectly: true,
        executedCompletely: true,
        sincereIntentions: true
      },
      context: context,
      performative: performative
    },
    timestamp: Date.now()
  };
}

function isHappy(act) {
  let f = act.mood.felicity;
  if (f.conventionalProcedure && f.appropriateCircumstances && f.executedCorrectly && f.executedCompletely) {
    return f.sincereIntentions;
  } else {
    return false;
  }
}

function getMoodDescriptor(act) {
  let content = act.mood.force;
  switch (content.TAG) {
    case "Assertive" :
      return `Asserting: ` + content._0;
    case "Directive" :
      return `Directing: ` + content._0;
    case "Commissive" :
      return `Committing: ` + content._0;
    case "Expressive" :
      return `Expressing: ` + content._0;
    case "Declaration" :
      return `Declaring: ` + content._0;
  }
}

function getEmotionalTone(act) {
  let emotion = act.mood.force;
  if (emotion.TAG === "Expressive") {
    return emotion._0;
  }
}

function conflicts(act1, act2) {
  let match = act1.mood.force;
  let match$1 = act2.mood.force;
  switch (match.TAG) {
    case "Assertive" :
      if (match$1.TAG === "Assertive") {
        return match._0 !== match$1._0;
      } else {
        return false;
      }
    case "Declaration" :
      if (match$1.TAG === "Declaration") {
        return match._0 !== match$1._0;
      } else {
        return false;
      }
    default:
      return false;
  }
}

export {
  make,
  isHappy,
  getMoodDescriptor,
  getEmotionalTone,
  conflicts,
}
/* No side effect */
