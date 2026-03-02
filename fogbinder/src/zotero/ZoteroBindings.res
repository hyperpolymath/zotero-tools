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
  Js.Array2.map(collection.items, item => itemToText(item))
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

  let targetCollection = Js.Array2.find(collections, c => c.id == collectionId)

  switch targetCollection {
  | Some(coll) => {
      let citations = extractCitations(coll)

      // Would integrate with analysis engines here
      Js.log(`Analyzing ${Belt.Int.toString(Js.Array2.length(citations))} citations...`)
    }
  | None => Js.log("Collection not found")
  }
}
