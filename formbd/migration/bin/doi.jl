# SPDX-License-Identifier: AGPL-3.0-or-later
"""
FormDB DOI Management CLI (v0.3.0)

Manage DOI items and play-variants in your FormDB library.

Usage:
    formdb-doi --status KEY           Show DOI status of an item
    formdb-doi --create-variant KEY   Create a play-variant of a DOI item
    formdb-doi --list-doi             List all canonical DOI items
    formdb-doi --list-variants        List all play-variants
    formdb-doi --variants-of DOI      List variants of a specific DOI
    formdb-doi --help                 Show this help

Options:
    --name NAME           Name for the variant (added to title)
    --server URL          FormDB server URL (default: http://localhost:8080)
    --user ID             User ID (default: local)
"""

using HTTP
using JSON3
using Dates

# Configuration
const DEFAULT_SERVER = "http://localhost:8080"
const DEFAULT_USER = "local"

# Colors for terminal output
const BOLD = "\e[1m"
const RED = "\e[31m"
const GREEN = "\e[32m"
const YELLOW = "\e[33m"
const BLUE = "\e[34m"
const CYAN = "\e[36m"
const RESET = "\e[0m"

function print_status(status::String, key::String, doi::String, message::String)
    color = if status == "canonical"
        YELLOW
    elseif status == "variant"
        CYAN
    else
        GREEN
    end

    println("$(BOLD)Item:$(RESET) $key")
    println("$(BOLD)Status:$(RESET) $color$status$(RESET)")
    if !isempty(doi)
        println("$(BOLD)DOI:$(RESET) $doi")
    end
    println("$(BOLD)Message:$(RESET) $message")
end

function get_item_status(server::String, user::String, key::String)
    url = "$server/users/$user/items/$key/doi-status"

    try
        response = HTTP.get(url)
        data = JSON3.read(String(response.body), Dict{String, Any})

        status = get(data, "status", "unknown")
        doi = get(data, "doi", get(data, "parentDOI", ""))
        message = get(data, "message", "")

        print_status(status, key, doi, message)

        if status == "canonical"
            variants = get(data, "variants", [])
            if !isempty(variants)
                println("\n$(BOLD)Play-variants:$(RESET)")
                for v in variants
                    println("  • $v")
                end
            else
                println("\n$(YELLOW)No play-variants exist. Create one with:$(RESET)")
                println("  formdb-doi --create-variant $key")
            end
        elseif status == "variant"
            canonical = get(data, "canonicalKey", "")
            if !isempty(canonical)
                println("\n$(BOLD)Canonical item:$(RESET) $canonical")
            end
        end

        return true
    catch e
        if e isa HTTP.ExceptionRequest.StatusError && e.status == 404
            println("$(RED)Error:$(RESET) Item not found: $key")
        else
            println("$(RED)Error:$(RESET) Failed to get status: $e")
        end
        return false
    end
end

function create_variant(server::String, user::String, key::String, name::String)
    url = "$server/users/$user/items/$key/create-variant"

    body = if !isempty(name)
        JSON3.write(Dict("variantName" => name))
    else
        "{}"
    end

    try
        response = HTTP.post(url,
            ["Content-Type" => "application/json"],
            body)

        data = JSON3.read(String(response.body), Dict{String, Any})

        variant_key = get(data, "variantKey", "")
        parent_doi = get(data, "parentDOI", "")

        println("$(GREEN)✓$(RESET) Play-variant created successfully!")
        println()
        println("$(BOLD)Variant Key:$(RESET) $variant_key")
        println("$(BOLD)Parent DOI:$(RESET) $parent_doi")
        println()
        println("$(CYAN)You can now:$(RESET)")
        println("  • Edit the variant freely")
        println("  • Attach notes and annotations to it")
        println("  • The canonical DOI item remains immutable")

        return true
    catch e
        if e isa HTTP.ExceptionRequest.StatusError
            error_body = JSON3.read(String(e.response.body), Dict{String, Any})
            code = get(error_body, "code", "")
            message = get(error_body, "message", get(error_body, "error", "Unknown error"))

            if code == "NO_DOI"
                println("$(YELLOW)Note:$(RESET) $message")
            elseif code == "ALREADY_VARIANT"
                println("$(YELLOW)Note:$(RESET) $message")
            else
                println("$(RED)Error:$(RESET) $message")
            end
        else
            println("$(RED)Error:$(RESET) Failed to create variant: $e")
        end
        return false
    end
end

function list_doi_items(server::String, user::String)
    url = "$server/users/$user/items?hasDOI=true"

    try
        response = HTTP.get(url)
        items = JSON3.read(String(response.body), Vector{Dict{String, Any}})

        if isempty(items)
            println("$(YELLOW)No items with DOIs found.$(RESET)")
            return true
        end

        println("$(BOLD)Canonical DOI Items:$(RESET)")
        println()

        for item in items
            key = get(item, "key", "")
            data = get(item, "data", Dict())
            title = get(data, "title", "Untitled")
            doi = get(data, "DOI", "")

            # Truncate title if too long
            if length(title) > 60
                title = title[1:57] * "..."
            end

            println("$(CYAN)$key$(RESET) │ $title")
            println("       │ DOI: $doi")
            println()
        end

        println("$(BOLD)Total:$(RESET) $(length(items)) DOI item(s)")
        return true
    catch e
        println("$(RED)Error:$(RESET) Failed to list DOI items: $e")
        return false
    end
end

function list_variants(server::String, user::String)
    url = "$server/users/$user/items?isVariant=true"

    try
        response = HTTP.get(url)
        items = JSON3.read(String(response.body), Vector{Dict{String, Any}})

        if isempty(items)
            println("$(YELLOW)No play-variants found.$(RESET)")
            return true
        end

        println("$(BOLD)Play-Variants:$(RESET)")
        println()

        for item in items
            key = get(item, "key", "")
            data = get(item, "data", Dict())
            title = get(data, "title", "Untitled")
            parent_doi = get(data, "parentDOI", "")

            # Truncate title if too long
            if length(title) > 60
                title = title[1:57] * "..."
            end

            println("$(CYAN)$key$(RESET) │ $title")
            println("       │ Parent DOI: $parent_doi")
            println()
        end

        println("$(BOLD)Total:$(RESET) $(length(items)) variant(s)")
        return true
    catch e
        println("$(RED)Error:$(RESET) Failed to list variants: $e")
        return false
    end
end

function show_help()
    println("""
$(BOLD)FormDB DOI Management CLI (v0.3.0)$(RESET)

Manage DOI items and play-variants in your FormDB library.

$(BOLD)BACKGROUND$(RESET)
DOIs are unique identifiers for published documents. When an item has a DOI,
it represents THE canonical document as published. FormDB enforces this by
making DOI items immutable - you cannot edit them directly.

To work with a DOI item (add notes, annotations, make edits), you create a
"play-variant" - a clearly-marked editable copy that links back to the
original DOI.

$(BOLD)USAGE$(RESET)
    formdb-doi --status KEY           Show DOI status of an item
    formdb-doi --create-variant KEY   Create a play-variant of a DOI item
    formdb-doi --list-doi             List all canonical DOI items
    formdb-doi --list-variants        List all play-variants
    formdb-doi --help                 Show this help

$(BOLD)OPTIONS$(RESET)
    --name NAME           Name for the variant (added to title)
    --server URL          FormDB server URL (default: http://localhost:8080)
    --user ID             User ID (default: local)

$(BOLD)EXAMPLES$(RESET)
    # Check if an item is a DOI item
    formdb-doi --status 7MP78SG8

    # Create a variant for annotation
    formdb-doi --create-variant 7MP78SG8 --name "My Notes"

    # List all your DOI items
    formdb-doi --list-doi

    # See all your working variants
    formdb-doi --list-variants

$(BOLD)DOI IMMUTABILITY RULES$(RESET)
    ┌─────────────────┬───────────────────┬─────────────────┐
    │ Operation       │ Canonical DOI     │ Play-Variant    │
    ├─────────────────┼───────────────────┼─────────────────┤
    │ Edit item       │ ✗ Blocked         │ ✓ Allowed       │
    │ Add notes       │ ✗ Blocked         │ ✓ Allowed       │
    │ Add attachments │ ✗ Blocked         │ ✓ Allowed       │
    │ Add tags        │ ✗ Blocked         │ ✓ Allowed       │
    │ Identity        │ IS that document  │ Derived from... │
    └─────────────────┴───────────────────┴─────────────────┘
""")
end

function main()
    args = ARGS

    if isempty(args) || "--help" in args || "-h" in args
        show_help()
        return
    end

    # Parse arguments
    server = DEFAULT_SERVER
    user = DEFAULT_USER
    name = ""

    i = 1
    action = nothing
    action_arg = nothing

    while i <= length(args)
        arg = args[i]

        if arg == "--server" && i < length(args)
            server = args[i+1]
            i += 2
        elseif arg == "--user" && i < length(args)
            user = args[i+1]
            i += 2
        elseif arg == "--name" && i < length(args)
            name = args[i+1]
            i += 2
        elseif arg == "--status" && i < length(args)
            action = :status
            action_arg = args[i+1]
            i += 2
        elseif arg == "--create-variant" && i < length(args)
            action = :create_variant
            action_arg = args[i+1]
            i += 2
        elseif arg == "--list-doi"
            action = :list_doi
            i += 1
        elseif arg == "--list-variants"
            action = :list_variants
            i += 1
        elseif arg == "--variants-of" && i < length(args)
            action = :variants_of
            action_arg = args[i+1]
            i += 2
        else
            println("$(RED)Error:$(RESET) Unknown argument: $arg")
            println("Use --help for usage information.")
            return
        end
    end

    if isnothing(action)
        println("$(RED)Error:$(RESET) No action specified.")
        println("Use --help for usage information.")
        return
    end

    # Execute action
    success = if action == :status
        get_item_status(server, user, action_arg)
    elseif action == :create_variant
        create_variant(server, user, action_arg, name)
    elseif action == :list_doi
        list_doi_items(server, user)
    elseif action == :list_variants
        list_variants(server, user)
    elseif action == :variants_of
        # TODO: Implement variants-of specific DOI
        println("$(YELLOW)Not yet implemented$(RESET)")
        false
    else
        false
    end

    exit(success ? 0 : 1)
end

main()
