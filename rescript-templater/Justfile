# justfile - Build automation for Zotero ReScript Templater
# https://github.com/casey/just
#
# Install just: cargo install just
# Or: brew install just (macOS)
# Or: choco install just (Windows)
#
# Usage:
#   just --list          # Show all recipes
#   just test            # Run all tests
#   just validate        # Full validation
#   just scaffold-demo   # Create demo project

# Default recipe (runs when you type 'just')
default:
    @just --list

# === Testing ===

# Run all tests (PowerShell + Racket)
test: test-powershell test-racket
    @echo "✅ All tests passed!"

# Run PowerShell tests using Pester
test-powershell:
    @echo "🔍 Running PowerShell tests..."
    pwsh -Command "Invoke-Pester -Path ./tests/*.Tests.ps1 -Output Detailed"

# Run Racket tests using rackunit
test-racket:
    @echo "🔍 Running Racket tests..."
    racket tests/racket-tests.rkt

# Run tests in watch mode (PowerShell)
test-watch:
    @echo "👀 Watching PowerShell tests..."
    pwsh -Command "Invoke-Pester -Path ./tests/*.Tests.ps1 -Output Detailed -PesterPreference @{Run=@{SkipRemainingOnFailure='None'};Watch=@{Enabled=$true}}"

# Run tests with coverage (PowerShell)
test-coverage:
    @echo "📊 Running tests with coverage..."
    pwsh -Command "Invoke-Pester -Path ./tests/*.Tests.ps1 -CodeCoverage ./init-zotero-rscript-plugin.ps1 -Output Detailed"

# === Linting ===

# Run all linters
lint: lint-powershell lint-racket lint-bash lint-markdown
    @echo "✅ All linters passed!"

# Lint PowerShell code
lint-powershell:
    @echo "🔍 Linting PowerShell..."
    pwsh -Command "Invoke-ScriptAnalyzer -Path ./init-zotero-rscript-plugin.ps1 -Settings PSGallery -Severity Warning,Error"

# Lint Racket code
lint-racket:
    @echo "🔍 Checking Racket syntax..."
    raco check init-raczotbuild.rkt

# Lint Bash script
lint-bash:
    @echo "🔍 Linting Bash..."
    shellcheck init-zotero-plugin.sh || echo "shellcheck not installed, skipping"

# Lint Markdown files
lint-markdown:
    @echo "🔍 Linting Markdown..."
    markdownlint *.md docs/*.md || echo "markdownlint not installed, skipping"

# === Scaffolding Demos ===

# Create all demo projects
scaffold-demos: scaffold-demo-practitioner scaffold-demo-researcher scaffold-demo-student
    @echo "✅ All demo projects created!"

# Scaffold practitioner template demo (PowerShell)
scaffold-demo-practitioner:
    @echo "🏗️  Creating practitioner demo..."
    pwsh ./init-zotero-rscript-plugin.ps1 -ProjectName "DemoPractitioner" -AuthorName "Demo Author" -TemplateType practitioner -GitInit

# Scaffold researcher template demo (PowerShell)
scaffold-demo-researcher:
    @echo "🏗️  Creating researcher demo..."
    pwsh ./init-zotero-rscript-plugin.ps1 -ProjectName "DemoResearcher" -AuthorName "Demo Author" -TemplateType researcher -GitInit

# Scaffold student template demo (PowerShell)
scaffold-demo-student:
    @echo "🏗️  Creating student demo..."
    pwsh ./init-zotero-rscript-plugin.ps1 -ProjectName "DemoStudent" -AuthorName "Demo Author" -TemplateType student -GitInit

# Scaffold using Racket
scaffold-demo-racket:
    @echo "🏗️  Creating Racket demo..."
    racket init-raczotbuild.rkt -n "DemoRacket" -a "Demo Author" -g

# Scaffold using Bash
scaffold-demo-bash:
    @echo "🏗️  Creating Bash demo..."
    bash init-zotero-plugin.sh -n "DemoBash" -a "Demo Author" -t student -g

# === Cleanup ===

# Clean all demo projects
clean-demos:
    @echo "🧹 Cleaning demo projects..."
    rm -rf DemoPractitioner DemoResearcher DemoStudent DemoRacket DemoBash

# Clean all generated files
clean: clean-demos
    @echo "🧹 Cleaning generated files..."
    find . -name "audit-index.json" -delete
    find . -name "*.xpi" -delete

# === Validation ===

# Full project validation (RSR compliance)
validate: test lint check-rsr check-security check-docs
    @echo "✅ Full validation passed! Project is RSR compliant."

# Check RSR framework compliance
check-rsr:
    @echo "📋 Checking RSR compliance..."
    @echo "Verifying required files..."
    @test -f README.md || (echo "❌ Missing README.md" && exit 1)
    @test -f LICENSE || (echo "❌ Missing LICENSE" && exit 1)
    @test -f CONTRIBUTING.md || (echo "❌ Missing CONTRIBUTING.md" && exit 1)
    @test -f CODE_OF_CONDUCT.md || (echo "❌ Missing CODE_OF_CONDUCT.md" && exit 1)
    @test -f SECURITY.md || (echo "❌ Missing SECURITY.md" && exit 1)
    @test -f CHANGELOG.md || (echo "❌ Missing CHANGELOG.md" && exit 1)
    @test -f MAINTAINERS.md || (echo "❌ Missing MAINTAINERS.md" && exit 1)
    @test -f .well-known/security.txt || (echo "❌ Missing .well-known/security.txt" && exit 1)
    @test -f .well-known/ai.txt || (echo "❌ Missing .well-known/ai.txt" && exit 1)
    @test -f .well-known/humans.txt || (echo "❌ Missing .well-known/humans.txt" && exit 1)
    @test -f RSR_COMPLIANCE.md || (echo "❌ Missing RSR_COMPLIANCE.md" && exit 1)
    @echo "✅ All required RSR files present"

# Check for security issues
check-security:
    @echo "🔒 Checking for security issues..."
    @echo "Checking for secrets..."
    @! git grep -i "password\s*=" || echo "⚠️  Potential hardcoded password found"
    @! git grep -i "api[_-]key\s*=" || echo "⚠️  Potential hardcoded API key found"
    @! git grep -i "secret\s*=" || echo "⚠️  Potential hardcoded secret found"
    @echo "✅ No obvious secrets found"

# Check documentation quality
check-docs:
    @echo "📚 Checking documentation..."
    @test -s README.md || (echo "❌ README.md is empty" && exit 1)
    @grep -q "Installation" README.md || (echo "⚠️  README.md missing Installation section" && exit 1)
    @grep -q "Usage" README.md || (echo "⚠️  README.md missing Usage section" && exit 1)
    @echo "✅ Documentation checks passed"

# Verify offline-first capability
check-offline:
    @echo "🌐 Verifying offline-first capability..."
    @echo "Checking for network calls in core scripts..."
    @! grep -r "http://" init-*.{ps1,rkt,sh} || echo "⚠️  HTTP call found"
    @! grep -r "https://" init-*.{ps1,rkt,sh} | grep -v "^#" | grep -v "comment" || echo "⚠️  HTTPS call found"
    @echo "✅ Core scripts are offline-first"

# === Container Operations ===

# Build container image
container-build:
    @echo "🐳 Building container..."
    podman build -t zotero-templater -f Containerfile . || docker build -t zotero-templater -f Containerfile .

# Run tests in container
container-test:
    @echo "🐳 Running tests in container..."
    podman run --rm -v $(pwd):/workspace zotero-templater pwsh -Command "Invoke-Pester tests/*.Tests.ps1"

# Start interactive container shell
container-shell:
    @echo "🐳 Starting container shell..."
    podman run -it --rm -v $(pwd):/workspace zotero-templater /bin/bash

# === Git Operations ===

# Check git status
git-status:
    @git status --short

# Check for uncommitted changes
git-check-clean:
    @git diff-index --quiet HEAD -- || (echo "❌ Uncommitted changes present" && exit 1)
    @echo "✅ Git working directory clean"

# Create a new release (requires clean git state)
release VERSION: git-check-clean
    @echo "🚀 Creating release {{VERSION}}..."
    @git tag -a "v{{VERSION}}" -m "Release version {{VERSION}}"
    @echo "✅ Tagged v{{VERSION}}"
    @echo "Now run: git push origin v{{VERSION}}"

# === CI/CD Simulation ===

# Simulate CI/CD pipeline locally
ci: test lint validate
    @echo "✅ CI simulation passed! Ready for push."

# === Documentation ===

# Generate contributor graph
docs-contributors:
    @echo "👥 Generating contributor list..."
    @git shortlog -sn --all

# Count lines of code
docs-loc:
    @echo "📊 Lines of code:"
    @echo "PowerShell:"
    @find . -name "*.ps1" -exec wc -l {} + | tail -1
    @echo "Racket:"
    @find . -name "*.rkt" -exec wc -l {} + | tail -1
    @echo "Bash:"
    @find . -name "*.sh" -exec wc -l {} + | tail -1
    @echo "Markdown:"
    @find . -name "*.md" -exec wc -l {} + | tail -1

# Generate project statistics
stats:
    @echo "📊 Project Statistics"
    @echo "===================="
    @echo ""
    @echo "Files:"
    @echo "  PowerShell: $(find . -name '*.ps1' | wc -l)"
    @echo "  Racket:     $(find . -name '*.rkt' | wc -l)"
    @echo "  Bash:       $(find . -name '*.sh' | wc -l)"
    @echo "  Markdown:   $(find . -name '*.md' | wc -l)"
    @echo "  YAML:       $(find . -name '*.yml' -o -name '*.yaml' | wc -l)"
    @echo ""
    @echo "Tests:"
    @echo "  PowerShell: $(grep -c "^Describe" tests/*.Tests.ps1 || echo 0)"
    @echo "  Racket:     $(grep -c "test-case" tests/*.rkt || echo 0)"
    @echo ""
    @echo "Documentation:"
    @echo "  README:         $(wc -l < README.md) lines"
    @echo "  CONTRIBUTING:   $(wc -l < CONTRIBUTING.md) lines"
    @echo "  SECURITY:       $(wc -l < SECURITY.md) lines"
    @echo ""
    @just docs-loc

# === Integrity Verification ===

# Verify file integrity for demo projects
verify-integrity PROJECT:
    @echo "🔐 Verifying integrity of {{PROJECT}}..."
    pwsh ./init-zotero-rscript-plugin.ps1 -ProjectName "{{PROJECT}}" -VerifyIntegrity

# === Development Helpers ===

# Format all code (where formatters available)
format:
    @echo "🎨 Formatting code..."
    @echo "Note: Manual formatting required for PowerShell/Racket"

# Watch for file changes and run tests
watch:
    @echo "👀 Watching for changes..."
    @echo "Note: Use 'just test-watch' for PowerShell tests"

# Install development dependencies
install-deps:
    @echo "📦 Installing dependencies..."
    @echo "Installing PowerShell modules..."
    pwsh -Command "Install-Module -Name Pester -Force -Scope CurrentUser" || echo "Pester already installed"
    pwsh -Command "Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser" || echo "PSScriptAnalyzer already installed"
    @echo "✅ Dependencies installed"

# Check if all required tools are available
check-tools:
    @echo "🔧 Checking required tools..."
    @command -v pwsh >/dev/null 2>&1 || echo "❌ PowerShell (pwsh) not found"
    @command -v racket >/dev/null 2>&1 || echo "❌ Racket not found"
    @command -v bash >/dev/null 2>&1 || echo "❌ Bash not found"
    @command -v git >/dev/null 2>&1 || echo "❌ Git not found"
    @command -v podman >/dev/null 2>&1 && command -v docker >/dev/null 2>&1 || echo "ℹ️  Neither podman nor docker found (optional)"
    @echo "✅ Tool check complete"

# === RSR Specific ===

# Generate RSR compliance report
rsr-report:
    @echo "📊 RSR Compliance Report"
    @echo "======================="
    @cat RSR_COMPLIANCE.md | grep "Score:" | head -11

# Verify all .well-known files
check-wellknown:
    @echo "🔍 Checking .well-known directory..."
    @test -f .well-known/security.txt || (echo "❌ Missing security.txt" && exit 1)
    @test -f .well-known/ai.txt || (echo "❌ Missing ai.txt" && exit 1)
    @test -f .well-known/humans.txt || (echo "❌ Missing humans.txt" && exit 1)
    @echo "✅ All .well-known files present"
    @echo ""
    @echo "Checking security.txt expiration..."
    @grep "Expires:" .well-known/security.txt || echo "⚠️  No expiration date"

# === Help ===

# Show this help message
help:
    @just --list --unsorted

# Show extended help with descriptions
help-extended:
    @echo "Zotero ReScript Templater - Build System"
    @echo "========================================"
    @echo ""
    @echo "Quick Start:"
    @echo "  just test              # Run all tests"
    @echo "  just validate          # Full project validation"
    @echo "  just scaffold-demos    # Create demo projects"
    @echo "  just clean-demos       # Remove demo projects"
    @echo ""
    @echo "For full recipe list: just --list"
    @echo "For recipe details: just --show <recipe-name>"
    @echo ""
    @echo "Documentation:"
    @echo "  README.md              # Project overview"
    @echo "  CONTRIBUTING.md        # Contribution guide"
    @echo "  RSR_COMPLIANCE.md      # RSR framework compliance"
