# SPDX-License-Identifier: AGPL-3.0-or-later
"""
ZoteroLibrarian - Intelligent metadata extraction and file normalization for Zotero

Extracts metadata from:
- Filenames (platforms, dates, usernames, resolutions)
- EXIF data (camera, GPS, timestamps)
- File hashes (BLAKE3 for deduplication)

Normalizes:
- Attachment filenames
- Attachment titles
- Parent item titles (when generic)

Tracks all renames with BLAKE3 hashes for recovery.
"""
module ZoteroLibrarian

using SQLite
using Dates
using JSON3
using SHA

# Include submodules
include("patterns.jl")
include("exif.jl")
include("zotero_db.jl")
include("hash_tracker.jl")
include("zotero_api.jl")

export normalize_library,
       extract_metadata,
       find_generic_files,
       find_duplicates,
       RenameHistory,
       ZoteroDB,
       # API exports
       ZoteroAPIClient,
       process_attachments_api,
       verify_api_key

"""
    normalize_library(db_path::String; dry_run::Bool=true)

Main entry point for normalizing a Zotero library.
- Extracts metadata from filenames and EXIF
- Renames generic files based on parent item metadata
- Tracks all changes with BLAKE3 hashes
- Stores extracted metadata in Zotero fields

Returns a detailed report of changes.
"""
function normalize_library(db_path::String;
                          dry_run::Bool=true,
                          storage_path::String="",
                          history_path::String="")
    # Determine storage path if not provided
    if isempty(storage_path)
        storage_path = joinpath(dirname(db_path), "storage")
    end

    if isempty(history_path)
        history_path = joinpath(dirname(db_path), "rename-history.json")
    end

    println("ZoteroLibrarian v0.1.0")
    println("=" ^ 50)
    println("Database: $db_path")
    println("Storage: $storage_path")
    println("Dry run: $dry_run")
    println()

    # Load or create rename history
    history = load_history(history_path)

    # Open database
    db = open_zotero_db(db_path)

    # Find all attachments with generic filenames
    attachments = find_generic_files(db, storage_path)
    println("Found $(length(attachments)) files with generic/extractable names")

    # Find duplicates by hash
    duplicates = find_duplicates(attachments)
    if !isempty(duplicates)
        println("Found $(length(duplicates)) duplicate file groups")
    end

    # Process each attachment
    results = ProcessingResult[]

    for att in attachments
        result = process_attachment(db, att, history, dry_run)
        push!(results, result)
    end

    # Generate report
    report = generate_report(results, duplicates, dry_run)

    # Save history if not dry run
    if !dry_run
        save_history(history, history_path)
    end

    close(db.conn)

    return report
end

"""
Processing result for a single attachment
"""
struct ProcessingResult
    item_id::Int
    old_filename::String
    new_filename::String
    extracted_metadata::Dict{String,Any}
    blake3_hash::String
    status::Symbol  # :renamed, :skipped, :duplicate, :error
    message::String
end

"""
Process a single attachment - extract metadata, rename, update DB
"""
function process_attachment(db::ZoteroDatabase,
                           att::AttachmentInfo,
                           history::RenameHistory,
                           dry_run::Bool)
    try
        # Extract metadata from filename
        file_meta = extract_from_filename(att.filename)

        # Extract EXIF if file exists
        exif_meta = Dict{String,Any}()
        if isfile(att.full_path)
            exif_meta = extract_exif(att.full_path)
        end

        # Compute BLAKE3 hash
        file_hash = ""
        if isfile(att.full_path)
            file_hash = compute_blake3(att.full_path)
        end

        # Check if already in history (already processed)
        if haskey(history.by_hash, file_hash)
            return ProcessingResult(
                att.item_id,
                att.filename,
                att.filename,
                merge(file_meta, exif_meta),
                file_hash,
                :skipped,
                "Already processed (hash in history)"
            )
        end

        # Get parent item info
        parent_info = get_parent_item(db, att.parent_item_id)

        # Generate new filename
        new_filename = generate_filename(att, parent_info, file_meta, exif_meta)

        if new_filename == att.filename
            return ProcessingResult(
                att.item_id,
                att.filename,
                new_filename,
                merge(file_meta, exif_meta),
                file_hash,
                :skipped,
                "Filename already good"
            )
        end

        # Perform rename and DB update if not dry run
        if !dry_run
            # Rename physical file
            if isfile(att.full_path)
                new_path = joinpath(dirname(att.full_path), new_filename)
                mv(att.full_path, new_path)
            end

            # Update database
            update_attachment_filename(db, att.item_id, new_filename)
            update_attachment_title(db, att.item_id, new_filename)

            # Store extracted metadata in extra field
            store_extracted_metadata(db, att.item_id, merge(file_meta, exif_meta))

            # Record in history
            add_to_history!(history, file_hash, att.filename, new_filename, file_meta)
        end

        return ProcessingResult(
            att.item_id,
            att.filename,
            new_filename,
            merge(file_meta, exif_meta),
            file_hash,
            :renamed,
            "OK"
        )

    catch e
        return ProcessingResult(
            att.item_id,
            att.filename,
            "",
            Dict{String,Any}(),
            "",
            :error,
            string(e)
        )
    end
end

"""
Generate report from processing results
"""
function generate_report(results::Vector{ProcessingResult},
                        duplicates::Vector{DuplicateGroup},
                        dry_run::Bool)
    renamed = count(r -> r.status == :renamed, results)
    skipped = count(r -> r.status == :skipped, results)
    errors = count(r -> r.status == :error, results)

    report = """
    ================================================
    ZoteroLibrarian Normalization Report
    $(dry_run ? "(DRY RUN - no changes made)" : "(CHANGES APPLIED)")
    ================================================

    Summary:
    - Total processed: $(length(results))
    - Renamed: $renamed
    - Skipped: $skipped
    - Errors: $errors
    - Duplicate groups: $(length(duplicates))

    """

    if renamed > 0
        report *= "\nRenames:\n"
        for r in filter(r -> r.status == :renamed, results)[1:min(50, renamed)]
            report *= "  $(r.old_filename)\n    → $(r.new_filename)\n"
            if !isempty(r.extracted_metadata)
                for (k, v) in r.extracted_metadata
                    report *= "      [$k: $v]\n"
                end
            end
        end
        if renamed > 50
            report *= "  ... and $(renamed - 50) more\n"
        end
    end

    if errors > 0
        report *= "\nErrors:\n"
        for r in filter(r -> r.status == :error, results)
            report *= "  $(r.old_filename): $(r.message)\n"
        end
    end

    return report
end

end # module
