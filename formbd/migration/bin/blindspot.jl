# SPDX-License-Identifier: AGPL-3.0-or-later
"""
FormDB Blindspot Detection CLI (v0.4.0)

Analyze your library for potential blind spots in funding sources,
publisher diversity, and methodological quality - inspired by Ground News.

Usage:
    formdb-blindspot                    Show all blindspot analysis
    formdb-blindspot --severity high    Filter by severity
    formdb-blindspot --type funding     Filter by blindspot type
    formdb-blindspot --stats            Show library statistics only
    formdb-blindspot --help             Show this help

Options:
    --severity LEVEL    Filter: high, medium, low
    --type TYPE         Filter: funding_concentration, funding_gap,
                                publisher_concentration, methodology_quality
    --server URL        FormDB server URL (default: http://localhost:8080)
    --user ID           User ID (default: local)

What Blindspots Detect:
    funding_concentration   - >70% of items from single funding source
    funding_gap            - Missing entire funding categories
    publisher_concentration - >50% of items from single publisher
    methodology_quality    - >50% of items with low methodology scores
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

function severity_color(severity::String)
    if severity == "high"
        return RED
    elseif severity == "medium"
        return YELLOW
    else
        return BLUE
    end
end

function type_icon(blindspot_type::String)
    if startswith(blindspot_type, "funding")
        return "💰"
    elseif startswith(blindspot_type, "publisher")
        return "📚"
    elseif startswith(blindspot_type, "methodology")
        return "🔬"
    else
        return "⚠️"
    end
end

function show_blindspots(server::String, user::String;
                        severity_filter::Union{String, Nothing}=nothing,
                        type_filter::Union{String, Nothing}=nothing,
                        stats_only::Bool=false)
    url = "$server/users/$user/blindspots"

    try
        response = HTTP.get(url)
        data = JSON3.read(String(response.body), Dict{String, Any})

        blindspots = get(data, "blindspots", [])
        stats = get(data, "library_stats", Dict())
        high_count = get(data, "high_severity_count", 0)
        medium_count = get(data, "medium_severity_count", 0)
        low_count = get(data, "low_severity_count", 0)

        # Show library statistics
        println("$(BOLD)Library Statistics$(RESET)")
        println("─" ^ 40)
        println("  Total items:          $(get(stats, "total_items", 0))")
        println("  With funding info:    $(get(stats, "items_with_funding", 0))")
        println("  With publisher info:  $(get(stats, "items_with_publisher", 0))")
        println("  With PROMPT scores:   $(get(stats, "items_with_scores", 0))")
        println("  Publishers tracked:   $(get(stats, "publishers_registered", 0))")
        println()

        if stats_only
            return true
        end

        # Summary
        println("$(BOLD)Blindspot Summary$(RESET)")
        println("─" ^ 40)
        if isempty(blindspots)
            println("$(GREEN)✓ No blindspots detected!$(RESET)")
            println()
            println("Your library appears diverse. Keep tracking funding and")
            println("publisher information to maintain this healthy balance.")
            return true
        end

        println("  $(RED)High:$(RESET)   $high_count")
        println("  $(YELLOW)Medium:$(RESET) $medium_count")
        println("  $(BLUE)Low:$(RESET)    $low_count")
        println()

        # Filter blindspots
        filtered = blindspots
        if !isnothing(severity_filter)
            filtered = filter(b -> get(b, "severity", "") == severity_filter, filtered)
        end
        if !isnothing(type_filter)
            filtered = filter(b -> get(b, "type", "") == type_filter, filtered)
        end

        if isempty(filtered)
            println("$(YELLOW)No blindspots match the specified filters.$(RESET)")
            return true
        end

        # Group by type
        println("$(BOLD)Detected Blindspots$(RESET)")
        println("─" ^ 40)

        # Sort by severity (high first)
        severity_order = Dict("high" => 1, "medium" => 2, "low" => 3)
        sorted = sort(collect(filtered), by=b -> get(severity_order, get(b, "severity", "low"), 4))

        for blindspot in sorted
            btype = get(blindspot, "type", "unknown")
            severity = get(blindspot, "severity", "low")
            message = get(blindspot, "message", "")

            color = severity_color(severity)
            icon = type_icon(btype)

            println()
            println("$icon $(color)[$severity]$(RESET) $(BOLD)$btype$(RESET)")
            println("   $message")

            # Additional details based on type
            if haskey(blindspot, "proportion")
                proportion = blindspot["proportion"]
                println("   Proportion: $(round(proportion, digits=1))%")
            end
            if haskey(blindspot, "category")
                println("   Category: $(blindspot["category"])")
            end
            if haskey(blindspot, "publisher")
                println("   Publisher: $(blindspot["publisher"])")
            end
            if haskey(blindspot, "average_score")
                println("   Average score: $(blindspot["average_score"])")
            end
        end

        println()
        println("$(BOLD)Recommendations$(RESET)")
        println("─" ^ 40)

        # Generate recommendations based on blindspots
        has_funding = any(b -> startswith(get(b, "type", ""), "funding"), blindspots)
        has_publisher = any(b -> startswith(get(b, "type", ""), "publisher"), blindspots)
        has_methodology = any(b -> startswith(get(b, "type", ""), "methodology"), blindspots)

        if has_funding
            println("$(YELLOW)•$(RESET) Diversify funding sources in your reading")
            println("  Consider seeking sources from underrepresented categories")
        end

        if has_publisher
            println("$(YELLOW)•$(RESET) Expand publisher diversity")
            println("  Add sources from different publishers and ownership types")
        end

        if has_methodology
            println("$(YELLOW)•$(RESET) Prioritize methodologically rigorous sources")
            println("  Focus on sources with clear methods and replication")
        end

        if get(stats, "items_with_funding", 0) < get(stats, "total_items", 0) / 2
            println("$(BLUE)•$(RESET) Track more funding information")
            println("  Use: formdb-score --funding ITEM_KEY")
        end

        if get(stats, "publishers_registered", 0) == 0
            println("$(BLUE)•$(RESET) Start building your publisher registry")
            println("  Use: formdb-publisher --add KEY --name NAME")
        end

        return true
    catch e
        if e isa HTTP.ExceptionRequest.StatusError
            println("$(RED)Error:$(RESET) Server returned $(e.status)")
        else
            println("$(RED)Error:$(RESET) Failed to get blindspots: $e")
        end
        return false
    end
end

function show_help()
    println("""
$(BOLD)FormDB Blindspot Detection CLI (v0.4.0)$(RESET)

Analyze your library for potential blind spots in funding sources,
publisher diversity, and methodological quality.

$(BOLD)CONCEPT$(RESET)
Like Ground News shows you when you're only reading news from one
political perspective, FormDB shows you when your academic sources
are too concentrated in:

• Funding sources (e.g., 80% industry-funded)
• Publishers (e.g., 70% from one publisher)
• Methodological quality (e.g., many low-quality sources)

$(BOLD)USAGE$(RESET)
    formdb-blindspot                    Show all blindspot analysis
    formdb-blindspot --severity high    Filter by severity level
    formdb-blindspot --type funding     Filter by blindspot type
    formdb-blindspot --stats            Show library statistics only
    formdb-blindspot --help             Show this help

$(BOLD)OPTIONS$(RESET)
    --severity LEVEL    Filter: high, medium, low
    --type TYPE         Filter by blindspot type (see below)
    --server URL        FormDB server URL (default: http://localhost:8080)
    --user ID           User ID (default: local)

$(BOLD)BLINDSPOT TYPES$(RESET)
    funding_concentration
        Detected when >70% of items are from a single funding source.
        High severity if >85%.

    funding_gap
        Detected when entire funding categories are missing from
        your library (e.g., no government-funded sources).

    publisher_concentration
        Detected when >50% of items are from a single publisher.
        High severity if >70%.

    methodology_quality
        Detected when >50% of items have methodology scores below 50.
        Indicates potential quality concerns.

$(BOLD)EXAMPLES$(RESET)
    # Full blindspot analysis
    formdb-blindspot

    # Show only high-severity issues
    formdb-blindspot --severity high

    # Check only funding-related blindspots
    formdb-blindspot --type funding_concentration

    # Just library statistics
    formdb-blindspot --stats

$(BOLD)FIXING BLINDSPOTS$(RESET)
1. Add funding information to items:
   formdb-score --funding ITEM_KEY

2. Register publishers:
   formdb-publisher --add nature --name "Nature" --ownership commercial_large

3. Score items with PROMPT:
   formdb-score --item KEY --methodology 85 --provenance 90

$(BOLD)SEVERITY LEVELS$(RESET)
    $(RED)high$(RESET)     - Serious concentration (>85% funding, >70% publisher)
    $(YELLOW)medium$(RESET)   - Moderate concentration requiring attention
    $(BLUE)low$(RESET)      - Minor gaps (e.g., missing funding categories)
""")
end

function main()
    args = ARGS

    if "--help" in args || "-h" in args
        show_help()
        return
    end

    # Parse arguments
    server = DEFAULT_SERVER
    user = DEFAULT_USER
    severity_filter = nothing
    type_filter = nothing
    stats_only = false

    i = 1
    while i <= length(args)
        arg = args[i]

        if arg == "--server" && i < length(args)
            server = args[i+1]
            i += 2
        elseif arg == "--user" && i < length(args)
            user = args[i+1]
            i += 2
        elseif arg == "--severity" && i < length(args)
            severity_filter = args[i+1]
            if !(severity_filter in ["high", "medium", "low"])
                println("$(RED)Error:$(RESET) Invalid severity: $severity_filter")
                println("Valid values: high, medium, low")
                return
            end
            i += 2
        elseif arg == "--type" && i < length(args)
            type_filter = args[i+1]
            i += 2
        elseif arg == "--stats"
            stats_only = true
            i += 1
        else
            println("$(RED)Error:$(RESET) Unknown argument: $arg")
            println("Use --help for usage information.")
            return
        end
    end

    success = show_blindspots(server, user;
                             severity_filter=severity_filter,
                             type_filter=type_filter,
                             stats_only=stats_only)

    exit(success ? 0 : 1)
end

main()
