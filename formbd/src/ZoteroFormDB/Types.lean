-- SPDX-License-Identifier: AGPL-3.0-or-later
/-!
# Core Types

Refinement types that enforce constraints at compile time.
-/

namespace ZoteroFormDB.Types

/-! ## Bounded Natural Numbers -/

/-- A natural number with proven bounds -/
structure BoundedNat (min max : Nat) where
  val : Nat
  min_le : min ≤ val
  val_le : val ≤ max

instance : ToString (BoundedNat min max) where
  toString bn := toString bn.val

/-- Smart constructor with automatic proof search -/
def mkBoundedNat (min max : Nat) (n : Nat)
    (h1 : min ≤ n := by omega) (h2 : n ≤ max := by omega) : BoundedNat min max :=
  ⟨n, h1, h2⟩

/-! ## Bounded Floats -/

/-- A float with proven bounds -/
structure BoundedFloat (min max : Float) where
  val : Float
  min_le : min ≤ val
  val_le : val ≤ max

/-- Confidence level: float in [0.0, 1.0] -/
abbrev Confidence := BoundedFloat 0.0 1.0

/-! ## Non-Empty Strings -/

/-- A string guaranteed to be non-empty -/
structure NonEmptyString where
  val : String
  nonempty : val.length > 0

instance : ToString NonEmptyString where
  toString nes := nes.val

/-- Smart constructor -/
def mkNonEmptyString (s : String) (h : s.length > 0 := by decide) : NonEmptyString :=
  ⟨s, h⟩

/-! ## Actor ID -/

/-- Identifier for who performed an action -/
abbrev ActorId := NonEmptyString

/-! ## Rationale -/

/-- Explanation for why something was done - must be non-empty -/
abbrev Rationale := NonEmptyString

/-! ## Timestamps -/

/-- Unix timestamp in milliseconds -/
structure Timestamp where
  millis : Nat
  deriving Repr, BEq

instance : ToString Timestamp where
  toString ts := s!"Timestamp({ts.millis})"

/-- Current timestamp (placeholder - needs IO) -/
def Timestamp.now : IO Timestamp := do
  -- In real implementation, get system time
  pure ⟨0⟩

/-! ## UUIDs -/

/-- UUID v4 format validation -/
def isValidUUID (s : String) : Bool :=
  s.length == 36 &&
  s.get? 8 == some '-' &&
  s.get? 13 == some '-' &&
  s.get? 18 == some '-' &&
  s.get? 23 == some '-'

/-- A validated UUID -/
structure ValidUUID where
  val : String
  valid : isValidUUID val = true

instance : ToString ValidUUID where
  toString uuid := uuid.val

/-! ## Content Hashes -/

/-- BLAKE3 hash (32 bytes as hex string) -/
structure Blake3Hash where
  hex : String
  valid_length : hex.length == 64

instance : ToString Blake3Hash where
  toString h := h.hex

/-! ## MIME Types -/

/-- Common MIME types for attachments -/
inductive MimeType where
  | pdf : MimeType
  | html : MimeType
  | jpeg : MimeType
  | png : MimeType
  | gif : MimeType
  | text : MimeType
  | other : String → MimeType
  deriving Repr, BEq

instance : ToString MimeType where
  toString
    | .pdf => "application/pdf"
    | .html => "text/html"
    | .jpeg => "image/jpeg"
    | .png => "image/png"
    | .gif => "image/gif"
    | .text => "text/plain"
    | .other s => s

/-! ## Item Types -/

/-- Zotero item types -/
inductive ItemType where
  | artwork
  | attachment
  | audioRecording
  | bill
  | blogPost
  | book
  | bookSection
  | case_
  | computerProgram
  | conferencePaper
  | dictionaryEntry
  | document
  | email
  | encyclopediaArticle
  | film
  | forumPost
  | hearing
  | instantMessage
  | interview
  | journalArticle
  | letter
  | magazineArticle
  | manuscript
  | map
  | newspaperArticle
  | note
  | patent
  | podcast
  | presentation
  | radioBroadcast
  | report
  | statute
  | thesis
  | tvBroadcast
  | videoRecording
  | webpage
  deriving Repr, BEq

end ZoteroFormDB.Types
