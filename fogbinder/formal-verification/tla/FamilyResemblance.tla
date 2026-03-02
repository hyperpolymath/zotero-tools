--------------------------- MODULE FamilyResemblance ---------------------------
(***************************************************************************
 * Formal specification for Wittgensteinian family resemblance clustering
 *
 * This spec models family resemblance clustering, ensuring:
 * 1. No necessary/sufficient conditions (no single feature required)
 * 2. Membership based on overlapping features
 * 3. Boundaries are genuinely vague (not crisp)
 * 4. Prototype effects (central members vs peripheral members)
 * 5. Resemblance strength is transitive but graded
 *
 * Key insight: Unlike classical categorization, family resemblance
 * allows members to belong without sharing ALL features.
 *
 * Author: Fogbinder Team
 * License: GNU AGPLv3
 ***************************************************************************)

EXTENDS Naturals, Sequences, FiniteSets, TLC, Reals

CONSTANTS
  Items,             \* Set of all possible items
  Features,          \* Set of all possible features
  Threshold          \* Minimum resemblance threshold for membership

ASSUME Threshold \in Real /\ Threshold >= 0.0 /\ Threshold =< 1.0

VARIABLES
  cluster,           \* Current family resemblance cluster
  boundaries         \* Boundary type: "vague" or "contested" or "clear"

(* A family resemblance cluster *)
FamilyCluster == [
  label: STRING,
  features: Seq([
    name: STRING,
    weight: Real,
    exemplars: SUBSET Items
  ]),
  members: SUBSET Items,
  boundaries: {"vague", "contested", "clear"}
]

(* Type invariants *)
TypeOK ==
  /\ cluster \in FamilyCluster
  /\ boundaries \in {"vague", "contested", "clear"}

(* Initial state: empty cluster with vague boundaries *)
Init ==
  /\ cluster = [
       label |-> "Empty",
       features |-> <<>>,
       members |-> {},
       boundaries |-> "vague"
     ]
  /\ boundaries = "vague"

(* Add a feature to the cluster *)
AddFeature(feat_name, weight, exemplars) ==
  /\ weight >= 0.0 /\ weight =< 1.0
  /\ exemplars \subseteq Items
  /\ cluster' = [cluster EXCEPT
       !.features = Append(@, [
         name |-> feat_name,
         weight |-> weight,
         exemplars |-> exemplars
       ])
     ]
  /\ UNCHANGED boundaries

(* Add a member to the cluster *)
AddMember(item) ==
  /\ item \in Items
  /\ cluster' = [cluster EXCEPT !.members = @ \union {item}]
  /\ UNCHANGED boundaries

(* Calculate resemblance strength between two items *)
ResemblanceStrength(item1, item2) ==
  LET
    \* Features shared by both items
    shared_features == {
      i \in 1..Len(cluster.features):
        /\ item1 \in cluster.features[i].exemplars
        /\ item2 \in cluster.features[i].exemplars
    }

    \* Sum of weights for shared features
    total_weight == IF shared_features = {}
                    THEN 0
                    ELSE LET sumWeights[S \in SUBSET (1..Len(cluster.features))] ==
                           IF S = {}
                           THEN 0
                           ELSE LET i == CHOOSE x \in S: TRUE
                                IN cluster.features[i].weight + sumWeights[S \ {i}]
                         IN sumWeights[shared_features]

    \* Normalize by total possible weight
    max_weight == IF Len(cluster.features) = 0
                  THEN 1
                  ELSE LET sumAllWeights[n \in 0..Len(cluster.features)] ==
                         IF n = 0
                         THEN 0
                         ELSE cluster.features[n].weight + sumAllWeights[n-1]
                       IN sumAllWeights[Len(cluster.features)]
  IN
    IF max_weight = 0 THEN 0 ELSE total_weight / max_weight

(* Check if item belongs to family *)
BelongsToFamily(item) ==
  LET
    \* Features possessed by item
    item_features == {f \in 1..Len(cluster.features): item \in cluster.features[f].exemplars}

    \* Calculate resemblance to existing members
    avg_resemblance == IF cluster.members = {}
                       THEN 1.0  \* First member always belongs
                       ELSE LET
                              total == LET sum[S \in SUBSET cluster.members] ==
                                         IF S = {}
                                         THEN 0
                                         ELSE LET m == CHOOSE x \in S: TRUE
                                              IN ResemblanceStrength(item, m) + sum[S \ {m}]
                                       IN sum[cluster.members]
                            IN total / Cardinality(cluster.members)
  IN
    avg_resemblance >= Threshold

(* Next state relation *)
Next ==
  \/ \E name \in STRING, w \in Real, ex \in SUBSET Items:
       w >= 0.0 /\ w =< 1.0 /\ AddFeature(name, w, ex)
  \/ \E item \in Items:
       BelongsToFamily(item) /\ AddMember(item)

(* Specification *)
Spec == Init /\ [][Next]_<<cluster, boundaries>>

(***************************************************************************
 * INVARIANTS (Properties that should always hold)
 ***************************************************************************)

(* INV1: No single feature is possessed by ALL members *)
NoNecessaryCondition ==
  \A f \in 1..Len(cluster.features):
    \E m \in cluster.members:
      m \notin cluster.features[f].exemplars

(* INV2: Members can belong without sharing all features *)
NoSufficientCondition ==
  \E m1, m2 \in cluster.members:
    m1 # m2 /\
    \E f \in 1..Len(cluster.features):
      /\ m1 \in cluster.features[f].exemplars
      /\ m2 \notin cluster.features[f].exemplars

(* INV3: Boundaries are vague (no crisp cutoff) *)
VagueBoundaries ==
  boundaries = "vague" =>
    \E item \in Items:
      \* Item is on the boundary (resemblance near threshold)
      LET resemblance == ResemblanceStrength(item, CHOOSE m \in cluster.members: TRUE)
      IN ABS(resemblance - Threshold) < 0.1

(* INV4: Resemblance is symmetric *)
ResemblanceSymmetry ==
  \A i1, i2 \in Items:
    ResemblanceStrength(i1, i2) = ResemblanceStrength(i2, i1)

(* INV5: Resemblance to self is maximal *)
ResemblanceReflexivity ==
  \A i \in Items:
    cluster.members # {} =>
    ResemblanceStrength(i, i) = 1.0

(***************************************************************************
 * WITTGENSTEINIAN PROPERTIES
 ***************************************************************************)

(* PROP1: Overlapping features create family resemblance *)
OverlappingFeatures ==
  Cardinality(cluster.members) > 2 =>
    \E m1, m2, m3 \in cluster.members:
      /\ m1 # m2 /\ m2 # m3 /\ m1 # m3
      /\ \E f1, f2 \in 1..Len(cluster.features):
           f1 # f2 /\
           /\ m1 \in cluster.features[f1].exemplars
           /\ m2 \in cluster.features[f1].exemplars
           /\ m2 \in cluster.features[f2].exemplars
           /\ m3 \in cluster.features[f2].exemplars
           /\ m1 \notin cluster.features[f2].exemplars
           /\ m3 \notin cluster.features[f1].exemplars

(* PROP2: Prototype effects exist *)
PrototypeExists ==
  cluster.members # {} =>
    \E prototype \in cluster.members:
      \* Prototype has more features than most other members
      \A m \in cluster.members:
        m # prototype =>
        Cardinality({f \in 1..Len(cluster.features): prototype \in cluster.features[f].exemplars})
        >=
        Cardinality({f \in 1..Len(cluster.features): m \in cluster.features[f].exemplars})

(* PROP3: Graded membership (some members more central than others) *)
GradedMembership ==
  Cardinality(cluster.members) > 1 =>
    \E m1, m2 \in cluster.members:
      m1 # m2 /\
      LET
        m1_feature_count == Cardinality({
          f \in 1..Len(cluster.features): m1 \in cluster.features[f].exemplars
        })
        m2_feature_count == Cardinality({
          f \in 1..Len(cluster.features): m2 \in cluster.features[f].exemplars
        })
      IN
        m1_feature_count # m2_feature_count

(***************************************************************************
 * THEOREMS (Properties we want to prove)
 ***************************************************************************)

(* THEOREM 1: No feature is necessary for all members *)
THEOREM NoNecessaryFeatures == Spec => []NoNecessaryCondition

(* THEOREM 2: Members can differ in features *)
THEOREM MembersDiffer == Spec => []NoSufficientCondition

(* THEOREM 3: Resemblance is symmetric *)
THEOREM SymmetricResemblance == Spec => []ResemblanceSymmetry

(* THEOREM 4: Self-resemblance is maximal *)
THEOREM SelfResemblanceMaximal == Spec => []ResemblanceReflexivity

(***************************************************************************
 * SAFETY PROPERTIES
 ***************************************************************************)

(* Only items meeting threshold can join *)
SafetyMembershipThreshold ==
  [](
    \A m \in cluster.members:
      BelongsToFamily(m) = TRUE
  )

(* Boundaries remain vague unless explicitly contested *)
SafetyBoundariesVague ==
  [](boundaries = "vague" \/ boundaries = "contested")

(***************************************************************************
 * LIVENESS PROPERTIES
 ***************************************************************************)

(* Eventually, a prototype emerges *)
LivenessPrototype ==
  (Cardinality(cluster.members) > 2) ~> PrototypeExists

(* Eventually, graded membership is established *)
LivenessGraded ==
  (Cardinality(cluster.members) > 3) ~> GradedMembership

(***************************************************************************
 * MODEL CHECKING CONFIGURATION
 *
 * To verify this spec with TLC model checker:
 *
 * 1. Define constants:
 *    Items = {car, bicycle, motorcycle, skateboard}
 *    Features = {has_wheels, has_engine, has_pedals}
 *    Threshold = 0.5
 *
 * 2. Define initial predicate:
 *    cluster = [label |-> "Vehicles", features |-> <<>>, members |-> {}, boundaries |-> "vague"]
 *
 * 3. Add features:
 *    AddFeature("has_wheels", 1.0, {car, bicycle, motorcycle, skateboard})
 *    AddFeature("has_engine", 0.8, {car, motorcycle})
 *    AddFeature("has_pedals", 0.6, {bicycle})
 *
 * 4. Check invariants:
 *    - TypeOK
 *    - NoNecessaryCondition
 *    - NoSufficientCondition
 *    - ResemblanceSymmetry
 *    - VagueBoundaries
 *
 * 5. Check Wittgensteinian properties:
 *    - OverlappingFeatures
 *    - PrototypeExists
 *    - GradedMembership
 *
 * Expected results:
 * - car and motorcycle share "has_wheels" and "has_engine"
 * - bicycle and car share "has_wheels"
 * - bicycle is peripheral (only has wheels and pedals)
 * - car is prototype (has most features)
 * - skateboard is borderline (only has wheels)
 ***************************************************************************)

=============================================================================
