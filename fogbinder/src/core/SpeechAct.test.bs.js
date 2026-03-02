

import * as Primitive_object from "@rescript/runtime/lib/es6/Primitive_object.js";
import * as SpeechAct$Fogbinder from "./SpeechAct.bs.js";

function assertEqual(actual, expected, message) {
  if (Primitive_object.notequal(actual, expected)) {
    console.error("FAIL:", message);
  } else {
    console.log("PASS:", message);
  }
}

function assertTrue(condition, message) {
  if (condition) {
    console.log("PASS:", message);
  } else {
    console.error("FAIL:", message);
  }
}

let testContext_conventions = [];

let testContext_participants = [];

let testContext = {
  domain: "Scientific",
  conventions: testContext_conventions,
  participants: testContext_participants,
  purpose: "Testing"
};

function testAssertive() {
  let act = SpeechAct$Fogbinder.make("The sky is blue", {
    TAG: "Assertive",
    _0: "The sky is blue",
    [Symbol.for("name")]: "Assertive"
  }, testContext, undefined);
  assertEqual(act.utterance, "The sky is blue", "Utterance should be preserved");
  assertEqual(act.mood.performative, false, "Assertive should not be performative");
}

function testDeclaration() {
  let act = SpeechAct$Fogbinder.make("I hereby declare this session open", {
    TAG: "Declaration",
    _0: "session open",
    [Symbol.for("name")]: "Declaration"
  }, testContext, undefined);
  assertEqual(act.mood.performative, true, "Declaration should be performative");
}

function testCommissive() {
  let act = SpeechAct$Fogbinder.make("I promise to finish the report", {
    TAG: "Commissive",
    _0: "finish report",
    [Symbol.for("name")]: "Commissive"
  }, testContext, undefined);
  assertEqual(act.mood.performative, true, "Commissive should be performative");
}

function testDirective() {
  let act = SpeechAct$Fogbinder.make("Please close the door", {
    TAG: "Directive",
    _0: "close door",
    [Symbol.for("name")]: "Directive"
  }, testContext, undefined);
  assertEqual(act.mood.performative, false, "Directive should not be performative");
}

function testExpressive() {
  let act = SpeechAct$Fogbinder.make("Thank you so much!", {
    TAG: "Expressive",
    _0: "gratitude",
    [Symbol.for("name")]: "Expressive"
  }, testContext, undefined);
  assertEqual(act.mood.performative, false, "Expressive should not be performative");
}

function testIsHappy() {
  let act = SpeechAct$Fogbinder.make("I now pronounce you married", {
    TAG: "Declaration",
    _0: "married",
    [Symbol.for("name")]: "Declaration"
  }, testContext, undefined);
  assertEqual(SpeechAct$Fogbinder.isHappy(act), true, "Felicitous speech act should be happy");
}

function testFelicityConditions() {
  let act = SpeechAct$Fogbinder.make("Test utterance", {
    TAG: "Assertive",
    _0: "test",
    [Symbol.for("name")]: "Assertive"
  }, testContext, undefined);
  let f = act.mood.felicity;
  assertEqual(f.conventionalProcedure, true, "conventionalProcedure should be true");
  assertEqual(f.appropriateCircumstances, true, "appropriateCircumstances should be true");
  assertEqual(f.executedCorrectly, true, "executedCorrectly should be true");
  assertEqual(f.executedCompletely, true, "executedCompletely should be true");
  assertEqual(f.sincereIntentions, true, "sincereIntentions should be true");
}

function testMoodDescriptorAssertive() {
  let act = SpeechAct$Fogbinder.make("Water boils at 100C", {
    TAG: "Assertive",
    _0: "Water boils at 100C",
    [Symbol.for("name")]: "Assertive"
  }, testContext, undefined);
  assertEqual(SpeechAct$Fogbinder.getMoodDescriptor(act), "Asserting: Water boils at 100C", "Should describe assertive mood");
}

function testMoodDescriptorDirective() {
  let act = SpeechAct$Fogbinder.make("Submit the form", {
    TAG: "Directive",
    _0: "submit form",
    [Symbol.for("name")]: "Directive"
  }, testContext, undefined);
  assertEqual(SpeechAct$Fogbinder.getMoodDescriptor(act), "Directing: submit form", "Should describe directive mood");
}

function testGetEmotionalToneExpressive() {
  let act = SpeechAct$Fogbinder.make("I'm so sorry", {
    TAG: "Expressive",
    _0: "sorrow",
    [Symbol.for("name")]: "Expressive"
  }, testContext, undefined);
  let tone = SpeechAct$Fogbinder.getEmotionalTone(act);
  if (tone !== undefined) {
    return assertEqual(tone, "sorrow", "Should extract emotional tone");
  } else {
    return assertTrue(false, "Expected Some(tone)");
  }
}

function testGetEmotionalToneNonExpressive() {
  let act = SpeechAct$Fogbinder.make("The cat is on the mat", {
    TAG: "Assertive",
    _0: "cat location",
    [Symbol.for("name")]: "Assertive"
  }, testContext, undefined);
  let match = SpeechAct$Fogbinder.getEmotionalTone(act);
  if (match !== undefined) {
    return assertTrue(false, "Should return None");
  } else {
    return assertTrue(true, "Correctly returned None for non-expressive");
  }
}

function testConflictsDifferentAssertives() {
  let act1 = SpeechAct$Fogbinder.make("The value is 42", {
    TAG: "Assertive",
    _0: "value is 42",
    [Symbol.for("name")]: "Assertive"
  }, testContext, undefined);
  let act2 = SpeechAct$Fogbinder.make("The value is 7", {
    TAG: "Assertive",
    _0: "value is 7",
    [Symbol.for("name")]: "Assertive"
  }, testContext, undefined);
  assertEqual(SpeechAct$Fogbinder.conflicts(act1, act2), true, "Different assertives should conflict");
}

function testConflictsSameAssertives() {
  let act1 = SpeechAct$Fogbinder.make("The sky is blue", {
    TAG: "Assertive",
    _0: "sky is blue",
    [Symbol.for("name")]: "Assertive"
  }, testContext, undefined);
  let act2 = SpeechAct$Fogbinder.make("The sky is blue", {
    TAG: "Assertive",
    _0: "sky is blue",
    [Symbol.for("name")]: "Assertive"
  }, testContext, undefined);
  assertEqual(SpeechAct$Fogbinder.conflicts(act1, act2), false, "Same assertives should not conflict");
}

function testNoConflictDifferentForces() {
  let act1 = SpeechAct$Fogbinder.make("Close the door", {
    TAG: "Directive",
    _0: "close door",
    [Symbol.for("name")]: "Directive"
  }, testContext, undefined);
  let act2 = SpeechAct$Fogbinder.make("The door is open", {
    TAG: "Assertive",
    _0: "door is open",
    [Symbol.for("name")]: "Assertive"
  }, testContext, undefined);
  assertEqual(SpeechAct$Fogbinder.conflicts(act1, act2), false, "Different force types should not conflict");
}

function runTests() {
  console.log("================================");
  console.log("Running SpeechAct Tests");
  console.log("================================");
  testAssertive();
  testDeclaration();
  testCommissive();
  testDirective();
  testExpressive();
  testIsHappy();
  testFelicityConditions();
  testMoodDescriptorAssertive();
  testMoodDescriptorDirective();
  testGetEmotionalToneExpressive();
  testGetEmotionalToneNonExpressive();
  testConflictsDifferentAssertives();
  testConflictsSameAssertives();
  testNoConflictDifferentForces();
  console.log("================================");
  console.log("All SpeechAct tests completed");
  console.log("================================");
}

runTests();

export {
  assertEqual,
  assertTrue,
  testContext,
  testAssertive,
  testDeclaration,
  testCommissive,
  testDirective,
  testExpressive,
  testIsHappy,
  testFelicityConditions,
  testMoodDescriptorAssertive,
  testMoodDescriptorDirective,
  testGetEmotionalToneExpressive,
  testGetEmotionalToneNonExpressive,
  testConflictsDifferentAssertives,
  testConflictsSameAssertives,
  testNoConflictDifferentForces,
  runTests,
}
/*  Not a pure module */
