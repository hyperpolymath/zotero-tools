/**
 * Tractarian Atomic Facts: Core data structures for NSAI
 *
 * Based on Wittgenstein's Tractatus Logico-Philosophicus:
 * "The world is the totality of facts, not of things." (1.1)
 */

/** The kind of thing this citation is */
type itemType =
  | Book
  | BookSection
  | JournalArticle
  | ConferencePaper
  | Thesis
  | Webpage
  | Manuscript
  | Report
  | Patent

/** Creator types */
type creatorType =
  | Author
  | Editor
  | Contributor
  | Translator

/** Creator record */
type creator = {
  creatorType: creatorType,
  firstName: option<string>,
  lastName: string,
}

/** Atomic Citation: The fundamental unit of bibliographic reality */
type atomicCitation = {
  id: string,
  itemType: itemType,
  title: string,
  creators: array<creator>,
  date: option<string>,
  publicationTitle: option<string>,
  publisher: option<string>,
  place: option<string>,
  doi: option<string>,
  isbn: option<string>,
  issn: option<string>,
  url: option<string>,
  pages: option<string>,
  volume: option<string>,
  issue: option<string>,
  edition: option<string>,
  abstractNote: option<string>,
  tags: array<string>,
  extra: option<string>,
}

/** Validation State: Truth-functional analysis */
type validationState =
  | Valid
  | Incomplete
  | Inconsistent
  | Uncertain

/** Certainty score factors */
type certaintyFactors = {
  structural: float,
  consistency: float,
  referential: float,
}

/** How confident are we in validation? */
type certaintyScore = {
  score: float,
  factors: certaintyFactors,
  reasoning: string,
}

/** Issue severity */
type severity =
  | SeverityError
  | SeverityWarning
  | SeverityInfo

/** Validation Issue: What's wrong with this citation? */
type validationIssue = {
  severity: severity,
  field: option<string>,
  message: string,
  suggestion: option<string>,
  requiresUncertaintyNavigation: bool,
}

/** Validation Result: The output of formal verification */
type validationResult = {
  citation: atomicCitation,
  state: validationState,
  certainty: certaintyScore,
  issues: array<validationIssue>,
  timestamp: Date.t,
}

/** Citation Relation types */
type relationType =
  | Cites
  | CitedBy
  | RelatedTo
  | Contradicts
  | Supports

/** Citation Relation: Logical connections between citations */
type citationRelation = {
  relationType: relationType,
  source: string,
  target: string,
  confidence: float,
  isContradiction: bool,
}

/** Bibliography metadata */
type bibliographyMetadata = {
  created: Date.t,
  updated: Date.t,
  source: string,
}

/** Molecular Fact: Multiple citations related logically */
type bibliography = {
  citations: array<atomicCitation>,
  relationships: array<citationRelation>,
  metadata: bibliographyMetadata,
}

// Helper functions for itemType string conversion
let itemTypeToString = itemType =>
  switch itemType {
  | Book => "book"
  | BookSection => "bookSection"
  | JournalArticle => "journalArticle"
  | ConferencePaper => "conferencePaper"
  | Thesis => "thesis"
  | Webpage => "webpage"
  | Manuscript => "manuscript"
  | Report => "report"
  | Patent => "patent"
  }

let stringToItemType = str =>
  switch str {
  | "book" => Some(Book)
  | "bookSection" => Some(BookSection)
  | "journalArticle" => Some(JournalArticle)
  | "conferencePaper" => Some(ConferencePaper)
  | "thesis" => Some(Thesis)
  | "webpage" => Some(Webpage)
  | "manuscript" => Some(Manuscript)
  | "report" => Some(Report)
  | "patent" => Some(Patent)
  | _ => None
  }

let validationStateToString = state =>
  switch state {
  | Valid => "VALID"
  | Incomplete => "INCOMPLETE"
  | Inconsistent => "INCONSISTENT"
  | Uncertain => "UNCERTAIN"
  }
