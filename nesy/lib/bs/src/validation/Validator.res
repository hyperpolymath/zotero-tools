/**
 * Core Validation Engine: Truth-Functional Analysis
 *
 * Implements Tractarian logical validation:
 * "A proposition is a truth-function of elementary propositions."
 * (Tractatus 5)
 */

open Atomic

/** Required fields by item type */
let requiredFields = itemType =>
  switch itemType {
  | Book => ["title", "creators", "publisher", "date"]
  | BookSection => ["title", "creators", "publicationTitle", "date"]
  | JournalArticle => ["title", "creators", "publicationTitle", "date"]
  | ConferencePaper => ["title", "creators", "date"]
  | Thesis => ["title", "creators", "date"]
  | Webpage => ["title", "url", "date"]
  | Manuscript => ["title", "creators"]
  | Report => ["title", "creators", "date"]
  | Patent => ["title", "creators", "date"]
  }

/** Check if a field has a value in a citation */
let hasField = (citation: atomicCitation, field: string): bool => {
  switch field {
  | "title" => citation.title->String.length > 0
  | "creators" => citation.creators->Array.length > 0
  | "publisher" => citation.publisher->Option.isSome
  | "publicationTitle" => citation.publicationTitle->Option.isSome
  | "date" => citation.date->Option.isSome
  | "url" => citation.url->Option.isSome
  | _ => false
  }
}

/** Validate structural completeness */
let validateStructure = (citation: atomicCitation): array<validationIssue> => {
  let issues: array<validationIssue> = []
  let required = requiredFields(citation.itemType)

  // Check required fields
  let missingFields =
    required->Array.filter(field => !hasField(citation, field))

  let fieldIssues =
    missingFields->Array.map(field => {
      severity: SeverityError,
      field: Some(field),
      message: `Required field "${field}" is missing`,
      suggestion: Some(`Add ${field} to complete citation structure`),
      requiresUncertaintyNavigation: false,
    })

  // Creators validation
  let creatorIssues = if citation.creators->Array.length == 0 {
    [
      {
        severity: SeverityError,
        field: Some("creators"),
        message: "Citation must have at least one creator",
        suggestion: Some("Add author, editor, or contributor"),
        requiresUncertaintyNavigation: false,
      },
    ]
  } else {
    []
  }

  // Title validation
  let titleIssues = if citation.title->String.trim->String.length == 0 {
    [
      {
        severity: SeverityError,
        field: Some("title"),
        message: "Title cannot be empty",
        suggestion: Some("Add a title for this citation"),
        requiresUncertaintyNavigation: false,
      },
    ]
  } else {
    []
  }

  Array.concat(issues, fieldIssues)
  ->Array.concat(creatorIssues)
  ->Array.concat(titleIssues)
}

/** Validate date format (ISO 8601 partial) */
let isValidDateFormat = (date: string): bool => {
  let datePattern = %re("/^\d{4}(-\d{2}(-\d{2})?)?$/")
  datePattern->RegExp.test(date)
}

/** Extract year from date string */
let extractYear = (date: string): option<int> => {
  if date->String.length >= 4 {
    date->String.substring(~start=0, ~end=4)->Int.fromString
  } else {
    None
  }
}

/** Validate internal consistency */
let validateConsistency = (citation: atomicCitation): array<validationIssue> => {
  let issues: array<validationIssue> = []

  // Date validation
  let dateIssues = switch citation.date {
  | Some(date) =>
    if !isValidDateFormat(date) {
      [
        {
          severity: SeverityError,
          field: Some("date"),
          message: `Invalid date format: "${date}"`,
          suggestion: Some("Use ISO 8601 format (YYYY, YYYY-MM, or YYYY-MM-DD)"),
          requiresUncertaintyNavigation: false,
        },
      ]
    } else {
      switch extractYear(date) {
      | Some(year) if year < 1000 || year > 2100 =>
        [
          {
            severity: SeverityWarning,
            field: Some("date"),
            message: `Unusual publication year: ${year->Int.toString}`,
            suggestion: Some("Verify publication date is correct"),
            requiresUncertaintyNavigation: true,
          },
        ]
      | _ => []
      }
    }
  | None => []
  }

  // Creator lastName validation
  let creatorIssues =
    citation.creators
    ->Array.filter(c => c.lastName->String.trim->String.length == 0)
    ->Array.map(_ => {
      severity: SeverityError,
      field: Some("creators"),
      message: "Creator missing lastName",
      suggestion: Some("Add lastName for all creators"),
      requiresUncertaintyNavigation: false,
    })

  Array.concat(issues, dateIssues)->Array.concat(creatorIssues)
}

/** Validate DOI format */
let isValidDOI = (doi: string): bool => {
  let doiPattern = %re("/^10\.\d{4,}\/\S+$/")
  doiPattern->RegExp.test(doi)
}

/** Validate ISBN (basic length check) */
let isValidISBN = (isbn: string): bool => {
  let clean = isbn->String.replaceRegExp(%re("/[-\s]/g"), "")
  clean->String.length == 10 || clean->String.length == 13
}

/** Validate referential integrity */
let validateReferences = (citation: atomicCitation): array<validationIssue> => {
  let issues: array<validationIssue> = []

  // DOI validation
  let doiIssues = switch citation.doi {
  | Some(doi) if !isValidDOI(doi) =>
    [
      {
        severity: SeverityWarning,
        field: Some("DOI"),
        message: "DOI format may be invalid",
        suggestion: Some("DOI should start with \"10.\" followed by registrant/suffix"),
        requiresUncertaintyNavigation: false,
      },
    ]
  | _ => []
  }

  // ISBN validation
  let isbnIssues = switch citation.isbn {
  | Some(isbn) if !isValidISBN(isbn) =>
    [
      {
        severity: SeverityWarning,
        field: Some("ISBN"),
        message: "ISBN should be 10 or 13 digits",
        suggestion: Some("Verify ISBN is correct"),
        requiresUncertaintyNavigation: false,
      },
    ]
  | _ => []
  }

  // No persistent identifier warning
  let identifierIssues =
    if (
      citation.doi->Option.isNone &&
      citation.isbn->Option.isNone &&
      citation.url->Option.isNone &&
      citation.itemType != Manuscript
    ) {
      [
        {
          severity: SeverityWarning,
          field: Some("identifiers"),
          message: "No persistent identifier (DOI, ISBN, or URL)",
          suggestion: Some("Add DOI or ISBN if available"),
          requiresUncertaintyNavigation: true,
        },
      ]
    } else {
      []
    }

  Array.concat(issues, doiIssues)
  ->Array.concat(isbnIssues)
  ->Array.concat(identifierIssues)
}

/** Determine overall validation state */
let determineState = (issues: array<validationIssue>): validationState => {
  let errors = issues->Array.filter(i => i.severity == SeverityError)
  let uncertainties = issues->Array.filter(i => i.requiresUncertaintyNavigation)

  if errors->Array.length > 0 {
    let hasConsistencyErrors =
      errors->Array.some(e =>
        e.message->String.includes("Invalid") || e.message->String.includes("inconsistent")
      )
    if hasConsistencyErrors {
      Inconsistent
    } else {
      Incomplete
    }
  } else if uncertainties->Array.length > 0 {
    Uncertain
  } else {
    Valid
  }
}

/** Calculate certainty score */
let rec calculateCertainty = (
  citation: atomicCitation,
  issues: array<validationIssue>,
): certaintyScore => {
  let required = requiredFields(citation.itemType)
  let presentCount =
    required->Array.filter(field => hasField(citation, field))->Array.length

  let structural = if required->Array.length > 0 {
    presentCount->Int.toFloat /. required->Array.length->Int.toFloat
  } else {
    1.0
  }

  let errors = issues->Array.filter(i => i.severity == SeverityError)
  let totalChecks = issues->Array.length + 10
  let consistency = 1.0 -. errors->Array.length->Int.toFloat /. totalChecks->Int.toFloat

  let referential = {
    let base = 0.5
    let doiBoost = if citation.doi->Option.isSome {
      0.3
    } else {
      0.0
    }
    let isbnBoost = if citation.isbn->Option.isSome {
      0.2
    } else {
      0.0
    }
    let urlBoost = if citation.url->Option.isSome {
      0.1
    } else {
      0.0
    }
    let total = base +. doiBoost +. isbnBoost +. urlBoost
    if total > 1.0 { 1.0 } else { total }
  }

  let score = structural *. 0.5 +. consistency *. 0.3 +. referential *. 0.2

  let reasoning = generateCertaintyReasoning(structural, consistency, referential, issues)

  {
    score: Math.round(score *. 100.0) /. 100.0,
    factors: {
      structural: Math.round(structural *. 100.0) /. 100.0,
      consistency: Math.round(consistency *. 100.0) /. 100.0,
      referential: Math.round(referential *. 100.0) /. 100.0,
    },
    reasoning,
  }
}
and generateCertaintyReasoning = (
  structural: float,
  consistency: float,
  referential: float,
  issues: array<validationIssue>,
): string => {
  let structuralPart = if structural >= 0.9 {
    "Structurally complete"
  } else if structural >= 0.7 {
    "Mostly complete structure"
  } else {
    "Missing required fields"
  }

  let consistencyPart = if consistency >= 0.9 {
    "internally consistent"
  } else if consistency >= 0.7 {
    "minor inconsistencies"
  } else {
    "significant inconsistencies"
  }

  let referentialPart = if referential >= 0.8 {
    "strong referential integrity"
  } else if referential >= 0.5 {
    "some referential identifiers"
  } else {
    "weak referential integrity"
  }

  let uncertaintyCount =
    issues->Array.filter(i => i.requiresUncertaintyNavigation)->Array.length
  let uncertaintyPart = if uncertaintyCount > 0 {
    `, ${uncertaintyCount->Int.toString} uncertainties require Fogbinder exploration`
  } else {
    ""
  }

  `${structuralPart}, ${consistencyPart}, ${referentialPart}${uncertaintyPart}.`
}

/** Main validation function */
let validate = (citation: atomicCitation): validationResult => {
  let structuralIssues = validateStructure(citation)
  let consistencyIssues = validateConsistency(citation)
  let referentialIssues = validateReferences(citation)

  let issues =
    structuralIssues->Array.concat(consistencyIssues)->Array.concat(referentialIssues)

  let state = determineState(issues)
  let certainty = calculateCertainty(citation, issues)

  {
    citation,
    state,
    certainty,
    issues,
    timestamp: Date.make(),
  }
}

/** Batch validate multiple citations */
let validateBatch = (citations: array<atomicCitation>): array<validationResult> => {
  citations->Array.map(validate)
}
