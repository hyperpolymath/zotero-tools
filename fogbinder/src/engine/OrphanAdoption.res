// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
//
// OrphanAdoption.res — Orphan Attachment Adoption Engine
//
// Solves a persistent Zotero UX frustration: when importing many items,
// some arrive as bare attachments without parent items. Zotero's built-in
// "Create Parent Item" action requires manual selection and fails if even
// one selected item already has a parent.
//
// This module:
//   1. Finds ALL attachments that lack a parent item.
//   2. Filters out known problem items (BetterNotes, etc.) that cannot
//      or should not receive parent items.
//   3. Creates parent items for every remaining orphan in one operation.
//   4. Reports what was adopted, what was skipped, and what failed.
//
// Usage from Fogbinder menu:
//   "Adopt Orphan Attachments" → runs adoptAll with default skip list
//
// Usage from Zotero JS console:
//   Fogbinder.OrphanAdoption.adoptAll()

open ZoteroBindings

// Default item types/patterns to skip during adoption. These are attachments
// that Zotero plugins inject as standalone items and which break if you try
// to give them parent items. BetterNotes is the most common offender.
let defaultSkipPatterns = ["betternotes", "note"]

// Adoption report — human-readable summary of what happened.
type adoptionReport = {
  result: adoptionResult,
  summary: string,
}

// Build a human-readable summary string from an adoption result.
let summarise = (result: adoptionResult): string => {
  if result.total == 0 {
    "No orphan attachments found — library is clean."
  } else {
    let lines = [
      `Found ${Int.toString(result.total)} orphan attachment(s).`,
      `  Adopted: ${Int.toString(result.adopted)}`,
      `  Failed:  ${Int.toString(result.failed)}`,
      `  Skipped: ${Int.toString(result.skipped)}`,
    ]

    let errorLines = Array.map(result.errors, err =>
      `  Error on item ${Int.toString(err.id)}: ${err.error}`
    )

    let allLines = Array.concat(lines, errorLines)
    Array.join(allLines, "\n")
  }
}

// Run the full adoption pipeline with the default skip list.
// Returns a report with both the raw result and a human-readable summary.
let adoptAll = async (): adoptionReport => {
  Console.log("Fogbinder: scanning for orphan attachments...")

  let result = await adoptAllOrphans(defaultSkipPatterns)
  let summary = summarise(result)

  Console.log(`Fogbinder: orphan adoption complete.\n${summary}`)

  {result, summary}
}

// Run adoption with a custom skip list (extends the defaults).
let adoptAllWithSkips = async (~extraSkips: array<string>): adoptionReport => {
  let skipList = Array.concat(defaultSkipPatterns, extraSkips)

  Console.log(
    `Fogbinder: scanning for orphan attachments (skipping ${Int.toString(
        Array.length(skipList),
      )} patterns)...`,
  )

  let result = await adoptAllOrphans(skipList)
  let summary = summarise(result)

  Console.log(`Fogbinder: orphan adoption complete.\n${summary}`)

  {result, summary}
}

// Preview only — find orphans without adopting them.
// Useful to check what WOULD be adopted before committing.
let previewOrphans = async (): array<orphanAttachment> => {
  let orphans = await getOrphanAttachments(defaultSkipPatterns)

  Console.log(
    `Fogbinder: found ${Int.toString(Array.length(orphans))} orphan attachment(s).`,
  )

  Array.forEach(orphans, orphan =>
    Console.log(`  [${Int.toString(orphan.id)}] ${orphan.title} (${orphan.filename})`)
  )

  orphans
}
