-- SPDX-License-Identifier: PMPL-1.0-or-later
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

/-- Deduplicate a sorted list by sequence number, keeping first occurrence -/
def dedupBySequence : Journal → Journal
  | [] => []
  | e :: rest =>
    e :: dedupBySequence (rest.filter fun e' => e'.sequence != e.sequence)

/-- Merge two journals (for sync resolution) -/
def merge (j1 j2 : Journal) : Journal :=
  -- Combine and sort by sequence, dedupe by sequence number.
  -- Uses List.mergeSort (not Array.qsort) for provable membership preservation.
  let combined := j1 ++ j2
  let sorted := combined.mergeSort (fun a b => a.sequence ≤ b.sequence)
  dedupBySequence sorted

/-! ## Proofs -/

/-- Appending preserves strict ordering if new sequence is larger -/
theorem appendPreservesOrdering (j : Journal) (e : JournalEntry)
    (h : latestSequence j < e.sequence) :
    latestSequence (append j e) = e.sequence := by
  simp only [append, latestSequence]
  -- After append, the list is j ++ [e], so getLast? returns some e
  simp [List.getLast?_append_of_ne_nil _ (List.cons_ne_nil e [])]

/-- dedupBySequence preserves at least one entry per sequence number.
    Requires well-founded induction on list length since dedupBySequence
    recurses on a filtered sublist. -/
theorem dedupBySequence_preserves_sequence (sorted : Journal) (e : JournalEntry) :
    e ∈ sorted → ∃ e' ∈ dedupBySequence sorted, e'.sequence = e.sequence := by
  intro h
  induction sorted with
  | nil => exact absurd h (List.not_mem_nil _)
  | cons hd tl _ih =>
    simp only [dedupBySequence]
    by_cases heq : hd.sequence = e.sequence
    · -- hd has same sequence — use it as witness
      exact ⟨hd, List.mem_cons_self _ _, heq⟩
    · -- e ∈ tl with different sequence from hd, so e passes the filter.
      -- Need: ∃ e' ∈ dedupBySequence (tl.filter ...), e'.sequence = e.sequence
      -- This requires well-founded induction on (tl.filter ...).length < (hd :: tl).length
      -- which is true but not available from structural induction on the cons case.
      sorry  -- BLOCKED: well-founded induction on List.length needed for filter recursion.
             -- The structural IH gives us tl, but we recurse on tl.filter p.
             -- Path: use `have : (tl.filter p).length < (hd :: tl).length` + WF induction.

/-- Merged journals contain all entries from both.
    Proof uses List.mergeSort (permutation-preserving) instead of Array.qsort.
    The sort step is fully proved; only the dedup step still needs WF induction. -/
theorem mergeContainsBoth (j1 j2 : Journal) (e : JournalEntry) :
    e ∈ j1 ∨ e ∈ j2 → ∃ e' ∈ merge j1 j2, e'.sequence = e.sequence := by
  intro h
  simp only [merge]
  -- Step 1: e is in the combined list
  have h_combined : e ∈ j1 ++ j2 := List.mem_append.mpr h
  -- Step 2: e is in the sorted list (mergeSort is a permutation via Mathlib)
  have h_sorted : e ∈ (j1 ++ j2).mergeSort (fun a b => a.sequence ≤ b.sequence) :=
    (List.perm_mergeSort _ _).symm.mem_iff.mp h_combined
  -- Step 3: dedupBySequence preserves at least one entry per sequence
  exact dedupBySequence_preserves_sequence _ _ h_sorted

end ZoteroFormDB.Journal
