-- SPDX-License-Identifier: AGPL-3.0-or-later
/-!
# Provenance Tracking

Every piece of data carries its provenance - who added it, when, and why.
This is enforced at the type level: you literally cannot construct data without provenance.
-/

import ZoteroFormDB.Types

namespace ZoteroFormDB.Provenance

open Types

/-! ## Tracked Values -/

/-- A value wrapped with provenance information.
    You cannot construct a Tracked value without providing:
    - Who added it (ActorId - non-empty)
    - When (Timestamp)
    - Why (Rationale - non-empty) -/
structure Tracked (α : Type) where
  value : α
  added_by : ActorId
  added_at : Timestamp
  rationale : Rationale
  deriving Repr

/-- Create a tracked value - provenance is required by types -/
def track (value : α) (actor : ActorId) (ts : Timestamp) (reason : Rationale) : Tracked α :=
  ⟨value, actor, ts, reason⟩

/-- Extract the value (provenance is preserved in the type) -/
def Tracked.get (t : Tracked α) : α := t.value

/-! ## Provenance Proofs -/

/-- Proof that a tracked value has non-empty actor -/
theorem Tracked.hasActor (t : Tracked α) : t.added_by.val.length > 0 :=
  t.added_by.nonempty

/-- Proof that a tracked value has non-empty rationale -/
theorem Tracked.hasRationale (t : Tracked α) : t.rationale.val.length > 0 :=
  t.rationale.nonempty

/-! ## Correction Records -/

/-- Types of corrections -/
inductive CorrectionType where
  | factual_update    -- Facts changed (e.g., revised statistics)
  | error_fix         -- Error in original entry
  | clarification     -- Making something clearer
  | retraction        -- Removing false information
  | addition          -- Adding missing information
  deriving Repr, BEq

/-- A correction to existing data -/
structure Correction (α : Type) where
  original : Tracked α
  corrected : Tracked α
  correction_type : CorrectionType
  disclosed_at : Timestamp
  disclosed_by : ActorId
  -- The correction must also have rationale (inherited from Tracked)

/-- Proof that corrections maintain provenance chain -/
theorem Correction.maintainsProvenance (c : Correction α) :
    c.original.added_by.val.length > 0 ∧ c.corrected.added_by.val.length > 0 :=
  ⟨c.original.hasActor, c.corrected.hasActor⟩

/-! ## Reversibility -/

/-- An operation with its inverse -/
structure ReversibleOp (α : Type) where
  forward : α → α
  inverse : α → α
  roundtrip : ∀ x, inverse (forward x) = x

/-- Irreversible operation with justification -/
structure IrreversibleOp (α : Type) where
  operation : α → Option α  -- Returns None if deleted
  reason : Rationale
  justification : String    -- Legal/policy basis (e.g., "GDPR Article 17")

end ZoteroFormDB.Provenance
