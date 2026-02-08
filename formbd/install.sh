#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-or-later
#
# FormDB for Zotero - Safe Installer
#
# This script sets up FormDB as a provenance-tracked mirror of your Zotero library.
# It NEVER modifies your Zotero data - only creates a separate FormDB copy.
#
# What it does:
#   1. Checks prerequisites (Julia, Zotero database)
#   2. Sets up FormDB in ~/.formdb/zotero/
#   3. Migrates your Zotero library (read-only copy)
#   4. Installs convenience commands
#
# Safe by design:
#   - Dry-run by default (use --apply to actually install)
#   - Never modifies Zotero's database
#   - Shows exactly what it will do before doing it
#   - Creates uninstall script for easy removal
#
# Usage:
#   curl -sSL https://raw.githubusercontent.com/hyperpolymath/zotero-formdb/main/install.sh | bash
#   # or
#   ./install.sh           # Dry run - shows what would happen
#   ./install.sh --apply   # Actually install
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Configuration
FORMDB_HOME="${FORMDB_HOME:-$HOME/.formdb}"
FORMDB_ZOTERO="$FORMDB_HOME/zotero"
FORMDB_REPO="$FORMDB_HOME/repo"
REPO_URL="https://github.com/hyperpolymath/zotero-formdb.git"

# State
DRY_RUN=true
VERBOSE=false
FORCE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --apply)
            DRY_RUN=false
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --force|-f)
            FORCE=true
            shift
            ;;
        --uninstall)
            exec "$0" --do-uninstall
            ;;
        --do-uninstall)
            # Uninstall mode
            echo -e "${YELLOW}Uninstalling FormDB for Zotero...${NC}"
            echo
            echo "This will remove:"
            echo "  - $FORMDB_HOME (FormDB data and repo)"
            echo "  - ~/.local/bin/formdb-* commands"
            echo
            echo "Your Zotero library is NOT affected."
            echo
            read -p "Continue? [y/N] " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rm -rf "$FORMDB_HOME"
                rm -f ~/.local/bin/formdb-server
                rm -f ~/.local/bin/formdb-sync
                rm -f ~/.local/bin/formdb-migrate
                rm -f ~/.local/bin/formdb-score
                rm -f ~/.local/bin/formdb-doi
                rm -f ~/.local/bin/formdb-publisher
                rm -f ~/.local/bin/formdb-blindspot
                echo -e "${GREEN}✓ FormDB uninstalled${NC}"
            else
                echo "Cancelled."
            fi
            exit 0
            ;;
        --help|-h)
            echo "FormDB for Zotero - Safe Installer"
            echo
            echo "Usage: $0 [options]"
            echo
            echo "Options:"
            echo "  --apply      Actually install (default is dry-run)"
            echo "  --verbose    Show detailed output"
            echo "  --force      Skip confirmations"
            echo "  --uninstall  Remove FormDB installation"
            echo "  --help       Show this help"
            echo
            echo "Environment:"
            echo "  FORMDB_HOME  Installation directory (default: ~/.formdb)"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

log_step() {
    echo -e "${CYAN}▶${NC} ${BOLD}$1${NC}"
}

dry_run_note() {
    if $DRY_RUN; then
        echo -e "  ${YELLOW}(dry run - would execute)${NC}"
    fi
}

# Find Zotero database
find_zotero_db() {
    local paths=(
        "$HOME/Zotero/zotero.sqlite"
        "$HOME/.zotero/zotero/zotero.sqlite"
        "$HOME/snap/zotero-snap/common/Zotero/zotero.sqlite"
        "$HOME/.var/app/org.zotero.Zotero/data/zotero/zotero.sqlite"
    )

    for path in "${paths[@]}"; do
        if [[ -f "$path" ]]; then
            echo "$path"
            return 0
        fi
    done

    # Try to find it
    local found
    found=$(find "$HOME" -name "zotero.sqlite" -type f 2>/dev/null | head -1)
    if [[ -n "$found" ]]; then
        echo "$found"
        return 0
    fi

    return 1
}

# Check prerequisites
check_prerequisites() {
    log_step "Checking prerequisites..."
    echo

    local all_ok=true

    # Check Julia
    if command -v julia &> /dev/null; then
        local julia_version
        julia_version=$(julia --version | cut -d' ' -f3)
        log_success "Julia $julia_version found"
    else
        log_error "Julia not found"
        echo "  Install from: https://julialang.org/downloads/"
        all_ok=false
    fi

    # Check Git
    if command -v git &> /dev/null; then
        log_success "Git found"
    else
        log_error "Git not found"
        all_ok=false
    fi

    # Check Zotero database
    ZOTERO_DB=$(find_zotero_db || true)
    if [[ -n "$ZOTERO_DB" ]]; then
        local db_size
        db_size=$(du -h "$ZOTERO_DB" | cut -f1)
        log_success "Zotero database found: $ZOTERO_DB ($db_size)"
    else
        log_error "Zotero database not found"
        echo "  Make sure Zotero is installed and has been run at least once"
        all_ok=false
    fi

    # Check disk space
    local available_space
    available_space=$(df -h "$HOME" | awk 'NR==2 {print $4}')
    log_info "Available disk space: $available_space"

    echo
    if $all_ok; then
        return 0
    else
        return 1
    fi
}

# Show installation plan
show_plan() {
    echo
    echo -e "${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║          FormDB for Zotero - Installation Plan               ║${NC}"
    echo -e "${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo

    echo -e "${BOLD}What will be created:${NC}"
    echo "  📁 $FORMDB_HOME/"
    echo "     ├── repo/          # FormDB source code"
    echo "     └── zotero/        # Your library mirror"
    echo "         ├── journal.jsonl  # Provenance-tracked data"
    echo "         └── index.json     # Fast lookup index"
    echo

    echo -e "${BOLD}Commands that will be installed:${NC}"
    echo "  🔧 formdb-server    - Start the Zotero-compatible API server"
    echo "  🔧 formdb-sync      - Sync changes from Zotero"
    echo "  🔧 formdb-migrate   - Re-run full migration"
    echo "  🔧 formdb-score     - PROMPT evidence quality scoring (v0.2.0)"
    echo "  🔧 formdb-doi       - DOI immutability management (v0.3.0)"
    echo "  🔧 formdb-publisher - Publisher registry management (v0.4.0)"
    echo "  🔧 formdb-blindspot - Library blindspot analysis (v0.4.0)"
    echo

    echo -e "${BOLD}What will NOT be modified:${NC}"
    echo "  ✓ Your Zotero database (read-only access)"
    echo "  ✓ Your Zotero settings"
    echo "  ✓ Your Zotero sync"
    echo

    echo -e "${BOLD}Source:${NC}"
    echo "  📦 Zotero DB: $ZOTERO_DB"
    echo

    if $DRY_RUN; then
        echo -e "${YELLOW}This is a DRY RUN. No changes will be made.${NC}"
        echo -e "${YELLOW}Run with --apply to actually install.${NC}"
    fi
    echo
}

# Clone or update repo
setup_repo() {
    log_step "Setting up FormDB repository..."
    dry_run_note

    if $DRY_RUN; then
        echo "  Would clone $REPO_URL to $FORMDB_REPO"
        return 0
    fi

    mkdir -p "$FORMDB_HOME"

    if [[ -d "$FORMDB_REPO/.git" ]]; then
        log_info "Updating existing repository..."
        cd "$FORMDB_REPO"
        git pull --quiet
        log_success "Repository updated"
    else
        log_info "Cloning repository..."
        git clone --quiet "$REPO_URL" "$FORMDB_REPO"
        log_success "Repository cloned"
    fi
}

# Install Julia dependencies
setup_julia() {
    log_step "Installing Julia dependencies..."
    dry_run_note

    if $DRY_RUN; then
        echo "  Would run: julia --project=$FORMDB_REPO/migration -e 'using Pkg; Pkg.instantiate()'"
        return 0
    fi

    cd "$FORMDB_REPO/migration"
    julia --project=. -e 'using Pkg; Pkg.instantiate()' 2>&1 | while read -r line; do
        if $VERBOSE; then
            echo "  $line"
        fi
    done
    log_success "Julia dependencies installed"
}

# Run migration
run_migration() {
    log_step "Migrating Zotero library to FormDB..."
    dry_run_note

    if $DRY_RUN; then
        echo "  Would run migration from $ZOTERO_DB"
        echo "  Output would go to $FORMDB_ZOTERO/"
        return 0
    fi

    mkdir -p "$FORMDB_ZOTERO"

    cd "$FORMDB_REPO/migration"

    log_info "This may take a minute for large libraries..."
    echo

    julia --project=. bin/migrate.jl \
        --from "$ZOTERO_DB" \
        --to "$FORMDB_ZOTERO" \
        --apply

    echo
    log_success "Migration complete"

    # Show stats
    if [[ -f "$FORMDB_ZOTERO/journal.jsonl" ]]; then
        local journal_size
        local entry_count
        journal_size=$(du -h "$FORMDB_ZOTERO/journal.jsonl" | cut -f1)
        entry_count=$(wc -l < "$FORMDB_ZOTERO/journal.jsonl")
        log_info "Journal: $journal_size ($entry_count entries)"
    fi
}

# Install convenience commands
install_commands() {
    log_step "Installing convenience commands..."
    dry_run_note

    local bin_dir="$HOME/.local/bin"

    if $DRY_RUN; then
        echo "  Would create: $bin_dir/formdb-server"
        echo "  Would create: $bin_dir/formdb-sync"
        echo "  Would create: $bin_dir/formdb-migrate"
        echo "  Would create: $bin_dir/formdb-score"
        echo "  Would create: $bin_dir/formdb-doi"
        echo "  Would create: $bin_dir/formdb-publisher"
        echo "  Would create: $bin_dir/formdb-blindspot"
        return 0
    fi

    mkdir -p "$bin_dir"

    # formdb-server
    cat > "$bin_dir/formdb-server" << 'SCRIPT'
#!/usr/bin/env bash
# Start FormDB server with Zotero-compatible API
FORMDB_HOME="${FORMDB_HOME:-$HOME/.formdb}"
cd "$FORMDB_HOME/repo/migration"
exec julia --project=. bin/server.jl \
    --journal "$FORMDB_HOME/zotero" \
    "$@"
SCRIPT
    chmod +x "$bin_dir/formdb-server"

    # formdb-sync
    cat > "$bin_dir/formdb-sync" << 'SCRIPT'
#!/usr/bin/env bash
# Sync from Zotero's local API to FormDB
FORMDB_HOME="${FORMDB_HOME:-$HOME/.formdb}"
cd "$FORMDB_HOME/repo/migration"
exec julia --project=. bin/sync.jl \
    --journal "$FORMDB_HOME/zotero" \
    "$@"
SCRIPT
    chmod +x "$bin_dir/formdb-sync"

    # formdb-migrate
    cat > "$bin_dir/formdb-migrate" << 'SCRIPT'
#!/usr/bin/env bash
# Re-run full migration from Zotero SQLite
FORMDB_HOME="${FORMDB_HOME:-$HOME/.formdb}"

# Find Zotero database
ZOTERO_DB=""
for path in "$HOME/Zotero/zotero.sqlite" \
            "$HOME/.zotero/zotero/zotero.sqlite" \
            "$HOME/snap/zotero-snap/common/Zotero/zotero.sqlite"; do
    if [[ -f "$path" ]]; then
        ZOTERO_DB="$path"
        break
    fi
done

if [[ -z "$ZOTERO_DB" ]]; then
    echo "Error: Zotero database not found"
    exit 1
fi

cd "$FORMDB_HOME/repo/migration"
exec julia --project=. bin/migrate.jl \
    --from "$ZOTERO_DB" \
    --to "$FORMDB_HOME/zotero" \
    "$@"
SCRIPT
    chmod +x "$bin_dir/formdb-migrate"

    # formdb-score (v0.2.0)
    cat > "$bin_dir/formdb-score" << 'SCRIPT'
#!/usr/bin/env bash
# PROMPT evidence quality scoring
FORMDB_HOME="${FORMDB_HOME:-$HOME/.formdb}"
cd "$FORMDB_HOME/repo/migration"
exec julia --project=. bin/score.jl "$@"
SCRIPT
    chmod +x "$bin_dir/formdb-score"

    # formdb-doi (v0.3.0)
    cat > "$bin_dir/formdb-doi" << 'SCRIPT'
#!/usr/bin/env bash
# DOI immutability management
FORMDB_HOME="${FORMDB_HOME:-$HOME/.formdb}"
cd "$FORMDB_HOME/repo/migration"
exec julia --project=. bin/doi.jl "$@"
SCRIPT
    chmod +x "$bin_dir/formdb-doi"

    # formdb-publisher (v0.4.0)
    cat > "$bin_dir/formdb-publisher" << 'SCRIPT'
#!/usr/bin/env bash
# Publisher registry management
FORMDB_HOME="${FORMDB_HOME:-$HOME/.formdb}"
cd "$FORMDB_HOME/repo/migration"
exec julia --project=. bin/publisher.jl "$@"
SCRIPT
    chmod +x "$bin_dir/formdb-publisher"

    # formdb-blindspot (v0.4.0)
    cat > "$bin_dir/formdb-blindspot" << 'SCRIPT'
#!/usr/bin/env bash
# Library blindspot analysis
FORMDB_HOME="${FORMDB_HOME:-$HOME/.formdb}"
cd "$FORMDB_HOME/repo/migration"
exec julia --project=. bin/blindspot.jl "$@"
SCRIPT
    chmod +x "$bin_dir/formdb-blindspot"

    log_success "Commands installed to $bin_dir/"

    # Check if bin is in PATH
    if [[ ":$PATH:" != *":$bin_dir:"* ]]; then
        log_warn "$bin_dir is not in your PATH"
        echo "  Add this to your ~/.bashrc or ~/.zshrc:"
        echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
}

# Create uninstall script
create_uninstall() {
    if $DRY_RUN; then
        return 0
    fi

    cat > "$FORMDB_HOME/uninstall.sh" << 'SCRIPT'
#!/usr/bin/env bash
# Uninstall FormDB for Zotero
echo "This will remove FormDB installation."
echo "Your Zotero library will NOT be affected."
echo
read -p "Continue? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf "$HOME/.formdb"
    rm -f "$HOME/.local/bin/formdb-server"
    rm -f "$HOME/.local/bin/formdb-sync"
    rm -f "$HOME/.local/bin/formdb-migrate"
    rm -f "$HOME/.local/bin/formdb-score"
    rm -f "$HOME/.local/bin/formdb-doi"
    rm -f "$HOME/.local/bin/formdb-publisher"
    rm -f "$HOME/.local/bin/formdb-blindspot"
    echo "FormDB uninstalled."
fi
SCRIPT
    chmod +x "$FORMDB_HOME/uninstall.sh"
}

# Show completion message
show_complete() {
    echo
    echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║              Installation Complete! 🎉                        ║${NC}"
    echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo

    echo -e "${BOLD}Your FormDB installation:${NC}"
    echo "  📁 Data:    $FORMDB_ZOTERO/"
    echo "  📁 Repo:    $FORMDB_REPO/"
    echo

    echo -e "${BOLD}Available commands:${NC}"
    echo "  formdb-server         # Start API server (port 8080)"
    echo "  formdb-sync           # Sync from running Zotero"
    echo "  formdb-migrate --apply  # Re-run full migration"
    echo "  formdb-score          # PROMPT evidence scoring (v0.2.0)"
    echo "  formdb-doi            # DOI management (v0.3.0)"
    echo "  formdb-publisher      # Publisher registry (v0.4.0)"
    echo "  formdb-blindspot      # Blindspot analysis (v0.4.0)"
    echo

    echo -e "${BOLD}Quick start:${NC}"
    echo "  # Start the server"
    echo "  formdb-server"
    echo
    echo "  # Query your library"
    echo "  curl http://localhost:8080/users/local/items"
    echo

    echo -e "${BOLD}To uninstall:${NC}"
    echo "  $FORMDB_HOME/uninstall.sh"
    echo "  # or: $0 --uninstall"
    echo
}

# Main installation flow
main() {
    echo
    echo -e "${BOLD}FormDB for Zotero - Safe Installer${NC}"
    echo -e "═══════════════════════════════════"
    echo

    if $DRY_RUN; then
        echo -e "${YELLOW}DRY RUN MODE - No changes will be made${NC}"
        echo
    fi

    # Check prerequisites
    if ! check_prerequisites; then
        log_error "Prerequisites not met. Please install missing dependencies."
        exit 1
    fi

    # Show plan
    show_plan

    # Confirm if not dry run and not forced
    if ! $DRY_RUN && ! $FORCE; then
        read -p "Proceed with installation? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Installation cancelled."
            exit 0
        fi
        echo
    fi

    # Run installation steps
    setup_repo
    echo

    setup_julia
    echo

    run_migration
    echo

    install_commands
    echo

    create_uninstall

    if ! $DRY_RUN; then
        show_complete
    else
        echo
        echo -e "${YELLOW}DRY RUN complete. Run with --apply to install.${NC}"
        echo
    fi
}

main
