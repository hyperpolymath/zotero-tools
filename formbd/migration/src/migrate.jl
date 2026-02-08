# SPDX-License-Identifier: AGPL-3.0-or-later
"""
Zotero SQLite to FormDB Migration Tool

Converts a Zotero SQLite database to FormDB's append-only journal format.
All migrated items get default provenance: "Migrated from Zotero SQLite"
"""

module ZoteroMigration

using SQLite
using DBInterface
using Tables
using JSON3
using Dates
using SHA
using UUIDs

export migrate_database, MigrationConfig, MigrationResult

# ============================================================================
# Configuration
# ============================================================================

"""
Migration configuration
"""
Base.@kwdef struct MigrationConfig
    sqlite_path::String
    output_dir::String
    actor_id::String = "zotero-formdb-migration"
    rationale::String = "Migrated from Zotero SQLite database"
    dry_run::Bool = true
    verbose::Bool = false
end

"""
Result of migration
"""
mutable struct MigrationResult
    items_migrated::Int
    attachments_migrated::Int
    notes_migrated::Int
    collections_migrated::Int
    errors::Vector{String}
    journal_entries::Int
end

MigrationResult() = MigrationResult(0, 0, 0, 0, String[], 0)

# ============================================================================
# Journal Entry Structure
# ============================================================================

"""
A single journal entry (matches Lean 4 JournalEntry)
"""
struct JournalEntry
    sequence::Int
    timestamp::Int64  # Unix millis
    op_type::String
    collection::String
    item_key::String
    actor::String
    rationale::String
    payload::String
    prev_hash::Union{String, Nothing}
end

function to_dict(entry::JournalEntry)
    Dict(
        "sequence" => entry.sequence,
        "timestamp" => entry.timestamp,
        "op_type" => entry.op_type,
        "collection" => entry.collection,
        "item_key" => entry.item_key,
        "actor" => entry.actor,
        "rationale" => entry.rationale,
        "payload" => entry.payload,
        "prev_hash" => entry.prev_hash
    )
end

"""
Compute BLAKE3-like hash (using SHA-256 as fallback)
"""
function compute_hash(data::String)::String
    bytes2hex(sha256(data))
end

# ============================================================================
# SQLite Reading
# ============================================================================

"""
Open Zotero database
"""
function open_zotero_db(path::String)
    if !isfile(path)
        error("Database not found: $path")
    end
    SQLite.DB(path)
end

"""
Get all item types from Zotero
"""
function get_item_types(db::SQLite.DB)
    query = """
        SELECT itemTypeID, typeName
        FROM itemTypes
    """
    result = DBInterface.execute(db, query) |> Tables.columntable
    Dict(zip(result.itemTypeID, result.typeName))
end

"""
Get all field names from Zotero
"""
function get_field_names(db::SQLite.DB)
    query = """
        SELECT fieldID, fieldName
        FROM fields
    """
    result = DBInterface.execute(db, query) |> Tables.columntable
    Dict(zip(result.fieldID, result.fieldName))
end

"""
Fetch all items with their metadata
"""
function fetch_items(db::SQLite.DB, item_types::Dict, field_names::Dict)
    # Get base items
    query = """
        SELECT i.itemID, i.key, i.dateAdded, i.dateModified,
               i.itemTypeID, i.libraryID, i.version
        FROM items i
        WHERE i.itemTypeID NOT IN (3, 28)  -- Not attachment or note
    """

    items = Dict{Int, Dict{String, Any}}()

    for row in DBInterface.execute(db, query)
        item_id = row.itemID
        items[item_id] = Dict(
            "key" => row.key,
            "dateAdded" => row.dateAdded,
            "dateModified" => row.dateModified,
            "itemType" => get(item_types, row.itemTypeID, "unknown"),
            "version" => row.version,
            "fields" => Dict{String, Any}(),
            "creators" => []
        )
    end

    # Get field values for each item
    field_query = """
        SELECT itemID, fieldID, value
        FROM itemDataValues idv
        JOIN itemData id ON id.valueID = idv.valueID
    """

    for row in DBInterface.execute(db, field_query)
        if haskey(items, row.itemID)
            field_name = get(field_names, row.fieldID, "field_$(row.fieldID)")
            items[row.itemID]["fields"][field_name] = row.value
        end
    end

    # Get creators
    creator_query = """
        SELECT ic.itemID, c.firstName, c.lastName, ct.creatorType, ic.orderIndex
        FROM itemCreators ic
        JOIN creators c ON ic.creatorID = c.creatorID
        JOIN creatorTypes ct ON ic.creatorTypeID = ct.creatorTypeID
        ORDER BY ic.itemID, ic.orderIndex
    """

    for row in DBInterface.execute(db, creator_query)
        if haskey(items, row.itemID)
            push!(items[row.itemID]["creators"], Dict(
                "firstName" => ismissing(row.firstName) ? nothing : row.firstName,
                "lastName" => row.lastName,
                "creatorType" => row.creatorType
            ))
        end
    end

    return items
end

"""
Fetch all attachments
"""
function fetch_attachments(db::SQLite.DB)
    query = """
        SELECT i.itemID, i.key, i.dateAdded, i.dateModified,
               ia.parentItemID, ia.contentType, ia.path
        FROM items i
        JOIN itemAttachments ia ON i.itemID = ia.itemID
        WHERE i.itemTypeID = 3  -- Attachment type
    """

    attachments = Dict{Int, Dict{String, Any}}()

    for row in DBInterface.execute(db, query)
        attachments[row.itemID] = Dict(
            "key" => row.key,
            "dateAdded" => row.dateAdded,
            "dateModified" => row.dateModified,
            "parentItemID" => ismissing(row.parentItemID) ? nothing : row.parentItemID,
            "contentType" => ismissing(row.contentType) ? "application/octet-stream" : row.contentType,
            "path" => ismissing(row.path) ? nothing : row.path
        )
    end

    # Get titles
    title_query = """
        SELECT itemID, value
        FROM itemDataValues idv
        JOIN itemData id ON id.valueID = idv.valueID
        WHERE id.fieldID = 110  -- title field
    """

    for row in DBInterface.execute(db, title_query)
        if haskey(attachments, row.itemID)
            attachments[row.itemID]["title"] = row.value
        end
    end

    return attachments
end

"""
Fetch all notes
"""
function fetch_notes(db::SQLite.DB)
    query = """
        SELECT i.itemID, i.key, i.dateAdded, i.dateModified,
               n.parentItemID, n.note
        FROM items i
        JOIN itemNotes n ON i.itemID = n.itemID
        WHERE i.itemTypeID = 28  -- Note type
    """

    notes = Dict{Int, Dict{String, Any}}()

    for row in DBInterface.execute(db, query)
        notes[row.itemID] = Dict(
            "key" => row.key,
            "dateAdded" => row.dateAdded,
            "dateModified" => row.dateModified,
            "parentItemID" => ismissing(row.parentItemID) ? nothing : row.parentItemID,
            "content" => ismissing(row.note) ? "" : row.note
        )
    end

    return notes
end

"""
Fetch all collections
"""
function fetch_collections(db::SQLite.DB)
    query = """
        SELECT collectionID, collectionName, parentCollectionID, key
        FROM collections
    """

    collections = Dict{Int, Dict{String, Any}}()

    for row in DBInterface.execute(db, query)
        collections[row.collectionID] = Dict(
            "key" => row.key,
            "name" => row.collectionName,
            "parentCollectionID" => ismissing(row.parentCollectionID) ? nothing : row.parentCollectionID
        )
    end

    return collections
end

"""
Fetch collection-item mappings
"""
function fetch_collection_items(db::SQLite.DB)
    query = """
        SELECT collectionID, itemID
        FROM collectionItems
    """

    mappings = Dict{Int, Vector{Int}}()

    for row in DBInterface.execute(db, query)
        if !haskey(mappings, row.itemID)
            mappings[row.itemID] = Int[]
        end
        push!(mappings[row.itemID], row.collectionID)
    end

    return mappings
end

"""
Fetch tags for items
"""
function fetch_tags(db::SQLite.DB)
    query = """
        SELECT it.itemID, t.name
        FROM itemTags it
        JOIN tags t ON it.tagID = t.tagID
    """

    tags = Dict{Int, Vector{String}}()

    for row in DBInterface.execute(db, query)
        if !haskey(tags, row.itemID)
            tags[row.itemID] = String[]
        end
        push!(tags[row.itemID], row.name)
    end

    return tags
end

# ============================================================================
# Journal Writing
# ============================================================================

"""
Create journal entry for an item
"""
function create_item_entry(
    item::Dict{String, Any},
    item_key::String,
    sequence::Int,
    prev_hash::Union{String, Nothing},
    config::MigrationConfig,
    item_tags::Vector{String},
    collection_keys::Vector{String}
)::JournalEntry
    # Build payload with provenance
    payload = Dict(
        "key" => item_key,
        "itemType" => item["itemType"],
        "dateAdded" => item["dateAdded"],
        "dateModified" => item["dateModified"],
        "version" => item["version"],
        "fields" => item["fields"],
        "creators" => item["creators"],
        "tags" => item_tags,
        "collections" => collection_keys,
        # Provenance (required by FormDB types)
        "added_by" => config.actor_id,
        "rationale" => config.rationale,
        "migrated_at" => Dates.format(now(), "yyyy-mm-ddTHH:MM:SS")
    )

    JournalEntry(
        sequence,
        round(Int64, datetime2unix(now()) * 1000),
        "insert",
        "items",
        item_key,
        config.actor_id,
        config.rationale,
        JSON3.write(payload),
        prev_hash
    )
end

"""
Create journal entry for an attachment
"""
function create_attachment_entry(
    attachment::Dict{String, Any},
    parent_key::Union{String, Nothing},
    sequence::Int,
    prev_hash::Union{String, Nothing},
    config::MigrationConfig
)::JournalEntry
    payload = Dict(
        "key" => attachment["key"],
        "parentItem" => parent_key,
        "title" => get(attachment, "title", "Untitled"),
        "contentType" => attachment["contentType"],
        "path" => attachment["path"],
        "dateAdded" => attachment["dateAdded"],
        # Provenance
        "added_by" => config.actor_id,
        "rationale" => config.rationale,
        "migrated_at" => Dates.format(now(), "yyyy-mm-ddTHH:MM:SS")
    )

    JournalEntry(
        sequence,
        round(Int64, datetime2unix(now()) * 1000),
        "insert",
        "attachments",
        attachment["key"],
        config.actor_id,
        config.rationale,
        JSON3.write(payload),
        prev_hash
    )
end

"""
Create journal entry for a note
"""
function create_note_entry(
    note::Dict{String, Any},
    parent_key::Union{String, Nothing},
    sequence::Int,
    prev_hash::Union{String, Nothing},
    config::MigrationConfig
)::JournalEntry
    payload = Dict(
        "key" => note["key"],
        "parentItem" => parent_key,
        "content" => note["content"],
        "dateAdded" => note["dateAdded"],
        # Provenance
        "added_by" => config.actor_id,
        "rationale" => config.rationale,
        "migrated_at" => Dates.format(now(), "yyyy-mm-ddTHH:MM:SS")
    )

    JournalEntry(
        sequence,
        round(Int64, datetime2unix(now()) * 1000),
        "insert",
        "notes",
        note["key"],
        config.actor_id,
        config.rationale,
        JSON3.write(payload),
        prev_hash
    )
end

"""
Create journal entry for a collection
"""
function create_collection_entry(
    collection::Dict{String, Any},
    parent_key::Union{String, Nothing},
    sequence::Int,
    prev_hash::Union{String, Nothing},
    config::MigrationConfig
)::JournalEntry
    payload = Dict(
        "key" => collection["key"],
        "name" => collection["name"],
        "parentCollection" => parent_key,
        # Provenance
        "added_by" => config.actor_id,
        "rationale" => config.rationale,
        "migrated_at" => Dates.format(now(), "yyyy-mm-ddTHH:MM:SS")
    )

    JournalEntry(
        sequence,
        round(Int64, datetime2unix(now()) * 1000),
        "insert",
        "collections",
        collection["key"],
        config.actor_id,
        config.rationale,
        JSON3.write(payload),
        prev_hash
    )
end

"""
Write journal to disk
"""
function write_journal(entries::Vector{JournalEntry}, output_dir::String)
    journal_path = joinpath(output_dir, "journal.jsonl")

    open(journal_path, "w") do io
        for entry in entries
            println(io, JSON3.write(to_dict(entry)))
        end
    end

    # Write index for fast lookups
    index_path = joinpath(output_dir, "index.json")
    index = Dict{String, Dict{String, Int}}()

    for entry in entries
        if !haskey(index, entry.collection)
            index[entry.collection] = Dict{String, Int}()
        end
        index[entry.collection][entry.item_key] = entry.sequence
    end

    open(index_path, "w") do io
        JSON3.pretty(io, index)
    end

    return journal_path
end

# ============================================================================
# Main Migration
# ============================================================================

"""
Migrate a Zotero SQLite database to FormDB journal format
"""
function migrate_database(config::MigrationConfig)::MigrationResult
    result = MigrationResult()

    println("=" ^ 60)
    println("  Zotero → FormDB Migration")
    println("=" ^ 60)
    println()
    println("Source: $(config.sqlite_path)")
    println("Output: $(config.output_dir)")
    println("Mode: $(config.dry_run ? "DRY RUN" : "APPLY")")
    println()

    # Open database
    db = open_zotero_db(config.sqlite_path)

    # Get type/field mappings
    item_types = get_item_types(db)
    field_names = get_field_names(db)

    # Fetch all data
    println("Fetching items...")
    items = fetch_items(db, item_types, field_names)
    println("  Found $(length(items)) items")

    println("Fetching attachments...")
    attachments = fetch_attachments(db)
    println("  Found $(length(attachments)) attachments")

    println("Fetching notes...")
    notes = fetch_notes(db)
    println("  Found $(length(notes)) notes")

    println("Fetching collections...")
    collections = fetch_collections(db)
    println("  Found $(length(collections)) collections")

    println("Fetching tags and mappings...")
    tags = fetch_tags(db)
    collection_items = fetch_collection_items(db)

    # Build key lookup for parent references
    item_id_to_key = Dict{Int, String}()
    for (id, item) in items
        item_id_to_key[id] = item["key"]
    end
    for (id, att) in attachments
        item_id_to_key[id] = att["key"]
    end
    for (id, note) in notes
        item_id_to_key[id] = note["key"]
    end

    collection_id_to_key = Dict{Int, String}()
    for (id, coll) in collections
        collection_id_to_key[id] = coll["key"]
    end

    # Create journal entries
    println()
    println("Creating journal entries...")

    entries = JournalEntry[]
    sequence = 1
    prev_hash = nothing

    # Collections first (for references)
    for (id, collection) in collections
        parent_key = if !isnothing(collection["parentCollectionID"])
            get(collection_id_to_key, collection["parentCollectionID"], nothing)
        else
            nothing
        end

        entry = create_collection_entry(collection, parent_key, sequence, prev_hash, config)
        push!(entries, entry)
        prev_hash = compute_hash(JSON3.write(to_dict(entry)))
        sequence += 1
        result.collections_migrated += 1
    end

    # Items
    for (id, item) in items
        item_tags = get(tags, id, String[])
        item_collection_ids = get(collection_items, id, Int[])
        collection_keys = [get(collection_id_to_key, cid, "") for cid in item_collection_ids]
        filter!(!isempty, collection_keys)

        entry = create_item_entry(item, item["key"], sequence, prev_hash, config, item_tags, collection_keys)
        push!(entries, entry)
        prev_hash = compute_hash(JSON3.write(to_dict(entry)))
        sequence += 1
        result.items_migrated += 1

        if config.verbose && result.items_migrated % 100 == 0
            println("  Processed $(result.items_migrated) items...")
        end
    end

    # Attachments
    for (id, attachment) in attachments
        parent_key = if !isnothing(attachment["parentItemID"])
            get(item_id_to_key, attachment["parentItemID"], nothing)
        else
            nothing
        end

        entry = create_attachment_entry(attachment, parent_key, sequence, prev_hash, config)
        push!(entries, entry)
        prev_hash = compute_hash(JSON3.write(to_dict(entry)))
        sequence += 1
        result.attachments_migrated += 1
    end

    # Notes
    for (id, note) in notes
        parent_key = if !isnothing(note["parentItemID"])
            get(item_id_to_key, note["parentItemID"], nothing)
        else
            nothing
        end

        entry = create_note_entry(note, parent_key, sequence, prev_hash, config)
        push!(entries, entry)
        prev_hash = compute_hash(JSON3.write(to_dict(entry)))
        sequence += 1
        result.notes_migrated += 1
    end

    result.journal_entries = length(entries)

    # Write journal
    if !config.dry_run
        println()
        println("Writing journal...")
        mkpath(config.output_dir)
        journal_path = write_journal(entries, config.output_dir)
        println("  Written to: $journal_path")
    end

    # Summary
    println()
    println("=" ^ 60)
    println("  Migration Summary")
    println("=" ^ 60)
    println("  Collections: $(result.collections_migrated)")
    println("  Items: $(result.items_migrated)")
    println("  Attachments: $(result.attachments_migrated)")
    println("  Notes: $(result.notes_migrated)")
    println("  Journal entries: $(result.journal_entries)")
    println()

    if config.dry_run
        println("DRY RUN - no files written")
        println("Run with --apply to write the journal")
    else
        println("Migration complete!")
        println("Journal written to: $(config.output_dir)")
    end

    close(db)
    return result
end

end # module
