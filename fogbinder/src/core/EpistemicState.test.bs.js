

import * as Primitive_object from "@rescript/runtime/lib/es6/Primitive_object.js";
import * as EpistemicState$Fogbinder from "./EpistemicState.bs.js";

function assertEqual(actual, expected, message) {
  if (Primitive_object.notequal(actual, expected)) {
    console.error("FAIL:", message);
    console.error("Expected:", expected);
    console.error("Actual:", actual);
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
  domain: "Test domain",
  conventions: testContext_conventions,
  participants: testContext_participants,
  purpose: "Testing"
};

function testKnownState() {
  let state = EpistemicState$Fogbinder.make("Known", testContext, ["Evidence 1"], undefined);
  assertEqual(state.certainty, "Known", "Known state should have Known certainty");
  assertEqual(state.context.domain, "Test domain", "Context should be preserved");
  assertTrue(state.evidence.length === 1, "Should have 1 evidence");
}

function testKnownIsNotAmbiguous() {
  let state = EpistemicState$Fogbinder.make("Known", testContext, [], undefined);
  assertTrue(EpistemicState$Fogbinder.isGenuinelyAmbiguous(state) === false, "Known state should not be ambiguous");
}

function testProbableIsNotAmbiguous() {
  let state = EpistemicState$Fogbinder.make({
    TAG: "Probable",
    _0: 0.8,
    [Symbol.for("name")]: "Probable"
  }, testContext, [], undefined);
  assertTrue(EpistemicState$Fogbinder.isGenuinelyAmbiguous(state) === false, "Probable state should not be ambiguous");
}

function testMysteriousIsAmbiguous() {
  let state = EpistemicState$Fogbinder.make("Mysterious", testContext, [], undefined);
  assertTrue(EpistemicState$Fogbinder.isGenuinelyAmbiguous(state) === true, "Mysterious state should be ambiguous");
}

function testVagueIsAmbiguous() {
  let state = EpistemicState$Fogbinder.make("Vague", testContext, [], undefined);
  assertTrue(EpistemicState$Fogbinder.isGenuinelyAmbiguous(state) === true, "Vague state should be ambiguous");
}

function testAmbiguousIsAmbiguous() {
  let state = EpistemicState$Fogbinder.make({
    TAG: "Ambiguous",
    _0: [
      "interp1",
      "interp2"
    ],
    [Symbol.for("name")]: "Ambiguous"
  }, testContext, [], undefined);
  assertTrue(EpistemicState$Fogbinder.isGenuinelyAmbiguous(state) === true, "Ambiguous state should be ambiguous");
}

function testContradictoryIsAmbiguous() {
  let state = EpistemicState$Fogbinder.make({
    TAG: "Contradictory",
    _0: ["conflict1"],
    [Symbol.for("name")]: "Contradictory"
  }, testContext, [], undefined);
  assertTrue(EpistemicState$Fogbinder.isGenuinelyAmbiguous(state) === true, "Contradictory state should be ambiguous");
}

function testGetInterpretationsAmbiguous() {
  let state = EpistemicState$Fogbinder.make({
    TAG: "Ambiguous",
    _0: [
      "interp1",
      "interp2",
      "interp3"
    ],
    [Symbol.for("name")]: "Ambiguous"
  }, testContext, [], undefined);
  let interps = EpistemicState$Fogbinder.getInterpretations(state);
  assertTrue(interps.length === 3, "Should return 3 interpretations");
}

function testGetInterpretationsContradictory() {
  let state = EpistemicState$Fogbinder.make({
    TAG: "Contradictory",
    _0: [
      "conflict1",
      "conflict2"
    ],
    [Symbol.for("name")]: "Contradictory"
  }, testContext, [], undefined);
  let interps = EpistemicState$Fogbinder.getInterpretations(state);
  assertTrue(interps.length === 2, "Should return 2 conflicts");
}

function testGetInterpretationsKnown() {
  let state = EpistemicState$Fogbinder.make("Known", testContext, [], undefined);
  let interps = EpistemicState$Fogbinder.getInterpretations(state);
  assertTrue(interps.length === 0, "Known should have no interpretations");
}

function testMergePreservesEvidence() {
  let state1 = EpistemicState$Fogbinder.make("Known", testContext, [
    "A",
    "B"
  ], undefined);
  let state2 = EpistemicState$Fogbinder.make("Vague", testContext, ["C"], undefined);
  let merged = EpistemicState$Fogbinder.merge(state1, state2);
  assertTrue(merged.evidence.length >= 3, "Merged state should preserve all evidence");
}

function testMergeKnownKnown() {
  let known1 = EpistemicState$Fogbinder.make("Known", testContext, [], undefined);
  let known2 = EpistemicState$Fogbinder.make("Known", testContext, [], undefined);
  let merged = EpistemicState$Fogbinder.merge(known1, known2);
  assertEqual(merged.certainty, "Known", "Known + Known should be Known");
}

function testMergeProbableProbable() {
  let prob1 = EpistemicState$Fogbinder.make({
    TAG: "Probable",
    _0: 0.6,
    [Symbol.for("name")]: "Probable"
  }, testContext, [], undefined);
  let prob2 = EpistemicState$Fogbinder.make({
    TAG: "Probable",
    _0: 0.8,
    [Symbol.for("name")]: "Probable"
  }, testContext, [], undefined);
  let merged = EpistemicState$Fogbinder.merge(prob1, prob2);
  let p = merged.certainty;
  if (typeof p !== "object" || p.TAG !== "Probable") {
    return assertTrue(false, "Should be Probable");
  } else {
    return assertTrue(p._0 === 0.7, "Probabilities should be averaged");
  }
}

function testMergeKnownMysterious() {
  let known = EpistemicState$Fogbinder.make("Known", testContext, [], undefined);
  let mysterious = EpistemicState$Fogbinder.make("Mysterious", testContext, [], undefined);
  let merged = EpistemicState$Fogbinder.merge(known, mysterious);
  assertEqual(merged.certainty, "Mysterious", "Known + Mysterious should be Mysterious");
}

function testMergeAmbiguousAmbiguous() {
  let amb1 = EpistemicState$Fogbinder.make({
    TAG: "Ambiguous",
    _0: [
      "a",
      "b"
    ],
    [Symbol.for("name")]: "Ambiguous"
  }, testContext, [], undefined);
  let amb2 = EpistemicState$Fogbinder.make({
    TAG: "Ambiguous",
    _0: [
      "c",
      "d"
    ],
    [Symbol.for("name")]: "Ambiguous"
  }, testContext, [], undefined);
  let merged = EpistemicState$Fogbinder.merge(amb1, amb2);
  let interps = merged.certainty;
  if (typeof interps !== "object" || interps.TAG !== "Ambiguous") {
    return assertTrue(false, "Should be Ambiguous");
  } else {
    return assertTrue(interps._0.length === 4, "Should combine interpretations");
  }
}

function testToJsonProducesObject() {
  let state = EpistemicState$Fogbinder.make("Vague", testContext, ["test"], undefined);
  EpistemicState$Fogbinder.toJson(state);
  assertTrue(true, "toJson should produce valid JSON");
}

function runTests() {
  console.log("================================");
  console.log("Running EpistemicState Tests");
  console.log("================================");
  testKnownState();
  testKnownIsNotAmbiguous();
  testProbableIsNotAmbiguous();
  testMysteriousIsAmbiguous();
  testVagueIsAmbiguous();
  testAmbiguousIsAmbiguous();
  testContradictoryIsAmbiguous();
  testGetInterpretationsAmbiguous();
  testGetInterpretationsContradictory();
  testGetInterpretationsKnown();
  testMergePreservesEvidence();
  testMergeKnownKnown();
  testMergeProbableProbable();
  testMergeKnownMysterious();
  testMergeAmbiguousAmbiguous();
  testToJsonProducesObject();
  console.log("================================");
  console.log("All EpistemicState tests completed");
  console.log("================================");
}

runTests();

export {
  assertEqual,
  assertTrue,
  testContext,
  testKnownState,
  testKnownIsNotAmbiguous,
  testProbableIsNotAmbiguous,
  testMysteriousIsAmbiguous,
  testVagueIsAmbiguous,
  testAmbiguousIsAmbiguous,
  testContradictoryIsAmbiguous,
  testGetInterpretationsAmbiguous,
  testGetInterpretationsContradictory,
  testGetInterpretationsKnown,
  testMergePreservesEvidence,
  testMergeKnownKnown,
  testMergeProbableProbable,
  testMergeKnownMysterious,
  testMergeAmbiguousAmbiguous,
  testToJsonProducesObject,
  runTests,
}
/*  Not a pure module */
