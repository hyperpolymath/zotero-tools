-- SPDX-License-Identifier: AGPL-3.0-or-later
/-!
# PROMPT Framework

Evidence quality scoring using the PROMPT framework:
- **P**rovenance: Where does the information come from?
- **R**eplicability: Can others verify this?
- **O**bjectivity: Is it free from bias?
- **M**ethodology: How was it produced?
- **P**ublication: Is it properly reviewed/published?
- **T**ransparency: Is the process open?

All scores are in [0, 100] with compile-time bounds checking.
-/

import ZoteroFormDB.Types

namespace ZoteroFormDB.Prompt

open Types

/-- A single PROMPT dimension score: integer in [0, 100] -/
abbrev PromptDimension := BoundedNat 0 100

/-- Create a dimension score with automatic proof -/
def mkDimension (n : Nat) (h : n ≤ 100 := by omega) : PromptDimension :=
  ⟨n, Nat.zero_le n, h⟩

/-! ## PROMPT Scores Structure -/

/-- Complete PROMPT scores with proof that overall is computed correctly -/
structure PromptScores where
  provenance : PromptDimension
  replicability : PromptDimension
  objective : PromptDimension
  methodology : PromptDimension
  publication : PromptDimension
  transparency : PromptDimension
  overall : PromptDimension
  -- Proof that overall is the average (integer division)
  overall_correct : overall.val =
    (provenance.val + replicability.val + objective.val +
     methodology.val + publication.val + transparency.val) / 6
  deriving Repr

/-- Compute overall score from dimensions -/
def computeOverall (p r o m pub t : Nat) : Nat :=
  (p + r + o + m + pub + t) / 6

/-- Smart constructor that computes overall automatically -/
def mkPromptScores
    (p : PromptDimension)
    (r : PromptDimension)
    (o : PromptDimension)
    (m : PromptDimension)
    (pub : PromptDimension)
    (t : PromptDimension) : PromptScores :=
  let avg := computeOverall p.val r.val o.val m.val pub.val t.val
  -- Average of values in [0,100] is in [0,100]
  let overall : PromptDimension := ⟨avg, Nat.zero_le avg, by
    simp only [computeOverall]
    omega⟩
  ⟨p, r, o, m, pub, t, overall, rfl⟩

/-! ## Quality Thresholds -/

/-- Evidence quality levels -/
inductive QualityLevel where
  | excellent  -- 90-100
  | good       -- 70-89
  | acceptable -- 50-69
  | poor       -- 25-49
  | unreliable -- 0-24
  deriving Repr, BEq

/-- Determine quality level from overall score -/
def qualityLevel (scores : PromptScores) : QualityLevel :=
  let o := scores.overall.val
  if o >= 90 then .excellent
  else if o >= 70 then .good
  else if o >= 50 then .acceptable
  else if o >= 25 then .poor
  else .unreliable

/-! ## Source Type Templates -/

/-- Default PROMPT scores for common source types -/
def officialStatistics : PromptScores :=
  mkPromptScores
    (mkDimension 100)  -- Provenance: Government/official
    (mkDimension 100)  -- Replicability: Public data
    (mkDimension 90)   -- Objective: Statistical methodology
    (mkDimension 95)   -- Methodology: Documented
    (mkDimension 100)  -- Publication: Official release
    (mkDimension 90)   -- Transparency: Methods published

def peerReviewedJournal : PromptScores :=
  mkPromptScores
    (mkDimension 85)   -- Provenance: Academic institution
    (mkDimension 80)   -- Replicability: May vary
    (mkDimension 85)   -- Objective: Peer reviewed
    (mkDimension 90)   -- Methodology: Required
    (mkDimension 100)  -- Publication: Peer reviewed
    (mkDimension 75)   -- Transparency: Varies

def newsArticle : PromptScores :=
  mkPromptScores
    (mkDimension 60)   -- Provenance: Varies
    (mkDimension 50)   -- Replicability: Often not
    (mkDimension 50)   -- Objective: Editorial bias
    (mkDimension 40)   -- Methodology: Often unclear
    (mkDimension 70)   -- Publication: Editorial review
    (mkDimension 40)   -- Transparency: Limited

def socialMediaPost : PromptScores :=
  mkPromptScores
    (mkDimension 20)   -- Provenance: Often anonymous
    (mkDimension 30)   -- Replicability: Low
    (mkDimension 20)   -- Objective: Personal opinion
    (mkDimension 10)   -- Methodology: None
    (mkDimension 10)   -- Publication: None
    (mkDimension 30)   -- Transparency: Varies

/-! ## Proofs -/

/-- All PROMPT dimensions are bounded -/
theorem allDimensionsBounded (scores : PromptScores) :
    scores.provenance.val ≤ 100 ∧
    scores.replicability.val ≤ 100 ∧
    scores.objective.val ≤ 100 ∧
    scores.methodology.val ≤ 100 ∧
    scores.publication.val ≤ 100 ∧
    scores.transparency.val ≤ 100 ∧
    scores.overall.val ≤ 100 :=
  ⟨scores.provenance.val_le,
   scores.replicability.val_le,
   scores.objective.val_le,
   scores.methodology.val_le,
   scores.publication.val_le,
   scores.transparency.val_le,
   scores.overall.val_le⟩

/-- Overall is never greater than max dimension -/
theorem overallBoundedByMax (scores : PromptScores) :
    scores.overall.val ≤ max scores.provenance.val
      (max scores.replicability.val
        (max scores.objective.val
          (max scores.methodology.val
            (max scores.publication.val scores.transparency.val)))) := by
  simp only [scores.overall_correct, computeOverall]
  omega

end ZoteroFormDB.Prompt
