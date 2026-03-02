// MoodScorer.res
// Mood scoring based on SPEECH ACT THEORY, not sentiment analysis
// J.L. Austin: mood is about what you're doing with words, not how you feel

open SpeechAct
open EpistemicState

// Mood score is illocutionary force + felicity + context
type moodScore = {
  primary: illocutionaryForce,
  secondary: option<illocutionaryForce>, // Mixed speech acts
  felicitous: bool,
  emotionalTone: option<string>, // Secondary to speech act
  confidence: float, // How sure are we of this analysis?
}

type t = moodScore

// Analyze text to extract mood (simplified - would use NLP in production)
let analyze = (text: string, context: languageGame): moodScore => {
  // This is a simplified heuristic - real implementation would use:
  // - Part-of-speech tagging
  // - Performative verb detection
  // - Context analysis
  // - Felicity condition checking

  let lower = Js.String.toLowerCase(text)

  // Detect performative verbs (Austin's key insight)
  let primary = if Js.String.includes("promise", lower) ||
    Js.String.includes("vow", lower) {
    Commissive("commitment")
  } else if Js.String.includes("command", lower) ||
    Js.String.includes("request", lower) ||
    Js.String.includes("must", lower) {
    Directive("directive")
  } else if Js.String.includes("declare", lower) ||
    Js.String.includes("pronounce", lower) {
    Declaration("declaration")
  } else if Js.String.includes("thank", lower) ||
    Js.String.includes("apologize", lower) ||
    Js.String.includes("congratulate", lower) {
    Expressive("gratitude/apology")
  } else {
    Assertive("statement") // Default to assertive
  }

  // Extract emotional tone (secondary)
  let emotionalTone = if Js.String.includes("melancholy", lower) ||
    Js.String.includes("sad", lower) {
    Some("melancholic")
  } else if Js.String.includes("anxious", lower) ||
    Js.String.includes("worried", lower) {
    Some("anxious")
  } else if Js.String.includes("ecstatic", lower) ||
    Js.String.includes("joyful", lower) {
    Some("ecstatic")
  } else {
    None
  }

  {
    primary,
    secondary: None,
    felicitous: true, // Would check felicity conditions
    emotionalTone,
    confidence: 0.7, // Simplified heuristic has moderate confidence
  }
}

// Score a speech act
let score = (act: SpeechAct.t): moodScore => {
  {
    primary: act.mood.force,
    secondary: None,
    felicitous: SpeechAct.isHappy(act),
    emotionalTone: SpeechAct.getEmotionalTone(act),
    confidence: if SpeechAct.isHappy(act) { 0.9 } else { 0.5 },
  }
}

// Get mood descriptor for UI
let getDescriptor = (mood: moodScore): string => {
  let primary = switch mood.primary {
  | Assertive(_) => "Stating"
  | Directive(_) => "Directing"
  | Commissive(_) => "Committing"
  | Expressive(_) => "Expressing"
  | Declaration(_) => "Declaring"
  }

  let felicity = if mood.felicitous { "" } else { " (infelicitous)" }

  let emotion = switch mood.emotionalTone {
  | Some(e) => ` [${e}]`
  | None => ""
  }

  `${primary}${emotion}${felicity}`
}

// Compare moods across sources
let compare = (m1: moodScore, m2: moodScore): string => {
  let same = switch (m1.primary, m2.primary) {
  | (Assertive(_), Assertive(_)) => true
  | (Directive(_), Directive(_)) => true
  | (Commissive(_), Commissive(_)) => true
  | (Expressive(_), Expressive(_)) => true
  | (Declaration(_), Declaration(_)) => true
  | _ => false
  }

  if same {
    "Similar illocutionary force"
  } else {
    "Different speech acts"
  }
}

// Convert to JSON
let toJson = (mood: moodScore): Js.Json.t => {
  open Js.Dict
  let dict = empty()

  set(dict, "descriptor", Js.Json.string(getDescriptor(mood)))
  set(dict, "felicitous", Js.Json.boolean(mood.felicitous))
  set(dict, "confidence", Js.Json.number(mood.confidence))

  Js.Json.object_(dict)
}
