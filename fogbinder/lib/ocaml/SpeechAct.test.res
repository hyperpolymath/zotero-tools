// SpeechAct.test.res
// Tests for J.L. Austin's speech act theory implementation
// License: MIT OR AGPL-3.0 (with Palimpsest)

open SpeechAct

// Test helpers
let assertEqual = (actual, expected, message) => {
  if actual != expected {
    Console.error2("FAIL:", message)
  } else {
    Console.log2("PASS:", message)
  }
}

let assertTrue = (condition, message) => {
  if !condition {
    Console.error2("FAIL:", message)
  } else {
    Console.log2("PASS:", message)
  }
}

// Create test context
let testContext: EpistemicState.languageGame = {
  domain: "Scientific",
  conventions: [],
  participants: [],
  purpose: "Testing",
}

// Test: Create assertive speech act
let testAssertive = () => {
  let act = make(
    ~utterance="The sky is blue",
    ~force=Assertive("The sky is blue"),
    ~context=testContext,
    (),
  )

  assertEqual(act.utterance, "The sky is blue", "Utterance should be preserved")
  assertEqual(act.mood.performative, false, "Assertive should not be performative")
}

// Test: Create performative declaration
let testDeclaration = () => {
  let act = make(
    ~utterance="I hereby declare this session open",
    ~force=Declaration("session open"),
    ~context=testContext,
    (),
  )

  assertEqual(act.mood.performative, true, "Declaration should be performative")
}

// Test: Create performative commissive
let testCommissive = () => {
  let act = make(
    ~utterance="I promise to finish the report",
    ~force=Commissive("finish report"),
    ~context=testContext,
    (),
  )

  assertEqual(act.mood.performative, true, "Commissive should be performative")
}

// Test: Create non-performative directive
let testDirective = () => {
  let act = make(
    ~utterance="Please close the door",
    ~force=Directive("close door"),
    ~context=testContext,
    (),
  )

  assertEqual(act.mood.performative, false, "Directive should not be performative")
}

// Test: Create non-performative expressive
let testExpressive = () => {
  let act = make(
    ~utterance="Thank you so much!",
    ~force=Expressive("gratitude"),
    ~context=testContext,
    (),
  )

  assertEqual(act.mood.performative, false, "Expressive should not be performative")
}

// Test: isHappy returns true for felicitous speech act
let testIsHappy = () => {
  let act = make(
    ~utterance="I now pronounce you married",
    ~force=Declaration("married"),
    ~context=testContext,
    (),
  )

  assertEqual(isHappy(act), true, "Felicitous speech act should be happy")
}

// Test: Check felicity conditions
let testFelicityConditions = () => {
  let act = make(
    ~utterance="Test utterance",
    ~force=Assertive("test"),
    ~context=testContext,
    (),
  )

  let f = act.mood.felicity
  assertEqual(f.conventionalProcedure, true, "conventionalProcedure should be true")
  assertEqual(f.appropriateCircumstances, true, "appropriateCircumstances should be true")
  assertEqual(f.executedCorrectly, true, "executedCorrectly should be true")
  assertEqual(f.executedCompletely, true, "executedCompletely should be true")
  assertEqual(f.sincereIntentions, true, "sincereIntentions should be true")
}

// Test: getMoodDescriptor for assertive
let testMoodDescriptorAssertive = () => {
  let act = make(
    ~utterance="Water boils at 100C",
    ~force=Assertive("Water boils at 100C"),
    ~context=testContext,
    (),
  )

  assertEqual(getMoodDescriptor(act), "Asserting: Water boils at 100C", "Should describe assertive mood")
}

// Test: getMoodDescriptor for directive
let testMoodDescriptorDirective = () => {
  let act = make(
    ~utterance="Submit the form",
    ~force=Directive("submit form"),
    ~context=testContext,
    (),
  )

  assertEqual(getMoodDescriptor(act), "Directing: submit form", "Should describe directive mood")
}

// Test: getEmotionalTone extracts from expressive
let testGetEmotionalToneExpressive = () => {
  let act = make(
    ~utterance="I'm so sorry",
    ~force=Expressive("sorrow"),
    ~context=testContext,
    (),
  )

  switch getEmotionalTone(act) {
  | Some(tone) => assertEqual(tone, "sorrow", "Should extract emotional tone")
  | None => assertTrue(false, "Expected Some(tone)")
  }
}

// Test: getEmotionalTone returns None for non-expressive
let testGetEmotionalToneNonExpressive = () => {
  let act = make(
    ~utterance="The cat is on the mat",
    ~force=Assertive("cat location"),
    ~context=testContext,
    (),
  )

  switch getEmotionalTone(act) {
  | Some(_) => assertTrue(false, "Should return None")
  | None => assertTrue(true, "Correctly returned None for non-expressive")
  }
}

// Test: conflicts between different assertives
let testConflictsDifferentAssertives = () => {
  let act1 = make(
    ~utterance="The value is 42",
    ~force=Assertive("value is 42"),
    ~context=testContext,
    (),
  )

  let act2 = make(
    ~utterance="The value is 7",
    ~force=Assertive("value is 7"),
    ~context=testContext,
    (),
  )

  assertEqual(conflicts(act1, act2), true, "Different assertives should conflict")
}

// Test: conflicts between same assertives
let testConflictsSameAssertives = () => {
  let act1 = make(
    ~utterance="The sky is blue",
    ~force=Assertive("sky is blue"),
    ~context=testContext,
    (),
  )

  let act2 = make(
    ~utterance="The sky is blue",
    ~force=Assertive("sky is blue"),
    ~context=testContext,
    (),
  )

  assertEqual(conflicts(act1, act2), false, "Same assertives should not conflict")
}

// Test: no conflict between different force types
let testNoConflictDifferentForces = () => {
  let act1 = make(
    ~utterance="Close the door",
    ~force=Directive("close door"),
    ~context=testContext,
    (),
  )

  let act2 = make(
    ~utterance="The door is open",
    ~force=Assertive("door is open"),
    ~context=testContext,
    (),
  )

  assertEqual(conflicts(act1, act2), false, "Different force types should not conflict")
}

// Run all tests
let runTests = () => {
  Console.log("================================")
  Console.log("Running SpeechAct Tests")
  Console.log("================================")

  testAssertive()
  testDeclaration()
  testCommissive()
  testDirective()
  testExpressive()
  testIsHappy()
  testFelicityConditions()
  testMoodDescriptorAssertive()
  testMoodDescriptorDirective()
  testGetEmotionalToneExpressive()
  testGetEmotionalToneNonExpressive()
  testConflictsDifferentAssertives()
  testConflictsSameAssertives()
  testNoConflictDifferentForces()

  Console.log("================================")
  Console.log("All SpeechAct tests completed")
  Console.log("================================")
}

// Auto-run tests when loaded
runTests()
