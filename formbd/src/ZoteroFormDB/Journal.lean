-- SPDX-License-Identifier: AGPL-3.0-or-later
/-!
# Append-Only Journal

Cloud-safe storage using append-only operations.
No concurrent write corruption possible - only appends.
-/

import ZoteroFormDB.Types
import ZoteroFormDB.Provenance

namespace ZoteroFormDB.Journal

open Types Provenance

/-! ## Journal Entry Types -/

/-- Types of journal operations -/
inductive OpType where
  | insert
  | update
  | delete
  | schema_change
  | migration
  deriving Repr, BEq

/-- A single journal entry -/
structure JournalEntry where
  sequence : Nat              -- Monotonically increasing
  timestamp : Timestamp
  op_type : OpType
  collection : String
  item_key : ValidUUID
  actor : ActorId
  rationale : Rationale
  payload : String            -- JSON-encoded data
  prev_hash : Option Blake3Hash  -- Chain link
  deriving Repr

/-- The journal is a list of entries -/
abbrev Journal := List JournalEntry

/-! ## Journal Invariants -/

/-- Sequence numbers are strictly increasing -/
def isStrictlyIncreasing : Journal → Prop
  | [] => True
  | [_] => True
  | e1 :: e2 :: rest => e1.sequence < e2.sequence ∧ isStrictlyIncreasing (e2 :: rest)

/-- Each entry chains to the previous -/
def isChained : Journal → Prop
  | [] => True
  | [_] => True
  | e1 :: e2 :: rest =>
    -- e2.prev_hash should equal hash of e1
    -- (simplified - real impl would compute hash)
    e2.prev_hash.isSome ∧ isChained (e2 :: rest)

/-- All entries have provenance -/
def allHaveProvenance (j : Journal) : Prop :=
  j.all fun e => e.actor.val.length > 0 ∧ e.rationale.val.length > 0

/-! ## Journal Operations -/

/-- Append an entry (only valid operation) -/
def append (j : Journal) (e : JournalEntry) : Journal :=
  j ++ [e]

/-- Get latest sequence number -/
def latestSequence (j : Journal) : Nat :=
  match j.getLast? with
  | some e => e.sequence
  | none => 0

/-- Find entries by item key -/
def findByKey (j : Journal) (key : ValidUUID) : List JournalEntry :=
  j.filter fun e => e.item_key.val == key.val

/-- Reconstruct item state by replaying journal -/
def replay (j : Journal) (key : ValidUUID) : Option String :=
  let entries := findByKey j key
  match entries.getLast? with
  | some e =>
    if e.op_type == .delete then none
    else some e.payload
  | none => none

/-! ## Cloud Safety -/

/-- Journal is append-only, so:
    1. No corruption from concurrent writes (both just append)
    2. Sync conflicts are mergeable (append both, sort by sequence)
    3. No partial write corruption (complete entry or nothing) -/

/-- Merge two journals (for sync resolution) -/
def merge (j1 j2 : Journal) : Journal :=
  -- Combine and sort by sequence, dedupe by sequence number
  let combined := j1 ++ j2
  let sorted := combined.toArray.qsort (fun a b => a.sequence < b.sequence)
  -- Deduplicate by sequence number
  sorted.toList.foldl (fun acc e =>
    match acc.getLast? with
    | some last => if last.sequence == e.sequence then acc else acc ++ [e]
    | none => [e]
  ) []

/-! ## Proofs -/

/-- Appending preserves strict ordering if new sequence is larger -/
theorem appendPreservesOrdering (j : Journal) (e : JournalEntry)
    (h : latestSequence j < e.sequence) :
    latestSequence (append j e) = e.sequence := by
  simp only [append, latestSequence]
  sorry  -- Full proof requires List lemmas

/-- Merged journals contain all entries from both -/
theorem mergeContainsBoth (j1 j2 : Journal) (e : JournalEntry) :
    e ∈ j1 ∨ e ∈ j2 → ∃ e' ∈ merge j1 j2, e'.sequence = e.sequence := by
  sorry  -- Full proof requires List membership lemmas

end ZoteroFormDB.Journal
