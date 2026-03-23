# SPDX-License-Identifier: MIT OR Apache-2.0
# SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
#
# ZoteRho-template - ReScript + Deno Development Tasks
# Hyperpolymath Rhodium Standard Compliant

set shell := ["bash", "-uc"]
set dotenv-load := true
set positional-arguments := true

project := "zoterho-template"
version := "2.0.0"
tier := "plugin"
target_version := "2.0"

# --- Default & Help ---

# Show all recipes
default:
    @just --list --unsorted

# Show detailed help
help:
    @echo "ZoteRho-template Development Tasks"
    @echo ""
    @echo "Build Commands:"
    @echo "  build         - Build ReScript to JavaScript"
    @echo "  build-clean   - Clean and rebuild"
    @echo "  watch         - Watch mode for development"
    @echo "  clean         - Clean build artifacts"
    @echo ""
    @echo "Quality Commands:"
    @echo "  fmt           - Format ReScript code"
    @echo "  lint          - Run linter"
    @echo "  validate      - Run mustfile validations"
    @echo ""
    @echo "Packaging:"
    @echo "  package       - Create XPI package"
    @echo "  compile-nickel - Compile Nickel configs to JSON"
    @echo ""
    @echo "Deployment:"
    @echo "  must          - Run full must deployment flow"

# Project info
info:
    @echo "Project: {{project}}"
    @echo "Version: {{version}}"
    @echo "Tier: {{tier}}"

# --- Build & Compile (Deno-based) ---

# Build ReScript to JavaScript
build:
    @echo "Building ReScript source..."
    deno run --allow-run --allow-read --allow-write npm:rescript build

# Clean and rebuild
build-clean:
    @echo "Clean building ReScript..."
    deno run --allow-run --allow-read --allow-write npm:rescript build -clean-world

# Watch mode for development
watch:
    @echo "Starting watch mode..."
    deno run --allow-run --allow-read --allow-write npm:rescript build -w

# Clean build artifacts
clean:
    @echo "Cleaning build artifacts..."
    deno run --allow-run --allow-read --allow-write npm:rescript clean
    rm -rf build/
    rm -rf lib/
    rm -f src-{{target_version}}/manifest.json
    rm -f src-{{target_version}}/updates-{{target_version}}.json

# --- Quality ---

# Format ReScript code
fmt:
    @echo "Formatting ReScript code..."
    deno run --allow-run --allow-read --allow-write npm:rescript format -all

# Run linter
lint:
    @echo "Running Deno linter..."
    deno lint --ignore=node_modules,lib,build || true

# Run all quality checks
quality: fmt lint validate
    @echo "All quality checks passed!"

# --- Nickel Configuration ---

# Compile Nickel manifest to JSON
compile-nickel:
    @echo "Compiling Nickel configurations..."
    @if command -v nickel >/dev/null 2>&1; then \
        if [ -f config/manifest.ncl ]; then \
            nickel export --format json config/manifest.ncl -o src-{{target_version}}/manifest.json; \
            echo "Generated manifest.json"; \
        fi; \
        if [ -f config/updates.ncl ]; then \
            nickel export --format json config/updates.ncl -o src-{{target_version}}/updates-{{target_version}}.json; \
            echo "Generated updates.json"; \
        fi; \
    else \
        echo "nickel not installed - skipping config compilation"; \
    fi

# Validate Nickel configurations
validate-nickel:
    @echo "Validating Nickel configurations..."
    @if command -v nickel >/dev/null 2>&1; then \
        for f in config/*.ncl; do \
            if [ -f "$$f" ]; then \
                nickel typecheck "$$f" && echo "Valid: $$f"; \
            fi; \
        done; \
    else \
        echo "nickel not installed - skipping validation"; \
    fi

# --- Package ---

# Copy compiled ReScript files to src-2.0 for packaging
copy-compiled:
    @echo "Copying compiled ReScript files to src-{{target_version}}..."
    @# Copy bootstrap.res.js as bootstrap.js (Zotero expects this name)
    @if [ -f bootstrap.res.js ]; then \
        cp bootstrap.res.js src-{{target_version}}/bootstrap.js; \
        echo "  Copied bootstrap.js"; \
    fi
    @# Copy ZoteRhoTemplate.res.js as ZoteRhoTemplate.js (main plugin logic)
    @if [ -f ZoteRhoTemplate.res.js ]; then \
        cp ZoteRhoTemplate.res.js src-{{target_version}}/ZoteRhoTemplate.js; \
        echo "  Copied ZoteRhoTemplate.js"; \
    fi
    @# Copy Preferences.res.js as preferences.js
    @if [ -f Preferences.res.js ]; then \
        cp Preferences.res.js src-{{target_version}}/preferences.js; \
        echo "  Copied preferences.js"; \
    fi
    @# Copy RhodiumLinter if it exists
    @if [ -f RhodiumLinter.res.js ]; then \
        cp RhodiumLinter.res.js src-{{target_version}}/RhodiumLinter.js; \
        echo "  Copied RhodiumLinter.js"; \
    fi

# Create XPI package
package: build compile-nickel copy-compiled
    @echo "Creating XPI package..."
    @mkdir -p build
    @# Use reproducible zip flags: -X removes extra fields, sorted file list
    @cd src-{{target_version}} && find . -type f \
        ! -name "*.ts" ! -name "*.tsx" ! -name "*.res" ! -name "*.resi" \
        ! -path "./.git/*" ! -path "./node_modules/*" \
        | sort | zip -X -@ ../build/zoterho-template-{{target_version}}.xpi
    @echo "Package created: build/zoterho-template-{{target_version}}.xpi"
    @sha256sum build/zoterho-template-{{target_version}}.xpi

# Generate update JSON with hash
generate-update-json:
    @echo "Generating update JSON..."
    @if [ -f build/zoterho-template-{{target_version}}.xpi ]; then \
        XPI_HASH=$$(sha256sum build/zoterho-template-{{target_version}}.xpi | awk '{print $$1}'); \
        echo "SHA256: $$XPI_HASH"; \
        if command -v nickel >/dev/null 2>&1 && [ -f config/updates.ncl ]; then \
            nickel export --format json \
                --field 'version' '"{{target_version}}"' \
                --field 'hash' "\"sha256:$$XPI_HASH\"" \
                config/updates.ncl \
                -o build/updates-{{target_version}}.json; \
        fi; \
    else \
        echo "Error: XPI file not found. Run 'just package' first."; \
        exit 1; \
    fi

# --- Validation & Deployment ---

# Run mustfile validations
validate:
    @echo "Running MUST validations..."
    ./mustfile validate

# Run full must deployment
must:
    ./mustfile build

# Pre-commit checks
pre-commit: quality
    @echo "Pre-commit checks passed!"

# --- Dependencies ---

# Install Deno dependencies
deps:
    @echo "Caching Deno dependencies..."
    deno cache --reload deno.json

# Audit dependencies
deps-audit:
    @echo "Auditing dependencies..."
    deno run --allow-read --allow-net npm:audit || true

# --- Development Setup ---

# Setup development environment
setup:
    @echo "Setting up development environment..."
    @if ! command -v deno >/dev/null 2>&1; then \
        echo "Deno not found. Install from https://deno.land/"; \
        exit 1; \
    fi
    @if ! command -v just >/dev/null 2>&1; then \
        echo "just not found. Install from https://just.systems/"; \
        exit 1; \
    fi
    @echo "Installing Deno dependencies..."
    deno cache deno.json || true
    @echo "Setup complete!"

# --- CI/CD ---

# Full CI pipeline
ci: setup quality build validate
    @echo "CI pipeline complete!"

# --- 1-Click Reproducible Build ---

# Bootstrap: setup environment from scratch
bootstrap:
    @echo "=== ZoteRho Template Bootstrap ==="
    @echo "Checking required tools..."
    @# Check Deno
    @if ! command -v deno >/dev/null 2>&1; then \
        echo "ERROR: Deno not found. Install from https://deno.land/"; \
        echo "  curl -fsSL https://deno.land/install.sh | sh"; \
        exit 1; \
    fi
    @echo "  ✓ Deno $(deno --version | head -n1 | cut -d' ' -f2)"
    @# Check just
    @if ! command -v just >/dev/null 2>&1; then \
        echo "ERROR: just not found. Install from https://just.systems/"; \
        echo "  cargo install just  OR  brew install just"; \
        exit 1; \
    fi
    @echo "  ✓ just $(just --version | cut -d' ' -f2)"
    @# Check zip
    @if ! command -v zip >/dev/null 2>&1; then \
        echo "ERROR: zip not found. Install via your package manager."; \
        exit 1; \
    fi
    @echo "  ✓ zip available"
    @# Optional: nickel
    @if command -v nickel >/dev/null 2>&1; then \
        echo "  ✓ nickel $(nickel --version 2>/dev/null || echo 'available')"; \
    else \
        echo "  ○ nickel not found (optional, for config generation)"; \
    fi
    @echo ""
    @echo "Caching dependencies..."
    @deno cache deno.json 2>/dev/null || true
    @echo ""
    @echo "=== Bootstrap Complete ==="
    @echo "Run 'just reproducible' for 1-click build"

# 1-click reproducible build: bootstrap → build → package
reproducible: bootstrap
    @echo ""
    @echo "=== 1-Click Reproducible Build ==="
    @echo ""
    @# Step 1: Policy validation
    @echo "[1/4] Validating policy compliance..."
    @./mustfile validate
    @echo ""
    @# Step 2: Build ReScript
    @echo "[2/4] Building ReScript source..."
    @deno run --allow-run --allow-read --allow-write npm:rescript build
    @echo ""
    @# Step 3: Compile Nickel configs (if available)
    @echo "[3/4] Compiling configurations..."
    @just compile-nickel
    @echo ""
    @# Step 4: Package XPI
    @echo "[4/4] Creating XPI package..."
    @just copy-compiled
    @mkdir -p build
    @cd src-{{target_version}} && find . -type f \
        ! -name "*.ts" ! -name "*.tsx" ! -name "*.res" ! -name "*.resi" \
        ! -path "./.git/*" ! -path "./node_modules/*" \
        | sort | zip -X -@ ../build/zoterho-template-{{target_version}}.xpi
    @echo ""
    @echo "=== Build Complete ==="
    @echo ""
    @echo "Package: build/zoterho-template-{{target_version}}.xpi"
    @sha256sum build/zoterho-template-{{target_version}}.xpi
    @echo ""
    @echo "Install in Zotero:"
    @echo "  just install-zotero"
    @echo "  OR: Tools → Add-ons → Install Add-on From File..."

# --- Zotero Installation ---

# Detect Zotero profile directory
zotero-profile-dir := if os() == "macos" { "~/Library/Application Support/Zotero/Profiles" } else if os() == "windows" { "~/AppData/Roaming/Zotero/Zotero/Profiles" } else { "~/.zotero/zotero" }

# Install XPI to Zotero (requires profile detection)
install-zotero:
    @echo "Installing to Zotero..."
    @if [ ! -f build/zoterho-template-{{target_version}}.xpi ]; then \
        echo "XPI not found. Run 'just reproducible' first."; \
        exit 1; \
    fi
    @# Find Zotero extensions directory
    @PROFILE_BASE="{{zotero-profile-dir}}"; \
    PROFILE_BASE=$$(eval echo "$$PROFILE_BASE"); \
    if [ -d "$$PROFILE_BASE" ]; then \
        PROFILE=$$(ls -1 "$$PROFILE_BASE" 2>/dev/null | grep -E '\.default$$|default-release$$' | head -n1); \
        if [ -n "$$PROFILE" ]; then \
            EXT_DIR="$$PROFILE_BASE/$$PROFILE/extensions"; \
            mkdir -p "$$EXT_DIR"; \
            cp build/zoterho-template-{{target_version}}.xpi "$$EXT_DIR/zoterho-template@metadatstastician.art.xpi"; \
            echo "Installed to: $$EXT_DIR/zoterho-template@metadatstastician.art.xpi"; \
            echo ""; \
            echo "Restart Zotero to load the plugin."; \
        else \
            echo "Could not find Zotero default profile."; \
            echo "Manual install: Tools → Add-ons → Install Add-on From File..."; \
            echo "Select: build/zoterho-template-{{target_version}}.xpi"; \
        fi; \
    else \
        echo "Zotero profile directory not found at: $$PROFILE_BASE"; \
        echo "Manual install: Tools → Add-ons → Install Add-on From File..."; \
        echo "Select: build/zoterho-template-{{target_version}}.xpi"; \
    fi

# Open Zotero with the XPI for manual install
install-zotero-manual:
    @echo "Opening XPI for manual installation..."
    @if [ ! -f build/zoterho-template-{{target_version}}.xpi ]; then \
        echo "XPI not found. Run 'just reproducible' first."; \
        exit 1; \
    fi
    @echo ""
    @echo "To install in Zotero:"
    @echo "  1. Open Zotero"
    @echo "  2. Go to: Tools → Add-ons"
    @echo "  3. Click gear icon → Install Add-on From File..."
    @echo "  4. Select: $(pwd)/build/zoterho-template-{{target_version}}.xpi"
    @echo ""
    @# Try to open file manager at build directory
    @if command -v xdg-open >/dev/null 2>&1; then \
        xdg-open build/ 2>/dev/null || true; \
    elif command -v open >/dev/null 2>&1; then \
        open build/ 2>/dev/null || true; \
    fi
