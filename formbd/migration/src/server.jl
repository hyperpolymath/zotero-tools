# SPDX-License-Identifier: AGPL-3.0-or-later
"""
Zotero-Compatible REST API Server (v0.4.0)

Serves FormDB journal data through Zotero's REST API endpoints.
This allows existing Zotero clients to work with FormDB storage.

Endpoints implemented:
  GET  /users/:userID/items           - List all items
  GET  /users/:userID/items/:key      - Get single item
  GET  /users/:userID/collections     - List all collections
  GET  /users/:userID/collections/:key - Get single collection
  GET  /users/:userID/items/:key/children - Get item's attachments/notes
  POST /users/:userID/items           - Create items
  PUT  /users/:userID/items/:key      - Update item
  DELETE /users/:userID/items/:key    - Delete item

PROMPT scoring endpoints (v0.2.0):
  GET  /users/:userID/items/:key/prompt-scores - Get PROMPT scores
  PUT  /users/:userID/items/:key/prompt-scores - Set PROMPT scores

DOI immutability endpoints (v0.3.0):
  GET  /users/:userID/items/:key/doi-status    - Check if canonical/variant
  POST /users/:userID/items/:key/create-variant - Create editable play-variant

Publisher registry endpoints (v0.4.0):
  GET  /users/:userID/publishers                - List all publishers
  GET  /users/:userID/publishers/:key           - Get publisher details
  PUT  /users/:userID/publishers/:key           - Update publisher scores
  GET  /users/:userID/items/:key/funding        - Get item funding sources
  PUT  /users/:userID/items/:key/funding        - Set item funding sources
  GET  /users/:userID/blindspots                - Get blindspot analysis

Query parameters supported:
  format=json (default)
  limit=100 (default, max 100)
  start=0 (pagination offset)
  sort=dateModified (default)
  direction=desc (default)
  itemType=book,journalArticle,...
  q=search query
  minScore=0-100 (filter by minimum overall PROMPT score)
  hasScore=true (filter to only items with PROMPT scores)
  hasDOI=true (filter to only DOI items - v0.3.0)
  isVariant=true (filter to only play-variants - v0.3.0)
  fundingType=industry,academic,... (filter by funding - v0.4.0)
  publisherScore=0-100 (filter by publisher quality - v0.4.0)
"""
module ZoteroServer

using HTTP
using JSON3
using Dates
using SHA
using UUIDs

export start_server, ServerConfig

# Server configuration
Base.@kwdef struct ServerConfig
    journal_dir::String
    port::Int = 8080
    host::String = "127.0.0.1"
    user_id::String = "local"
    api_key::Union{String, Nothing} = nothing
end

# PROMPT framework dimensions
const PROMPT_DIMENSIONS = ["provenance", "replicability", "objectivity", "methodology", "publication", "transparency"]

# Funding source categories (v0.4.0) - inspired by Ground News ownership tracking
const FUNDING_CATEGORIES = [
    "academic",      # University/academic institution funded
    "government",    # Government grants (NIH, NSF, etc.)
    "industry",      # Commercial/corporate funded
    "foundation",    # Non-profit foundation (Gates, Wellcome, etc.)
    "ngo",           # NGO/advocacy organization
    "crowdfunded",   # Public/crowdfunded research
    "self-funded",   # Author self-funded
    "mixed",         # Multiple funding sources
    "unknown"        # Funding not disclosed
]

# Publisher ownership categories (v0.4.0) - adapted from Ground News
const OWNERSHIP_CATEGORIES = [
    "academic_society",    # Learned society (ACS, IEEE, etc.)
    "university_press",    # University-owned press
    "commercial_large",    # Large commercial (Elsevier, Springer, Wiley)
    "commercial_small",    # Smaller commercial publishers
    "open_access",         # Pure OA publishers (PLOS, MDPI, Frontiers)
    "government",          # Government publishers
    "independent",         # Independent/nonprofit
    "predatory",           # Known predatory publishers
    "unknown"              # Classification unknown
]

# Publisher quality dimensions (v0.4.0)
const PUBLISHER_DIMENSIONS = [
    "peer_review_rigor",   # Quality of peer review process
    "retraction_rate",     # Inverse - lower is better (normalized)
    "transparency",        # Editorial transparency
    "reproducibility",     # Support for reproducibility
    "accessibility"        # Open access policies
]

"""
Calculate overall PROMPT score (average of 6 dimensions).
Each dimension should be 0-100.
"""
function calculate_overall_score(scores::Dict{String, Any})::Float64
    total = 0.0
    count = 0
    for dim in PROMPT_DIMENSIONS
        if haskey(scores, dim)
            total += scores[dim]
            count += 1
        end
    end
    return count > 0 ? total / count : 0.0
end

"""
Calculate publisher quality score (average of publisher dimensions).
"""
function calculate_publisher_score(scores::Dict{String, Any})::Float64
    total = 0.0
    count = 0
    for dim in PUBLISHER_DIMENSIONS
        if haskey(scores, dim)
            total += scores[dim]
            count += 1
        end
    end
    return count > 0 ? total / count : 0.0
end

"""
Aggregate multiple PROMPT scores from different scorers (v0.4.0).
Returns average, range, standard deviation, and individual scores.
"""
function aggregate_prompt_scores(scores_list::Vector{Dict{String, Any}})::Dict{String, Any}
    if isempty(scores_list)
        return Dict{String, Any}()
    end

    result = Dict{String, Any}(
        "scorer_count" => length(scores_list),
        "scorers" => scores_list
    )

    # Aggregate each dimension
    for dim in PROMPT_DIMENSIONS
        values = Float64[]
        for scores in scores_list
            if haskey(scores, dim)
                push!(values, Float64(scores[dim]))
            end
        end

        if !isempty(values)
            avg = sum(values) / length(values)
            min_val = minimum(values)
            max_val = maximum(values)
            range_val = max_val - min_val

            # Standard deviation
            variance = sum((v - avg)^2 for v in values) / length(values)
            std_dev = sqrt(variance)

            result[dim] = Dict(
                "average" => round(avg, digits=1),
                "min" => min_val,
                "max" => max_val,
                "range" => range_val,
                "std_dev" => round(std_dev, digits=2),
                "consensus" => range_val <= 20 ? "high" : range_val <= 40 ? "medium" : "low"
            )
        end
    end

    # Calculate overall aggregated score
    overall_values = Float64[]
    for scores in scores_list
        overall = calculate_overall_score(scores)
        if overall > 0
            push!(overall_values, overall)
        end
    end

    if !isempty(overall_values)
        avg = sum(overall_values) / length(overall_values)
        result["overall"] = Dict(
            "average" => round(avg, digits=1),
            "min" => minimum(overall_values),
            "max" => maximum(overall_values),
            "range" => maximum(overall_values) - minimum(overall_values)
        )
    end

    return result
end

"""
Detect blindspots in the library (v0.4.0).
Identifies topics/areas with:
- Predominantly single funding source
- Low methodological diversity
- Skewed publisher representation
"""
function detect_blindspots(index::JournalIndex)::Vector{Dict{String, Any}}
    blindspots = Vector{Dict{String, Any}}()

    # Analyze funding distribution
    funding_counts = Dict{String, Int}()
    total_with_funding = 0

    for (key, funding) in index.item_funding
        category = get(funding, "primary_category", "unknown")
        funding_counts[category] = get(funding_counts, category, 0) + 1
        total_with_funding += 1
    end

    if total_with_funding > 0
        for (category, count) in funding_counts
            proportion = count / total_with_funding
            if proportion >= 0.7 && category != "unknown"
                push!(blindspots, Dict{String, Any}(
                    "type" => "funding_concentration",
                    "category" => category,
                    "proportion" => round(proportion * 100, digits=1),
                    "count" => count,
                    "total" => total_with_funding,
                    "severity" => proportion >= 0.85 ? "high" : "medium",
                    "message" => "$(round(proportion * 100, digits=0))% of items are funded by $category sources"
                ))
            end
        end

        # Check for funding blindspot (missing categories)
        for category in FUNDING_CATEGORIES
            if category != "unknown" && !haskey(funding_counts, category)
                push!(blindspots, Dict{String, Any}(
                    "type" => "funding_gap",
                    "category" => category,
                    "severity" => "low",
                    "message" => "No items from $category funding sources"
                ))
            end
        end
    end

    # Analyze publisher distribution
    publisher_counts = Dict{String, Int}()
    total_with_publisher = 0

    for (key, pub_key) in index.item_publishers
        publisher_counts[pub_key] = get(publisher_counts, pub_key, 0) + 1
        total_with_publisher += 1
    end

    if total_with_publisher >= 10
        for (pub_key, count) in publisher_counts
            proportion = count / total_with_publisher
            if proportion >= 0.5
                pub_data = get(index.publishers, pub_key, Dict{String, Any}())
                pub_name = get(pub_data, "name", pub_key)
                push!(blindspots, Dict{String, Any}(
                    "type" => "publisher_concentration",
                    "publisher" => pub_name,
                    "publisher_key" => pub_key,
                    "proportion" => round(proportion * 100, digits=1),
                    "count" => count,
                    "severity" => proportion >= 0.7 ? "high" : "medium",
                    "message" => "$(round(proportion * 100, digits=0))% of items from single publisher: $pub_name"
                ))
            end
        end
    end

    # Analyze PROMPT score distribution (methodology blindspots)
    methodology_scores = Float64[]
    for (key, scores) in index.prompt_scores
        if haskey(scores, "methodology")
            push!(methodology_scores, Float64(scores["methodology"]))
        end
    end

    if length(methodology_scores) >= 5
        avg_methodology = sum(methodology_scores) / length(methodology_scores)
        low_methodology_count = count(s -> s < 50, methodology_scores)
        low_proportion = low_methodology_count / length(methodology_scores)

        if low_proportion >= 0.5
            push!(blindspots, Dict{String, Any}(
                "type" => "methodology_quality",
                "average_score" => round(avg_methodology, digits=1),
                "low_score_proportion" => round(low_proportion * 100, digits=1),
                "severity" => low_proportion >= 0.7 ? "high" : "medium",
                "message" => "$(round(low_proportion * 100, digits=0))% of items have methodology scores below 50"
            ))
        end
    end

    return blindspots
end

# In-memory index for fast lookups
mutable struct JournalIndex
    items::Dict{String, Dict{String, Any}}
    collections::Dict{String, Dict{String, Any}}
    attachments::Dict{String, Vector{Dict{String, Any}}}
    notes::Dict{String, Vector{Dict{String, Any}}}
    collection_items::Dict{String, Vector{String}}
    prompt_scores::Dict{String, Dict{String, Any}}  # item_key -> PROMPT scores
    # DOI immutability tracking (v0.3.0)
    canonical_dois::Dict{String, String}     # DOI string -> canonical item key
    variant_parents::Dict{String, String}    # variant item key -> parent DOI
    # Publisher registry (v0.4.0)
    publishers::Dict{String, Dict{String, Any}}           # publisher_key -> publisher data
    publisher_scores::Dict{String, Dict{String, Any}}     # publisher_key -> quality scores
    item_publishers::Dict{String, String}                 # item_key -> publisher_key
    # Funding tracking (v0.4.0)
    item_funding::Dict{String, Dict{String, Any}}         # item_key -> funding info
    # Multi-scorer PROMPT (v0.4.0)
    prompt_scores_multi::Dict{String, Vector{Dict{String, Any}}}  # item_key -> [scorer ratings]
    last_version::Int
    lock::ReentrantLock
end

JournalIndex() = JournalIndex(
    Dict{String, Dict{String, Any}}(),
    Dict{String, Dict{String, Any}}(),
    Dict{String, Vector{Dict{String, Any}}}(),
    Dict{String, Vector{Dict{String, Any}}}(),
    Dict{String, Vector{String}}(),
    Dict{String, Dict{String, Any}}(),
    Dict{String, String}(),  # canonical_dois
    Dict{String, String}(),  # variant_parents
    Dict{String, Dict{String, Any}}(),  # publishers
    Dict{String, Dict{String, Any}}(),  # publisher_scores
    Dict{String, String}(),              # item_publishers
    Dict{String, Dict{String, Any}}(),  # item_funding
    Dict{String, Vector{Dict{String, Any}}}(),  # prompt_scores_multi
    0,
    ReentrantLock()
)

# Global state
const JOURNAL_INDEX = Ref{JournalIndex}(JournalIndex())
const SERVER_CONFIG = Ref{ServerConfig}(ServerConfig(journal_dir="."))

"""
Load journal into memory index for fast queries.
"""
function load_journal!(config::ServerConfig)
    journal_path = joinpath(config.journal_dir, "journal.jsonl")

    if !isfile(journal_path)
        @warn "Journal not found" path=journal_path
        return
    end

    index = JournalIndex()

    open(journal_path, "r") do io
        for line in eachline(io)
            isempty(strip(line)) && continue

            try
                entry = JSON3.read(line, Dict{String, Any})
                process_entry!(index, entry)
            catch e
                @warn "Failed to parse journal entry" error=e
            end
        end
    end

    JOURNAL_INDEX[] = index
    @info "Journal loaded" items=length(index.items) collections=length(index.collections)
end

"""
Process a single journal entry into the index.

Handles two formats:
1. Migration format: {op_type, collection, payload (JSON string), ...}
2. API format: {type, data, ...}
"""
function process_entry!(index::JournalIndex, entry::Dict{String, Any})
    seq = get(entry, "sequence", 0)

    # Detect format and extract entry type and data
    local entry_type::String
    local data::Dict{String, Any}

    if haskey(entry, "collection")
        # Migration format: collection field indicates type
        collection = get(entry, "collection", "")
        payload_str = get(entry, "payload", "{}")

        # Parse payload JSON string
        data = try
            JSON3.read(payload_str, Dict{String, Any})
        catch
            Dict{String, Any}()
        end

        # Map collection name to entry type
        entry_type = if collection == "collections"
            "collection"
        elseif collection == "items"
            "item"
        elseif collection == "attachments"
            "attachment"
        elseif collection == "notes"
            "note"
        elseif collection == "collection_items"
            "collection_item"
        else
            collection
        end
    else
        # API format: type and data fields
        entry_type = get(entry, "type", "")
        data_raw = get(entry, "data", nothing)
        data = if isnothing(data_raw)
            Dict{String, Any}()
        elseif data_raw isa Dict
            Dict{String, Any}(data_raw)
        else
            Dict{String, Any}()
        end
    end

    lock(index.lock) do
        index.last_version = max(index.last_version, seq)

        if entry_type == "item"
            key = get(data, "key", "")
            if !isempty(key)
                index.items[key] = data
                # DOI tracking (v0.3.0): register canonical DOI items
                doi = get(data, "DOI", "")
                if !isempty(doi) && !haskey(data, "parentDOI")
                    # This is a canonical DOI item (not a variant)
                    index.canonical_dois[doi] = key
                end
                # Track play-variants
                parent_doi = get(data, "parentDOI", "")
                if !isempty(parent_doi)
                    index.variant_parents[key] = parent_doi
                end
            end
        elseif entry_type == "attachment"
            key = get(data, "key", "")
            parent_key = get(data, "parentItem", "")
            if !isempty(key)
                index.items[key] = data
                if !isempty(parent_key)
                    if !haskey(index.attachments, parent_key)
                        index.attachments[parent_key] = Vector{Dict{String, Any}}()
                    end
                    push!(index.attachments[parent_key], data)
                end
            end
        elseif entry_type == "note"
            key = get(data, "key", "")
            parent_key = get(data, "parentItem", "")
            if !isempty(key)
                index.items[key] = data
                if !isempty(parent_key)
                    if !haskey(index.notes, parent_key)
                        index.notes[parent_key] = Vector{Dict{String, Any}}()
                    end
                    push!(index.notes[parent_key], data)
                end
            end
        elseif entry_type == "collection"
            key = get(data, "key", "")
            if !isempty(key)
                index.collections[key] = data
            end
        elseif entry_type == "collection_item"
            collection_key = get(data, "collectionKey", "")
            item_key = get(data, "itemKey", "")
            if !isempty(collection_key) && !isempty(item_key)
                if !haskey(index.collection_items, collection_key)
                    index.collection_items[collection_key] = Vector{String}()
                end
                push!(index.collection_items[collection_key], item_key)
            end
        elseif entry_type == "prompt_score"
            item_key = get(data, "itemKey", "")
            if !isempty(item_key)
                scores = get(data, "scores", Dict{String, Any}())
                scores["overall"] = calculate_overall_score(scores)
                scores["scored_at"] = get(data, "scored_at", "")
                scores["scored_by"] = get(data, "scored_by", "")
                index.prompt_scores[item_key] = scores
            end
        # v0.4.0: Publisher registry
        elseif entry_type == "publisher"
            pub_key = get(data, "key", "")
            if !isempty(pub_key)
                index.publishers[pub_key] = data
            end
        elseif entry_type == "publisher_score"
            pub_key = get(data, "publisherKey", "")
            if !isempty(pub_key)
                scores = get(data, "scores", Dict{String, Any}())
                scores["overall"] = calculate_publisher_score(scores)
                scores["scored_at"] = get(data, "scored_at", "")
                scores["scored_by"] = get(data, "scored_by", "")
                index.publisher_scores[pub_key] = scores
            end
        elseif entry_type == "item_publisher"
            item_key = get(data, "itemKey", "")
            pub_key = get(data, "publisherKey", "")
            if !isempty(item_key) && !isempty(pub_key)
                index.item_publishers[item_key] = pub_key
            end
        # v0.4.0: Funding tracking
        elseif entry_type == "item_funding"
            item_key = get(data, "itemKey", "")
            if !isempty(item_key)
                index.item_funding[item_key] = data
            end
        # v0.4.0: Multi-scorer PROMPT
        elseif entry_type == "prompt_score_multi"
            item_key = get(data, "itemKey", "")
            if !isempty(item_key)
                scorer_data = Dict{String, Any}(
                    "scorer_id" => get(data, "scorer_id", "anonymous"),
                    "scores" => get(data, "scores", Dict{String, Any}()),
                    "scored_at" => get(data, "scored_at", ""),
                    "rationale" => get(data, "rationale", "")
                )
                if !haskey(index.prompt_scores_multi, item_key)
                    index.prompt_scores_multi[item_key] = Vector{Dict{String, Any}}()
                end
                push!(index.prompt_scores_multi[item_key], scorer_data)
            end
        end
    end
end

"""
Convert FormDB item to Zotero API format.
"""
function to_zotero_format(item::Dict{String, Any}, version::Int)
    key = get(item, "key", "")
    item_type = get(item, "itemType", "unknown")

    # Build Zotero-compatible response
    response = Dict{String, Any}(
        "key" => key,
        "version" => version,
        "library" => Dict(
            "type" => "user",
            "id" => SERVER_CONFIG[].user_id,
            "name" => "FormDB Library"
        ),
        "data" => Dict{String, Any}(
            "key" => key,
            "version" => version,
            "itemType" => item_type
        )
    )

    # Copy over standard fields
    data = response["data"]
    for field in ["title", "creators", "abstractNote", "date", "url", "accessDate",
                  "DOI", "ISBN", "ISSN", "pages", "volume", "issue", "publisher",
                  "publicationTitle", "journalAbbreviation", "language", "rights",
                  "extra", "dateAdded", "dateModified", "tags", "collections",
                  "relations", "parentItem", "note", "contentType", "charset",
                  "filename", "md5", "mtime", "linkMode", "path"]
        if haskey(item, field)
            data[field] = item[field]
        end
    end

    # Add provenance metadata as extra field if present
    if haskey(item, "provenance")
        prov = item["provenance"]
        existing_extra = get(data, "extra", "")
        prov_extra = "FormDB-Actor: $(get(prov, "actor", "unknown"))\nFormDB-Rationale: $(get(prov, "rationale", ""))"
        data["extra"] = isempty(existing_extra) ? prov_extra : "$existing_extra\n$prov_extra"
    end

    # Add PROMPT scores if available
    index = JOURNAL_INDEX[]
    if haskey(index.prompt_scores, key)
        response["promptScores"] = index.prompt_scores[key]
    end

    # Add DOI status (v0.3.0)
    doi = get(item, "DOI", "")
    parent_doi = get(item, "parentDOI", "")
    if !isempty(doi) && isempty(parent_doi)
        # Canonical DOI item - immutable
        response["doiStatus"] = Dict(
            "type" => "canonical",
            "doi" => doi,
            "immutable" => true,
            "message" => "This item has a DOI and is immutable. Create a play-variant to make edits."
        )
    elseif !isempty(parent_doi)
        # Play-variant of a DOI item
        response["doiStatus"] = Dict(
            "type" => "variant",
            "parentDOI" => parent_doi,
            "immutable" => false,
            "message" => "This is a play-variant. The canonical version is at DOI: $parent_doi"
        )
        data["parentDOI"] = parent_doi
    end

    return response
end

"""
Convert FormDB collection to Zotero API format.
"""
function collection_to_zotero_format(coll::Dict{String, Any}, version::Int)
    key = get(coll, "key", "")

    Dict{String, Any}(
        "key" => key,
        "version" => version,
        "library" => Dict(
            "type" => "user",
            "id" => SERVER_CONFIG[].user_id,
            "name" => "FormDB Library"
        ),
        "data" => Dict{String, Any}(
            "key" => key,
            "version" => version,
            "name" => get(coll, "name", "Untitled"),
            "parentCollection" => get(coll, "parentKey", nothing)
        )
    )
end

# Request handlers

function handle_get_items(req::HTTP.Request, params::Dict{String, String})
    index = JOURNAL_INDEX[]
    version = index.last_version

    # Parse query parameters
    uri = HTTP.URI(req.target)
    query = HTTP.queryparams(uri)

    limit = min(parse(Int, get(query, "limit", "100")), 100)
    start = parse(Int, get(query, "start", "0"))
    item_type_filter = get(query, "itemType", nothing)
    search_query = get(query, "q", nothing)
    min_score = get(query, "minScore", nothing)
    has_score_filter = get(query, "hasScore", nothing)
    # DOI filters (v0.3.0)
    has_doi_filter = get(query, "hasDOI", nothing)
    is_variant_filter = get(query, "isVariant", nothing)

    # Filter and collect items (excluding attachments and notes as top-level)
    items = Vector{Dict{String, Any}}()

    lock(index.lock) do
        for (key, item) in index.items
            item_type = get(item, "itemType", "")

            # Skip attachments and notes in top-level listing
            if item_type in ["attachment", "note"]
                continue
            end

            # Apply item type filter
            if !isnothing(item_type_filter)
                types = split(item_type_filter, ",")
                if !(item_type in types)
                    continue
                end
            end

            # Apply search filter
            if !isnothing(search_query)
                title = lowercase(get(item, "title", ""))
                if !contains(title, lowercase(search_query))
                    continue
                end
            end

            # Apply PROMPT score filters
            if !isnothing(min_score)
                min_val = parse(Float64, min_score)
                if haskey(index.prompt_scores, key)
                    overall = get(index.prompt_scores[key], "overall", 0.0)
                    if overall < min_val
                        continue
                    end
                else
                    # No score = doesn't meet minimum
                    continue
                end
            end

            # Filter for items that have scores
            if !isnothing(has_score_filter) && lowercase(has_score_filter) == "true"
                if !haskey(index.prompt_scores, key)
                    continue
                end
            end

            # DOI filters (v0.3.0)
            item_doi = get(item, "DOI", "")
            item_parent_doi = get(item, "parentDOI", "")

            # Filter for canonical DOI items
            if !isnothing(has_doi_filter) && lowercase(has_doi_filter) == "true"
                if isempty(item_doi) || !isempty(item_parent_doi)
                    continue  # Must have DOI and NOT be a variant
                end
            end

            # Filter for play-variants only
            if !isnothing(is_variant_filter) && lowercase(is_variant_filter) == "true"
                if isempty(item_parent_doi)
                    continue  # Must be a variant (has parentDOI)
                end
            end

            push!(items, to_zotero_format(item, version))
        end
    end

    # Sort by dateModified (desc)
    sort!(items, by=x -> get(get(x, "data", Dict()), "dateModified", ""), rev=true)

    # Paginate
    total = length(items)
    items = items[start+1:min(start+limit, total)]

    # Build response with headers
    headers = [
        "Content-Type" => "application/json",
        "Zotero-API-Version" => "3",
        "Total-Results" => string(total),
        "Last-Modified-Version" => string(version)
    ]

    return HTTP.Response(200, headers, JSON3.write(items))
end

function handle_get_item(req::HTTP.Request, params::Dict{String, String})
    key = get(params, "key", "")
    index = JOURNAL_INDEX[]
    version = index.last_version

    item = lock(index.lock) do
        get(index.items, key, nothing)
    end

    if isnothing(item)
        return HTTP.Response(404, ["Content-Type" => "application/json"],
                            JSON3.write(Dict("error" => "Item not found")))
    end

    response = to_zotero_format(item, version)

    headers = [
        "Content-Type" => "application/json",
        "Zotero-API-Version" => "3",
        "Last-Modified-Version" => string(version)
    ]

    return HTTP.Response(200, headers, JSON3.write(response))
end

function handle_get_item_children(req::HTTP.Request, params::Dict{String, String})
    key = get(params, "key", "")
    index = JOURNAL_INDEX[]
    version = index.last_version

    children = Vector{Dict{String, Any}}()

    lock(index.lock) do
        # Get attachments
        for att in get(index.attachments, key, [])
            push!(children, to_zotero_format(att, version))
        end
        # Get notes
        for note in get(index.notes, key, [])
            push!(children, to_zotero_format(note, version))
        end
    end

    headers = [
        "Content-Type" => "application/json",
        "Zotero-API-Version" => "3",
        "Total-Results" => string(length(children)),
        "Last-Modified-Version" => string(version)
    ]

    return HTTP.Response(200, headers, JSON3.write(children))
end

function handle_get_collections(req::HTTP.Request, params::Dict{String, String})
    index = JOURNAL_INDEX[]
    version = index.last_version

    collections = Vector{Dict{String, Any}}()

    lock(index.lock) do
        for (key, coll) in index.collections
            push!(collections, collection_to_zotero_format(coll, version))
        end
    end

    # Sort by name
    sort!(collections, by=x -> get(get(x, "data", Dict()), "name", ""))

    headers = [
        "Content-Type" => "application/json",
        "Zotero-API-Version" => "3",
        "Total-Results" => string(length(collections)),
        "Last-Modified-Version" => string(version)
    ]

    return HTTP.Response(200, headers, JSON3.write(collections))
end

function handle_get_collection(req::HTTP.Request, params::Dict{String, String})
    key = get(params, "key", "")
    index = JOURNAL_INDEX[]
    version = index.last_version

    coll = lock(index.lock) do
        get(index.collections, key, nothing)
    end

    if isnothing(coll)
        return HTTP.Response(404, ["Content-Type" => "application/json"],
                            JSON3.write(Dict("error" => "Collection not found")))
    end

    response = collection_to_zotero_format(coll, version)

    headers = [
        "Content-Type" => "application/json",
        "Zotero-API-Version" => "3",
        "Last-Modified-Version" => string(version)
    ]

    return HTTP.Response(200, headers, JSON3.write(response))
end

function handle_get_collection_items(req::HTTP.Request, params::Dict{String, String})
    collection_key = get(params, "key", "")
    index = JOURNAL_INDEX[]
    version = index.last_version

    items = Vector{Dict{String, Any}}()

    lock(index.lock) do
        item_keys = get(index.collection_items, collection_key, String[])
        for key in item_keys
            item = get(index.items, key, nothing)
            if !isnothing(item)
                push!(items, to_zotero_format(item, version))
            end
        end
    end

    headers = [
        "Content-Type" => "application/json",
        "Zotero-API-Version" => "3",
        "Total-Results" => string(length(items)),
        "Last-Modified-Version" => string(version)
    ]

    return HTTP.Response(200, headers, JSON3.write(items))
end

# Write operations - append to journal

function append_to_journal(entry::Dict{String, Any})
    config = SERVER_CONFIG[]
    journal_path = joinpath(config.journal_dir, "journal.jsonl")

    index = JOURNAL_INDEX[]

    new_seq = lock(index.lock) do
        index.last_version += 1
        index.last_version
    end

    # Build journal entry with provenance
    journal_entry = Dict{String, Any}(
        "sequence" => new_seq,
        "timestamp" => Dates.format(now(UTC), "yyyy-mm-ddTHH:MM:SSZ"),
        "type" => entry["type"],
        "data" => entry["data"],
        "provenance" => Dict(
            "actor" => "zotero-api-client",
            "rationale" => get(entry, "rationale", "API write operation")
        )
    )

    # Compute hash chain
    prev_hash = ""
    if isfile(journal_path)
        # Read last line for previous hash
        lines = readlines(journal_path)
        if !isempty(lines)
            last_entry = JSON3.read(lines[end], Dict{String, Any})
            prev_hash = get(last_entry, "hash", "")
        end
    end

    content_hash = bytes2hex(sha256(JSON3.write(journal_entry)))
    journal_entry["prev_hash"] = prev_hash
    journal_entry["hash"] = bytes2hex(sha256(prev_hash * content_hash))

    # Append to journal
    open(journal_path, "a") do io
        println(io, JSON3.write(journal_entry))
    end

    # Update in-memory index
    process_entry!(index, journal_entry)

    return new_seq
end

function handle_post_items(req::HTTP.Request, params::Dict{String, String})
    try
        body = JSON3.read(String(req.body), Vector{Dict{String, Any}})

        created_items = Vector{Dict{String, Any}}()
        failed_items = Dict{String, Any}()

        for (idx, item_data) in enumerate(body)
            item_type = get(item_data, "itemType", "")
            parent_item = get(item_data, "parentItem", "")

            # DOI restriction (v0.3.0): notes and attachments cannot attach to canonical DOI items
            if item_type in ["note", "attachment"] && !isempty(parent_item)
                error_msg = check_can_attach_children(parent_item)
                if !isnothing(error_msg)
                    failed_items[string(idx-1)] = Dict(
                        "code" => "DOI_IMMUTABLE",
                        "message" => error_msg
                    )
                    continue
                end
            end

            # Generate key if not provided
            if !haskey(item_data, "key")
                item_data["key"] = uppercase(randstring(['A':'Z'; '0':'9'], 8))
            end

            # Set timestamps
            now_str = Dates.format(now(UTC), "yyyy-mm-ddTHH:MM:SSZ")
            item_data["dateAdded"] = get(item_data, "dateAdded", now_str)
            item_data["dateModified"] = now_str

            # Append to journal
            new_version = append_to_journal(Dict(
                "type" => "item",
                "data" => item_data,
                "rationale" => "Created via Zotero API"
            ))

            push!(created_items, to_zotero_format(item_data, new_version))
        end

        headers = [
            "Content-Type" => "application/json",
            "Zotero-API-Version" => "3",
            "Last-Modified-Version" => string(JOURNAL_INDEX[].last_version)
        ]

        return HTTP.Response(200, headers, JSON3.write(Dict(
            "successful" => Dict(string(i-1) => item for (i, item) in enumerate(created_items)),
            "success" => Dict(string(i-1) => item["key"] for (i, item) in enumerate(created_items)),
            "unchanged" => Dict(),
            "failed" => failed_items  # Include DOI restriction failures (v0.3.0)
        )))

    catch e
        @error "Failed to create items" exception=e
        return HTTP.Response(400, ["Content-Type" => "application/json"],
                            JSON3.write(Dict("error" => string(e))))
    end
end

function handle_put_item(req::HTTP.Request, params::Dict{String, String})
    key = get(params, "key", "")
    index = JOURNAL_INDEX[]

    # Check if this is a canonical DOI item (v0.3.0)
    existing_item = lock(index.lock) do
        get(index.items, key, nothing)
    end

    if !isnothing(existing_item)
        doi = get(existing_item, "DOI", "")
        parent_doi = get(existing_item, "parentDOI", "")

        # If item has DOI and is NOT already a variant, block the edit
        if !isempty(doi) && isempty(parent_doi)
            return HTTP.Response(409, ["Content-Type" => "application/json"],
                JSON3.write(Dict(
                    "error" => "Cannot modify canonical DOI item",
                    "code" => "DOI_IMMUTABLE",
                    "doi" => doi,
                    "message" => "Items with DOIs are immutable canonical references. Use POST /users/:userID/items/:key/create-variant to create an editable play-variant.",
                    "createVariantUrl" => "/users/$(SERVER_CONFIG[].user_id)/items/$key/create-variant"
                )))
        end
    end

    try
        item_data = JSON3.read(String(req.body), Dict{String, Any})
        item_data["key"] = key
        item_data["dateModified"] = Dates.format(now(UTC), "yyyy-mm-ddTHH:MM:SSZ")

        new_version = append_to_journal(Dict(
            "type" => "item",
            "data" => item_data,
            "rationale" => "Updated via Zotero API"
        ))

        headers = [
            "Content-Type" => "application/json",
            "Zotero-API-Version" => "3",
            "Last-Modified-Version" => string(new_version)
        ]

        return HTTP.Response(204, headers, "")

    catch e
        @error "Failed to update item" exception=e
        return HTTP.Response(400, ["Content-Type" => "application/json"],
                            JSON3.write(Dict("error" => string(e))))
    end
end

function handle_delete_item(req::HTTP.Request, params::Dict{String, String})
    key = get(params, "key", "")

    # In FormDB, we don't really delete - we mark as deleted with provenance
    new_version = append_to_journal(Dict(
        "type" => "deletion",
        "data" => Dict("key" => key, "deleted" => true),
        "rationale" => "Deleted via Zotero API"
    ))

    # Remove from index
    index = JOURNAL_INDEX[]
    lock(index.lock) do
        delete!(index.items, key)
    end

    headers = [
        "Content-Type" => "application/json",
        "Zotero-API-Version" => "3",
        "Last-Modified-Version" => string(new_version)
    ]

    return HTTP.Response(204, headers, "")
end

# PROMPT Score handlers

"""
Get PROMPT scores for an item.
GET /users/:userID/items/:key/prompt-scores
"""
function handle_get_prompt_scores(req::HTTP.Request, params::Dict{String, String})
    key = get(params, "key", "")
    index = JOURNAL_INDEX[]
    version = index.last_version

    # Check if item exists
    item_exists = lock(index.lock) do
        haskey(index.items, key)
    end

    if !item_exists
        return HTTP.Response(404, ["Content-Type" => "application/json"],
                            JSON3.write(Dict("error" => "Item not found")))
    end

    # Get scores
    scores = lock(index.lock) do
        get(index.prompt_scores, key, nothing)
    end

    if isnothing(scores)
        return HTTP.Response(404, ["Content-Type" => "application/json"],
                            JSON3.write(Dict("error" => "No PROMPT scores for this item")))
    end

    headers = [
        "Content-Type" => "application/json",
        "Zotero-API-Version" => "3",
        "Last-Modified-Version" => string(version)
    ]

    response = Dict{String, Any}(
        "itemKey" => key,
        "scores" => scores,
        "dimensions" => PROMPT_DIMENSIONS
    )

    return HTTP.Response(200, headers, JSON3.write(response))
end

"""
Set PROMPT scores for an item.
PUT /users/:userID/items/:key/prompt-scores

Request body:
{
    "provenance": 85,
    "replicability": 70,
    "objectivity": 90,
    "methodology": 75,
    "publication": 80,
    "transparency": 65,
    "rationale": "Why these scores"
}
"""
function handle_put_prompt_scores(req::HTTP.Request, params::Dict{String, String})
    key = get(params, "key", "")
    index = JOURNAL_INDEX[]

    # Check if item exists
    item_exists = lock(index.lock) do
        haskey(index.items, key)
    end

    if !item_exists
        return HTTP.Response(404, ["Content-Type" => "application/json"],
                            JSON3.write(Dict("error" => "Item not found")))
    end

    try
        body = JSON3.read(String(req.body), Dict{String, Any})

        # Validate scores are in range 0-100
        scores = Dict{String, Any}()
        for dim in PROMPT_DIMENSIONS
            if haskey(body, dim)
                val = body[dim]
                if !(val isa Number) || val < 0 || val > 100
                    return HTTP.Response(400, ["Content-Type" => "application/json"],
                                        JSON3.write(Dict("error" => "Score '$dim' must be 0-100")))
                end
                scores[dim] = Float64(val)
            end
        end

        if isempty(scores)
            return HTTP.Response(400, ["Content-Type" => "application/json"],
                                JSON3.write(Dict("error" => "At least one PROMPT dimension required")))
        end

        # Add metadata
        scores["rationale"] = get(body, "rationale", "")

        # Append to journal
        new_version = append_to_journal(Dict(
            "type" => "prompt_score",
            "data" => Dict(
                "itemKey" => key,
                "scores" => scores,
                "scored_at" => Dates.format(now(UTC), "yyyy-mm-ddTHH:MM:SSZ"),
                "scored_by" => "api-client"
            ),
            "rationale" => get(body, "rationale", "PROMPT score update via API")
        ))

        # Calculate overall
        scores["overall"] = calculate_overall_score(scores)

        headers = [
            "Content-Type" => "application/json",
            "Zotero-API-Version" => "3",
            "Last-Modified-Version" => string(new_version)
        ]

        response = Dict{String, Any}(
            "itemKey" => key,
            "scores" => scores,
            "version" => new_version
        )

        return HTTP.Response(200, headers, JSON3.write(response))

    catch e
        @error "Failed to set PROMPT scores" exception=e
        return HTTP.Response(400, ["Content-Type" => "application/json"],
                            JSON3.write(Dict("error" => string(e))))
    end
end

# DOI Immutability handlers (v0.3.0)

"""
Get DOI status for an item.
GET /users/:userID/items/:key/doi-status

Returns whether item is canonical (immutable), a variant, or has no DOI.
"""
function handle_get_doi_status(req::HTTP.Request, params::Dict{String, String})
    key = get(params, "key", "")
    index = JOURNAL_INDEX[]
    version = index.last_version

    item = lock(index.lock) do
        get(index.items, key, nothing)
    end

    if isnothing(item)
        return HTTP.Response(404, ["Content-Type" => "application/json"],
                            JSON3.write(Dict("error" => "Item not found")))
    end

    doi = get(item, "DOI", "")
    parent_doi = get(item, "parentDOI", "")

    headers = [
        "Content-Type" => "application/json",
        "Zotero-API-Version" => "3",
        "Last-Modified-Version" => string(version)
    ]

    if !isempty(doi) && isempty(parent_doi)
        # Canonical DOI item
        # Find variants of this DOI
        variants = lock(index.lock) do
            [k for (k, pd) in index.variant_parents if pd == doi]
        end

        response = Dict{String, Any}(
            "itemKey" => key,
            "status" => "canonical",
            "doi" => doi,
            "immutable" => true,
            "variantCount" => length(variants),
            "variants" => variants,
            "message" => "This item is the canonical DOI reference. It cannot be modified directly."
        )
        return HTTP.Response(200, headers, JSON3.write(response))

    elseif !isempty(parent_doi)
        # Play-variant
        canonical_key = lock(index.lock) do
            get(index.canonical_dois, parent_doi, "")
        end

        response = Dict{String, Any}(
            "itemKey" => key,
            "status" => "variant",
            "parentDOI" => parent_doi,
            "canonicalKey" => canonical_key,
            "immutable" => false,
            "message" => "This is a play-variant of DOI: $parent_doi. It can be freely edited."
        )
        return HTTP.Response(200, headers, JSON3.write(response))

    else
        # No DOI
        response = Dict{String, Any}(
            "itemKey" => key,
            "status" => "no-doi",
            "immutable" => false,
            "message" => "This item has no DOI. It can be freely edited."
        )
        return HTTP.Response(200, headers, JSON3.write(response))
    end
end

"""
Create a play-variant of a canonical DOI item.
POST /users/:userID/items/:key/create-variant

Creates an editable copy of a DOI item with parentDOI linking back.
Notes and annotations can only be attached to play-variants.
"""
function handle_create_variant(req::HTTP.Request, params::Dict{String, String})
    key = get(params, "key", "")
    index = JOURNAL_INDEX[]

    # Get the original item
    original = lock(index.lock) do
        get(index.items, key, nothing)
    end

    if isnothing(original)
        return HTTP.Response(404, ["Content-Type" => "application/json"],
                            JSON3.write(Dict("error" => "Item not found")))
    end

    doi = get(original, "DOI", "")

    if isempty(doi)
        return HTTP.Response(400, ["Content-Type" => "application/json"],
            JSON3.write(Dict(
                "error" => "Item has no DOI",
                "code" => "NO_DOI",
                "message" => "Only items with DOIs need play-variants. This item can be edited directly."
            )))
    end

    # Check if already a variant
    if haskey(original, "parentDOI")
        return HTTP.Response(400, ["Content-Type" => "application/json"],
            JSON3.write(Dict(
                "error" => "Item is already a play-variant",
                "code" => "ALREADY_VARIANT",
                "parentDOI" => original["parentDOI"],
                "message" => "This item is already a play-variant. Edit it directly."
            )))
    end

    try
        # Parse optional variant name from body
        variant_name = ""
        if !isempty(req.body)
            body = JSON3.read(String(req.body), Dict{String, Any})
            variant_name = get(body, "variantName", "")
        end

        # Create the variant as a copy with parentDOI
        variant_data = Dict{String, Any}()
        for (k, v) in original
            variant_data[k] = v
        end

        # Generate new key for variant
        variant_key = uppercase(randstring(['A':'Z'; '0':'9'], 8))
        variant_data["key"] = variant_key

        # Link to parent DOI (not parent item key - DOI is the identity)
        variant_data["parentDOI"] = doi

        # Remove the DOI from variant (it's not THE canonical document)
        delete!(variant_data, "DOI")

        # Mark as variant in title if name provided
        if !isempty(variant_name)
            original_title = get(variant_data, "title", "Untitled")
            variant_data["title"] = "$original_title [$variant_name]"
        end

        # Set timestamps
        now_str = Dates.format(now(UTC), "yyyy-mm-ddTHH:MM:SSZ")
        variant_data["dateAdded"] = now_str
        variant_data["dateModified"] = now_str

        # Add extra field noting this is a variant
        existing_extra = get(variant_data, "extra", "")
        variant_extra = "FormDB-Variant-Of: $doi\nFormDB-Variant-Created: $now_str"
        variant_data["extra"] = isempty(existing_extra) ? variant_extra : "$existing_extra\n$variant_extra"

        # Append to journal
        new_version = append_to_journal(Dict(
            "type" => "item",
            "data" => variant_data,
            "rationale" => "Created play-variant of canonical DOI item: $doi"
        ))

        headers = [
            "Content-Type" => "application/json",
            "Zotero-API-Version" => "3",
            "Last-Modified-Version" => string(new_version)
        ]

        response = Dict{String, Any}(
            "variantKey" => variant_key,
            "parentDOI" => doi,
            "canonicalKey" => key,
            "version" => new_version,
            "message" => "Play-variant created. You can now edit this variant and attach notes/annotations to it.",
            "item" => to_zotero_format(variant_data, new_version)
        )

        return HTTP.Response(201, headers, JSON3.write(response))

    catch e
        @error "Failed to create variant" exception=e
        return HTTP.Response(400, ["Content-Type" => "application/json"],
                            JSON3.write(Dict("error" => string(e))))
    end
end

# Publisher registry handlers (v0.4.0)

"""
Get all publishers in the registry.
GET /users/:userID/publishers
"""
function handle_get_publishers(req::HTTP.Request, params::Dict{String, String})
    index = JOURNAL_INDEX[]
    version = index.last_version

    publishers = Vector{Dict{String, Any}}()

    lock(index.lock) do
        for (key, pub) in index.publishers
            pub_response = Dict{String, Any}(
                "key" => key,
                "name" => get(pub, "name", key),
                "ownership" => get(pub, "ownership", "unknown"),
                "website" => get(pub, "website", ""),
                "issn" => get(pub, "issn", []),
                "itemCount" => count(p -> p.second == key, index.item_publishers)
            )

            # Add scores if available
            if haskey(index.publisher_scores, key)
                pub_response["scores"] = index.publisher_scores[key]
            end

            push!(publishers, pub_response)
        end
    end

    # Sort by name
    sort!(publishers, by=x -> get(x, "name", ""))

    headers = [
        "Content-Type" => "application/json",
        "Zotero-API-Version" => "3",
        "Total-Results" => string(length(publishers)),
        "Last-Modified-Version" => string(version)
    ]

    return HTTP.Response(200, headers, JSON3.write(publishers))
end

"""
Get a specific publisher.
GET /users/:userID/publishers/:key
"""
function handle_get_publisher(req::HTTP.Request, params::Dict{String, String})
    key = get(params, "key", "")
    index = JOURNAL_INDEX[]
    version = index.last_version

    pub = lock(index.lock) do
        get(index.publishers, key, nothing)
    end

    if isnothing(pub)
        return HTTP.Response(404, ["Content-Type" => "application/json"],
                            JSON3.write(Dict("error" => "Publisher not found")))
    end

    # Get items from this publisher
    items_from_pub = lock(index.lock) do
        [k for (k, pk) in index.item_publishers if pk == key]
    end

    scores = lock(index.lock) do
        get(index.publisher_scores, key, nothing)
    end

    response = Dict{String, Any}(
        "key" => key,
        "name" => get(pub, "name", key),
        "ownership" => get(pub, "ownership", "unknown"),
        "website" => get(pub, "website", ""),
        "issn" => get(pub, "issn", []),
        "itemCount" => length(items_from_pub),
        "items" => items_from_pub
    )

    if !isnothing(scores)
        response["scores"] = scores
    end

    headers = [
        "Content-Type" => "application/json",
        "Zotero-API-Version" => "3",
        "Last-Modified-Version" => string(version)
    ]

    return HTTP.Response(200, headers, JSON3.write(response))
end

"""
Create or update a publisher.
PUT /users/:userID/publishers/:key

Request body:
{
    "name": "Nature Publishing Group",
    "ownership": "commercial_large",
    "website": "https://www.nature.com",
    "issn": ["1476-4687"]
}
"""
function handle_put_publisher(req::HTTP.Request, params::Dict{String, String})
    key = get(params, "key", "")
    index = JOURNAL_INDEX[]

    try
        body = JSON3.read(String(req.body), Dict{String, Any})

        # Validate ownership category
        ownership = get(body, "ownership", "unknown")
        if !(ownership in OWNERSHIP_CATEGORIES)
            return HTTP.Response(400, ["Content-Type" => "application/json"],
                JSON3.write(Dict(
                    "error" => "Invalid ownership category",
                    "validCategories" => OWNERSHIP_CATEGORIES
                )))
        end

        pub_data = Dict{String, Any}(
            "key" => key,
            "name" => get(body, "name", key),
            "ownership" => ownership,
            "website" => get(body, "website", ""),
            "issn" => get(body, "issn", [])
        )

        new_version = append_to_journal(Dict(
            "type" => "publisher",
            "data" => pub_data,
            "rationale" => "Publisher registry update via API"
        ))

        headers = [
            "Content-Type" => "application/json",
            "Zotero-API-Version" => "3",
            "Last-Modified-Version" => string(new_version)
        ]

        return HTTP.Response(200, headers, JSON3.write(Dict(
            "key" => key,
            "version" => new_version,
            "message" => "Publisher created/updated"
        )))

    catch e
        @error "Failed to update publisher" exception=e
        return HTTP.Response(400, ["Content-Type" => "application/json"],
                            JSON3.write(Dict("error" => string(e))))
    end
end

"""
Set quality scores for a publisher.
PUT /users/:userID/publishers/:key/scores

Request body:
{
    "peer_review_rigor": 90,
    "retraction_rate": 85,
    "transparency": 80,
    "reproducibility": 75,
    "accessibility": 70,
    "rationale": "Well-established peer review process"
}
"""
function handle_put_publisher_scores(req::HTTP.Request, params::Dict{String, String})
    key = get(params, "key", "")
    index = JOURNAL_INDEX[]

    # Check if publisher exists
    pub_exists = lock(index.lock) do
        haskey(index.publishers, key)
    end

    if !pub_exists
        return HTTP.Response(404, ["Content-Type" => "application/json"],
                            JSON3.write(Dict("error" => "Publisher not found")))
    end

    try
        body = JSON3.read(String(req.body), Dict{String, Any})

        # Validate scores
        scores = Dict{String, Any}()
        for dim in PUBLISHER_DIMENSIONS
            if haskey(body, dim)
                val = body[dim]
                if !(val isa Number) || val < 0 || val > 100
                    return HTTP.Response(400, ["Content-Type" => "application/json"],
                                        JSON3.write(Dict("error" => "Score '$dim' must be 0-100")))
                end
                scores[dim] = Float64(val)
            end
        end

        if isempty(scores)
            return HTTP.Response(400, ["Content-Type" => "application/json"],
                                JSON3.write(Dict("error" => "At least one publisher dimension required")))
        end

        new_version = append_to_journal(Dict(
            "type" => "publisher_score",
            "data" => Dict(
                "publisherKey" => key,
                "scores" => scores,
                "scored_at" => Dates.format(now(UTC), "yyyy-mm-ddTHH:MM:SSZ"),
                "scored_by" => "api-client"
            ),
            "rationale" => get(body, "rationale", "Publisher score update via API")
        ))

        scores["overall"] = calculate_publisher_score(scores)

        headers = [
            "Content-Type" => "application/json",
            "Zotero-API-Version" => "3",
            "Last-Modified-Version" => string(new_version)
        ]

        return HTTP.Response(200, headers, JSON3.write(Dict(
            "publisherKey" => key,
            "scores" => scores,
            "version" => new_version
        )))

    catch e
        @error "Failed to set publisher scores" exception=e
        return HTTP.Response(400, ["Content-Type" => "application/json"],
                            JSON3.write(Dict("error" => string(e))))
    end
end

# Funding tracking handlers (v0.4.0)

"""
Get funding information for an item.
GET /users/:userID/items/:key/funding
"""
function handle_get_item_funding(req::HTTP.Request, params::Dict{String, String})
    key = get(params, "key", "")
    index = JOURNAL_INDEX[]
    version = index.last_version

    item_exists = lock(index.lock) do
        haskey(index.items, key)
    end

    if !item_exists
        return HTTP.Response(404, ["Content-Type" => "application/json"],
                            JSON3.write(Dict("error" => "Item not found")))
    end

    funding = lock(index.lock) do
        get(index.item_funding, key, nothing)
    end

    if isnothing(funding)
        return HTTP.Response(404, ["Content-Type" => "application/json"],
                            JSON3.write(Dict("error" => "No funding information for this item")))
    end

    headers = [
        "Content-Type" => "application/json",
        "Zotero-API-Version" => "3",
        "Last-Modified-Version" => string(version)
    ]

    return HTTP.Response(200, headers, JSON3.write(funding))
end

"""
Set funding information for an item.
PUT /users/:userID/items/:key/funding

Request body:
{
    "primary_category": "government",
    "sources": [
        {"name": "NIH", "grant": "R01-12345", "category": "government"},
        {"name": "Gates Foundation", "category": "foundation"}
    ],
    "disclosure": "full",
    "conflicts_of_interest": false
}
"""
function handle_put_item_funding(req::HTTP.Request, params::Dict{String, String})
    key = get(params, "key", "")
    index = JOURNAL_INDEX[]

    item_exists = lock(index.lock) do
        haskey(index.items, key)
    end

    if !item_exists
        return HTTP.Response(404, ["Content-Type" => "application/json"],
                            JSON3.write(Dict("error" => "Item not found")))
    end

    try
        body = JSON3.read(String(req.body), Dict{String, Any})

        # Validate primary category
        primary = get(body, "primary_category", "unknown")
        if !(primary in FUNDING_CATEGORIES)
            return HTTP.Response(400, ["Content-Type" => "application/json"],
                JSON3.write(Dict(
                    "error" => "Invalid funding category",
                    "validCategories" => FUNDING_CATEGORIES
                )))
        end

        funding_data = Dict{String, Any}(
            "itemKey" => key,
            "primary_category" => primary,
            "sources" => get(body, "sources", []),
            "disclosure" => get(body, "disclosure", "unknown"),
            "conflicts_of_interest" => get(body, "conflicts_of_interest", nothing),
            "updated_at" => Dates.format(now(UTC), "yyyy-mm-ddTHH:MM:SSZ")
        )

        new_version = append_to_journal(Dict(
            "type" => "item_funding",
            "data" => funding_data,
            "rationale" => get(body, "rationale", "Funding information update via API")
        ))

        headers = [
            "Content-Type" => "application/json",
            "Zotero-API-Version" => "3",
            "Last-Modified-Version" => string(new_version)
        ]

        return HTTP.Response(200, headers, JSON3.write(Dict(
            "itemKey" => key,
            "funding" => funding_data,
            "version" => new_version
        )))

    catch e
        @error "Failed to set item funding" exception=e
        return HTTP.Response(400, ["Content-Type" => "application/json"],
                            JSON3.write(Dict("error" => string(e))))
    end
end

# Multi-scorer PROMPT handlers (v0.4.0)

"""
Get aggregated multi-scorer PROMPT scores for an item.
GET /users/:userID/items/:key/prompt-scores-multi
"""
function handle_get_prompt_scores_multi(req::HTTP.Request, params::Dict{String, String})
    key = get(params, "key", "")
    index = JOURNAL_INDEX[]
    version = index.last_version

    item_exists = lock(index.lock) do
        haskey(index.items, key)
    end

    if !item_exists
        return HTTP.Response(404, ["Content-Type" => "application/json"],
                            JSON3.write(Dict("error" => "Item not found")))
    end

    scores_list = lock(index.lock) do
        get(index.prompt_scores_multi, key, nothing)
    end

    if isnothing(scores_list) || isempty(scores_list)
        return HTTP.Response(404, ["Content-Type" => "application/json"],
                            JSON3.write(Dict("error" => "No multi-scorer data for this item")))
    end

    # Extract just the scores dicts for aggregation
    scores_only = [s["scores"] for s in scores_list]
    aggregated = aggregate_prompt_scores(scores_only)

    # Add individual scorer metadata
    aggregated["scorers"] = scores_list

    headers = [
        "Content-Type" => "application/json",
        "Zotero-API-Version" => "3",
        "Last-Modified-Version" => string(version)
    ]

    response = Dict{String, Any}(
        "itemKey" => key,
        "aggregated" => aggregated,
        "dimensions" => PROMPT_DIMENSIONS
    )

    return HTTP.Response(200, headers, JSON3.write(response))
end

"""
Add a scorer's PROMPT evaluation for an item.
POST /users/:userID/items/:key/prompt-scores-multi

Request body:
{
    "scorer_id": "reviewer1",
    "provenance": 85,
    "methodology": 70,
    ...
    "rationale": "Detailed review notes"
}
"""
function handle_post_prompt_scores_multi(req::HTTP.Request, params::Dict{String, String})
    key = get(params, "key", "")
    index = JOURNAL_INDEX[]

    item_exists = lock(index.lock) do
        haskey(index.items, key)
    end

    if !item_exists
        return HTTP.Response(404, ["Content-Type" => "application/json"],
                            JSON3.write(Dict("error" => "Item not found")))
    end

    try
        body = JSON3.read(String(req.body), Dict{String, Any})

        scorer_id = get(body, "scorer_id", "anonymous")

        # Validate scores
        scores = Dict{String, Any}()
        for dim in PROMPT_DIMENSIONS
            if haskey(body, dim)
                val = body[dim]
                if !(val isa Number) || val < 0 || val > 100
                    return HTTP.Response(400, ["Content-Type" => "application/json"],
                                        JSON3.write(Dict("error" => "Score '$dim' must be 0-100")))
                end
                scores[dim] = Float64(val)
            end
        end

        if isempty(scores)
            return HTTP.Response(400, ["Content-Type" => "application/json"],
                                JSON3.write(Dict("error" => "At least one PROMPT dimension required")))
        end

        new_version = append_to_journal(Dict(
            "type" => "prompt_score_multi",
            "data" => Dict(
                "itemKey" => key,
                "scorer_id" => scorer_id,
                "scores" => scores,
                "scored_at" => Dates.format(now(UTC), "yyyy-mm-ddTHH:MM:SSZ"),
                "rationale" => get(body, "rationale", "")
            ),
            "rationale" => "Multi-scorer PROMPT evaluation from $scorer_id"
        ))

        # Get updated aggregation
        scores_list = lock(index.lock) do
            get(index.prompt_scores_multi, key, [])
        end

        scores_only = [s["scores"] for s in scores_list]
        aggregated = aggregate_prompt_scores(scores_only)

        headers = [
            "Content-Type" => "application/json",
            "Zotero-API-Version" => "3",
            "Last-Modified-Version" => string(new_version)
        ]

        return HTTP.Response(201, headers, JSON3.write(Dict(
            "itemKey" => key,
            "scorer_id" => scorer_id,
            "version" => new_version,
            "scorer_count" => length(scores_list),
            "aggregated" => aggregated
        )))

    catch e
        @error "Failed to add multi-scorer evaluation" exception=e
        return HTTP.Response(400, ["Content-Type" => "application/json"],
                            JSON3.write(Dict("error" => string(e))))
    end
end

# Blindspot detection handler (v0.4.0)

"""
Get blindspot analysis for the library.
GET /users/:userID/blindspots
"""
function handle_get_blindspots(req::HTTP.Request, params::Dict{String, String})
    index = JOURNAL_INDEX[]
    version = index.last_version

    blindspots = detect_blindspots(index)

    # Summary statistics
    stats = lock(index.lock) do
        Dict{String, Any}(
            "total_items" => length(index.items),
            "items_with_funding" => length(index.item_funding),
            "items_with_publisher" => length(index.item_publishers),
            "items_with_scores" => length(index.prompt_scores),
            "publishers_registered" => length(index.publishers)
        )
    end

    headers = [
        "Content-Type" => "application/json",
        "Zotero-API-Version" => "3",
        "Last-Modified-Version" => string(version)
    ]

    response = Dict{String, Any}(
        "blindspots" => blindspots,
        "blindspot_count" => length(blindspots),
        "high_severity_count" => count(b -> get(b, "severity", "") == "high", blindspots),
        "medium_severity_count" => count(b -> get(b, "severity", "") == "medium", blindspots),
        "low_severity_count" => count(b -> get(b, "severity", "") == "low", blindspots),
        "library_stats" => stats,
        "funding_categories" => FUNDING_CATEGORIES,
        "ownership_categories" => OWNERSHIP_CATEGORIES
    )

    return HTTP.Response(200, headers, JSON3.write(response))
end

"""
Check if notes/attachments can be added to an item.
Canonical DOI items cannot have direct children - must use a variant.
"""
function check_can_attach_children(parent_key::String)::Union{Nothing, String}
    index = JOURNAL_INDEX[]

    parent_item = lock(index.lock) do
        get(index.items, parent_key, nothing)
    end

    if isnothing(parent_item)
        return "Parent item not found"
    end

    doi = get(parent_item, "DOI", "")
    parent_doi = get(parent_item, "parentDOI", "")

    # If parent has DOI and is not itself a variant, block attachment
    if !isempty(doi) && isempty(parent_doi)
        return "Cannot attach notes/files to canonical DOI items. Create a play-variant first using POST /users/:userID/items/$parent_key/create-variant"
    end

    return nothing  # OK to attach
end

# Router

function route_request(req::HTTP.Request)
    path = HTTP.URI(req.target).path
    method = req.method

    # Parse path to extract user ID and resource
    # Pattern: /users/:userID/items/:key?
    #          /users/:userID/collections/:key?

    parts = split(path, "/", keepempty=false)

    if length(parts) < 3 || parts[1] != "users"
        return HTTP.Response(404, ["Content-Type" => "application/json"],
                            JSON3.write(Dict("error" => "Not found")))
    end

    user_id = parts[2]
    resource = parts[3]
    key = length(parts) >= 4 ? parts[4] : nothing
    sub_resource = length(parts) >= 5 ? parts[5] : nothing

    params = Dict{String, String}("userID" => user_id)
    if !isnothing(key)
        params["key"] = key
    end

    # Route based on method and path
    if resource == "items"
        if method == "GET"
            if isnothing(key)
                return handle_get_items(req, params)
            elseif sub_resource == "children"
                return handle_get_item_children(req, params)
            elseif sub_resource == "prompt-scores"
                return handle_get_prompt_scores(req, params)
            elseif sub_resource == "prompt-scores-multi"
                return handle_get_prompt_scores_multi(req, params)
            elseif sub_resource == "doi-status"
                return handle_get_doi_status(req, params)
            elseif sub_resource == "funding"
                return handle_get_item_funding(req, params)
            else
                return handle_get_item(req, params)
            end
        elseif method == "POST"
            if isnothing(key)
                return handle_post_items(req, params)
            elseif sub_resource == "create-variant"
                return handle_create_variant(req, params)
            elseif sub_resource == "prompt-scores-multi"
                return handle_post_prompt_scores_multi(req, params)
            end
        elseif method == "PUT" && !isnothing(key)
            if sub_resource == "prompt-scores"
                return handle_put_prompt_scores(req, params)
            elseif sub_resource == "funding"
                return handle_put_item_funding(req, params)
            else
                return handle_put_item(req, params)
            end
        elseif method == "DELETE" && !isnothing(key)
            return handle_delete_item(req, params)
        end
    elseif resource == "collections"
        if method == "GET"
            if isnothing(key)
                return handle_get_collections(req, params)
            elseif sub_resource == "items"
                return handle_get_collection_items(req, params)
            else
                return handle_get_collection(req, params)
            end
        end
    # v0.4.0: Publisher registry
    elseif resource == "publishers"
        if method == "GET"
            if isnothing(key)
                return handle_get_publishers(req, params)
            else
                return handle_get_publisher(req, params)
            end
        elseif method == "PUT" && !isnothing(key)
            if sub_resource == "scores"
                return handle_put_publisher_scores(req, params)
            else
                return handle_put_publisher(req, params)
            end
        end
    # v0.4.0: Blindspot analysis
    elseif resource == "blindspots"
        if method == "GET"
            return handle_get_blindspots(req, params)
        end
    end

    return HTTP.Response(405, ["Content-Type" => "application/json"],
                        JSON3.write(Dict("error" => "Method not allowed")))
end

function handle_request(req::HTTP.Request)
    # CORS headers for browser clients
    cors_headers = [
        "Access-Control-Allow-Origin" => "*",
        "Access-Control-Allow-Methods" => "GET, POST, PUT, DELETE, OPTIONS",
        "Access-Control-Allow-Headers" => "Content-Type, Zotero-API-Key, Zotero-API-Version"
    ]

    # Handle preflight
    if req.method == "OPTIONS"
        return HTTP.Response(204, cors_headers, "")
    end

    # Check API key if configured
    config = SERVER_CONFIG[]
    if !isnothing(config.api_key)
        provided_key = HTTP.header(req, "Zotero-API-Key", "")
        if provided_key != config.api_key
            return HTTP.Response(403, ["Content-Type" => "application/json"],
                                JSON3.write(Dict("error" => "Invalid API key")))
        end
    end

    try
        response = route_request(req)
        # Add CORS headers to response
        for (k, v) in cors_headers
            HTTP.setheader(response, k => v)
        end
        return response
    catch e
        @error "Request failed" exception=e
        return HTTP.Response(500, ["Content-Type" => "application/json"],
                            JSON3.write(Dict("error" => "Internal server error")))
    end
end

"""
Start the Zotero-compatible API server.
"""
function start_server(config::ServerConfig)
    SERVER_CONFIG[] = config

    @info "Loading journal..." dir=config.journal_dir
    load_journal!(config)

    @info "Starting Zotero API server (v0.4.0)" host=config.host port=config.port
    @info "Endpoints available:"
    @info "  GET  /users/$(config.user_id)/items"
    @info "  GET  /users/$(config.user_id)/items/:key"
    @info "  GET  /users/$(config.user_id)/items/:key/children"
    @info "  GET  /users/$(config.user_id)/collections"
    @info "  GET  /users/$(config.user_id)/collections/:key"
    @info "  GET  /users/$(config.user_id)/collections/:key/items"
    @info "  POST /users/$(config.user_id)/items"
    @info "  PUT  /users/$(config.user_id)/items/:key"
    @info "  DELETE /users/$(config.user_id)/items/:key"
    @info "PROMPT scoring (v0.2.0):"
    @info "  GET  /users/$(config.user_id)/items/:key/prompt-scores"
    @info "  PUT  /users/$(config.user_id)/items/:key/prompt-scores"
    @info "DOI immutability (v0.3.0):"
    @info "  GET  /users/$(config.user_id)/items/:key/doi-status"
    @info "  POST /users/$(config.user_id)/items/:key/create-variant"
    @info "Publisher registry (v0.4.0):"
    @info "  GET  /users/$(config.user_id)/publishers"
    @info "  GET  /users/$(config.user_id)/publishers/:key"
    @info "  PUT  /users/$(config.user_id)/publishers/:key"
    @info "  PUT  /users/$(config.user_id)/publishers/:key/scores"
    @info "Funding tracking (v0.4.0):"
    @info "  GET  /users/$(config.user_id)/items/:key/funding"
    @info "  PUT  /users/$(config.user_id)/items/:key/funding"
    @info "Multi-scorer PROMPT (v0.4.0):"
    @info "  GET  /users/$(config.user_id)/items/:key/prompt-scores-multi"
    @info "  POST /users/$(config.user_id)/items/:key/prompt-scores-multi"
    @info "Blindspot analysis (v0.4.0):"
    @info "  GET  /users/$(config.user_id)/blindspots"
    @info "Query filters: ?minScore=80 ?hasScore=true ?hasDOI=true ?isVariant=true ?fundingType=industry"

    HTTP.serve(handle_request, config.host, config.port)
end

end # module
