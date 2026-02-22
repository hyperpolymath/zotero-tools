# SPDX-License-Identifier: AGPL-3.0-or-later

"""
Zotero SQLite Operations — High-Assurance Metadata Management.

This module provides direct access to the Zotero SQLite database. It is 
responsible for identifying attachments with non-descriptive filenames and 
updating their metadata based on extracted EXIF or bibliographic data.

IMPORTANT: The Zotero application MUST be closed during write operations 
to prevent database corruption.

CORE SCHEMAS:
1. **AttachmentInfo**: Tracks physical file paths, keys, and sync states.
2. **ParentItemInfo**: Stores the top-level bibliographic data (Title, 
   Authors, Date) used to generate new, semantic filenames.
3. **DuplicateGroup**: Aggregates attachments sharing the same content hash.
"""

using SQLite
using Dates

"""
    open_zotero_db(db_path::String) -> ZoteroDatabase

CONNECTIVITY: Opens a session with the Zotero SQLite engine and 
resolves the absolute path to the 'storage' directory.
"""
function open_zotero_db(db_path::String)::ZoteroDatabase
    # ... [Implementation]
end

"""
    find_generic_files(db::ZoteroDatabase) -> Vector{AttachmentInfo}

AUDIT: Scans the `itemAttachments` table for files with non-semantic 
names (e.g. "image.png" or "download.pdf").
"""
function find_generic_files(db::ZoteroDatabase, storage_path::String)
    # ... [SQL query implementation]
end

"""
    store_extracted_metadata(db::ZoteroDatabase, item_id::Int, metadata::Dict)

PERSISTENCE: Writes recovered metadata (Platform, Post ID, GPS) into 
the Zotero 'extra' field. Appends to existing content to prevent data loss.
"""
function store_extracted_metadata(db::ZoteroDatabase, item_id::Int, metadata::Dict{String,Any})
    # ... [Bitemporal update logic for itemData/itemDataValues]
end

export open_zotero_db, find_generic_files, update_attachment_filename

end # module
