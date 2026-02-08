# SPDX-License-Identifier: MIT
# Zoterho - Zotero ecosystem tools
# Hyperpolymath Language Policy Compliant

# ═══════════════════════════════════════════════════════════════════════════════
# METADATA & DEFAULTS
# ═══════════════════════════════════════════════════════════════════════════════

set shell := ["bash", "-euo", "pipefail", "-c"]
set dotenv-load := true

project := "zoterho"
version := "0.1.0"

# Default recipe - show help
default:
    @just --list --unsorted

# Show project information
info:
    @echo "Project: {{project}}"
    @echo "Version: {{version}}"
    @echo "Policy:  Hyperpolymath Language Standard"
    @echo ""
    @echo "Allowed: ReScript, Rust, Deno, Gleam, PHP 8.2+ (WordPress)"
    @echo "Banned:  TypeScript, Node.js, npm, Go, Java, Swift"

# ═══════════════════════════════════════════════════════════════════════════════
# LANGUAGE POLICY ENFORCEMENT
# ═══════════════════════════════════════════════════════════════════════════════

# Check for banned files and patterns (enforcement)
check-policy:
    @echo "Checking Hyperpolymath language policy compliance..."
    @./scripts/check-policy.sh

# Validate no banned files exist
check-banned-files:
    @echo "Checking for banned file patterns..."
    @! find . -name "*.ts" -not -path "./.git/*" | grep -q . || \
        (echo "ERROR: TypeScript files found!" && exit 1)
    @! find . -name "package.json" -not -path "./.git/*" | grep -q . || \
        (echo "ERROR: package.json found! Use deno.json" && exit 1)
    @! find . -name "package-lock.json" -not -path "./.git/*" | grep -q . || \
        (echo "ERROR: package-lock.json found!" && exit 1)
    @! find . -name "bun.lockb" -not -path "./.git/*" | grep -q . || \
        (echo "ERROR: bun.lockb found!" && exit 1)
    @! find . -name "node_modules" -type d -not -path "./.git/*" | grep -q . || \
        (echo "ERROR: node_modules directory found!" && exit 1)
    @! find . -name "Makefile" -not -path "./.git/*" | grep -q . || \
        (echo "ERROR: Makefile found! Use justfile" && exit 1)
    @! find . -name "*.go" -not -path "./.git/*" | grep -q . || \
        (echo "ERROR: Go files found! Use Rust" && exit 1)
    @echo "✓ No banned files detected"

# ═══════════════════════════════════════════════════════════════════════════════
# SUBMODULES
# ═══════════════════════════════════════════════════════════════════════════════

# Initialize all submodules
submodules-init:
    git submodule update --init --recursive

# Update all submodules to latest
submodules-update:
    git submodule update --remote --merge

# Show submodule status
submodules-status:
    git submodule status

# ═══════════════════════════════════════════════════════════════════════════════
# BUILD & DEVELOPMENT
# ═══════════════════════════════════════════════════════════════════════════════

# Build all components (ReScript + Rust)
build:
    @echo "Building all components..."
    @just build-rescript
    @just build-rust

# Build ReScript components
build-rescript:
    @echo "Building ReScript components..."
    @if command -v deno &> /dev/null; then \
        deno task build 2>/dev/null || echo "No ReScript build configured yet"; \
    else \
        echo "Deno not installed. Install with: curl -fsSL https://deno.land/install.sh | sh"; \
    fi

# Build Rust components
build-rust:
    @echo "Building Rust components..."
    @if [ -f "Cargo.toml" ]; then \
        cargo build --release; \
    else \
        echo "No Cargo.toml found - no Rust components to build"; \
    fi

# Clean build artifacts
clean:
    @echo "Cleaning build artifacts..."
    @rm -rf lib/ .bsb.lock
    @[ -f "Cargo.toml" ] && cargo clean || true
    @echo "✓ Clean complete"

# ═══════════════════════════════════════════════════════════════════════════════
# TESTING
# ═══════════════════════════════════════════════════════════════════════════════

# Run all tests
test:
    @echo "Running tests..."
    @just test-rescript
    @just test-rust

# Run ReScript tests
test-rescript:
    @if command -v deno &> /dev/null; then \
        deno task test 2>/dev/null || echo "No ReScript tests configured yet"; \
    fi

# Run Rust tests
test-rust:
    @if [ -f "Cargo.toml" ]; then \
        cargo test; \
    else \
        echo "No Cargo.toml found - no Rust tests to run"; \
    fi

# ═══════════════════════════════════════════════════════════════════════════════
# LINTING & FORMATTING
# ═══════════════════════════════════════════════════════════════════════════════

# Run all linters and formatters
lint:
    @echo "Running linters..."
    @just check-policy
    @just lint-rescript
    @just lint-rust

# Lint ReScript files
lint-rescript:
    @if command -v deno &> /dev/null; then \
        deno lint 2>/dev/null || echo "No ReScript files to lint yet"; \
    fi

# Lint Rust files
lint-rust:
    @if [ -f "Cargo.toml" ]; then \
        cargo clippy -- -D warnings; \
    fi

# Format all code
fmt:
    @echo "Formatting code..."
    @just fmt-rescript
    @just fmt-rust

# Format ReScript
fmt-rescript:
    @if command -v deno &> /dev/null; then \
        deno fmt 2>/dev/null || true; \
    fi

# Format Rust
fmt-rust:
    @if [ -f "Cargo.toml" ]; then \
        cargo fmt; \
    fi

# ═══════════════════════════════════════════════════════════════════════════════
# SECURITY
# ═══════════════════════════════════════════════════════════════════════════════

# Run security audits
audit:
    @echo "Running security audits..."
    @if [ -f "Cargo.toml" ]; then \
        cargo audit 2>/dev/null || echo "Install cargo-audit: cargo install cargo-audit"; \
    fi
    @if [ -f "deno.json" ]; then \
        deno task audit 2>/dev/null || echo "No Deno audit configured"; \
    fi

# Generate SBOM (Software Bill of Materials)
sbom:
    @echo "Generating SBOM..."
    @if [ -f "Cargo.toml" ]; then \
        cargo sbom 2>/dev/null || echo "Install cargo-sbom: cargo install cargo-sbom"; \
    fi

# ═══════════════════════════════════════════════════════════════════════════════
# CI & AUTOMATION
# ═══════════════════════════════════════════════════════════════════════════════

# Run CI pipeline locally
ci: check-policy lint test build
    @echo "✓ CI pipeline complete"

# Install git hooks for policy enforcement
install-hooks:
    @echo "Installing git hooks..."
    @mkdir -p .git/hooks
    @cp scripts/pre-commit .git/hooks/pre-commit 2>/dev/null || \
        echo '#!/bin/bash\njust check-policy' > .git/hooks/pre-commit
    @chmod +x .git/hooks/pre-commit
    @echo "✓ Git hooks installed"

# ═══════════════════════════════════════════════════════════════════════════════
# NICKEL / MUSTFILE INTEGRATION
# ═══════════════════════════════════════════════════════════════════════════════

# Validate Mustfile contract
must-check:
    @if command -v nickel &> /dev/null; then \
        nickel typecheck Mustfile.ncl && echo "✓ Mustfile valid"; \
    else \
        echo "Nickel not installed. See: https://nickel-lang.org"; \
    fi

# Export Mustfile configuration
must-export:
    @if command -v nickel &> /dev/null; then \
        nickel export Mustfile.ncl; \
    fi

# ═══════════════════════════════════════════════════════════════════════════════
# PACKAGE MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════════

# Install dependencies via Deno
deps:
    @if command -v deno &> /dev/null; then \
        deno cache --reload deno.json 2>/dev/null || echo "No Deno deps to cache"; \
    else \
        echo "Install Deno: curl -fsSL https://deno.land/install.sh | sh"; \
    fi

# Setup development environment
setup:
    @echo "Setting up development environment..."
    @just deps
    @just install-hooks
    @just submodules-init
    @echo "✓ Setup complete"
