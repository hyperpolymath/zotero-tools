#!/usr/bin/env julia
# SPDX-License-Identifier: AGPL-3.0-or-later
"""
Zotero → FormDB Sync Bridge CLI

Syncs data from Zotero's local API to FormDB journal.
Requires Zotero to be running (local API on port 23119).

Usage:
    julia migration/bin/sync.jl --journal <dir> [options]

Options:
    --journal PATH    Directory for FormDB journal
    --api URL         Zotero API URL (default: http://localhost:23119/api)
    --actor ID        Actor ID for provenance (default: zotero-sync-bridge)
    --dry-run         Preview changes without writing
    --verbose         Show detailed progress
    --help            Show this help

Examples:
    # Preview sync
    julia migration/bin/sync.jl --journal ~/FormDB/zotero --dry-run

    # Sync with Zotero running
    julia migration/bin/sync.jl --journal ~/FormDB/zotero

    # Verbose sync
    julia migration/bin/sync.jl --journal ~/FormDB/zotero --verbose

Prerequisites:
    1. Zotero must be running (provides local API on port 23119)
    2. Test connection: curl http://localhost:23119/api/users/0/items?limit=1
"""

using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using ArgParse

include(joinpath(@__DIR__, "..", "src", "sync.jl"))
using .ZoteroSync

function parse_commandline()
    s = ArgParseSettings(
        description = "Sync from Zotero local API to FormDB journal",
        version = "0.1.0",
        add_version = true
    )

    @add_arg_table! s begin
        "--journal"
            help = "Directory for FormDB journal"
            required = true
        "--api"
            help = "Zotero API URL"
            default = "http://localhost:23119/api"
        "--actor"
            help = "Actor ID for provenance"
            default = "zotero-sync-bridge"
        "--dry-run"
            help = "Preview changes without writing"
            action = :store_true
        "--verbose"
            help = "Show detailed progress"
            action = :store_true
    end

    return parse_args(s)
end

function main()
    args = parse_commandline()

    config = SyncConfig(
        journal_dir = args["journal"],
        zotero_api = args["api"],
        actor_id = args["actor"],
        dry_run = args["dry-run"],
        verbose = args["verbose"]
    )

    result = sync_from_zotero(config)

    if !isempty(result.errors)
        println("\nErrors encountered:")
        for err in result.errors
            println("  - $err")
        end
        return 1
    end

    return 0
end

exit(main())
