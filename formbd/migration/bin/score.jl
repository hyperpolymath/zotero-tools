#!/usr/bin/env julia
# SPDX-License-Identifier: AGPL-3.0-or-later
"""
FormDB PROMPT Scoring CLI

Set and query evidence quality scores using the PROMPT framework.

PROMPT dimensions (each 0-100):
  - Provenance: Can the source be traced? Who created it?
  - Replicability: Can the findings be reproduced?
  - Objectivity: Is the evidence objective or biased?
  - Methodology: Is the methodology sound?
  - Publication: Is it peer-reviewed/published?
  - Transparency: Are methods/data openly available?

Usage:
    julia bin/score.jl --item KEY --provenance 85 --methodology 70 ...
    julia bin/score.jl --item KEY --get
    julia bin/score.jl --server URL --item KEY --all 80
    julia bin/score.jl --list-unscored

Options:
    --item KEY           Item key to score
    --get                Get existing scores for item
    --server URL         API server URL (default: http://localhost:8080)
    --user ID            User ID (default: local)

    Score options (0-100):
    --provenance N       Source traceability
    --replicability N    Reproducibility of findings
    --objectivity N      Freedom from bias
    --methodology N      Methodological soundness
    --publication N      Peer review status
    --transparency N     Openness of data/methods
    --all N              Set all dimensions to same value
    --rationale TEXT     Reason for these scores

    Query options:
    --list-unscored      List items without PROMPT scores
    --list-scored        List items with PROMPT scores
    --min-score N        Filter to items with overall >= N

Examples:
    # Score a journal article
    julia bin/score.jl --item ABC12345 \\
        --provenance 90 --methodology 85 --publication 95 \\
        --rationale "Peer-reviewed Nature paper with open data"

    # Quick scoring with same value for all dimensions
    julia bin/score.jl --item ABC12345 --all 75

    # Get scores for an item
    julia bin/score.jl --item ABC12345 --get

    # List unscored items (need to be evaluated)
    julia bin/score.jl --list-unscored
"""

using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using ArgParse
using HTTP
using JSON3

const PROMPT_DIMENSIONS = ["provenance", "replicability", "objectivity",
                           "methodology", "publication", "transparency"]

function parse_commandline()
    s = ArgParseSettings(
        description = "FormDB PROMPT Scoring CLI",
        version = "0.2.0",
        add_version = true
    )

    @add_arg_table! s begin
        "--item"
            help = "Item key to score"
        "--get"
            help = "Get existing scores for item"
            action = :store_true
        "--server"
            help = "API server URL"
            default = "http://localhost:8080"
        "--user"
            help = "User ID"
            default = "local"
        "--provenance"
            help = "Source traceability score (0-100)"
            arg_type = Int
        "--replicability"
            help = "Reproducibility score (0-100)"
            arg_type = Int
        "--objectivity"
            help = "Objectivity score (0-100)"
            arg_type = Int
        "--methodology"
            help = "Methodology score (0-100)"
            arg_type = Int
        "--publication"
            help = "Peer review score (0-100)"
            arg_type = Int
        "--transparency"
            help = "Openness score (0-100)"
            arg_type = Int
        "--all"
            help = "Set all dimensions to same value (0-100)"
            arg_type = Int
        "--rationale"
            help = "Reason for these scores"
            default = ""
        "--list-unscored"
            help = "List items without PROMPT scores"
            action = :store_true
        "--list-scored"
            help = "List items with PROMPT scores"
            action = :store_true
        "--min-score"
            help = "Filter to items with overall score >= N"
            arg_type = Int
    end

    return parse_args(s)
end

function api_get(base_url::String, endpoint::String)
    url = "$base_url$endpoint"
    response = HTTP.get(url; status_exception=false)
    return response.status, JSON3.read(String(response.body))
end

function api_put(base_url::String, endpoint::String, data::Dict)
    url = "$base_url$endpoint"
    body = JSON3.write(data)
    response = HTTP.put(url, ["Content-Type" => "application/json"], body;
                        status_exception=false)
    return response.status, JSON3.read(String(response.body))
end

function print_scores(scores::Dict)
    println("\n┌─────────────────────────────────────────┐")
    println("│           PROMPT Evidence Scores         │")
    println("├──────────────────┬──────────────────────┤")

    for dim in PROMPT_DIMENSIONS
        val = get(scores, dim, nothing)
        if !isnothing(val)
            bar = "█" ^ div(Int(round(val)), 5) * "░" ^ (20 - div(Int(round(val)), 5))
            println("│ $(rpad(titlecase(dim), 16)) │ $bar $(lpad(Int(round(val)), 3)) │")
        end
    end

    println("├──────────────────┼──────────────────────┤")
    overall = get(scores, "overall", 0.0)
    bar = "█" ^ div(Int(round(overall)), 5) * "░" ^ (20 - div(Int(round(overall)), 5))
    println("│ $(rpad("OVERALL", 16)) │ $bar $(lpad(Int(round(overall)), 3)) │")
    println("└──────────────────┴──────────────────────┘")

    if haskey(scores, "scored_at")
        println("\nScored: $(scores["scored_at"])")
    end
    if haskey(scores, "rationale") && !isempty(scores["rationale"])
        println("Rationale: $(scores["rationale"])")
    end
end

function main()
    args = parse_commandline()

    base_url = args["server"]
    user_id = args["user"]

    # Get scores for an item
    if args["get"] && !isnothing(args["item"])
        item_key = args["item"]
        status, data = api_get(base_url, "/users/$user_id/items/$item_key/prompt-scores")

        if status == 200
            print_scores(data["scores"])
        elseif status == 404
            println("No PROMPT scores for item $item_key")
            println("Use --provenance, --methodology, etc. to set scores")
        else
            println("Error: $(get(data, "error", "Unknown error"))")
            return 1
        end
        return 0
    end

    # List unscored items
    if args["list-unscored"]
        status, items = api_get(base_url, "/users/$user_id/items?hasScore=false&limit=100")
        if status == 200
            println("Items without PROMPT scores:")
            println("─" ^ 50)
            for item in items
                key = item["key"]
                title = get(get(item, "data", Dict()), "title", "Untitled")
                item_type = get(get(item, "data", Dict()), "itemType", "unknown")
                println("  $key  [$item_type] $title")
            end
            println("─" ^ 50)
            println("Total: $(length(items)) items need scoring")
        else
            println("Error fetching items")
            return 1
        end
        return 0
    end

    # List scored items
    if args["list-scored"]
        endpoint = "/users/$user_id/items?hasScore=true"
        if !isnothing(args["min-score"])
            endpoint *= "&minScore=$(args["min-score"])"
        end
        endpoint *= "&limit=100"

        status, items = api_get(base_url, endpoint)
        if status == 200
            println("Items with PROMPT scores:")
            println("─" ^ 60)
            for item in items
                key = item["key"]
                title = get(get(item, "data", Dict()), "title", "Untitled")
                scores = get(item, "promptScores", Dict())
                overall = get(scores, "overall", 0.0)
                println("  $key  [$(lpad(Int(round(overall)), 3))] $title")
            end
            println("─" ^ 60)
            println("Total: $(length(items)) scored items")
        else
            println("Error fetching items")
            return 1
        end
        return 0
    end

    # Set scores for an item
    if !isnothing(args["item"])
        item_key = args["item"]

        # Build scores from arguments
        scores = Dict{String, Any}()

        if !isnothing(args["all"])
            all_val = args["all"]
            if all_val < 0 || all_val > 100
                println("Error: Score must be 0-100")
                return 1
            end
            for dim in PROMPT_DIMENSIONS
                scores[dim] = all_val
            end
        else
            for dim in PROMPT_DIMENSIONS
                val = args[dim]
                if !isnothing(val)
                    if val < 0 || val > 100
                        println("Error: $dim score must be 0-100")
                        return 1
                    end
                    scores[dim] = val
                end
            end
        end

        if isempty(scores)
            println("Error: No scores provided. Use --provenance, --methodology, etc.")
            println("       Or use --all N to set all dimensions at once")
            return 1
        end

        if !isempty(args["rationale"])
            scores["rationale"] = args["rationale"]
        end

        # Submit scores
        status, data = api_put(base_url, "/users/$user_id/items/$item_key/prompt-scores", scores)

        if status == 200
            println("✓ PROMPT scores saved for $item_key")
            print_scores(data["scores"])
        else
            println("Error: $(get(data, "error", "Unknown error"))")
            return 1
        end
        return 0
    end

    # No valid operation specified
    println("Usage: julia bin/score.jl --item KEY [options]")
    println("       julia bin/score.jl --list-unscored")
    println("       julia bin/score.jl --help")
    return 1
end

exit(main())
