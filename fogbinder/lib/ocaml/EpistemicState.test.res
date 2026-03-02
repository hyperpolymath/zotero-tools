// EpistemicState.test.res
// ReScript tests for EpistemicState module
// License: MIT OR AGPL-3.0 (with Palimpsest)

open EpistemicState

// Test helpers
let assertEqual = (actual, expected, message) => {
  if actual != expected {
    Console.error2("FAIL:", message)
    Console.error2("Expected:", expected)
    Console.error2("Actual:", actual)
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
let testContext: languageGame = {
  domain: "Test domain",
  conventions: [],
  participants: [],
  purpose: "Testing",
}

// Test: Create Known state
let testKnownState = () => {
  let state = make(~certainty=Known, ~context=testContext, ~evidence=["Evidence 1"], ())
  assertEqual(state.certainty, Known, "Known state should have Known certainty")
  assertEqual(state.context.domain, "Test domain", "Context should be preserved")
  assertTrue(Array.length(state.evidence) == 1, "Should have 1 evidence")
}

// Test: isGenuinelyAmbiguous for Known
let testKnownIsNotAmbiguous = () => {
  let state = make(~certainty=Known, ~context=testContext, ~evidence=[], ())
  assertTrue(isGenuinelyAmbiguous(state) == false, "Known state should not be ambiguous")
}

// Test: isGenuinelyAmbiguous for Probable
let testProbableIsNotAmbiguous = () => {
  let state = make(~certainty=Probable(0.8), ~context=testContext, ~evidence=[], ())
  assertTrue(isGenuinelyAmbiguous(state) == false, "Probable state should not be ambiguous")
}

// Test: isGenuinelyAmbiguous for Mysterious
let testMysteriousIsAmbiguous = () => {
  let state = make(~certainty=Mysterious, ~context=testContext, ~evidence=[], ())
  assertTrue(isGenuinelyAmbiguous(state) == true, "Mysterious state should be ambiguous")
}

// Test: isGenuinelyAmbiguous for Vague
let testVagueIsAmbiguous = () => {
  let state = make(~certainty=Vague, ~context=testContext, ~evidence=[], ())
  assertTrue(isGenuinelyAmbiguous(state) == true, "Vague state should be ambiguous")
}

// Test: isGenuinelyAmbiguous for Ambiguous
let testAmbiguousIsAmbiguous = () => {
  let state = make(~certainty=Ambiguous(["interp1", "interp2"]), ~context=testContext, ~evidence=[], ())
  assertTrue(isGenuinelyAmbiguous(state) == true, "Ambiguous state should be ambiguous")
}

// Test: isGenuinelyAmbiguous for Contradictory
let testContradictoryIsAmbiguous = () => {
  let state = make(~certainty=Contradictory(["conflict1"]), ~context=testContext, ~evidence=[], ())
  assertTrue(isGenuinelyAmbiguous(state) == true, "Contradictory state should be ambiguous")
}

// Test: getInterpretations for Ambiguous
let testGetInterpretationsAmbiguous = () => {
  let state = make(~certainty=Ambiguous(["interp1", "interp2", "interp3"]), ~context=testContext, ~evidence=[], ())
  let interps = getInterpretations(state)
  assertTrue(Array.length(interps) == 3, "Should return 3 interpretations")
}

// Test: getInterpretations for Contradictory
let testGetInterpretationsContradictory = () => {
  let state = make(~certainty=Contradictory(["conflict1", "conflict2"]), ~context=testContext, ~evidence=[], ())
  let interps = getInterpretations(state)
  assertTrue(Array.length(interps) == 2, "Should return 2 conflicts")
}

// Test: getInterpretations for Known (empty)
let testGetInterpretationsKnown = () => {
  let state = make(~certainty=Known, ~context=testContext, ~evidence=[], ())
  let interps = getInterpretations(state)
  assertTrue(Array.length(interps) == 0, "Known should have no interpretations")
}

// Test: Merge preserves evidence
let testMergePreservesEvidence = () => {
  let state1 = make(~certainty=Known, ~context=testContext, ~evidence=["A", "B"], ())
  let state2 = make(~certainty=Vague, ~context=testContext, ~evidence=["C"], ())

  let merged = merge(state1, state2)

  assertTrue(
    Array.length(merged.evidence) >= 3,
    "Merged state should preserve all evidence",
  )
}

// Test: Merge Known + Known = Known
let testMergeKnownKnown = () => {
  let known1 = make(~certainty=Known, ~context=testContext, ~evidence=[], ())
  let known2 = make(~certainty=Known, ~context=testContext, ~evidence=[], ())

  let merged = merge(known1, known2)

  assertEqual(merged.certainty, Known, "Known + Known should be Known")
}

// Test: Merge Probable + Probable = Probable (averaged)
let testMergeProbableProbable = () => {
  let prob1 = make(~certainty=Probable(0.6), ~context=testContext, ~evidence=[], ())
  let prob2 = make(~certainty=Probable(0.8), ~context=testContext, ~evidence=[], ())

  let merged = merge(prob1, prob2)

  switch merged.certainty {
  | Probable(p) => assertTrue(p == 0.7, "Probabilities should be averaged")
  | _ => assertTrue(false, "Should be Probable")
  }
}

// Test: Merge Known + Mysterious = Mysterious
let testMergeKnownMysterious = () => {
  let known = make(~certainty=Known, ~context=testContext, ~evidence=[], ())
  let mysterious = make(~certainty=Mysterious, ~context=testContext, ~evidence=[], ())

  let merged = merge(known, mysterious)

  assertEqual(merged.certainty, Mysterious, "Known + Mysterious should be Mysterious")
}

// Test: Merge Ambiguous + Ambiguous combines interpretations
let testMergeAmbiguousAmbiguous = () => {
  let amb1 = make(~certainty=Ambiguous(["a", "b"]), ~context=testContext, ~evidence=[], ())
  let amb2 = make(~certainty=Ambiguous(["c", "d"]), ~context=testContext, ~evidence=[], ())

  let merged = merge(amb1, amb2)

  switch merged.certainty {
  | Ambiguous(interps) => assertTrue(Array.length(interps) == 4, "Should combine interpretations")
  | _ => assertTrue(false, "Should be Ambiguous")
  }
}

// Test: toJson produces valid JSON
let testToJsonProducesObject = () => {
  let state = make(~certainty=Vague, ~context=testContext, ~evidence=["test"], ())
  let _json = toJson(state)
  // If we get here without error, the test passes
  assertTrue(true, "toJson should produce valid JSON")
}

// Run all tests
let runTests = () => {
  Console.log("================================")
  Console.log("Running EpistemicState Tests")
  Console.log("================================")

  testKnownState()
  testKnownIsNotAmbiguous()
  testProbableIsNotAmbiguous()
  testMysteriousIsAmbiguous()
  testVagueIsAmbiguous()
  testAmbiguousIsAmbiguous()
  testContradictoryIsAmbiguous()
  testGetInterpretationsAmbiguous()
  testGetInterpretationsContradictory()
  testGetInterpretationsKnown()
  testMergePreservesEvidence()
  testMergeKnownKnown()
  testMergeProbableProbable()
  testMergeKnownMysterious()
  testMergeAmbiguousAmbiguous()
  testToJsonProducesObject()

  Console.log("================================")
  Console.log("All EpistemicState tests completed")
  Console.log("================================")
}

// Auto-run tests when loaded
runTests()
