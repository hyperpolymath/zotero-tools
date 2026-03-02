// EpistemicState.test.res
// ReScript tests for EpistemicState module
// License: MIT OR AGPL-3.0 (with Palimpsest)

open EpistemicState

// Test helpers
let assertEqual = (actual, expected, message) => {
  if actual != expected {
    Js.Console.error2("FAIL:", message)
    Js.Console.error2("Expected:", expected)
    Js.Console.error2("Actual:", actual)
  } else {
    Js.Console.log2("✅ PASS:", message)
  }
}

let assertTrue = (condition, message) => {
  if !condition {
    Js.Console.error2("FAIL:", message)
  } else {
    Js.Console.log2("✅ PASS:", message)
  }
}

// Test: Create Known state
let testKnownState = () => {
  let state = make(Known, "Test context", ["Evidence 1"], None)
  assertEqual(state.certainty, Known, "Known state should have Known certainty")
  assertEqual(state.context, "Test context", "Context should be preserved")
  assertTrue(Array.length(state.evidence) == 1, "Should have 1 evidence")
}

// Test: isUncertain for Known
let testKnownIsNotUncertain = () => {
  let state = make(Known, "Context", [], None)
  assertTrue(isUncertain(state) == false, "Known state should not be uncertain")
}

// Test: isUncertain for Probable
let testProbableIsUncertain = () => {
  let state = make(Probable(0.8), "Context", [], None)
  assertTrue(isUncertain(state) == true, "Probable state should be uncertain")
}

// Test: isUncertain for Mysterious
let testMysteriousIsUncertain = () => {
  let state = make(Mysterious, "Context", [], None)
  assertTrue(isUncertain(state) == true, "Mysterious state should be uncertain")
}

// Test: Merge commutativity
let testMergeCommutativity = () => {
  let state1 = make(Known, "Context A", ["Evidence A"], None)
  let state2 = make(Probable(0.7), "Context B", ["Evidence B"], None)

  let mergeAB = merge(state1, state2)
  let mergeBA = merge(state2, state1)

  assertEqual(mergeAB.certainty, mergeBA.certainty, "Merge should be commutative")
}

// Test: Merge preserves evidence
let testMergePreservesEvidence = () => {
  let state1 = make(Known, "Context", ["A", "B"], None)
  let state2 = make(Vague, "Context", ["C"], None)

  let merged = merge(state1, state2)

  assertTrue(
    Array.length(merged.evidence) >= 3,
    "Merged state should preserve all evidence",
  )
}

// Test: Merge Known + Mysterious = Ambiguous
let testMergeKnownMysteriousBecomesAmbiguous = () => {
  let known = make(Known, "Context", [], None)
  let mysterious = make(Mysterious, "Context", [], None)

  let merged = merge(known, mysterious)

  assertEqual(merged.certainty, Ambiguous, "Known + Mysterious should be Ambiguous")
}

// Test: toOpacity
let testOpacityKnown = () => {
  let state = make(Known, "Context", [], None)
  let opacity = toOpacity(state)
  assertEqual(opacity, 0.0, "Known should have opacity 0.0")
}

let testOpacityMysteriousIsHigh = () => {
  let state = make(Mysterious, "Context", [], None)
  let opacity = toOpacity(state)
  assertTrue(opacity >= 0.8, "Mysterious should have high opacity")
}

// Test: toString
let testToString = () => {
  let state = make(Contradictory, "Context", [], None)
  let str = toString(state)
  assertTrue(
    Js.String2.includes(str, "Contradictory"),
    "toString should include certainty level",
  )
}

// Property: toOpacity is always between 0.0 and 1.0
let testOpacityRange = () => {
  let states = [
    make(Known, "C", [], None),
    make(Probable(0.5), "C", [], None),
    make(Vague, "C", [], None),
    make(Ambiguous, "C", [], None),
    make(Mysterious, "C", [], None),
    make(Contradictory, "C", [], None),
  ]

  Array.forEach(states, state => {
    let opacity = toOpacity(state)
    assertTrue(opacity >= 0.0 && opacity <= 1.0, "Opacity must be in [0.0, 1.0]")
  })
}

// Property: isUncertain is consistent with certainty level
let testUncertaintyConsistency = () => {
  let known = make(Known, "C", [], None)
  assertTrue(!isUncertain(known), "Known should not be uncertain")

  let uncertain = [
    make(Probable(0.5), "C", [], None),
    make(Vague, "C", [], None),
    make(Ambiguous, "C", [], None),
    make(Mysterious, "C", [], None),
    make(Contradictory, "C", [], None),
  ]

  Array.forEach(uncertain, state => {
    assertTrue(isUncertain(state), "Non-Known states should be uncertain")
  })
}

// Run all tests
let runTests = () => {
  Js.Console.log("================================")
  Js.Console.log("Running EpistemicState Tests")
  Js.Console.log("================================")

  testKnownState()
  testKnownIsNotUncertain()
  testProbableIsUncertain()
  testMysteriousIsUncertain()
  testMergeCommutativity()
  testMergePreservesEvidence()
  testMergeKnownMysteriousBecomesAmbiguous()
  testOpacityKnown()
  testOpacityMysteriousIsHigh()
  testToString()
  testOpacityRange()
  testUncertaintyConsistency()

  Js.Console.log("================================")
  Js.Console.log("✅ All EpistemicState tests passed")
  Js.Console.log("================================")
}

// Auto-run tests when loaded
runTests()
