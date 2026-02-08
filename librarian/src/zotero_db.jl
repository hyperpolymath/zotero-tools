# SPDX-License-Identifier: AGPL-3.0-or-later
"""
Zotero SQLite database operations

Handles reading and writing to Zotero's database structure.
IMPORTANT: Zotero must be closed when modifying the database.
"""

using SQLite
using Dates

"""
Wrapper for Zotero database connection
"""
struct ZoteroDatabase
    conn::SQLite.DB
    storage_path::String
end

"""
Represents a Zotero attachment
"""
struct AttachmentInfo
    item_id::Int
    key::String
    parent_item_id::Union{Int,Nothing}
    filename::String
    full_path::String
    content_type::String
    link_mode::Int
    sync_state::Int
end

"""
Represents a parent item (article, webpage, etc.)
"""
struct ParentItemInfo
    item_id::Int
    key::String
    item_type::String
    title::String
    creators::Vector{NamedTuple{(:firstName, :lastName, :creatorType),Tuple{String,String,String}}}
    date::Union{String,Nothing}
    url::Union{String,Nothing}
    extra::Union{String,Nothing}
end

"""
Duplicate file group
"""
struct DuplicateGroup
    hash::String
    files::Vector{AttachmentInfo}
end

"""
Open Zotero database
"""
function open_zotero_db(db_path::String)::ZoteroDatabase
    if !isfile(db_path)
        error("Database not found: $db_path")
    end

    conn = SQLite.DB(db_path)
    storage_path = joinpath(dirname(db_path), "storage")

    return ZoteroDatabase(conn, storage_path)
end

"""
Find all attachments with generic or extractable filenames
"""
function find_generic_files(db::ZoteroDatabase, storage_path::String)::Vector{AttachmentInfo}
    results = AttachmentInfo[]

    query = """
    SELECT
        ia.itemID,
        i.key,
        ia.parentItemID,
        ia.path,
        ia.contentType,
        ia.linkMode,
        ia.syncState
    FROM itemAttachments ia
    JOIN items i ON ia.itemID = i.itemID
    WHERE ia.path IS NOT NULL
      AND ia.linkMode IN (0, 1)  -- Imported file or linked file
      AND (ia.contentType LIKE 'image/%'
           OR ia.contentType LIKE 'application/pdf'
           OR ia.contentType LIKE 'video/%')
    ORDER BY ia.itemID
    """

    for row in SQLite.DBInterface.execute(db.conn, query)
        path_str = row.path
        if isnothing(path_str) || isempty(path_str)
            continue
        end

        # Parse path - format is "storage:filename" for imported files
        filename = if startswith(path_str, "storage:")
            replace(path_str, "storage:" => "")
        else
            basename(path_str)
        end

        # Build full path
        full_path = joinpath(storage_path, row.key, filename)

        # Check if file needs processing
        if !is_well_named(filename)
            # Handle NULL parentItemID (Missing in Julia)
            parent_id = if ismissing(row.parentItemID)
                nothing
            else
                Int(row.parentItemID)
            end

            push!(results, AttachmentInfo(
                row.itemID,
                row.key,
                parent_id,
                filename,
                full_path,
                something(row.contentType, ""),
                row.linkMode,
                row.syncState
            ))
        end
    end

    return results
end

"""
Get parent item information
"""
function get_parent_item(db::ZoteroDatabase, parent_id::Union{Int,Nothing})::Union{ParentItemInfo,Nothing}
    if isnothing(parent_id)
        return nothing
    end

    # Get basic item info
    query = """
    SELECT
        i.itemID,
        i.key,
        it.typeName
    FROM items i
    JOIN itemTypes it ON i.itemTypeID = it.itemTypeID
    WHERE i.itemID = ?
    """

    result = SQLite.DBInterface.execute(db.conn, query, [parent_id]) |> collect

    if isempty(result)
        return nothing
    end

    row = first(result)

    # Get title
    title_query = """
    SELECT idv.value
    FROM itemData id
    JOIN itemDataValues idv ON id.valueID = idv.valueID
    JOIN fields f ON id.fieldID = f.fieldID
    WHERE id.itemID = ? AND f.fieldName = 'title'
    """
    title_result = SQLite.DBInterface.execute(db.conn, title_query, [parent_id]) |> collect
    title = if isempty(title_result)
        ""
    else
        val = first(title_result).value
        ismissing(val) ? "" : string(val)
    end

    # Get date
    date_query = """
    SELECT idv.value
    FROM itemData id
    JOIN itemDataValues idv ON id.valueID = idv.valueID
    JOIN fields f ON id.fieldID = f.fieldID
    WHERE id.itemID = ? AND f.fieldName = 'date'
    """
    date_result = SQLite.DBInterface.execute(db.conn, date_query, [parent_id]) |> collect
    date = if isempty(date_result)
        nothing
    else
        val = first(date_result).value
        ismissing(val) ? nothing : string(val)
    end

    # Get URL
    url_query = """
    SELECT idv.value
    FROM itemData id
    JOIN itemDataValues idv ON id.valueID = idv.valueID
    JOIN fields f ON id.fieldID = f.fieldID
    WHERE id.itemID = ? AND f.fieldName = 'url'
    """
    url_result = SQLite.DBInterface.execute(db.conn, url_query, [parent_id]) |> collect
    url = if isempty(url_result)
        nothing
    else
        val = first(url_result).value
        ismissing(val) ? nothing : string(val)
    end

    # Get extra field
    extra_query = """
    SELECT idv.value
    FROM itemData id
    JOIN itemDataValues idv ON id.valueID = idv.valueID
    JOIN fields f ON id.fieldID = f.fieldID
    WHERE id.itemID = ? AND f.fieldName = 'extra'
    """
    extra_result = SQLite.DBInterface.execute(db.conn, extra_query, [parent_id]) |> collect
    extra = if isempty(extra_result)
        nothing
    else
        val = first(extra_result).value
        ismissing(val) ? nothing : string(val)
    end

    # Get creators
    creators_query = """
    SELECT c.firstName, c.lastName, ct.creatorType
    FROM itemCreators ic
    JOIN creators c ON ic.creatorID = c.creatorID
    JOIN creatorTypes ct ON ic.creatorTypeID = ct.creatorTypeID
    WHERE ic.itemID = ?
    ORDER BY ic.orderIndex
    """
    creators = [
        (
            firstName = ismissing(r.firstName) ? "" : string(r.firstName),
            lastName = ismissing(r.lastName) ? "" : string(r.lastName),
            creatorType = ismissing(r.creatorType) ? "" : string(r.creatorType)
        )
        for r in SQLite.DBInterface.execute(db.conn, creators_query, [parent_id])
    ]

    # Handle potential missing values in row
    item_id = ismissing(row.itemID) ? 0 : Int(row.itemID)
    key = ismissing(row.key) ? "" : string(row.key)
    type_name = ismissing(row.typeName) ? "" : string(row.typeName)

    return ParentItemInfo(
        item_id,
        key,
        type_name,
        title,
        creators,
        date,
        url,
        extra
    )
end

"""
Update attachment filename in database
"""
function update_attachment_filename(db::ZoteroDatabase, item_id::Int, new_filename::String)
    query = """
    UPDATE itemAttachments
    SET path = 'storage:' || ?
    WHERE itemID = ?
    """
    SQLite.DBInterface.execute(db.conn, query, [new_filename, item_id])
end

"""
Update attachment title in database (the display name)
"""
function update_attachment_title(db::ZoteroDatabase, item_id::Int, new_title::String)
    # First check if title field exists for this item
    check_query = """
    SELECT id.valueID
    FROM itemData id
    JOIN fields f ON id.fieldID = f.fieldID
    WHERE id.itemID = ? AND f.fieldName = 'title'
    """
    result = SQLite.DBInterface.execute(db.conn, check_query, [item_id]) |> collect

    # Get or create value in itemDataValues
    value_check = """
    SELECT valueID FROM itemDataValues WHERE value = ?
    """
    value_result = SQLite.DBInterface.execute(db.conn, value_check, [new_title]) |> collect

    value_id = if isempty(value_result)
        # Insert new value
        SQLite.DBInterface.execute(db.conn,
            "INSERT INTO itemDataValues (value) VALUES (?)",
            [new_title])
        # Get the new ID
        last_id = SQLite.DBInterface.execute(db.conn,
            "SELECT last_insert_rowid() as id") |> collect
        first(last_id).id
    else
        first(value_result).valueID
    end

    if isempty(result)
        # Insert new title field
        # Get title fieldID (should be 1)
        field_query = "SELECT fieldID FROM fields WHERE fieldName = 'title'"
        field_result = SQLite.DBInterface.execute(db.conn, field_query) |> collect
        field_id = isempty(field_result) ? 1 : first(field_result).fieldID

        SQLite.DBInterface.execute(db.conn,
            "INSERT INTO itemData (itemID, fieldID, valueID) VALUES (?, ?, ?)",
            [item_id, field_id, value_id])
    else
        # Update existing
        SQLite.DBInterface.execute(db.conn,
            "UPDATE itemData SET valueID = ? WHERE itemID = ? AND fieldID = (SELECT fieldID FROM fields WHERE fieldName = 'title')",
            [value_id, item_id])
    end
end

"""
Store extracted metadata in the extra field
"""
function store_extracted_metadata(db::ZoteroDatabase, item_id::Int, metadata::Dict{String,Any})
    # Format metadata for extra field
    lines = String[]

    if haskey(metadata, "platform") && !isnothing(metadata["platform"])
        push!(lines, "Original Platform: $(metadata["platform"])")
    end
    if haskey(metadata, "username") && !isnothing(metadata["username"])
        push!(lines, "Original Username: $(metadata["username"])")
    end
    if haskey(metadata, "post_id") && !isnothing(metadata["post_id"])
        push!(lines, "Original Post ID: $(metadata["post_id"])")
    end
    if haskey(metadata, "extracted_date") && !isnothing(metadata["extracted_date"])
        push!(lines, "Extracted Date: $(metadata["extracted_date"])")
    end
    if haskey(metadata, "original_filename") && !isnothing(metadata["original_filename"])
        push!(lines, "Original Filename: $(metadata["original_filename"])")
    end
    if haskey(metadata, "exif_date") && !isnothing(metadata["exif_date"])
        push!(lines, "EXIF Date: $(metadata["exif_date"])")
    end
    if haskey(metadata, "camera_make") && !isnothing(metadata["camera_make"])
        push!(lines, "Camera: $(metadata["camera_make"]) $(get(metadata, "camera_model", ""))")
    end
    if haskey(metadata, "gps_lat") && !isnothing(metadata["gps_lat"])
        push!(lines, "GPS: $(metadata["gps_lat"]), $(metadata["gps_lon"])")
    end

    if isempty(lines)
        return
    end

    extra_text = join(lines, "\n")

    # Get current extra field
    current_query = """
    SELECT idv.value, id.valueID
    FROM itemData id
    JOIN itemDataValues idv ON id.valueID = idv.valueID
    JOIN fields f ON id.fieldID = f.fieldID
    WHERE id.itemID = ? AND f.fieldName = 'extra'
    """
    current = SQLite.DBInterface.execute(db.conn, current_query, [item_id]) |> collect

    new_extra = if isempty(current)
        extra_text
    else
        existing = first(current).value
        if contains(existing, "Original Filename:")
            existing  # Already has our metadata
        else
            existing * "\n\n--- Extracted Metadata ---\n" * extra_text
        end
    end

    # Get or create value
    value_check = "SELECT valueID FROM itemDataValues WHERE value = ?"
    value_result = SQLite.DBInterface.execute(db.conn, value_check, [new_extra]) |> collect

    value_id = if isempty(value_result)
        SQLite.DBInterface.execute(db.conn,
            "INSERT INTO itemDataValues (value) VALUES (?)",
            [new_extra])
        last_id = SQLite.DBInterface.execute(db.conn,
            "SELECT last_insert_rowid() as id") |> collect
        first(last_id).id
    else
        first(value_result).valueID
    end

    if isempty(current)
        # Insert new extra field
        field_query = "SELECT fieldID FROM fields WHERE fieldName = 'extra'"
        field_result = SQLite.DBInterface.execute(db.conn, field_query) |> collect
        field_id = isempty(field_result) ? 16 : first(field_result).fieldID

        SQLite.DBInterface.execute(db.conn,
            "INSERT INTO itemData (itemID, fieldID, valueID) VALUES (?, ?, ?)",
            [item_id, field_id, value_id])
    else
        SQLite.DBInterface.execute(db.conn,
            "UPDATE itemData SET valueID = ? WHERE itemID = ? AND fieldID = (SELECT fieldID FROM fields WHERE fieldName = 'extra')",
            [value_id, item_id])
    end
end

"""
Generate new filename from parent item and extracted metadata
"""
function generate_filename(att::AttachmentInfo,
                          parent::Union{ParentItemInfo,Nothing},
                          file_meta::Dict{String,Any},
                          exif_meta::Dict{String,Any})::String
    ext = lowercase(last(splitext(att.filename)))
    if isempty(ext)
        ext = if contains(att.content_type, "jpeg") || contains(att.content_type, "jpg")
            ".jpg"
        elseif contains(att.content_type, "png")
            ".png"
        elseif contains(att.content_type, "gif")
            ".gif"
        elseif contains(att.content_type, "pdf")
            ".pdf"
        elseif contains(att.content_type, "webp")
            ".webp"
        else
            ".unknown"
        end
    end

    base_name = ""

    # Try to use parent item info first
    if !isnothing(parent) && !isempty(parent.title) && !is_likely_generic(parent.title)
        # Truncate title intelligently
        title = parent.title
        if length(title) > 60
            # Find a good break point
            title = first(title, 60)
            last_space = findlast(' ', title)
            if !isnothing(last_space) && last_space > 30
                title = first(title, last_space - 1)
            end
        end

        # Add author and year if available
        if !isempty(parent.creators)
            author = parent.creators[1].lastName
            year = if !isnothing(parent.date) && length(parent.date) >= 4
                first(parent.date, 4)
            else
                ""
            end

            base_name = if !isempty(year)
                "$author-$year-$title"
            else
                "$author-$title"
            end
        else
            base_name = title
        end
    end

    # Fallback to extracted metadata
    if isempty(base_name)
        platform = get(file_meta, "platform", nothing)
        extracted_date = get(file_meta, "extracted_date", get(exif_meta, "exif_date", nothing))
        username = get(file_meta, "username", nothing)

        parts = String[]

        if !isnothing(platform)
            push!(parts, platform)
        end

        if !isnothing(username)
            push!(parts, username)
        end

        if !isnothing(extracted_date)
            push!(parts, Dates.format(extracted_date, "yyyy-mm-dd"))
        end

        if isempty(parts)
            # Last resort: use date added with descriptive prefix
            push!(parts, "attachment")
            push!(parts, Dates.format(now(), "yyyy-mm-dd-HHMMSS"))
        end

        base_name = join(parts, "-")
    end

    # Add suffix for content type
    content_type = att.content_type
    if contains(content_type, "image")
        base_name *= "-img"
    elseif contains(content_type, "pdf")
        base_name *= "-doc"
    elseif contains(content_type, "video")
        base_name *= "-vid"
    end

    # Sanitize filename
    base_name = sanitize_filename(base_name)

    return base_name * ext
end

"""
Sanitize a string for use as a filename
"""
function sanitize_filename(name::String)::String
    # Replace problematic characters
    result = replace(name,
        r"[<>:\"/\\|?*]" => "-",
        r"\s+" => "-",
        r"-+" => "-"
    )

    # Remove leading/trailing dashes
    result = strip(result, '-')

    # Limit length
    if length(result) > 100
        result = first(result, 100)
    end

    return result
end

"""
Find duplicate files by hash
"""
function find_duplicates(attachments::Vector{AttachmentInfo})::Vector{DuplicateGroup}
    hash_to_files = Dict{String,Vector{AttachmentInfo}}()

    for att in attachments
        if isfile(att.full_path)
            h = compute_blake3(att.full_path)
            if !haskey(hash_to_files, h)
                hash_to_files[h] = AttachmentInfo[]
            end
            push!(hash_to_files[h], att)
        end
    end

    # Return only groups with duplicates
    return [DuplicateGroup(h, files) for (h, files) in hash_to_files if length(files) > 1]
end
