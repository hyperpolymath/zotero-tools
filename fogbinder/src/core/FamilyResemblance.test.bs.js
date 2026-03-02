

import * as Primitive_object from "@rescript/runtime/lib/es6/Primitive_object.js";
import * as FamilyResemblance$Fogbinder from "./FamilyResemblance.bs.js";

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

let gameFeatures = [
  {
    name: "competition",
    weight: 0.3,
    exemplars: [
      "chess",
      "football",
      "tennis"
    ]
  },
  {
    name: "skill",
    weight: 0.3,
    exemplars: [
      "chess",
      "tennis",
      "poker"
    ]
  },
  {
    name: "amusement",
    weight: 0.2,
    exemplars: [
      "solitaire",
      "ring-around-the-rosie",
      "peek-a-boo"
    ]
  },
  {
    name: "luck",
    weight: 0.2,
    exemplars: [
      "poker",
      "dice",
      "lottery"
    ]
  },
  {
    name: "teams",
    weight: 0.15,
    exemplars: [
      "football",
      "baseball",
      "volleyball"
    ]
  }
];

let gameMembers = [
  "chess",
  "football",
  "tennis",
  "poker",
  "solitaire",
  "dice"
];

function testMake() {
  let games = FamilyResemblance$Fogbinder.make("Games", gameFeatures, gameMembers, undefined);
  assertEqual(games.label, "Games", "Label should be Games");
  assertEqual(games.members.length, 6, "Should have 6 members");
  assertEqual(games.boundaries, "vague", "Boundaries should be vague");
}

function testNoCenterOfGravity() {
  let games = FamilyResemblance$Fogbinder.make("Games", gameFeatures, gameMembers, undefined);
  let match = games.centerOfGravity;
  if (match !== undefined) {
    return assertTrue(false, "Should have no center of gravity");
  } else {
    return assertTrue(true, "No center of gravity initially");
  }
}

function testBelongsToFamily() {
  let games = FamilyResemblance$Fogbinder.make("Games", gameFeatures, gameMembers, undefined);
  let belongs = FamilyResemblance$Fogbinder.belongsToFamily("chess", [
    "competition",
    "skill"
  ], games);
  assertEqual(belongs, true, "Chess should belong to Games family");
}

function testFindPrototype() {
  let games = FamilyResemblance$Fogbinder.make("Games", gameFeatures, gameMembers, undefined);
  let prototype = FamilyResemblance$Fogbinder.findPrototype(games);
  if (prototype !== undefined) {
    return assertTrue(prototype === "chess" || prototype === "tennis" || prototype === "poker" || prototype === "football", "Prototype should be a game with multiple features");
  } else {
    return assertTrue(false, "Expected a prototype");
  }
}

function testMerge() {
  let indoor = FamilyResemblance$Fogbinder.make("Indoor Games", [{
      name: "indoors",
      weight: 0.5,
      exemplars: [
        "chess",
        "poker"
      ]
    }], [
    "chess",
    "poker"
  ], undefined);
  let outdoor = FamilyResemblance$Fogbinder.make("Outdoor Games", [{
      name: "outdoors",
      weight: 0.5,
      exemplars: [
        "football",
        "tennis"
      ]
    }], [
    "football",
    "tennis"
  ], undefined);
  let merged = FamilyResemblance$Fogbinder.merge(indoor, outdoor);
  assertEqual(merged.features.length, 2, "Merged should have 2 features");
  assertEqual(merged.members.length, 4, "Merged should have 4 members");
  assertEqual(merged.boundaries, "contested", "Merged boundaries should be contested");
  assertEqual(merged.label, "Indoor Games + Outdoor Games", "Label should be combined");
}

function testResemblanceStrength() {
  let games = FamilyResemblance$Fogbinder.make("Games", gameFeatures, gameMembers, undefined);
  let strength = FamilyResemblance$Fogbinder.resemblanceStrength("chess", "tennis", games);
  assertTrue(strength > 0.5, "Chess and tennis should have high resemblance");
}

function testResemblanceStrengthZero() {
  let games = FamilyResemblance$Fogbinder.make("Games", gameFeatures, gameMembers, undefined);
  let strength = FamilyResemblance$Fogbinder.resemblanceStrength("chess", "dice", games);
  assertEqual(strength, 0.0, "Chess and dice should have no resemblance");
}

function testResemblanceStrengthSymmetric() {
  let games = FamilyResemblance$Fogbinder.make("Games", gameFeatures, gameMembers, undefined);
  let strengthAB = FamilyResemblance$Fogbinder.resemblanceStrength("chess", "poker", games);
  let strengthBA = FamilyResemblance$Fogbinder.resemblanceStrength("poker", "chess", games);
  assertEqual(strengthAB, strengthBA, "Resemblance should be symmetric");
}

function testToNetwork() {
  let games = FamilyResemblance$Fogbinder.make("Games", gameFeatures, gameMembers, undefined);
  let network = FamilyResemblance$Fogbinder.toNetwork(games);
  assertTrue(network.length !== 0, "Network should have edges");
}

function testToNetworkNoSelfEdges() {
  let games = FamilyResemblance$Fogbinder.make("Games", gameFeatures, gameMembers, undefined);
  let network = FamilyResemblance$Fogbinder.toNetwork(games);
  let hasSelfEdge = network.some(param => param[0] === param[1]);
  assertEqual(hasSelfEdge, false, "Network should have no self-edges");
}

function testVagueBoundaries() {
  let throwingBall = FamilyResemblance$Fogbinder.make("Ball Games", [{
      name: "amusement",
      weight: 0.2,
      exemplars: ["throw-and-catch"]
    }], ["throw-and-catch"], undefined);
  assertEqual(throwingBall.boundaries, "vague", "Boundaries should be vague");
}

function runTests() {
  console.log("================================");
  console.log("Running FamilyResemblance Tests");
  console.log("================================");
  testMake();
  testNoCenterOfGravity();
  testBelongsToFamily();
  testFindPrototype();
  testMerge();
  testResemblanceStrength();
  testResemblanceStrengthZero();
  testResemblanceStrengthSymmetric();
  testToNetwork();
  testToNetworkNoSelfEdges();
  testVagueBoundaries();
  console.log("================================");
  console.log("All FamilyResemblance tests completed");
  console.log("================================");
}

runTests();

export {
  assertEqual,
  assertTrue,
  gameFeatures,
  gameMembers,
  testMake,
  testNoCenterOfGravity,
  testBelongsToFamily,
  testFindPrototype,
  testMerge,
  testResemblanceStrength,
  testResemblanceStrengthZero,
  testResemblanceStrengthSymmetric,
  testToNetwork,
  testToNetworkNoSelfEdges,
  testVagueBoundaries,
  runTests,
}
/*  Not a pure module */
