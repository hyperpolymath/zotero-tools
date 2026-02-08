#!/usr/bin/env julia
# SPDX-License-Identifier: AGPL-3.0-or-later
"""
zotero-librarian cloud normalize CLI

Updates attachment titles and metadata in Zotero cloud library.

Usage:
    julia bin/normalize-cloud.jl [options]

Options:
    --api-key KEY   Zotero API key (or set ZOTERO_API_KEY env var)
    --user-id ID    Zotero user ID (or set ZOTERO_USER_ID env var)
    --dry-run       Preview changes without modifying (default: true)
    --apply         Actually apply changes
    --help          Show this help

Get your API key at: https://www.zotero.org/settings/keys/new
Find your user ID at: https://www.zotero.org/settings/keys (shown as "Your userID for API calls")

Examples:
    # Preview what would change
    ZOTERO_API_KEY=xxx ZOTERO_USER_ID=123 julia bin/normalize-cloud.jl

    # Apply changes
    julia bin/normalize-cloud.jl --api-key xxx --user-id 123 --apply
"""

using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using ArgParse

# Include modules
include(joinpath(@__DIR__, "..", "src", "patterns.jl"))
include(joinpath(@__DIR__, "..", "src", "zotero_api.jl"))

function parse_commandline()
    s = ArgParseSettings(
        description = "Zotero Librarian Cloud - Update attachment titles via Zotero API",
        version = "0.1.0",
        add_version = true
    )

    @add_arg_table! s begin
        "--api-key"
            help = "Zotero API key (or use ZOTERO_API_KEY env var)"
            default = get(ENV, "ZOTERO_API_KEY", "")
        "--user-id"
            help = "Zotero user ID (or use ZOTERO_USER_ID env var)"
            default = get(ENV, "ZOTERO_USER_ID", "")
        "--dry-run"
            help = "Preview changes without modifying (default)"
            action = :store_true
        "--apply"
            help = "Actually apply changes to cloud library"
            action = :store_true
    end

    return parse_args(s)
end

function main()
    args = parse_commandline()

    api_key = args["api-key"]
    user_id = args["user-id"]
    dry_run = !args["apply"]

    # Validate credentials
    if isempty(api_key)
        println("Error: API key required")
        println("Set ZOTERO_API_KEY environment variable or use --api-key")
        println("\nGet your API key at: https://www.zotero.org/settings/keys/new")
        return 1
    end

    if isempty(user_id)
        println("Error: User ID required")
        println("Set ZOTERO_USER_ID environment variable or use --user-id")
        println("\nFind your user ID at: https://www.zotero.org/settings/keys")
        return 1
    end

    println()
    println("=" ^ 60)
    println("  Zotero Librarian Cloud v0.1.0")
    println("=" ^ 60)
    println()

    # Verify API key
    println("Verifying API key...")
    key_info = verify_api_key(api_key)

    if isnothing(key_info)
        println("Error: Invalid API key")
        return 1
    end

    println("Authenticated as user: $(key_info.userID)")
    println("Key permissions: $(join(keys(key_info.access), ", "))")
    println()

    if dry_run
        println("MODE: DRY RUN (no changes will be made)")
        println("      Use --apply to update cloud library")
    else
        println("MODE: APPLYING CHANGES TO CLOUD")
        println("      Attachment titles and metadata will be updated")
    end
    println()

    # Create client
    client = ZoteroAPIClient(api_key, user_id)

    # Process attachments
    progress = (i, total, old, new) -> begin
        if i % 100 == 0 || i == total
            println("  [$i/$total] Processing...")
        end
    end

    results = process_attachments_api(client; dry_run=dry_run, progress_callback=progress)

    # Print summary
    println()
    println("=" ^ 60)
    println("  Summary")
    println("=" ^ 60)
    println("  Attachments processed: $(results["processed"])")
    println("  Updates $(dry_run ? "prepared" : "applied"): $(results["updated"])")
    println("  Errors: $(results["errors"])")
    println()

    if dry_run && results["updated"] > 0
        println("Run with --apply to update these $(results["updated"]) attachments in the cloud.")
    end

    return 0
end

exit(main())
