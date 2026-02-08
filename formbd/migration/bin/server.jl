#!/usr/bin/env julia
# SPDX-License-Identifier: AGPL-3.0-or-later
"""
Zotero-Compatible API Server CLI

Serves FormDB journal through Zotero's REST API.

Usage:
    julia migration/bin/server.jl --journal <dir> [options]

Options:
    --journal PATH    Directory containing journal.jsonl
    --port PORT       Server port (default: 8080)
    --host HOST       Server host (default: 127.0.0.1)
    --user-id ID      User ID for API paths (default: local)
    --api-key KEY     Optional API key for authentication
    --help            Show this help

Examples:
    # Start server with migrated journal
    julia migration/bin/server.jl --journal ~/FormDB/zotero

    # With custom port and public binding
    julia migration/bin/server.jl --journal ~/FormDB/zotero --port 3000 --host 0.0.0.0

    # Test with curl
    curl http://localhost:8080/users/local/items
    curl http://localhost:8080/users/local/collections
"""

using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using ArgParse

include(joinpath(@__DIR__, "..", "src", "server.jl"))
using .ZoteroServer

function parse_commandline()
    s = ArgParseSettings(
        description = "Zotero-compatible API server for FormDB",
        version = "0.1.0",
        add_version = true
    )

    @add_arg_table! s begin
        "--journal"
            help = "Directory containing journal.jsonl"
            required = true
        "--port"
            help = "Server port"
            arg_type = Int
            default = 8080
        "--host"
            help = "Server host"
            default = "127.0.0.1"
        "--user-id"
            help = "User ID for API paths"
            default = "local"
        "--api-key"
            help = "Optional API key for authentication"
            default = nothing
    end

    return parse_args(s)
end

function main()
    args = parse_commandline()

    config = ServerConfig(
        journal_dir = args["journal"],
        port = args["port"],
        host = args["host"],
        user_id = args["user-id"],
        api_key = args["api-key"]
    )

    # Verify journal exists
    journal_path = joinpath(config.journal_dir, "journal.jsonl")
    if !isfile(journal_path)
        println("Error: Journal not found at $journal_path")
        println("Run the migration tool first to create a journal.")
        return 1
    end

    println("╔══════════════════════════════════════════════════════════════╗")
    println("║           FormDB Zotero-Compatible API Server                ║")
    println("╚══════════════════════════════════════════════════════════════╝")
    println()

    start_server(config)

    return 0
end

main()
