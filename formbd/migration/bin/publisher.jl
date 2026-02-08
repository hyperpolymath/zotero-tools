# SPDX-License-Identifier: AGPL-3.0-or-later
"""
FormDB Publisher Management CLI (v0.4.0)

Manage publishers and their quality scores in your FormDB library.
Inspired by Ground News bias/factuality tracking for academic sources.

Usage:
    formdb-publisher --list                     List all publishers
    formdb-publisher --show KEY                 Show publisher details
    formdb-publisher --add KEY --name NAME      Add a new publisher
    formdb-publisher --score KEY                Score a publisher
    formdb-publisher --link ITEM_KEY PUB_KEY    Link an item to a publisher
    formdb-publisher --help                     Show this help

Options:
    --ownership TYPE      Ownership category (see below)
    --website URL         Publisher website
    --server URL          FormDB server URL (default: http://localhost:8080)
    --user ID             User ID (default: local)

Ownership Categories:
    academic_society    - Learned society (ACS, IEEE, etc.)
    university_press    - University-owned press
    commercial_large    - Large commercial (Elsevier, Springer, Wiley)
    commercial_small    - Smaller commercial publishers
    open_access         - Pure OA publishers (PLOS, MDPI, Frontiers)
    government          - Government publishers
    independent         - Independent/nonprofit
    predatory           - Known predatory publishers
    unknown             - Classification unknown

Publisher Quality Dimensions (0-100):
    peer_review_rigor   - Quality of peer review process
    retraction_rate     - Inverse: lower retraction rate = higher score
    transparency        - Editorial transparency
    reproducibility     - Support for reproducibility
    accessibility       - Open access policies
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

const OWNERSHIP_CATEGORIES = [
    "academic_society", "university_press", "commercial_large",
    "commercial_small", "open_access", "government", "independent",
    "predatory", "unknown"
]

const PUBLISHER_DIMENSIONS = [
    "peer_review_rigor", "retraction_rate", "transparency",
    "reproducibility", "accessibility"
]

function list_publishers(server::String, user::String)
    url = "$server/users/$user/publishers"

    try
        response = HTTP.get(url)
        publishers = JSON3.read(String(response.body), Vector{Dict{String, Any}})

        if isempty(publishers)
            println("$(YELLOW)No publishers registered yet.$(RESET)")
            println("\nAdd publishers with:")
            println("  formdb-publisher --add nature --name \"Nature Publishing Group\" --ownership commercial_large")
            return true
        end

        println("$(BOLD)Publishers in Registry:$(RESET)")
        println()

        for pub in publishers
            key = get(pub, "key", "")
            name = get(pub, "name", key)
            ownership = get(pub, "ownership", "unknown")
            item_count = get(pub, "itemCount", 0)

            # Color-code by ownership type
            ownership_color = if ownership == "predatory"
                RED
            elseif ownership in ["academic_society", "university_press"]
                GREEN
            elseif ownership in ["commercial_large", "commercial_small"]
                YELLOW
            else
                CYAN
            end

            println("$(CYAN)$key$(RESET) │ $name")
            println("       │ $(ownership_color)$ownership$(RESET) │ $item_count items")

            # Show scores if available
            scores = get(pub, "scores", nothing)
            if !isnothing(scores)
                overall = get(scores, "overall", 0.0)
                println("       │ Score: $(round(overall, digits=1))/100")
            end
            println()
        end

        println("$(BOLD)Total:$(RESET) $(length(publishers)) publisher(s)")
        return true
    catch e
        println("$(RED)Error:$(RESET) Failed to list publishers: $e")
        return false
    end
end

function show_publisher(server::String, user::String, key::String)
    url = "$server/users/$user/publishers/$key"

    try
        response = HTTP.get(url)
        pub = JSON3.read(String(response.body), Dict{String, Any})

        name = get(pub, "name", key)
        ownership = get(pub, "ownership", "unknown")
        website = get(pub, "website", "")
        item_count = get(pub, "itemCount", 0)
        items = get(pub, "items", [])

        println("$(BOLD)Publisher:$(RESET) $name")
        println("$(BOLD)Key:$(RESET) $key")
        println("$(BOLD)Ownership:$(RESET) $ownership")
        if !isempty(website)
            println("$(BOLD)Website:$(RESET) $website")
        end
        println("$(BOLD)Items:$(RESET) $item_count")
        println()

        scores = get(pub, "scores", nothing)
        if !isnothing(scores)
            println("$(BOLD)Quality Scores:$(RESET)")
            for dim in PUBLISHER_DIMENSIONS
                if haskey(scores, dim)
                    val = scores[dim]
                    color = val >= 80 ? GREEN : val >= 50 ? YELLOW : RED
                    println("  $dim: $color$val$(RESET)")
                end
            end
            overall = get(scores, "overall", 0.0)
            println("  $(BOLD)Overall: $(round(overall, digits=1))$(RESET)")
        else
            println("$(YELLOW)No quality scores yet.$(RESET)")
            println("Score with: formdb-publisher --score $key")
        end

        if !isempty(items)
            println("\n$(BOLD)Items from this publisher:$(RESET)")
            for item_key in items[1:min(10, length(items))]
                println("  • $item_key")
            end
            if length(items) > 10
                println("  ... and $(length(items) - 10) more")
            end
        end

        return true
    catch e
        if e isa HTTP.ExceptionRequest.StatusError && e.status == 404
            println("$(RED)Error:$(RESET) Publisher not found: $key")
        else
            println("$(RED)Error:$(RESET) Failed to get publisher: $e")
        end
        return false
    end
end

function add_publisher(server::String, user::String, key::String, name::String, ownership::String, website::String)
    url = "$server/users/$user/publishers/$key"

    if !(ownership in OWNERSHIP_CATEGORIES)
        println("$(RED)Error:$(RESET) Invalid ownership category: $ownership")
        println("Valid categories: $(join(OWNERSHIP_CATEGORIES, ", "))")
        return false
    end

    body = Dict(
        "name" => name,
        "ownership" => ownership,
        "website" => website
    )

    try
        response = HTTP.put(url,
            ["Content-Type" => "application/json"],
            JSON3.write(body))

        println("$(GREEN)✓$(RESET) Publisher added: $name")
        println("  Key: $key")
        println("  Ownership: $ownership")
        if !isempty(website)
            println("  Website: $website")
        end
        println("\nNext steps:")
        println("  • Score quality: formdb-publisher --score $key")
        println("  • Link items: formdb-publisher --link ITEM_KEY $key")

        return true
    catch e
        println("$(RED)Error:$(RESET) Failed to add publisher: $e")
        return false
    end
end

function score_publisher(server::String, user::String, key::String)
    println("$(BOLD)Score Publisher: $key$(RESET)")
    println("Enter scores 0-100 for each dimension (or press Enter to skip):")
    println()

    scores = Dict{String, Any}()

    for dim in PUBLISHER_DIMENSIONS
        print("$dim: ")
        input = readline()
        if !isempty(strip(input))
            try
                val = parse(Float64, input)
                if val < 0 || val > 100
                    println("$(YELLOW)Skipping: must be 0-100$(RESET)")
                else
                    scores[dim] = val
                end
            catch
                println("$(YELLOW)Skipping: invalid number$(RESET)")
            end
        end
    end

    if isempty(scores)
        println("$(YELLOW)No scores entered.$(RESET)")
        return false
    end

    print("Rationale for scores: ")
    rationale = readline()
    scores["rationale"] = rationale

    url = "$server/users/$user/publishers/$key/scores"

    try
        response = HTTP.put(url,
            ["Content-Type" => "application/json"],
            JSON3.write(scores))

        data = JSON3.read(String(response.body), Dict{String, Any})
        overall = get(get(data, "scores", Dict()), "overall", 0.0)

        println()
        println("$(GREEN)✓$(RESET) Publisher scored successfully!")
        println("  Overall: $(round(overall, digits=1))/100")

        return true
    catch e
        println("$(RED)Error:$(RESET) Failed to score publisher: $e")
        return false
    end
end

function link_item_to_publisher(server::String, user::String, item_key::String, pub_key::String)
    # This would require a new endpoint - for now, inform the user
    println("$(YELLOW)Note:$(RESET) Item-publisher linking is done through the API.")
    println()
    println("Use curl or the API directly:")
    println("  curl -X PUT \"$server/users/$user/items/$item_key\" \\")
    println("       -H \"Content-Type: application/json\" \\")
    println("       -d '{\"publisher\": \"$pub_key\"}'")

    return true
end

function show_help()
    println("""
$(BOLD)FormDB Publisher Management CLI (v0.4.0)$(RESET)

Manage publishers and their quality scores in your FormDB library.
Inspired by Ground News bias/factuality tracking for academic sources.

$(BOLD)USAGE$(RESET)
    formdb-publisher --list                     List all publishers
    formdb-publisher --show KEY                 Show publisher details
    formdb-publisher --add KEY --name NAME      Add a new publisher
    formdb-publisher --score KEY                Score a publisher interactively
    formdb-publisher --link ITEM_KEY PUB_KEY    Link an item to a publisher
    formdb-publisher --help                     Show this help

$(BOLD)OPTIONS$(RESET)
    --ownership TYPE      Ownership category
    --website URL         Publisher website
    --server URL          FormDB server URL (default: http://localhost:8080)
    --user ID             User ID (default: local)

$(BOLD)OWNERSHIP CATEGORIES$(RESET)
    academic_society    Learned society (ACS, IEEE, etc.)
    university_press    University-owned press
    commercial_large    Large commercial (Elsevier, Springer, Wiley)
    commercial_small    Smaller commercial publishers
    open_access         Pure OA publishers (PLOS, MDPI, Frontiers)
    government          Government publishers
    independent         Independent/nonprofit
    predatory           Known predatory publishers
    unknown             Classification unknown

$(BOLD)QUALITY DIMENSIONS$(RESET) (0-100)
    peer_review_rigor   Quality of peer review process
    retraction_rate     Inverse: lower retraction rate = higher score
    transparency        Editorial transparency
    reproducibility     Support for reproducibility
    accessibility       Open access policies

$(BOLD)EXAMPLES$(RESET)
    # Add Nature Publishing Group
    formdb-publisher --add nature --name "Nature Publishing Group" \\
                     --ownership commercial_large --website https://www.nature.com

    # Score a publisher interactively
    formdb-publisher --score nature

    # List all registered publishers
    formdb-publisher --list

$(BOLD)WHY THIS MATTERS$(RESET)
Like Ground News tracks media bias and ownership, FormDB tracks publisher
quality for academic sources. This helps identify:

• Publisher concentration in your library
• Quality distribution across your sources
• Potential blind spots (e.g., over-reliance on predatory publishers)
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
    ownership = "unknown"
    website = ""

    i = 1
    action = nothing
    action_args = String[]

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
        elseif arg == "--ownership" && i < length(args)
            ownership = args[i+1]
            i += 2
        elseif arg == "--website" && i < length(args)
            website = args[i+1]
            i += 2
        elseif arg == "--list"
            action = :list
            i += 1
        elseif arg == "--show" && i < length(args)
            action = :show
            push!(action_args, args[i+1])
            i += 2
        elseif arg == "--add" && i < length(args)
            action = :add
            push!(action_args, args[i+1])
            i += 2
        elseif arg == "--score" && i < length(args)
            action = :score
            push!(action_args, args[i+1])
            i += 2
        elseif arg == "--link" && i + 1 < length(args)
            action = :link
            push!(action_args, args[i+1])
            push!(action_args, args[i+2])
            i += 3
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
    success = if action == :list
        list_publishers(server, user)
    elseif action == :show
        show_publisher(server, user, action_args[1])
    elseif action == :add
        if isempty(name)
            println("$(RED)Error:$(RESET) --name is required when adding a publisher")
            false
        else
            add_publisher(server, user, action_args[1], name, ownership, website)
        end
    elseif action == :score
        score_publisher(server, user, action_args[1])
    elseif action == :link
        link_item_to_publisher(server, user, action_args[1], action_args[2])
    else
        false
    end

    exit(success ? 0 : 1)
end

main()
