// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
//
// ZoteroBindings.res
// ReScript bindings to Zotero API
// Minimal JS interop for Zotero plugin functionality

// Zotero item (citation)
type zoteroItem = {
  id: string,
  title: string,
  creators: array<string>,
  abstractText: option<string>,
  tags: array<string>,
  dateAdded: float,
}

// Zotero collection
type zoteroCollection = {
  id: string,
  name: string,
  items: array<zoteroItem>,
}

// External Zotero API (would be implemented in JS/TypeScript)
@module("./zotero_api.js")
external getItems: unit => promise<array<zoteroItem>> = "getItems"

@module("./zotero_api.js")
external getCollections: unit => promise<array<zoteroCollection>> = "getCollections"

@module("./zotero_api.js")
external addTag: (string, string) => promise<unit> = "addTag"

@module("./zotero_api.js")
external createNote: (string, string) => promise<unit> = "createNote"

// Convert Zotero item to text for analysis
let itemToText = (item: zoteroItem): string => {
  let abstract = switch item.abstractText {
  | Some(text) => text
  | None => ""
  }

  `${item.title}. ${abstract}`
}

// Extract citations from collection
let extractCitations = (collection: zoteroCollection): array<string> => {
  Array.map(collection.items, item => itemToText(item))
}

// Tag item with Fogbinder analysis
let tagWithAnalysis = (itemId: string, analysisType: string): promise<unit> => {
  let tag = `fogbinder:${analysisType}`
  addTag(itemId, tag)
}

// Create note with FogTrail visualization
let createFogTrailNote = (itemId: string, svgContent: string): promise<unit> => {
  let noteContent = `<h2>FogTrail Visualization</h2>\n${svgContent}`
  createNote(itemId, noteContent)
}

// Batch analyze collection
let analyzeCollection = async (collectionId: string): unit => {
  let collections = await getCollections()

  let targetCollection = Array.find(collections, c => c.id == collectionId)

  switch targetCollection {
  | Some(coll) => {
      let citations = extractCitations(coll)

      // Would integrate with analysis engines here
      Console.log(`Analyzing ${Int.toString(Array.length(citations))} citations...`)
    }
  | None => Console.log("Collection not found")
  }
}

// ---------------------------------------------------------------------------
// Orphan Adoption — bindings for finding and parenting orphan attachments
// ---------------------------------------------------------------------------

// An attachment that has no parent item.
type orphanAttachment = {
  id: int,
  title: string,
  filename: string,
  itemType: string,
}

// Result of an adoption operation.
type adoptionError = {
  id: int,
  error: string,
}

type adoptionResult = {
  total: int,
  adopted: int,
  failed: int,
  skipped: int,
  errors: array<adoptionError>,
}

// Get all orphan attachments (no parent item), skipping known problem types.
@module("./zotero_api.js")
external getOrphanAttachments: array<string> => promise<array<orphanAttachment>> =
  "getOrphanAttachments"

// Create parent items for a list of orphan attachment IDs.
@module("./zotero_api.js")
external adoptOrphans: array<int> => promise<adoptionResult> = "adoptOrphans"

// One-shot: find all orphans and create parent items for all of them.
@module("./zotero_api.js")
external adoptAllOrphans: array<string> => promise<adoptionResult> = "adoptAllOrphans"
