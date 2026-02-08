#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# Hyperpolymath Language Policy Enforcement Script
# Checks for banned files, patterns, and enforces compliance

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

echo "═══════════════════════════════════════════════════════════════════"
echo "  Hyperpolymath Language Policy Check"
echo "═══════════════════════════════════════════════════════════════════"
echo ""

# Function to check for banned file patterns
check_banned_pattern() {
    local pattern="$1"
    local message="$2"
    local replacement="${3:-}"

    if find . -name "$pattern" -not -path "./.git/*" -not -path "./node_modules/*" 2>/dev/null | grep -q .; then
        echo -e "${RED}ERROR:${NC} $message"
        find . -name "$pattern" -not -path "./.git/*" -not -path "./node_modules/*" 2>/dev/null | head -5
        if [ -n "$replacement" ]; then
            echo -e "${YELLOW}  → Use $replacement instead${NC}"
        fi
        ((ERRORS++))
    fi
}

# Function to check for banned directories
check_banned_directory() {
    local dirname="$1"
    local message="$2"

    if find . -type d -name "$dirname" -not -path "./.git/*" 2>/dev/null | grep -q .; then
        echo -e "${RED}ERROR:${NC} $message"
        find . -type d -name "$dirname" -not -path "./.git/*" 2>/dev/null | head -5
        ((ERRORS++))
    fi
}

echo "Checking for banned file patterns..."
echo ""

# TypeScript files
check_banned_pattern "*.ts" "TypeScript files found! TypeScript is banned." "ReScript (.res)"
check_banned_pattern "*.tsx" "TypeScript JSX files found! TypeScript is banned." "ReScript (.res)"
check_banned_pattern "tsconfig.json" "TypeScript configuration found!" "deno.json"

# npm/Node.js files
check_banned_pattern "package.json" "package.json found! npm is banned." "deno.json"
check_banned_pattern "package-lock.json" "package-lock.json found! npm is banned." "deno.json"
check_banned_pattern ".npmrc" ".npmrc found! npm is banned." "deno.json"

# Bun files
check_banned_pattern "bun.lockb" "bun.lockb found! Bun is banned." "Deno"
check_banned_pattern "bunfig.toml" "bunfig.toml found! Bun is banned." "deno.json"

# Yarn/pnpm files
check_banned_pattern "yarn.lock" "yarn.lock found! Yarn is banned." "deno.json"
check_banned_pattern "pnpm-lock.yaml" "pnpm-lock.yaml found! pnpm is banned." "deno.json"
check_banned_pattern ".yarnrc*" ".yarnrc found! Yarn is banned." "deno.json"

# Go files
check_banned_pattern "*.go" "Go files found! Go is banned." "Rust (.rs)"
check_banned_pattern "go.mod" "go.mod found! Go is banned." "Cargo.toml"
check_banned_pattern "go.sum" "go.sum found! Go is banned." "Cargo.lock"

# Java/Kotlin files
check_banned_pattern "*.java" "Java files found! Java is banned." "Rust (.rs)"
check_banned_pattern "*.kt" "Kotlin files found! Kotlin is banned." "Rust (.rs) or Tauri/Dioxus"
check_banned_pattern "*.kts" "Kotlin script files found! Kotlin is banned." "Rust (.rs)"
check_banned_pattern "pom.xml" "Maven configuration found! Java is banned." "Cargo.toml"
check_banned_pattern "build.gradle*" "Gradle configuration found! Java/Kotlin is banned." "Cargo.toml"

# Swift files
check_banned_pattern "*.swift" "Swift files found! Swift is banned." "Rust (.rs) or Tauri/Dioxus"
check_banned_pattern "Package.swift" "Swift Package Manager found! Swift is banned." "Cargo.toml"

# Dart/Flutter files
check_banned_pattern "*.dart" "Dart files found! Dart/Flutter is banned." "Rust (.rs) or Dioxus"
check_banned_pattern "pubspec.yaml" "Flutter/Dart pubspec found! Flutter is banned." "Cargo.toml"

# Makefile
check_banned_pattern "Makefile" "Makefile found! Make is banned." "justfile"
check_banned_pattern "makefile" "makefile found! Make is banned." "justfile"
check_banned_pattern "GNUmakefile" "GNUmakefile found! Make is banned." "justfile"

echo ""
echo "Checking for banned directories..."
echo ""

# node_modules
check_banned_directory "node_modules" "node_modules directory found! Use Deno's built-in caching."

# Vendor directories for banned languages
check_banned_directory "vendor" "vendor directory found! May indicate banned package manager usage."

echo ""
echo "═══════════════════════════════════════════════════════════════════"

if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}Policy check FAILED: $ERRORS violation(s) found${NC}"
    echo ""
    echo "Please review .claude/CLAUDE.md for the Hyperpolymath language policy."
    exit 1
else
    echo -e "${GREEN}✓ Policy check PASSED: No violations found${NC}"
    exit 0
fi
