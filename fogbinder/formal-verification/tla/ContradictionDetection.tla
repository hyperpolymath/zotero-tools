--------------------------- MODULE ContradictionDetection ---------------------------
(***************************************************************************
 * Formal specification for Fogbinder's contradiction detection algorithm
 *
 * This spec models the detection of language game contradictions, ensuring:
 * 1. Contradiction detection is symmetric (if A contradicts B, B contradicts A)
 * 2. Sources are correctly grouped by language game
 * 3. Severity calculation is consistent
 * 4. No false positives from sources in the same language game
 *
 * Author: Fogbinder Team
 * License: GNU AGPLv3
 ***************************************************************************)

EXTENDS Naturals, Sequences, FiniteSets, TLC

CONSTANTS
  Sources,           \* Set of all source texts
  LanguageGames,     \* Set of language game identifiers
  MaxSeverity,       \* Maximum severity value (typically 1.0)
  MinSeverity        \* Minimum severity value (typically 0.0)

VARIABLES
  contradictions,    \* Set of detected contradictions
  severity_map,      \* Map from contradiction pairs to severity scores
  game_assignments   \* Map from sources to language games

(* Type invariants *)
TypeOK ==
  /\ contradictions \subseteq (Sources \X Sources)
  /\ \A <<s1, s2>> \in contradictions: s1 # s2
  /\ \A <<s1, s2>> \in DOMAIN severity_map:
       /\ MinSeverity <= severity_map[<<s1, s2>>]
       /\ severity_map[<<s1, s2>>] <= MaxSeverity
  /\ game_assignments \in [Sources -> SUBSET LanguageGames]

(* Initial state *)
Init ==
  /\ contradictions = {}
  /\ severity_map = [x \in {} |-> 0]
  /\ game_assignments = [s \in Sources |-> {}]

(* Assign a source to a language game *)
AssignToGame(source, game) ==
  /\ source \in Sources
  /\ game \in LanguageGames
  /\ game_assignments' = [game_assignments EXCEPT ![source] = @ \union {game}]
  /\ UNCHANGED <<contradictions, severity_map>>

(* Detect contradiction between two sources *)
DetectContradiction(s1, s2, severity) ==
  /\ s1 \in Sources /\ s2 \in Sources
  /\ s1 # s2
  /\ MinSeverity <= severity /\ severity <= MaxSeverity
  \* Sources must be in different language games for contradiction
  /\ game_assignments[s1] \cap game_assignments[s2] = {}
  /\ game_assignments[s1] # {} /\ game_assignments[s2] # {}
  /\ contradictions' = contradictions \union {<<s1, s2>>, <<s2, s1>>}
  /\ severity_map' = severity_map @@ (<<s1, s2>> :> severity) @@ (<<s2, s1>> :> severity)
  /\ UNCHANGED <<game_assignments>>

(* Next state relation *)
Next ==
  \/ \E s \in Sources, g \in LanguageGames: AssignToGame(s, g)
  \/ \E s1, s2 \in Sources, sev \in MinSeverity..MaxSeverity: DetectContradiction(s1, s2, sev)

(* Specification *)
Spec == Init /\ [][Next]_<<contradictions, severity_map, game_assignments>>

(***************************************************************************
 * INVARIANTS (Properties that should always hold)
 ***************************************************************************)

(* INV1: Contradiction detection is symmetric *)
Symmetry ==
  \A <<s1, s2>> \in contradictions:
    <<s2, s1>> \in contradictions

(* INV2: Contradictions only occur between different language games *)
DifferentGames ==
  \A <<s1, s2>> \in contradictions:
    game_assignments[s1] \cap game_assignments[s2] = {}

(* INV3: Severity is symmetric *)
SeveritySymmetry ==
  \A <<s1, s2>> \in contradictions:
    /\ <<s1, s2>> \in DOMAIN severity_map
    /\ <<s2, s1>> \in DOMAIN severity_map
    /\ severity_map[<<s1, s2>>] = severity_map[<<s2, s1>>]

(* INV4: No self-contradictions *)
NoSelfContradiction ==
  \A s \in Sources:
    <<s, s>> \notin contradictions

(* INV5: Sources in same game don't contradict *)
SameGameConsistency ==
  \A s1, s2 \in Sources:
    (game_assignments[s1] \cap game_assignments[s2] # {}
     /\ game_assignments[s1] # {}
     /\ game_assignments[s2] # {})
    => <<s1, s2>> \notin contradictions

(***************************************************************************
 * THEOREMS (Properties we want to prove)
 ***************************************************************************)

(* THEOREM 1: Symmetry is always preserved *)
THEOREM SymmetryPreserved == Spec => []Symmetry

(* THEOREM 2: Different language games constraint is maintained *)
THEOREM DifferentGamesPreserved == Spec => []DifferentGames

(* THEOREM 3: Severity symmetry is maintained *)
THEOREM SeveritySymmetryPreserved == Spec => []SeveritySymmetry

(* THEOREM 4: No source contradicts itself *)
THEOREM NoSelfContradictions == Spec => []NoSelfContradiction

(* THEOREM 5: Sources in the same game remain consistent *)
THEOREM SameGameConsistencyPreserved == Spec => []SameGameConsistency

(***************************************************************************
 * LIVENESS PROPERTIES (Things that should eventually happen)
 ***************************************************************************)

(* LIVE1: If sources are in different games with conflicting claims,
          a contradiction should eventually be detected *)
EventualDetection ==
  \A s1, s2 \in Sources:
    (game_assignments[s1] # {} /\ game_assignments[s2] # {}
     /\ game_assignments[s1] \cap game_assignments[s2] = {})
    ~> (<<s1, s2>> \in contradictions \/ <<s2, s1>> \in contradictions)

(***************************************************************************
 * MODEL CHECKING CONFIGURATION
 *
 * To verify this spec with TLC model checker:
 *
 * 1. Define constants:
 *    Sources = {s1, s2, s3}
 *    LanguageGames = {g1, g2}
 *    MaxSeverity = 1
 *    MinSeverity = 0
 *
 * 2. Check invariants:
 *    - TypeOK
 *    - Symmetry
 *    - DifferentGames
 *    - SeveritySymmetry
 *    - NoSelfContradiction
 *    - SameGameConsistency
 *
 * 3. Check theorems using TLAPS (TLA+ Proof System) if available
 ***************************************************************************)

=============================================================================
