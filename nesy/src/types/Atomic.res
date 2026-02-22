/**
 * Tractarian Atomic Facts — Core NSAI Data Structures (ReScript).
 *
 * This module defines the foundational types for the Neuro-Symbolic 
 * AI (NSAI) pipeline. It treats bibliographic records as atomic 
 * logical facts that can be combined into molecular bibliographies.
 *
 * PHILOSOPHY: Based on Wittgenstein's Tractatus Logico-Philosophicus.
 * "The world is the totality of facts, not of things." (1.1)
 */

/** ITEM TYPE: The ontological category of a research artifact. */
type itemType =
  | Book | JournalArticle | ConferencePaper | Thesis | Webpage | Manuscript | Patent

/** ATOMIC CITATION: The irreducible unit of bibliographic reality. */
type atomicCitation = {
  id: string,
  itemType: itemType,
  title: string,
  creators: array<creator>,
  date: option<string>,
  doi: option<string>,
  isbn: option<string>,
  url: option<string>,
}

/** VALIDATION STATE: The outcome of truth-functional analysis. */
type validationState =
  | Valid        // Proved consistent and complete.
  | Incomplete   // Missing required elementary propositions (fields).
  | Inconsistent // Contains logical contradictions (e.g. invalid date).
  | Uncertain    // Requires subjective navigation (Fogbinder).

/** CERTAINTY MODEL: Quantifies the assurance level of a validation. */
type certaintyScore = {
  score: float, // 0.0 to 1.0
  factors: { structural: float, consistency: float, referential: float },
  reasoning: string, // Logical trace explaining the score.
}

/** RELATION TYPE: Semantic connections between atomic facts. */
type relationType =
  | Cites | CitedBy | RelatedTo | Contradicts | Supports
