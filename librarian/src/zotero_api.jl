# SPDX-License-Identifier: AGPL-3.0-or-later
"""
Zotero Web API client for cloud library operations

Supports:
- Fetching items from cloud library
- Updating attachment titles
- Storing metadata in extra field
- Batch operations with rate limiting

Note: Renaming actual files requires download/re-upload.
This module updates titles and metadata which syncs to all devices.
"""

using HTTP
using JSON3
using Dates

const ZOTERO_API_BASE = "https://api.zotero.org"
const ZOTERO_API_VERSION = 3

"""
Zotero API client configuration
"""
struct ZoteroAPIClient
    api_key::String
    user_id::String
    library_type::Symbol  # :user or :group
    library_id::String
end

"""
Create API client for user library
"""
function ZoteroAPIClient(api_key::String, user_id::String)
    return ZoteroAPIClient(api_key, user_id, :user, user_id)
end

"""
Create API client for group library
"""
function ZoteroAPIClient(api_key::String, user_id::String, group_id::String)
    return ZoteroAPIClient(api_key, user_id, :group, group_id)
end

"""
Build API URL for a resource
"""
function api_url(client::ZoteroAPIClient, path::String)
    prefix = if client.library_type == :user
        "/users/$(client.library_id)"
    else
        "/groups/$(client.library_id)"
    end
    return ZOTERO_API_BASE * prefix * path
end

"""
Make authenticated API request
"""
function api_request(client::ZoteroAPIClient, method::Symbol, path::String;
                    body=nothing, params=Dict{String,String}())
    url = api_url(client, path)

    headers = [
        "Zotero-API-Key" => client.api_key,
        "Zotero-API-Version" => string(ZOTERO_API_VERSION),
        "Content-Type" => "application/json"
    ]

    # Add query params
    if !isempty(params)
        url *= "?" * join(["$k=$v" for (k, v) in params], "&")
    end

    response = if method == :GET
        HTTP.get(url, headers; status_exception=false)
    elseif method == :PATCH
        HTTP.patch(url, headers, isnothing(body) ? "" : JSON3.write(body); status_exception=false)
    elseif method == :PUT
        HTTP.put(url, headers, isnothing(body) ? "" : JSON3.write(body); status_exception=false)
    elseif method == :POST
        HTTP.post(url, headers, isnothing(body) ? "" : JSON3.write(body); status_exception=false)
    else
        error("Unsupported method: $method")
    end

    # Handle rate limiting
    if response.status == 429
        retry_after = get(Dict(response.headers), "Retry-After", "60")
        @warn "Rate limited. Retry after $retry_after seconds"
        sleep(parse(Int, retry_after))
        return api_request(client, method, path; body=body, params=params)
    end

    # Handle backoff
    if haskey(Dict(response.headers), "Backoff")
        backoff = parse(Int, Dict(response.headers)["Backoff"])
        @info "API requested backoff of $backoff seconds"
        sleep(backoff)
    end

    return response
end

"""
Get current library version
"""
function get_library_version(client::ZoteroAPIClient)::Int
    response = api_request(client, :GET, "/items"; params=Dict("limit" => "1"))
    version_header = get(Dict(response.headers), "Last-Modified-Version", "0")
    return parse(Int, version_header)
end

"""
Fetch all items from library with pagination
"""
function fetch_all_items(client::ZoteroAPIClient;
                        item_type::String="attachment",
                        limit::Int=100)
    items = []
    start = 0

    while true
        params = Dict(
            "itemType" => item_type,
            "start" => string(start),
            "limit" => string(limit)
        )

        response = api_request(client, :GET, "/items"; params=params)

        if response.status != 200
            @error "Failed to fetch items: $(response.status)"
            break
        end

        batch = JSON3.read(String(response.body))
        append!(items, batch)

        # Check if more items
        total_results = get(Dict(response.headers), "Total-Results", "0")
        total = parse(Int, total_results)

        start += limit
        if start >= total
            break
        end

        @info "Fetched $(length(items)) / $total items..."
        sleep(0.1)  # Be nice to the API
    end

    return items
end

"""
Fetch attachments with generic filenames
"""
function fetch_generic_attachments(client::ZoteroAPIClient)
    attachments = fetch_all_items(client; item_type="attachment")

    generic = filter(attachments) do att
        data = att.data
        filename = get(data, :filename, "")
        title = get(data, :title, "")

        # Check if filename or title is generic
        !isempty(filename) && !is_well_named(filename)
    end

    @info "Found $(length(generic)) attachments with generic names out of $(length(attachments)) total"
    return generic
end

"""
Update an item via PATCH
"""
function update_item(client::ZoteroAPIClient, item_key::String, updates::Dict;
                    version::Int)
    response = api_request(client, :PATCH, "/items/$item_key";
                          body=updates,
                          params=Dict("If-Unmodified-Since-Version" => string(version)))

    if response.status == 204
        return true
    elseif response.status == 412
        @warn "Item $item_key was modified, version conflict"
        return false
    else
        @error "Failed to update $item_key: $(response.status)"
        return false
    end
end

"""
Batch update multiple items
"""
function batch_update_items(client::ZoteroAPIClient, updates::Vector{Dict})
    # Zotero API supports up to 50 items per batch
    results = Dict{String,Bool}()

    for batch in Iterators.partition(updates, 50)
        response = api_request(client, :POST, "/items"; body=collect(batch))

        if response.status in [200, 204]
            for item in batch
                results[item["key"]] = true
            end
        else
            @error "Batch update failed: $(response.status)"
            for item in batch
                results[item["key"]] = false
            end
        end

        sleep(0.5)  # Rate limiting courtesy
    end

    return results
end

"""
Get parent item for an attachment
"""
function get_parent_item(client::ZoteroAPIClient, parent_key::String)
    response = api_request(client, :GET, "/items/$parent_key")

    if response.status != 200
        return nothing
    end

    return JSON3.read(String(response.body))
end

"""
Generate new title for attachment based on parent and extracted metadata
"""
function generate_attachment_title(att_data::Dict, parent_data::Union{Dict,Nothing},
                                  extracted::Dict{String,Any})
    # Use parent title if available and meaningful
    if !isnothing(parent_data)
        parent_title = get(parent_data, :title, "")
        if !isempty(parent_title) && !is_likely_generic(parent_title)
            # Create descriptive title
            creators = get(parent_data, :creators, [])
            first_author = if !isempty(creators)
                get(first(creators), :lastName, "")
            else
                ""
            end

            date = get(parent_data, :date, "")
            year = if !isempty(date) && length(date) >= 4
                first(date, 4)
            else
                ""
            end

            # Build title
            parts = String[]
            if !isempty(first_author)
                push!(parts, first_author)
            end
            if !isempty(year)
                push!(parts, year)
            end

            # Truncate parent title
            short_title = if length(parent_title) > 50
                pt = first(parent_title, 50)
                last_space = findlast(' ', pt)
                if !isnothing(last_space) && last_space > 25
                    first(pt, last_space - 1)
                else
                    pt
                end
            else
                parent_title
            end
            push!(parts, short_title)

            return join(parts, " - ")
        end
    end

    # Fall back to extracted metadata
    platform = get(extracted, "platform", nothing)
    username = get(extracted, "username", nothing)
    extracted_date = get(extracted, "extracted_date", nothing)

    parts = String[]
    if !isnothing(platform)
        push!(parts, titlecase(string(platform)))
    end
    if !isnothing(username)
        push!(parts, string(username))
    end
    if !isnothing(extracted_date)
        push!(parts, Dates.format(extracted_date, "yyyy-mm-dd"))
    end

    if !isempty(parts)
        return join(parts, " - ")
    end

    # Last resort
    return "Attachment"
end

"""
Build extra field content with extracted metadata
"""
function build_extra_content(existing_extra::String, extracted::Dict{String,Any},
                            original_filename::String)
    lines = String[]

    # Preserve existing extra content
    if !isempty(existing_extra) && !contains(existing_extra, "Original Filename:")
        push!(lines, existing_extra)
        push!(lines, "")
        push!(lines, "--- Extracted Metadata ---")
    end

    if !isnothing(get(extracted, "platform", nothing))
        push!(lines, "Original Platform: $(extracted["platform"])")
    end
    if !isnothing(get(extracted, "username", nothing))
        push!(lines, "Original Username: $(extracted["username"])")
    end
    if !isnothing(get(extracted, "post_id", nothing))
        push!(lines, "Original Post ID: $(extracted["post_id"])")
    end
    if !isnothing(get(extracted, "extracted_date", nothing))
        push!(lines, "Extracted Date: $(extracted["extracted_date"])")
    end
    push!(lines, "Original Filename: $original_filename")
    push!(lines, "Processed: $(Dates.format(now(), "yyyy-mm-dd HH:MM:SS"))")

    return join(lines, "\n")
end

"""
Process attachments via API - update titles and metadata
"""
function process_attachments_api(client::ZoteroAPIClient;
                                dry_run::Bool=true,
                                progress_callback=nothing)
    println("Fetching attachments from Zotero cloud...")
    attachments = fetch_generic_attachments(client)

    if isempty(attachments)
        println("No generic attachments found.")
        return Dict("processed" => 0, "updated" => 0, "errors" => 0)
    end

    println("Processing $(length(attachments)) attachments...")

    updated = 0
    errors = 0
    updates_batch = Dict[]

    for (i, att) in enumerate(attachments)
        try
            data = att.data
            key = data.key
            version = att.version
            filename = get(data, :filename, "")
            current_title = get(data, :title, "")
            parent_key = get(data, :parentItem, nothing)

            # Extract metadata from filename
            extracted = extract_from_filename(filename)

            # Get parent item if available
            parent_data = if !isnothing(parent_key)
                parent = get_parent_item(client, parent_key)
                isnothing(parent) ? nothing : parent.data
            else
                nothing
            end

            # Generate new title
            new_title = generate_attachment_title(
                Dict(pairs(data)),
                isnothing(parent_data) ? nothing : Dict(pairs(parent_data)),
                extracted
            )

            if new_title == current_title
                continue
            end

            # Build update
            update = Dict(
                "key" => key,
                "version" => version,
                "title" => new_title
            )

            # Add extra field if we have metadata to store
            if haskey(extracted, "platform") || haskey(extracted, "username")
                existing_extra = get(data, :extra, "")
                update["extra"] = build_extra_content(
                    ismissing(existing_extra) ? "" : string(existing_extra),
                    extracted,
                    filename
                )
            end

            push!(updates_batch, update)

            if !isnothing(progress_callback)
                progress_callback(i, length(attachments), filename, new_title)
            end

        catch e
            @error "Error processing attachment: $e"
            errors += 1
        end
    end

    println("\nPrepared $(length(updates_batch)) updates")

    if dry_run
        println("DRY RUN - no changes applied")
        println("\nSample updates:")
        for update in updates_batch[1:min(10, length(updates_batch))]
            println("  $(update["key"]): $(update["title"])")
        end
    else
        println("Applying updates...")
        results = batch_update_items(client, updates_batch)
        updated = count(values(results))
        errors += count(!, values(results))
    end

    return Dict(
        "processed" => length(attachments),
        "updated" => dry_run ? length(updates_batch) : updated,
        "errors" => errors,
        "dry_run" => dry_run
    )
end

"""
Verify API key and get user info
"""
function verify_api_key(api_key::String)
    response = HTTP.get(
        "https://api.zotero.org/keys/$api_key",
        ["Zotero-API-Version" => string(ZOTERO_API_VERSION)];
        status_exception=false
    )

    if response.status != 200
        return nothing
    end

    return JSON3.read(String(response.body))
end
