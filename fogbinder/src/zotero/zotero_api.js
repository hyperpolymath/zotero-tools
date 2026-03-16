// SPDX-License-Identifier: PMPL-1.0-or-later
// Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
//
// zotero_api.js
// JavaScript shim for Zotero API — runs inside the Zotero process where
// the global `Zotero` object is available. ReScript modules call these
// functions via @module bindings.

/**
 * Get all items from Zotero library
 * @returns {Promise<Array>}
 */
export async function getItems() {
  // In production, this would call Zotero.Items.getAll() or similar
  // For now, return mock data
  return [
    {
      id: '1',
      title: 'Philosophical Investigations',
      creators: ['Wittgenstein, Ludwig'],
      abstractText: 'A work on language games and family resemblance',
      tags: [],
      dateAdded: Date.now(),
    },
    {
      id: '2',
      title: 'How to Do Things With Words',
      creators: ['Austin, J.L.'],
      abstractText: 'Speech act theory and performative utterances',
      tags: [],
      dateAdded: Date.now(),
    },
  ];
}

/**
 * Get all collections
 * @returns {Promise<Array>}
 */
export async function getCollections() {
  return [
    {
      id: 'coll1',
      name: 'Philosophy of Language',
      items: await getItems(),
    },
  ];
}

/**
 * Add tag to item
 * @param {string} itemId
 * @param {string} tag
 * @returns {Promise<void>}
 */
export async function addTag(itemId, tag) {
  console.log(`Adding tag "${tag}" to item ${itemId}`);
  // In production: Zotero.Items.get(itemId).addTag(tag)
}

/**
 * Create note attached to item
 * @param {string} itemId
 * @param {string} content
 * @returns {Promise<void>}
 */
export async function createNote(itemId, content) {
  console.log(`Creating note for item ${itemId}`);
  // In production: Zotero.Notes.create(itemId, content)
}

// ---------------------------------------------------------------------------
// Orphan Adoption — find attachments without parents and create parent items
// ---------------------------------------------------------------------------

// Item type IDs that should be skipped when adopting orphans. These are
// plugin-injected attachment types (e.g. BetterNotes) that cannot or should
// not receive parent items. The user can extend this list via config.
const SKIP_ITEM_TYPES = new Set([
  "betternotes",
  "note",         // standalone notes are not attachments
]);

/**
 * Get all attachment items that have no parent item (orphans).
 * Excludes items whose type is in SKIP_ITEM_TYPES.
 *
 * @param {Set<string>} [extraSkipTypes] - additional item types to skip
 * @returns {Promise<Array<{id: number, title: string, filename: string, itemType: string}>>}
 */
export async function getOrphanAttachments(extraSkipTypes = []) {
  const skipSet = new Set([...SKIP_ITEM_TYPES, ...extraSkipTypes]);

  // Zotero.Items.getAll() returns all items in the current library.
  // We filter to attachments (itemTypeID for attachment) with no parentID.
  const libraryID = Zotero.Libraries.userLibraryID;
  const allItems = await Zotero.Items.getAll(libraryID);

  const orphans = [];
  for (const item of allItems) {
    // Only consider attachment items
    if (!item.isAttachment()) continue;

    // Skip if it already has a parent
    if (item.parentID) continue;

    // Skip known problem types
    const typeName = (item.getField("extra") || "").toLowerCase();
    const filename = item.attachmentFilename || "";
    const title = item.getField("title") || filename;

    // Check if this is a known skip type (by title pattern or extra field)
    let shouldSkip = false;
    for (const skipType of skipSet) {
      if (
        title.toLowerCase().includes(skipType) ||
        typeName.includes(skipType) ||
        filename.toLowerCase().includes(skipType)
      ) {
        shouldSkip = true;
        break;
      }
    }

    if (!shouldSkip) {
      orphans.push({
        id: item.id,
        title: title,
        filename: filename,
        itemType: Zotero.ItemTypes.getName(item.itemTypeID) || "attachment",
      });
    }
  }

  return orphans;
}

/**
 * Create parent items for a list of orphan attachment IDs.
 * Uses Zotero's built-in "Create Parent Item" logic which attempts to
 * extract metadata from the attachment (PDF metadata, filename parsing, etc.).
 *
 * @param {Array<number>} orphanIds - item IDs of orphan attachments
 * @returns {Promise<{adopted: number, failed: number, errors: Array<{id: number, error: string}>}>}
 */
export async function adoptOrphans(orphanIds) {
  let adopted = 0;
  let failed = 0;
  const errors = [];

  for (const id of orphanIds) {
    try {
      const item = await Zotero.Items.getAsync(id);
      if (!item || !item.isAttachment() || item.parentID) {
        // Already has a parent or isn't an attachment — skip silently
        continue;
      }

      // Use Zotero's recogniser to create a parent from metadata.
      // This is the same logic as right-click → "Create Parent Item".
      const newParent = new Zotero.Item("journalArticle");
      newParent.libraryID = item.libraryID;

      // Attempt to extract title from filename if no embedded metadata
      const filename = item.attachmentFilename || "";
      const titleGuess = filename
        .replace(/\.[^.]+$/, "")     // strip extension
        .replace(/[_-]+/g, " ")      // underscores/hyphens to spaces
        .replace(/\s+/g, " ")        // collapse whitespace
        .trim();

      newParent.setField("title", titleGuess || "Untitled");
      await newParent.saveTx();

      // Reparent the attachment under the new item
      item.parentID = newParent.id;
      await item.saveTx();

      adopted++;
    } catch (err) {
      failed++;
      errors.push({ id: id, error: String(err) });
    }
  }

  return { adopted, failed, errors };
}

/**
 * One-shot: find all orphan attachments and create parent items for them.
 * Combines getOrphanAttachments + adoptOrphans.
 *
 * @param {Array<string>} [extraSkipTypes] - additional item types to skip
 * @returns {Promise<{total: number, adopted: number, failed: number, skipped: number, errors: Array}>}
 */
export async function adoptAllOrphans(extraSkipTypes = []) {
  const orphans = await getOrphanAttachments(extraSkipTypes);
  const ids = orphans.map((o) => o.id);

  if (ids.length === 0) {
    return { total: 0, adopted: 0, failed: 0, skipped: 0, errors: [] };
  }

  const result = await adoptOrphans(ids);
  return {
    total: orphans.length,
    adopted: result.adopted,
    failed: result.failed,
    skipped: orphans.length - ids.length,
    errors: result.errors,
  };
}
