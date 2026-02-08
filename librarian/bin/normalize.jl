#!/usr/bin/env julia
# SPDX-License-Identifier: AGPL-3.0-or-later
"""
zotero-librarian normalize CLI

Usage:
    julia bin/normalize.jl [options]

Options:
    --db PATH       Path to zotero.sqlite (default: ~/Zotero/zotero.sqlite)
    --dry-run       Preview changes without modifying files (default: true)
    --apply         Actually apply changes (sets dry-run to false)
    --report PATH   Save report to file
    --help          Show this help

Examples:
    # Preview what would change
    julia bin/normalize.jl

    # Apply changes
    julia bin/normalize.jl --apply

    # Use custom database path
    julia bin/normalize.jl --db /path/to/zotero.sqlite --apply
"""

using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using ArgParse

# Include the main module
include(joinpath(@__DIR__, "..", "src", "ZoteroLibrarian.jl"))
using .ZoteroLibrarian

function parse_commandline()
    s = ArgParseSettings(
        description = "Zotero Librarian - Intelligent metadata extraction and file normalization",
        version = "0.1.0",
        add_version = true
    )

    @add_arg_table! s begin
        "--db"
            help = "Path to zotero.sqlite"
            default = joinpath(homedir(), "Zotero", "zotero.sqlite")
        "--dry-run"
            help = "Preview changes without modifying (default)"
            action = :store_true
        "--apply"
            help = "Actually apply changes"
            action = :store_true
        "--report"
            help = "Save report to file"
            default = ""
        "--storage"
            help = "Path to storage directory (default: auto-detect from db path)"
            default = ""
        "--history"
            help = "Path to rename history JSON (default: alongside db)"
            default = ""
    end

    return parse_args(s)
end

function main()
    args = parse_commandline()

    db_path = args["db"]
    dry_run = !args["apply"]  # Default to dry-run unless --apply is specified

    if !isfile(db_path)
        println("Error: Database not found at $db_path")
        println("Specify path with --db /path/to/zotero.sqlite")
        return 1
    end

    # Check if Zotero is running (simple check for lock file)
    journal_path = db_path * "-journal"
    wal_path = db_path * "-wal"
    if isfile(journal_path) || isfile(wal_path)
        println("Warning: Zotero may be running (lock files present)")
        println("Please close Zotero before running with --apply")
        if !dry_run
            return 1
        end
    end

    println()
    println("=" ^ 60)
    println("  Zotero Librarian v0.1.0")
    println("=" ^ 60)
    println()

    if dry_run
        println("MODE: DRY RUN (no changes will be made)")
        println("      Use --apply to actually rename files")
    else
        println("MODE: APPLYING CHANGES")
        println("      Files will be renamed and database updated")
    end
    println()

    # Run normalization
    report = normalize_library(
        db_path;
        dry_run = dry_run,
        storage_path = args["storage"],
        history_path = args["history"]
    )

    println(report)

    # Save report if requested
    if !isempty(args["report"])
        open(args["report"], "w") do io
            write(io, report)
        end
        println("\nReport saved to: $(args["report"])")
    end

    return 0
end

exit(main())
