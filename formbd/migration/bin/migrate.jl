#!/usr/bin/env julia
# SPDX-License-Identifier: AGPL-3.0-or-later
"""
Zotero to FormDB Migration CLI

Usage:
    julia migration/bin/migrate.jl --from <sqlite_path> --to <output_dir> [options]

Options:
    --from PATH       Path to Zotero SQLite database
    --to PATH         Output directory for FormDB journal
    --actor ID        Actor ID for provenance (default: zotero-formdb-migration)
    --rationale TEXT  Migration rationale (default: "Migrated from Zotero SQLite")
    --apply           Actually write files (default: dry run)
    --verbose         Show detailed progress
    --help            Show this help

Examples:
    # Preview migration
    julia migration/bin/migrate.jl --from ~/.zotero/zotero.sqlite --to ~/FormDB/zotero

    # Apply migration
    julia migration/bin/migrate.jl --from ~/.zotero/zotero.sqlite --to ~/FormDB/zotero --apply
"""

using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using ArgParse

include(joinpath(@__DIR__, "..", "src", "migrate.jl"))
using .ZoteroMigration

function parse_commandline()
    s = ArgParseSettings(
        description = "Migrate Zotero SQLite to FormDB journal format",
        version = "0.1.0",
        add_version = true
    )

    @add_arg_table! s begin
        "--from"
            help = "Path to Zotero SQLite database"
            required = true
        "--to"
            help = "Output directory for FormDB journal"
            required = true
        "--actor"
            help = "Actor ID for provenance"
            default = "zotero-formdb-migration"
        "--rationale"
            help = "Migration rationale"
            default = "Migrated from Zotero SQLite database"
        "--apply"
            help = "Actually write files (default: dry run)"
            action = :store_true
        "--verbose"
            help = "Show detailed progress"
            action = :store_true
    end

    return parse_args(s)
end

function main()
    args = parse_commandline()

    config = MigrationConfig(
        sqlite_path = args["from"],
        output_dir = args["to"],
        actor_id = args["actor"],
        rationale = args["rationale"],
        dry_run = !args["apply"],
        verbose = args["verbose"]
    )

    result = migrate_database(config)

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
