--------------------------- MODULE EpistemicStateMerge ---------------------------
(***************************************************************************
 * Formal specification for Fogbinder's epistemic state merging algorithm
 *
 * This spec models the merging of epistemic states, ensuring:
 * 1. Merge operation is commutative (merge(A,B) = merge(B,A))
 * 2. Merge operation is associative (merge(merge(A,B),C) = merge(A,merge(B,C)))
 * 3. Evidence is properly combined
 * 4. Certainty is correctly adjusted based on conflicting states
 * 5. Language game context is preserved
 *
 * Author: Fogbinder Team
 * License: GNU AGPLv3
 ***************************************************************************)

EXTENDS Naturals, Sequences, FiniteSets, TLC

CONSTANTS
  Certainties,       \* Set of possible certainty values
  Contexts,          \* Set of language game contexts
  EvidenceItems      \* Set of all possible evidence items

(*
 * Certainty ordering:
 * Known > Probable(p) > Vague > Ambiguous > Mysterious > Contradictory
 *)
ASSUME Certainties = {
  "Known",
  "Probable",
  "Vague",
  "Ambiguous",
  "Mysterious",
  "Contradictory"
}

VARIABLES
  state1,            \* First epistemic state
  state2,            \* Second epistemic state
  merged_state,      \* Result of merging state1 and state2
  merge_history      \* History of merge operations

(* An epistemic state consists of: *)
EpistemicState == [
  certainty: Certainties,
  context: Contexts,
  evidence: SUBSET EvidenceItems,
  probability: 0..100    \* For Probable states
]

(* Type invariants *)
TypeOK ==
  /\ state1 \in EpistemicState
  /\ state2 \in EpistemicState
  /\ merged_state \in EpistemicState
  /\ merge_history \in Seq(EpistemicState \X EpistemicState \X EpistemicState)

(* Initial state *)
Init ==
  /\ state1 \in EpistemicState
  /\ state2 \in EpistemicState
  /\ merged_state = state1
  /\ merge_history = <<>>

(* Certainty comparison *)
LessCertain(c1, c2) ==
  CASE c1 = "Contradictory" -> TRUE
    [] c1 = "Mysterious" /\ c2 # "Contradictory" -> TRUE
    [] c1 = "Ambiguous" /\ c2 \in {"Vague", "Probable", "Known"} -> TRUE
    [] c1 = "Vague" /\ c2 \in {"Probable", "Known"} -> TRUE
    [] c1 = "Probable" /\ c2 = "Known" -> TRUE
    [] OTHER -> FALSE

(* Merge two epistemic states *)
MergeStates ==
  /\ state1.context = state2.context  \* Must have same context
  /\ LET
       \* Combine evidence
       combined_evidence == state1.evidence \union state2.evidence

       \* Determine resulting certainty
       result_certainty ==
         IF state1.certainty = state2.certainty
         THEN state1.certainty
         ELSE IF LessCertain(state1.certainty, state2.certainty)
              THEN state1.certainty
              ELSE state2.certainty

       \* Average probabilities for Probable states
       result_probability ==
         IF result_certainty = "Probable"
         THEN (state1.probability + state2.probability) \div 2
         ELSE 0

       result == [
         certainty |-> result_certainty,
         context |-> state1.context,
         evidence |-> combined_evidence,
         probability |-> result_probability
       ]
     IN
       /\ merged_state' = result
       /\ merge_history' = Append(merge_history, <<state1, state2, result>>)
       /\ UNCHANGED <<state1, state2>>

(* Swap states to test commutativity *)
SwapStates ==
  /\ state1' = state2
  /\ state2' = state1
  /\ UNCHANGED <<merged_state, merge_history>>

(* Next state relation *)
Next ==
  \/ MergeStates
  \/ SwapStates

(* Specification *)
Spec == Init /\ [][Next]_<<state1, state2, merged_state, merge_history>>

(***************************************************************************
 * INVARIANTS (Properties that should always hold)
 ***************************************************************************)

(* INV1: Merged state has combined evidence *)
EvidenceCombined ==
  (merged_state.evidence \subseteq state1.evidence \union state2.evidence)

(* INV2: Merged state uses less certain value *)
CertaintyPreserved ==
  LET c1 == state1.certainty
      c2 == state2.certainty
      cm == merged_state.certainty
  IN
    (c1 = c2 => cm = c1)
    /\ (LessCertain(c1, c2) => cm = c1)
    /\ (LessCertain(c2, c1) => cm = c2)

(* INV3: Context is preserved from inputs *)
ContextPreserved ==
  merged_state.context = state1.context
  /\ merged_state.context = state2.context

(* INV4: Probability is averaged for Probable states *)
ProbabilityAveraged ==
  (merged_state.certainty = "Probable")
  =>
  (merged_state.probability * 2 = state1.probability + state2.probability)

(***************************************************************************
 * COMMUTATIVITY PROPERTY
 ***************************************************************************)

(* Property: merge(A, B) = merge(B, A) *)
MergeCommutative ==
  \A s1, s2 \in EpistemicState:
    (s1.context = s2.context) =>
    LET
      merge_ab == [
        certainty |-> IF s1.certainty = s2.certainty
                      THEN s1.certainty
                      ELSE IF LessCertain(s1.certainty, s2.certainty)
                           THEN s1.certainty
                           ELSE s2.certainty,
        context |-> s1.context,
        evidence |-> s1.evidence \union s2.evidence,
        probability |-> (s1.probability + s2.probability) \div 2
      ]
      merge_ba == [
        certainty |-> IF s2.certainty = s1.certainty
                      THEN s2.certainty
                      ELSE IF LessCertain(s2.certainty, s1.certainty)
                           THEN s2.certainty
                           ELSE s1.certainty,
        context |-> s2.context,
        evidence |-> s2.evidence \union s1.evidence,
        probability |-> (s2.probability + s1.probability) \div 2
      ]
    IN
      merge_ab = merge_ba

(***************************************************************************
 * ASSOCIATIVITY PROPERTY
 ***************************************************************************)

(* Helper: Merge function *)
Merge(s1, s2) ==
  IF s1.context # s2.context
  THEN s1  \* Invalid merge, return first state
  ELSE [
    certainty |-> IF s1.certainty = s2.certainty
                  THEN s1.certainty
                  ELSE IF LessCertain(s1.certainty, s2.certainty)
                       THEN s1.certainty
                       ELSE s2.certainty,
    context |-> s1.context,
    evidence |-> s1.evidence \union s2.evidence,
    probability |-> (s1.probability + s2.probability) \div 2
  ]

(* Property: merge(merge(A, B), C) = merge(A, merge(B, C)) *)
MergeAssociative ==
  \A s1, s2, s3 \in EpistemicState:
    (s1.context = s2.context /\ s2.context = s3.context) =>
    Merge(Merge(s1, s2), s3) = Merge(s1, Merge(s2, s3))

(***************************************************************************
 * IDENTITY PROPERTY
 ***************************************************************************)

(* Property: merging with self doesn't change state *)
MergeIdentity ==
  \A s \in EpistemicState:
    Merge(s, s) = s

(***************************************************************************
 * IDEMPOTENCE PROPERTY
 ***************************************************************************)

(* Property: merge(merge(A, B), merge(A, B)) = merge(A, B) *)
MergeIdempotent ==
  \A s1, s2 \in EpistemicState:
    (s1.context = s2.context) =>
    LET merged == Merge(s1, s2)
    IN Merge(merged, merged) = merged

(***************************************************************************
 * THEOREMS (Properties we want to prove)
 ***************************************************************************)

(* THEOREM 1: Merge is commutative *)
THEOREM CommutativityHolds == Spec => []MergeCommutative

(* THEOREM 2: Merge is associative *)
THEOREM AssociativityHolds == Spec => []MergeAssociative

(* THEOREM 3: Merging with self is identity *)
THEOREM IdentityHolds == Spec => []MergeIdentity

(* THEOREM 4: Merge is idempotent *)
THEOREM IdempotenceHolds == Spec => []MergeIdempotent

(* THEOREM 5: Evidence is monotonic (never lost) *)
THEOREM EvidenceMonotonic ==
  Spec => [](
    state1.evidence \subseteq merged_state.evidence
    /\ state2.evidence \subseteq merged_state.evidence
  )

(***************************************************************************
 * SAFETY PROPERTIES
 ***************************************************************************)

(* Never lose evidence *)
SafetyNoEvidenceLoss ==
  []((state1.evidence \union state2.evidence) \subseteq merged_state.evidence)

(* Certainty never increases inappropriately *)
SafetyCertaintyBounded ==
  [](
    LET c1 == state1.certainty
        c2 == state2.certainty
        cm == merged_state.certainty
    IN
      \/ cm = c1
      \/ cm = c2
  )

(***************************************************************************
 * MODEL CHECKING CONFIGURATION
 *
 * To verify this spec with TLC model checker:
 *
 * 1. Define constants:
 *    Certainties = {"Known", "Probable", "Vague", "Mysterious"}
 *    Contexts = {ctx1}
 *    EvidenceItems = {e1, e2, e3}
 *
 * 2. Define initial predicate:
 *    state1 = [certainty |-> "Known", context |-> ctx1, evidence |-> {e1}, probability |-> 0]
 *    state2 = [certainty |-> "Vague", context |-> ctx1, evidence |-> {e2}, probability |-> 0]
 *
 * 3. Check invariants:
 *    - TypeOK
 *    - EvidenceCombined
 *    - CertaintyPreserved
 *    - ContextPreserved
 *
 * 4. Check properties:
 *    - MergeCommutative
 *    - MergeAssociative
 *    - MergeIdentity
 *    - MergeIdempotent
 ***************************************************************************)

=============================================================================
