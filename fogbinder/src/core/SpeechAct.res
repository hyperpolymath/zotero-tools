// SpeechAct.res
// J.L. Austin's speech act theory: language as action, not just description
// "How to Do Things With Words" - utterances perform actions

// Austin's taxonomy of speech acts
type illocutionaryForce =
  | Assertive(string) // Stating, claiming, asserting (truth-apt)
  | Directive(string) // Commanding, requesting, advising
  | Commissive(string) // Promising, threatening, offering
  | Expressive(string) // Apologizing, thanking, congratulating
  | Declaration(string) // Declaring, pronouncing, naming

// Felicity conditions (what makes a speech act successful)
type felicityConditions = {
  conventionalProcedure: bool, // Is there a recognized convention?
  appropriateCircumstances: bool, // Are circumstances right?
  executedCorrectly: bool, // Was it done properly?
  executedCompletely: bool, // Was it finished?
  sincereIntentions: bool, // Does speaker have requisite intentions?
}

// Mood is NOT sentiment - it's the illocutionary force + felicity
type mood = {
  force: illocutionaryForce,
  felicity: felicityConditions,
  context: EpistemicState.languageGame,
  performative: bool, // Is this a performative utterance?
}

type t = {
  utterance: string,
  mood: mood,
  timestamp: float,
}

// Create speech act from text
let make = (~utterance, ~force, ~context, ()): t => {
  // Default felicity conditions (would be inferred in real implementation)
  let felicity = {
    conventionalProcedure: true,
    appropriateCircumstances: true,
    executedCorrectly: true,
    executedCompletely: true,
    sincereIntentions: true,
  }

  let performative = switch force {
  | Declaration(_) | Commissive(_) => true // These do something in being said
  | _ => false
  }

  {
    utterance,
    mood: {
      force,
      felicity,
      context,
      performative,
    },
    timestamp: Js.Date.now(),
  }
}

// Check if speech act is "happy" (felicitous)
let isHappy = (act: t): bool => {
  let f = act.mood.felicity
  f.conventionalProcedure &&
  f.appropriateCircumstances &&
  f.executedCorrectly &&
  f.executedCompletely &&
  f.sincereIntentions
}

// Get mood descriptor (for UI display)
let getMoodDescriptor = (act: t): string => {
  switch act.mood.force {
  | Assertive(content) => `Asserting: ${content}`
  | Directive(content) => `Directing: ${content}`
  | Commissive(content) => `Committing: ${content}`
  | Expressive(content) => `Expressing: ${content}`
  | Declaration(content) => `Declaring: ${content}`
  }
}

// Extract emotional tone (secondary to illocutionary force)
let getEmotionalTone = (act: t): option<string> => {
  switch act.mood.force {
  | Expressive(emotion) => Some(emotion)
  | _ => None
  }
}

// Analyze if two speech acts conflict (different language games)
let conflicts = (act1: t, act2: t): bool => {
  // Conflict when same utterance type in different contexts with different conventions
  switch (act1.mood.force, act2.mood.force) {
  | (Assertive(c1), Assertive(c2)) when c1 != c2 => true
  | (Declaration(d1), Declaration(d2)) when d1 != d2 => true
  | _ => false
  }
}
