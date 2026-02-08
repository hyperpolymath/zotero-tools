# Justfile for Zotero Voyant Export
# Simplified build without CUE dependency

# Default recipe - list available commands
default:
	@just --list

# Clean build artifacts
clean:
	rm -rf lib/bs .bsb.lock .merlin
	rm -f src/**/*.mjs src/**/*.cmi src/**/*.cmj src/**/*.cmt src/**/*.cmti
	rm -rf web-ext-artifacts dist

# Build ReScript code to JavaScript
build:
	@echo "Building ReScript..."
	deno task rescript:build
	@echo "✓ Build complete"

# Complete rebuild from scratch
rebuild: clean build

# Watch mode for development
watch:
	@echo "Starting watch mode..."
	deno task rescript:dev

# Development mode - rebuild and watch
dev: rebuild watch

# Lint ReScript code
lint:
	@echo "Linting ReScript..."
	deno run --allow-read --allow-write --allow-env --allow-run npm:rescript format -check src
	@echo "✓ Lint complete"

# Format ReScript code
fmt:
	@echo "Formatting ReScript..."
	deno run --allow-read --allow-write --allow-env --allow-run npm:rescript format -all src
	@echo "✓ Format complete"

# Lint extension package
lint-ext:
	@echo "Linting extension..."
	deno task ext:lint
	@echo "✓ Extension lint complete"

# Package extension for distribution
package: rebuild
	@echo "Packaging extension..."
	deno task ext:build
	@echo "✓ Package complete - check web-ext-artifacts/"

# Run extension in Firefox
run: build
	@echo "Running extension in Firefox..."
	deno task ext:run

# Full release build
release: clean build package
	@echo "✓ Release build complete"

# Display project information
info:
	@echo "=== Zotero Voyant Export ==="
	@echo "Version: 2.0.0"
	@echo "Author: Cora Johnson-Roberson"
	@echo "Repository: https://github.com/Hyperpolymath/zotero-voyant-export"

# Install git hooks
install-hooks:
	@echo "Installing git hooks..."
	@echo "Note: Install lefthook separately: https://github.com/evilmartians/lefthook"
	@echo "Then run: lefthook install"
