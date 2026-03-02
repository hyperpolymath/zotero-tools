

import * as Zotero_apiJs from "./zotero_api.js";

function getItems(prim) {
  return Zotero_apiJs.getItems();
}

function getCollections(prim) {
  return Zotero_apiJs.getCollections();
}

function addTag(prim0, prim1) {
  return Zotero_apiJs.addTag(prim0, prim1);
}

function createNote(prim0, prim1) {
  return Zotero_apiJs.createNote(prim0, prim1);
}

function itemToText(item) {
  let text = item.abstractText;
  let abstract = text !== undefined ? text : "";
  return item.title + `. ` + abstract;
}

function extractCitations(collection) {
  return collection.items.map(itemToText);
}

function tagWithAnalysis(itemId, analysisType) {
  let tag = `fogbinder:` + analysisType;
  return Zotero_apiJs.addTag(itemId, tag);
}

function createFogTrailNote(itemId, svgContent) {
  let noteContent = `<h2>FogTrail Visualization</h2>\n` + svgContent;
  return Zotero_apiJs.createNote(itemId, noteContent);
}

async function analyzeCollection(collectionId) {
  let collections = await Zotero_apiJs.getCollections();
  let targetCollection = collections.find(c => c.id === collectionId);
  if (targetCollection !== undefined) {
    let citations = extractCitations(targetCollection);
    console.log(`Analyzing ` + String(citations.length) + ` citations...`);
    return;
  }
  console.log("Collection not found");
}

export {
  getItems,
  getCollections,
  addTag,
  createNote,
  itemToText,
  extractCitations,
  tagWithAnalysis,
  createFogTrailNote,
  analyzeCollection,
}
/* ./zotero_api.js Not a pure module */
