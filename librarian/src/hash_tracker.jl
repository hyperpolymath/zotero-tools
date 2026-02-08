# SPDX-License-Identifier: AGPL-3.0-or-later
"""
BLAKE3 hash-based rename tracking and deduplication

Provides:
- Rename history with BLAKE3 hashes for recovery
- Duplicate detection across library
- Change tracking for sync safety
"""

using Dates
using JSON3
using SHA  # Standard library - using SHA256 (BLAKE3 not registered in Julia yet)

"""
Single rename record
"""
struct RenameRecord
    timestamp::DateTime
    old_filename::String
    new_filename::String
    extracted_metadata::Dict{String,Any}
end

"""
Rename history keyed by BLAKE3 hash
"""
mutable struct RenameHistory
    by_hash::Dict{String,Vector{RenameRecord}}
    version::Int
    created::DateTime
    last_updated::DateTime
end

"""
Create empty rename history
"""
function RenameHistory()
    return RenameHistory(
        Dict{String,Vector{RenameRecord}}(),
        1,
        now(),
        now()
    )
end

"""
Load rename history from JSON file
"""
function load_history(path::String)::RenameHistory
    if !isfile(path)
        return RenameHistory()
    end

    try
        content = read(path, String)
        data = JSON3.read(content)

        history = RenameHistory()
        history.version = get(data, :version, 1)
        history.created = DateTime(get(data, :created, string(now())))
        history.last_updated = DateTime(get(data, :last_updated, string(now())))

        if haskey(data, :by_hash)
            for (hash, records) in data.by_hash
                history.by_hash[string(hash)] = [
                    RenameRecord(
                        DateTime(r.timestamp),
                        r.old_filename,
                        r.new_filename,
                        Dict{String,Any}(r.extracted_metadata)
                    )
                    for r in records
                ]
            end
        end

        return history
    catch e
        @warn "Failed to load history: $e"
        return RenameHistory()
    end
end

"""
Save rename history to JSON file
"""
function save_history(history::RenameHistory, path::String)
    history.last_updated = now()

    # Convert to serializable format
    data = Dict(
        :version => history.version,
        :created => string(history.created),
        :last_updated => string(history.last_updated),
        :by_hash => Dict(
            hash => [
                Dict(
                    :timestamp => string(r.timestamp),
                    :old_filename => r.old_filename,
                    :new_filename => r.new_filename,
                    :extracted_metadata => r.extracted_metadata
                )
                for r in records
            ]
            for (hash, records) in history.by_hash
        )
    )

    open(path, "w") do io
        JSON3.write(io, data)
    end
end

"""
Add a rename to history
"""
function add_to_history!(history::RenameHistory,
                        hash::String,
                        old_filename::String,
                        new_filename::String,
                        metadata::Dict{String,Any})
    record = RenameRecord(now(), old_filename, new_filename, metadata)

    if !haskey(history.by_hash, hash)
        history.by_hash[hash] = RenameRecord[]
    end

    push!(history.by_hash[hash], record)
end

"""
Get rename history for a file by its hash
"""
function get_file_history(history::RenameHistory, hash::String)::Vector{RenameRecord}
    return get(history.by_hash, hash, RenameRecord[])
end

"""
Get original filename from history
"""
function get_original_filename(history::RenameHistory, hash::String)::Union{String,Nothing}
    records = get_file_history(history, hash)
    if isempty(records)
        return nothing
    end
    return first(records).old_filename
end

"""
Compute BLAKE3 hash of a file

Falls back to SHA-256 if BLAKE3 is not available.
"""
function compute_blake3(filepath::String)::String
    if !isfile(filepath)
        return ""
    end

    try
        # Try BLAKE3 first (would need BLAKE3.jl package)
        # For now, use SHA-256 as fallback
        return bytes2hex(open(io -> sha256(io), filepath))
    catch e
        @warn "Hash computation failed for $filepath: $e"
        return ""
    end
end

"""
Check if a file has been renamed before (by current hash)
"""
function was_previously_renamed(history::RenameHistory, hash::String)::Bool
    return haskey(history.by_hash, hash) && !isempty(history.by_hash[hash])
end

"""
Generate deduplication report
"""
function generate_dedup_report(duplicates::Vector{DuplicateGroup})::String
    if isempty(duplicates)
        return "No duplicates found."
    end

    report = "Duplicate Files Report\n"
    report *= "=" ^ 50 * "\n\n"

    for (i, group) in enumerate(duplicates)
        report *= "Group $i ($(length(group.files)) files):\n"
        report *= "  Hash: $(first(group.hash, 16))...\n"
        for file in group.files
            report *= "  - $(file.filename) ($(file.key))\n"
        end
        report *= "\n"
    end

    report *= "Total duplicate groups: $(length(duplicates))\n"
    report *= "Total duplicate files: $(sum(g -> length(g.files), duplicates))\n"

    return report
end
