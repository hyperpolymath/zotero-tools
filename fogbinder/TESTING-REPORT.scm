;; SPDX-License-Identifier: MPL-2.0-or-later
;; Fogbinder Testing Report
;; Generated: 2025-12-29

(testing-report
  (metadata
    (project "fogbinder")
    (version "0.1.0")
    (test-date "2025-12-29")
    (overall-status passed)
    (generator "Claude Code"))

  (summary
    (test-suites 3)
    (total-tests 53)
    (passed 53)
    (failed 0)
    (skipped 0))

  (project-description
    "Zotero plugin for epistemic analysis implementing late Wittgenstein "
    "philosophy (language games, family resemblance) and J.L. Austin's "
    "speech act theory.")

  (build-system
    (tool "ReScript")
    (version "12.0.2")
    (package-manager "npm")
    (build-command "npx rescript build")
    (build-status success))

  (issues-fixed
    (issue
      (id "ISS-001")
      (type configuration)
      (severity critical)
      (description "Missing rescript.json configuration file")
      (fix "Created rescript.json from bsconfig.json (ReScript 12 requirement)")
      (files-affected "rescript.json"))

    (issue
      (id "ISS-002")
      (type configuration)
      (severity critical)
      (description "Missing package.json name field")
      (fix "Added name, version, private, type fields to package.json")
      (files-affected "package.json"))

    (issue
      (id "ISS-003")
      (type api-change)
      (severity high)
      (description "Js.Array2.reduce argument order changed in ReScript 12")
      (fix "Reordered arguments from (array, init, fn) to (array, fn, init)")
      (files-affected
        "src/core/FamilyResemblance.res"
        "src/engine/FogTrailVisualizer.res"))

    (issue
      (id "ISS-004")
      (type type-system)
      (severity high)
      (description "Type declarations used before defined")
      (fix "Reordered type declarations to appear before usage")
      (files-affected
        "src/engine/ContradictionDetector.res"
        "src/engine/MysteryClustering.res"
        "src/engine/FogTrailVisualizer.res"
        "src/Fogbinder.res"))

    (issue
      (id "ISS-005")
      (type naming-collision)
      (severity medium)
      (description "Edge type 'Mystery' conflicted with node type 'Mystery'")
      (fix "Renamed edge type to 'MysteryEdge'")
      (files-affected "src/engine/FogTrailVisualizer.res"))

    (issue
      (id "ISS-006")
      (type test-framework)
      (severity high)
      (description "Test files used non-existent RescriptMocha and wrong API signatures")
      (fix "Completely rewrote all test files with Console-based testing")
      (files-affected
        "src/core/EpistemicState.test.res"
        "src/core/SpeechAct.test.res"
        "src/core/FamilyResemblance.test.res")))

  (test-suites
    (suite
      (name "EpistemicState")
      (file "src/core/EpistemicState.test.res")
      (tests 18)
      (passed 18)
      (failed 0)
      (test-cases
        (test (name "Known state should have Known certainty") (status passed))
        (test (name "Context should be preserved") (status passed))
        (test (name "Should have 1 evidence") (status passed))
        (test (name "Known state should not be ambiguous") (status passed))
        (test (name "Probable state should not be ambiguous") (status passed))
        (test (name "Mysterious state should be ambiguous") (status passed))
        (test (name "Vague state should be ambiguous") (status passed))
        (test (name "Ambiguous state should be ambiguous") (status passed))
        (test (name "Contradictory state should be ambiguous") (status passed))
        (test (name "Should return 3 interpretations") (status passed))
        (test (name "Should return 2 conflicts") (status passed))
        (test (name "Known should have no interpretations") (status passed))
        (test (name "Merged state should preserve all evidence") (status passed))
        (test (name "Known + Known should be Known") (status passed))
        (test (name "Probabilities should be averaged") (status passed))
        (test (name "Known + Mysterious should be Mysterious") (status passed))
        (test (name "Should combine interpretations") (status passed))
        (test (name "toJson should produce valid JSON") (status passed))))

    (suite
      (name "SpeechAct")
      (file "src/core/SpeechAct.test.res")
      (tests 19)
      (passed 19)
      (failed 0)
      (test-cases
        (test (name "Utterance should be preserved") (status passed))
        (test (name "Assertive should not be performative") (status passed))
        (test (name "Declaration should be performative") (status passed))
        (test (name "Commissive should be performative") (status passed))
        (test (name "Directive should not be performative") (status passed))
        (test (name "Expressive should not be performative") (status passed))
        (test (name "Felicitous speech act should be happy") (status passed))
        (test (name "conventionalProcedure should be true") (status passed))
        (test (name "appropriateCircumstances should be true") (status passed))
        (test (name "executedCorrectly should be true") (status passed))
        (test (name "executedCompletely should be true") (status passed))
        (test (name "sincereIntentions should be true") (status passed))
        (test (name "Should describe assertive mood") (status passed))
        (test (name "Should describe directive mood") (status passed))
        (test (name "Should extract emotional tone") (status passed))
        (test (name "Correctly returned None for non-expressive") (status passed))
        (test (name "Different assertives should conflict") (status passed))
        (test (name "Same assertives should not conflict") (status passed))
        (test (name "Different force types should not conflict") (status passed))))

    (suite
      (name "FamilyResemblance")
      (file "src/core/FamilyResemblance.test.res")
      (tests 16)
      (passed 16)
      (failed 0)
      (test-cases
        (test (name "Label should be Games") (status passed))
        (test (name "Should have 6 members") (status passed))
        (test (name "Boundaries should be vague") (status passed))
        (test (name "No center of gravity initially") (status passed))
        (test (name "Chess should belong to Games family") (status passed))
        (test (name "Prototype should be a game with multiple features") (status passed))
        (test (name "Merged should have 2 features") (status passed))
        (test (name "Merged should have 4 members") (status passed))
        (test (name "Merged boundaries should be contested") (status passed))
        (test (name "Label should be combined") (status passed))
        (test (name "Chess and tennis should have high resemblance") (status passed))
        (test (name "Chess and dice should have no resemblance") (status passed))
        (test (name "Resemblance should be symmetric") (status passed))
        (test (name "Network should have edges") (status passed))
        (test (name "Network should have no self-edges") (status passed))
        (test (name "Boundaries should be vague") (status passed)))))

  (deprecation-warnings
    (warning
      (deprecated "Js.Array2.*")
      (replacement "Array.*")
      (count "~50 occurrences"))
    (warning
      (deprecated "Js.Dict.*")
      (replacement "Dict.*")
      (count "~10 occurrences"))
    (warning
      (deprecated "Js.Date.now")
      (replacement "Date.now")
      (count "~5 occurrences"))
    (warning
      (deprecated "Js.Json.*")
      (replacement "JSON.*")
      (count "~15 occurrences"))
    (warning
      (deprecated "Js.log")
      (replacement "Console.log")
      (count "~3 occurrences")))

  (recommendations
    (priority high
      (item "Run API migration tool to update deprecated Js.* APIs")
      (item "Test WASM build (src/wasm/ directory exists but untested)"))
    (priority medium
      (item "Add integration tests for full analysis pipeline")
      (item "Add Zotero API mock tests"))
    (priority low
      (item "Fix unused variable warning in belongsToFamily")
      (item "Remove unreachable match case in findPrototype")))

  (files-modified
    (configuration
      "rescript.json"
      "package.json")
    (source
      "src/core/FamilyResemblance.res"
      "src/engine/ContradictionDetector.res"
      "src/engine/MysteryClustering.res"
      "src/engine/FogTrailVisualizer.res"
      "src/Fogbinder.res")
    (tests-rewritten
      "src/core/EpistemicState.test.res"
      "src/core/SpeechAct.test.res"
      "src/core/FamilyResemblance.test.res"))

  (conclusion
    "Fogbinder builds and tests successfully after resolving ReScript 12 "
    "compatibility issues. The project implements sophisticated philosophical "
    "concepts (Wittgenstein's language games, Austin's speech acts) in a "
    "type-safe manner. All 53 tests pass."))
