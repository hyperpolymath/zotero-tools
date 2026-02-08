-- SPDX-License-Identifier: AGPL-3.0-or-later
/-!
# Zotero Items

Zotero-compatible item structures with provenance and quality tracking.
-/

import ZoteroFormDB.Types
import ZoteroFormDB.Provenance
import ZoteroFormDB.Prompt

namespace ZoteroFormDB.Items

open Types Provenance Prompt

/-! ## Base Item Structure -/

/-- Core fields all items have -/
structure ItemBase where
  key : ValidUUID
  version : Nat
  itemType : ItemType
  dateAdded : Timestamp
  dateModified : Timestamp
  -- Provenance (required by types!)
  added_by : ActorId
  rationale : Rationale
  deriving Repr

/-! ## Bibliographic Metadata -/

/-- Author/Creator -/
structure Creator where
  creatorType : String  -- "author", "editor", etc.
  firstName : Option String
  lastName : NonEmptyString
  deriving Repr

/-- Standard bibliographic fields -/
structure BiblioFields where
  title : Option NonEmptyString
  creators : List Creator
  abstractNote : Option String
  date : Option String
  url : Option String
  accessDate : Option String
  language : Option String
  shortTitle : Option String
  rights : Option String
  extra : Option String
  tags : List String
  collections : List ValidUUID
  relations : List (String × ValidUUID)
  deriving Repr

/-! ## Specific Item Types -/

/-- Journal Article -/
structure JournalArticle extends ItemBase, BiblioFields where
  publicationTitle : Option String
  volume : Option String
  issue : Option String
  pages : Option String
  doi : Option String
  issn : Option String
  -- Quality assessment (optional but encouraged)
  promptScores : Option PromptScores
  deriving Repr

/-- Book -/
structure Book extends ItemBase, BiblioFields where
  publisher : Option String
  place : Option String
  edition : Option String
  numPages : Option Nat
  isbn : Option String
  series : Option String
  seriesNumber : Option String
  promptScores : Option PromptScores
  deriving Repr

/-- Report -/
structure Report extends ItemBase, BiblioFields where
  reportNumber : Option String
  reportType : Option String
  institution : Option String
  place : Option String
  promptScores : Option PromptScores
  deriving Repr

/-- Webpage -/
structure Webpage extends ItemBase, BiblioFields where
  websiteTitle : Option String
  websiteType : Option String
  promptScores : Option PromptScores
  deriving Repr

/-! ## Attachments -/

/-- File attachment with content hash -/
structure Attachment where
  key : ValidUUID
  parentItem : ValidUUID
  title : NonEmptyString
  filename : NonEmptyString
  contentType : MimeType
  contentHash : Blake3Hash
  fileSize : Nat
  -- Provenance
  added_by : ActorId
  added_at : Timestamp
  rationale : Rationale
  -- Quality (for evidence files)
  promptScores : Option PromptScores
  deriving Repr

/-- Linked URL attachment -/
structure LinkAttachment where
  key : ValidUUID
  parentItem : ValidUUID
  title : NonEmptyString
  url : NonEmptyString
  -- Provenance
  added_by : ActorId
  added_at : Timestamp
  rationale : Rationale
  -- Snapshot hash if archived
  snapshotHash : Option Blake3Hash
  promptScores : Option PromptScores
  deriving Repr

/-! ## Notes -/

/-- Note attached to an item -/
structure Note where
  key : ValidUUID
  parentItem : Option ValidUUID  -- None for standalone notes
  content : NonEmptyString       -- HTML content
  -- Provenance
  added_by : ActorId
  added_at : Timestamp
  rationale : Rationale
  tags : List String
  deriving Repr

/-! ## Collections -/

/-- A collection (folder) of items -/
structure Collection where
  key : ValidUUID
  name : NonEmptyString
  parentCollection : Option ValidUUID
  -- Provenance
  added_by : ActorId
  added_at : Timestamp
  rationale : Rationale
  deriving Repr

/-! ## Item Union Type -/

/-- Any Zotero item -/
inductive ZoteroItem where
  | journalArticle : JournalArticle → ZoteroItem
  | book : Book → ZoteroItem
  | report : Report → ZoteroItem
  | webpage : Webpage → ZoteroItem
  | attachment : Attachment → ZoteroItem
  | linkAttachment : LinkAttachment → ZoteroItem
  | note : Note → ZoteroItem
  -- Add more as needed
  deriving Repr

/-! ## Provenance Proofs -/

/-- All items have provenance by construction -/
theorem JournalArticle.hasProvenance (j : JournalArticle) :
    j.added_by.val.length > 0 ∧ j.rationale.val.length > 0 :=
  ⟨j.added_by.nonempty, j.rationale.nonempty⟩

theorem Book.hasProvenance (b : Book) :
    b.added_by.val.length > 0 ∧ b.rationale.val.length > 0 :=
  ⟨b.added_by.nonempty, b.rationale.nonempty⟩

theorem Attachment.hasProvenance (a : Attachment) :
    a.added_by.val.length > 0 ∧ a.rationale.val.length > 0 :=
  ⟨a.added_by.nonempty, a.rationale.nonempty⟩

/-! ## Quality Filtering -/

/-- Get items with quality above threshold -/
def filterByQuality (items : List ZoteroItem) (minScore : Nat) : List ZoteroItem :=
  items.filter fun item =>
    match item with
    | .journalArticle j =>
      j.promptScores.map (·.overall.val ≥ minScore) |>.getD true
    | .book b =>
      b.promptScores.map (·.overall.val ≥ minScore) |>.getD true
    | .report r =>
      r.promptScores.map (·.overall.val ≥ minScore) |>.getD true
    | .webpage w =>
      w.promptScores.map (·.overall.val ≥ minScore) |>.getD true
    | _ => true  -- Non-rated items pass through

end ZoteroFormDB.Items
