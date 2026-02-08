# SPDX-License-Identifier: AGPL-3.0-or-later
"""
Zotero Local API Sync Bridge

Syncs data from Zotero's local API (port 23119) to FormDB journal.
This allows FormDB to mirror Zotero while Zotero continues normal sync.

Architecture:
    Zotero App ──▶ Local API :23119 ──▶ Sync Bridge ──▶ FormDB Journal

The sync bridge:
1. Connects to Zotero's local HTTP server (must be running)
2. Fetches all items, collections, attachments, notes
3. Compares with existing FormDB journal entries
4. Appends new/modified entries with provenance tracking
"""
module ZoteroSync

using HTTP
using JSON3
using Dates
using SHA
using UUIDs

export sync_from_zotero, SyncConfig, SyncResult

const ZOTERO_LOCAL_API = "http://localhost:23119/api"

Base.@kwdef struct SyncConfig
    journal_dir::String
    zotero_api::String = ZOTERO_LOCAL_API
    actor_id::String = "zotero-sync-bridge"
    dry_run::Bool = false
    verbose::Bool = false
end

Base.@kwdef mutable struct SyncResult
    items_added::Int = 0
    items_updated::Int = 0
    collections_added::Int = 0
    collections_updated::Int = 0
    attachments_synced::Int = 0
    notes_synced::Int = 0
    errors::Vector{String} = String[]
    last_version::Int = 0
end

# Load existing journal index for diffing
struct JournalState
    items::Dict{String, Dict{String, Any}}      # key -> item data
    collections::Dict{String, Dict{String, Any}}
    item_versions::Dict{String, String}          # key -> dateModified for change detection
    last_sequence::Int
end

function load_journal_state(journal_dir::String)::JournalState
    journal_path = joinpath(journal_dir, "journal.jsonl")

    items = Dict{String, Dict{String, Any}}()
    collections = Dict{String, Dict{String, Any}}()
    item_versions = Dict{String, String}()
    last_sequence = 0

    if !isfile(journal_path)
        return JournalState(items, collections, item_versions, last_sequence)
    end

    open(journal_path, "r") do io
        for line in eachline(io)
            isempty(strip(line)) && continue

            try
                entry = JSON3.read(line, Dict{String, Any})
                seq = get(entry, "sequence", 0)
                last_sequence = max(last_sequence, seq)

                # Parse based on format (migration vs API format)
                local entry_type::String
                local data::Dict{String, Any}

                if haskey(entry, "collection")
                    # Migration format
                    collection = get(entry, "collection", "")
                    payload_str = get(entry, "payload", "{}")
                    data = try
                        JSON3.read(payload_str, Dict{String, Any})
                    catch
                        Dict{String, Any}()
                    end
                    entry_type = collection == "collections" ? "collection" :
                                collection == "items" ? "item" :
                                collection == "attachments" ? "attachment" :
                                collection == "notes" ? "note" : collection
                else
                    # API format
                    entry_type = get(entry, "type", "")
                    data = get(entry, "data", Dict{String, Any}())
                end

                key = get(data, "key", "")
                if !isempty(key)
                    if entry_type == "collection"
                        collections[key] = data
                    elseif entry_type in ["item", "attachment", "note"]
                        items[key] = data
                        item_versions[key] = get(data, "dateModified", "")
                    end
                end
            catch e
                # Skip malformed entries
            end
        end
    end

    return JournalState(items, collections, item_versions, last_sequence)
end

# Fetch from Zotero local API
function fetch_zotero_items(config::SyncConfig)::Vector{Dict{String, Any}}
    items = Vector{Dict{String, Any}}()
    start = 0
    limit = 100

    while true
        url = "$(config.zotero_api)/users/0/items?start=$start&limit=$limit"

        try
            response = HTTP.get(url; status_exception=false)

            if response.status != 200
                if response.status == 404
                    # No more items
                    break
                end
                throw(HTTP.StatusError(response.status, "GET", url, response))
            end

            batch = JSON3.read(String(response.body), Vector{Dict{String, Any}})

            if isempty(batch)
                break
            end

            append!(items, batch)

            # Check if we got fewer than limit (last page)
            if length(batch) < limit
                break
            end

            start += limit

            config.verbose && println("  Fetched $(length(items)) items...")

        catch e
            if e isa HTTP.ConnectError
                throw(ErrorException("Cannot connect to Zotero. Is Zotero running?"))
            end
            rethrow(e)
        end
    end

    return items
end

function fetch_zotero_collections(config::SyncConfig)::Vector{Dict{String, Any}}
    url = "$(config.zotero_api)/users/0/collections"

    try
        response = HTTP.get(url; status_exception=false)

        if response.status != 200
            return Vector{Dict{String, Any}}()
        end

        return JSON3.read(String(response.body), Vector{Dict{String, Any}})
    catch e
        if e isa HTTP.ConnectError
            throw(ErrorException("Cannot connect to Zotero. Is Zotero running?"))
        end
        rethrow(e)
    end
end

# Append entry to journal with hash chain
function append_journal_entry!(
    journal_path::String,
    entry_type::String,
    data::Dict{String, Any},
    config::SyncConfig,
    state::JournalState,
    result::SyncResult
)
    result.last_version += 1
    seq = state.last_sequence + result.last_version

    journal_entry = Dict{String, Any}(
        "sequence" => seq,
        "timestamp" => Dates.format(now(UTC), "yyyy-mm-ddTHH:MM:SSZ"),
        "type" => entry_type,
        "data" => data,
        "provenance" => Dict(
            "actor" => config.actor_id,
            "rationale" => "Synced from Zotero local API",
            "source" => "zotero-local-api",
            "sync_time" => Dates.format(now(UTC), "yyyy-mm-ddTHH:MM:SSZ")
        )
    )

    # Compute hash chain
    prev_hash = ""
    if isfile(journal_path)
        lines = readlines(journal_path)
        if !isempty(lines)
            last_entry = try
                JSON3.read(lines[end], Dict{String, Any})
            catch
                Dict{String, Any}()
            end
            prev_hash = get(last_entry, "hash", "")
        end
    end

    content_hash = bytes2hex(sha256(JSON3.write(journal_entry)))
    journal_entry["prev_hash"] = prev_hash
    journal_entry["hash"] = bytes2hex(sha256(prev_hash * content_hash))

    if !config.dry_run
        open(journal_path, "a") do io
            println(io, JSON3.write(journal_entry))
        end
    end

    return seq
end

# Check if item has changed
function item_changed(zotero_item::Dict{String, Any}, state::JournalState)::Bool
    data = get(zotero_item, "data", zotero_item)
    key = get(data, "key", "")

    if isempty(key)
        return false
    end

    # New item
    if !haskey(state.items, key)
        return true
    end

    # Check dateModified
    new_modified = get(data, "dateModified", "")
    old_modified = get(state.item_versions, key, "")

    return new_modified != old_modified
end

function collection_changed(zotero_coll::Dict{String, Any}, state::JournalState)::Bool
    data = get(zotero_coll, "data", zotero_coll)
    key = get(data, "key", "")

    if isempty(key)
        return false
    end

    # New collection
    if !haskey(state.collections, key)
        return true
    end

    # Check if name or parent changed
    old = state.collections[key]
    return get(data, "name", "") != get(old, "name", "") ||
           get(data, "parentCollection", nothing) != get(old, "parentCollection", nothing)
end

"""
Sync from Zotero's local API to FormDB journal.

Requires Zotero to be running (local API on port 23119).
"""
function sync_from_zotero(config::SyncConfig)::SyncResult
    result = SyncResult()

    println("╔══════════════════════════════════════════════════════════════╗")
    println("║              Zotero → FormDB Sync Bridge                     ║")
    println("╚══════════════════════════════════════════════════════════════╝")
    println()

    if config.dry_run
        println("🔍 DRY RUN - no changes will be written")
        println()
    end

    # Check Zotero is running
    println("Connecting to Zotero local API...")
    try
        response = HTTP.get("$(config.zotero_api)/users/0/items?limit=1";
                           status_exception=false, connect_timeout=5)
        if response.status == 0
            throw(ErrorException("Connection failed"))
        end
        println("  ✓ Connected to $(config.zotero_api)")
    catch e
        println("  ✗ Cannot connect to Zotero local API")
        println()
        println("Make sure Zotero is running. The local API should be available at:")
        println("  $(config.zotero_api)")
        println()
        push!(result.errors, "Cannot connect to Zotero: $e")
        return result
    end

    # Load existing journal state
    println()
    println("Loading existing FormDB journal...")
    state = load_journal_state(config.journal_dir)
    println("  Existing items: $(length(state.items))")
    println("  Existing collections: $(length(state.collections))")
    println("  Last sequence: $(state.last_sequence)")

    journal_path = joinpath(config.journal_dir, "journal.jsonl")

    # Ensure output directory exists
    if !config.dry_run
        mkpath(config.journal_dir)
    end

    # Fetch and sync collections
    println()
    println("Fetching collections from Zotero...")
    collections = fetch_zotero_collections(config)
    println("  Found $(length(collections)) collections")

    for coll in collections
        data = get(coll, "data", coll)
        key = get(data, "key", "")

        if collection_changed(coll, state)
            is_new = !haskey(state.collections, key)

            if config.verbose
                action = is_new ? "Adding" : "Updating"
                name = get(data, "name", "Untitled")
                println("    $action collection: $name ($key)")
            end

            append_journal_entry!(journal_path, "collection", data, config, state, result)

            if is_new
                result.collections_added += 1
            else
                result.collections_updated += 1
            end
        end
    end

    # Fetch and sync items
    println()
    println("Fetching items from Zotero...")
    items = fetch_zotero_items(config)
    println("  Found $(length(items)) items")

    for item in items
        data = get(item, "data", item)
        key = get(data, "key", "")
        item_type = get(data, "itemType", "unknown")

        if item_changed(item, state)
            is_new = !haskey(state.items, key)

            # Determine entry type
            entry_type = if item_type == "attachment"
                result.attachments_synced += 1
                "attachment"
            elseif item_type == "note"
                result.notes_synced += 1
                "note"
            else
                if is_new
                    result.items_added += 1
                else
                    result.items_updated += 1
                end
                "item"
            end

            if config.verbose
                action = is_new ? "Adding" : "Updating"
                title = get(data, "title", get(data, "note", "Untitled"))
                if length(title) > 50
                    title = title[1:47] * "..."
                end
                println("    $action $item_type: $title")
            end

            append_journal_entry!(journal_path, entry_type, data, config, state, result)
        end
    end

    # Summary
    println()
    println("════════════════════════════════════════════════════════════════")
    println("  Sync Summary")
    println("════════════════════════════════════════════════════════════════")
    println("  Collections: $(result.collections_added) added, $(result.collections_updated) updated")
    println("  Items: $(result.items_added) added, $(result.items_updated) updated")
    println("  Attachments synced: $(result.attachments_synced)")
    println("  Notes synced: $(result.notes_synced)")
    println("  Total changes: $(result.last_version)")
    println()

    if config.dry_run
        println("DRY RUN complete - no changes written")
    else
        println("Sync complete!")
        println("Journal: $journal_path")
    end

    return result
end

end # module
