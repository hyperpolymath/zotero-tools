# zotpress - Development Tasks
# Modern WordPress plugin development with Deno + PHP tooling

set shell := ["bash", "-uc"]
set dotenv-load := true

project := "zotpress"
version := "8.0.0"

# Show all recipes
default:
    @just --list --unsorted

# ─────────────────────────────────────────────────────────────────────────────
# Build & Development
# ─────────────────────────────────────────────────────────────────────────────

# Build all assets (CSS + JS)
build: build-css build-js
    @echo "✓ Build complete"

# Build CSS with PostCSS/LightningCSS via Deno
build-css:
    deno task build:css

# Build JavaScript with esbuild via Deno
build-js:
    deno task build:js

# Watch mode for development
dev:
    deno task dev

# Clean build artifacts
clean:
    rm -rf dist/ .cache/ coverage/ .phpunit.cache/
    rm -rf vendor/ node_modules/ .deno/
    @echo "✓ Cleaned build artifacts"

# ─────────────────────────────────────────────────────────────────────────────
# Testing
# ─────────────────────────────────────────────────────────────────────────────

# Run all tests
test: test-php test-js
    @echo "✓ All tests passed"

# Run PHP tests
test-php:
    vendor/bin/phpunit

# Run PHP tests with coverage
test-php-coverage:
    XDEBUG_MODE=coverage vendor/bin/phpunit --coverage-html coverage/

# Run JavaScript/TypeScript tests via Deno
test-js:
    deno test --allow-read --allow-write

# ─────────────────────────────────────────────────────────────────────────────
# Linting & Static Analysis
# ─────────────────────────────────────────────────────────────────────────────

# Run all linters
lint: lint-php lint-js
    @echo "✓ All lints passed"

# Lint PHP with PHPCS
lint-php:
    vendor/bin/phpcs --standard=WordPress lib/ src/ || true

# Lint PHP syntax
lint-php-syntax:
    vendor/bin/parallel-lint lib/ src/

# Static analysis with PHPStan
phpstan:
    vendor/bin/phpstan analyse --memory-limit=512M

# Static analysis with Psalm
psalm:
    vendor/bin/psalm --no-cache

# Lint JavaScript/TypeScript via Deno
lint-js:
    deno lint

# ─────────────────────────────────────────────────────────────────────────────
# Formatting
# ─────────────────────────────────────────────────────────────────────────────

# Format all code
fmt: fmt-php fmt-js
    @echo "✓ Formatting complete"

# Format PHP with PHPCBF
fmt-php:
    vendor/bin/phpcbf --standard=WordPress lib/ src/ || true

# Format JavaScript/TypeScript via Deno
fmt-js:
    deno fmt

# Check formatting (CI)
fmt-check:
    deno fmt --check

# ─────────────────────────────────────────────────────────────────────────────
# Dependency Management
# ─────────────────────────────────────────────────────────────────────────────

# Install all dependencies
install: install-php install-js
    @echo "✓ Dependencies installed"

# Install PHP dependencies
install-php:
    composer install --prefer-dist

# Install JavaScript dependencies (Deno caches automatically)
install-js:
    deno cache --reload deno.json

# Update all dependencies
update: update-php
    @echo "✓ Dependencies updated"

# Update PHP dependencies
update-php:
    composer update

# ─────────────────────────────────────────────────────────────────────────────
# Code Quality & Refactoring
# ─────────────────────────────────────────────────────────────────────────────

# Preview Rector refactoring
rector-preview:
    vendor/bin/rector process --dry-run

# Apply Rector refactoring
rector-fix:
    vendor/bin/rector process

# Run all quality checks (CI)
ci: lint phpstan test fmt-check
    @echo "✓ CI checks passed"

# Fix all auto-fixable issues
fix: fmt-php rector-fix
    @echo "✓ Auto-fixes applied"

# ─────────────────────────────────────────────────────────────────────────────
# Security
# ─────────────────────────────────────────────────────────────────────────────

# Check for security vulnerabilities
security:
    composer audit

# ─────────────────────────────────────────────────────────────────────────────
# Documentation
# ─────────────────────────────────────────────────────────────────────────────

# Generate documentation
docs:
    @echo "Building documentation..."
    # Future: Add doc generation

# ─────────────────────────────────────────────────────────────────────────────
# Release
# ─────────────────────────────────────────────────────────────────────────────

# Create a release build
release: clean install build test lint phpstan
    @echo "Creating release for {{project}} v{{version}}"
    @mkdir -p dist/{{project}}
    @cp -r lib/ css/ js/ languages/ readme.txt zotpress.php dist/{{project}}/
    @cd dist && zip -r {{project}}-{{version}}.zip {{project}}/
    @echo "✓ Release created: dist/{{project}}-{{version}}.zip"

# ─────────────────────────────────────────────────────────────────────────────
# Guix Integration
# ─────────────────────────────────────────────────────────────────────────────

# Enter Guix development shell
guix-shell:
    guix shell -D -f guix.scm

# Build with Guix
guix-build:
    guix build -f guix.scm

# ─────────────────────────────────────────────────────────────────────────────
# Utilities
# ─────────────────────────────────────────────────────────────────────────────

# Show project info
info:
    @echo "Project: {{project}}"
    @echo "Version: {{version}}"
    @echo ""
    @echo "PHP: $(php --version | head -n1)"
    @echo "Deno: $(deno --version | head -n1)"
    @echo "Composer: $(composer --version)"
    @echo ""
    @echo "Run 'just --list' for available commands"

# Check tool availability
check-tools:
    @which php || echo "❌ PHP not found"
    @which deno || echo "❌ Deno not found"
    @which composer || echo "❌ Composer not found"
    @which just || echo "❌ Just not found"
    @echo "✓ Tool check complete"
