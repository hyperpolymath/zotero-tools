// FamilyResemblance.test.res
// Tests for Wittgenstein's family resemblance concept
// License: MIT OR AGPL-3.0 (with Palimpsest)

open FamilyResemblance

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

// Test data: "Game" example from Philosophical Investigations section 66
let gameFeatures: array<feature> = [
  {
    name: "competition",
    weight: 0.3,
    exemplars: ["chess", "football", "tennis"],
  },
  {
    name: "skill",
    weight: 0.3,
    exemplars: ["chess", "tennis", "poker"],
  },
  {
    name: "amusement",
    weight: 0.2,
    exemplars: ["solitaire", "ring-around-the-rosie", "peek-a-boo"],
  },
  {
    name: "luck",
    weight: 0.2,
    exemplars: ["poker", "dice", "lottery"],
  },
  {
    name: "teams",
    weight: 0.15,
    exemplars: ["football", "baseball", "volleyball"],
  },
]

let gameMembers = ["chess", "football", "tennis", "poker", "solitaire", "dice"]

// Test: make creates a family resemblance cluster
let testMake = () => {
  let games = make(~label="Games", ~features=gameFeatures, ~members=gameMembers, ())

  assertEqual(games.label, "Games", "Label should be Games")
  assertEqual(Array.length(games.members), 6, "Should have 6 members")
  assertEqual(games.boundaries, "vague", "Boundaries should be vague")
}

// Test: initializes with no center of gravity
let testNoCenterOfGravity = () => {
  let games = make(~label="Games", ~features=gameFeatures, ~members=gameMembers, ())

  switch games.centerOfGravity {
  | None => assertTrue(true, "No center of gravity initially")
  | Some(_) => assertTrue(false, "Should have no center of gravity")
  }
}

// Test: belongsToFamily with sufficient overlapping features
let testBelongsToFamily = () => {
  let games = make(~label="Games", ~features=gameFeatures, ~members=gameMembers, ())

  // Chess has competition + skill = 0.6 > 0.5 threshold
  let belongs = belongsToFamily("chess", ["competition", "skill"], games)

  assertEqual(belongs, true, "Chess should belong to Games family")
}

// Test: findPrototype finds member with most features
let testFindPrototype = () => {
  let games = make(~label="Games", ~features=gameFeatures, ~members=gameMembers, ())

  let prototype = findPrototype(games)

  switch prototype {
  | Some(game) =>
    // Chess, tennis, or poker likely (have multiple features)
    assertTrue(
      game == "chess" || game == "tennis" || game == "poker" || game == "football",
      "Prototype should be a game with multiple features",
    )
  | None => assertTrue(false, "Expected a prototype")
  }
}

// Test: merge combines two families
let testMerge = () => {
  let indoor = make(
    ~label="Indoor Games",
    ~features=[{name: "indoors", weight: 0.5, exemplars: ["chess", "poker"]}],
    ~members=["chess", "poker"],
    (),
  )

  let outdoor = make(
    ~label="Outdoor Games",
    ~features=[{name: "outdoors", weight: 0.5, exemplars: ["football", "tennis"]}],
    ~members=["football", "tennis"],
    (),
  )

  let merged = merge(indoor, outdoor)

  assertEqual(Array.length(merged.features), 2, "Merged should have 2 features")
  assertEqual(Array.length(merged.members), 4, "Merged should have 4 members")
  assertEqual(merged.boundaries, "contested", "Merged boundaries should be contested")
  assertEqual(merged.label, "Indoor Games + Outdoor Games", "Label should be combined")
}

// Test: resemblanceStrength calculates strength
let testResemblanceStrength = () => {
  let games = make(~label="Games", ~features=gameFeatures, ~members=gameMembers, ())

  // Chess and tennis both have competition + skill
  let strength = resemblanceStrength("chess", "tennis", games)

  assertTrue(strength > 0.5, "Chess and tennis should have high resemblance")
}

// Test: resemblanceStrength returns 0 for non-overlapping
let testResemblanceStrengthZero = () => {
  let games = make(~label="Games", ~features=gameFeatures, ~members=gameMembers, ())

  // Chess (competition, skill) vs dice (luck) - no overlap
  let strength = resemblanceStrength("chess", "dice", games)

  assertEqual(strength, 0.0, "Chess and dice should have no resemblance")
}

// Test: resemblanceStrength is symmetric
let testResemblanceStrengthSymmetric = () => {
  let games = make(~label="Games", ~features=gameFeatures, ~members=gameMembers, ())

  let strengthAB = resemblanceStrength("chess", "poker", games)
  let strengthBA = resemblanceStrength("poker", "chess", games)

  assertEqual(strengthAB, strengthBA, "Resemblance should be symmetric")
}

// Test: toNetwork creates edges
let testToNetwork = () => {
  let games = make(~label="Games", ~features=gameFeatures, ~members=gameMembers, ())

  let network = toNetwork(games)

  assertTrue(Array.length(network) > 0, "Network should have edges")
}

// Test: toNetwork creates no self-edges
let testToNetworkNoSelfEdges = () => {
  let games = make(~label="Games", ~features=gameFeatures, ~members=gameMembers, ())

  let network = toNetwork(games)

  let hasSelfEdge = Array.some(network, ((from, to, _)) => from == to)

  assertEqual(hasSelfEdge, false, "Network should have no self-edges")
}

// Test: vague boundaries (Wittgenstein's point)
let testVagueBoundaries = () => {
  let throwingBall = make(
    ~label="Ball Games",
    ~features=[{name: "amusement", weight: 0.2, exemplars: ["throw-and-catch"]}],
    ~members=["throw-and-catch"],
    (),
  )

  assertEqual(throwingBall.boundaries, "vague", "Boundaries should be vague")
}

// Run all tests
let runTests = () => {
  Console.log("================================")
  Console.log("Running FamilyResemblance Tests")
  Console.log("================================")

  testMake()
  testNoCenterOfGravity()
  testBelongsToFamily()
  testFindPrototype()
  testMerge()
  testResemblanceStrength()
  testResemblanceStrengthZero()
  testResemblanceStrengthSymmetric()
  testToNetwork()
  testToNetworkNoSelfEdges()
  testVagueBoundaries()

  Console.log("================================")
  Console.log("All FamilyResemblance tests completed")
  Console.log("================================")
}

// Auto-run tests when loaded
runTests()
