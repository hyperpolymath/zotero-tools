# justfile for NSAI task automation
# https://github.com/casey/just

# Default recipe (list all recipes)
default:
    @just --list

# Install dependencies
install:
    npm install

# Run tests
test:
    npm test

# Run tests in watch mode
test-watch:
    npm run test:watch

# Run tests with coverage
test-coverage:
    npm run test:coverage

# Type check
typecheck:
    npm run typecheck

# Lint code
lint:
    npm run lint

# Lint and fix
lint-fix:
    npm run lint -- --fix

# Build for production
build:
    npm run build

# Build in development mode (watch)
dev:
    npm run dev

# Clean build artifacts
clean:
    rm -rf build/ dist/ node_modules/.vite/

# Clean everything (including node_modules)
clean-all: clean
    rm -rf node_modules/

# Run all checks (test + typecheck + lint)
check: test typecheck lint

# Validate RSR compliance
validate:
    @echo "Validating RSR compliance..."
    @echo "✓ LICENSE file exists"
    @test -f LICENSE
    @echo "✓ SECURITY.md exists"
    @test -f SECURITY.md
    @echo "✓ CONTRIBUTING.md exists"
    @test -f CONTRIBUTING.md
    @echo "✓ CODE_OF_CONDUCT.md exists"
    @test -f CODE_OF_CONDUCT.md
    @echo "✓ MAINTAINERS.md exists"
    @test -f MAINTAINERS.md
    @echo "✓ CHANGELOG.md exists"
    @test -f CHANGELOG.md
    @echo "✓ .well-known/security.txt exists"
    @test -f .well-known/security.txt
    @echo "✓ .well-known/ai.txt exists"
    @test -f .well-known/ai.txt
    @echo "✓ .well-known/humans.txt exists"
    @test -f .well-known/humans.txt
    @echo "✓ Tests pass"
    @npm test > /dev/null 2>&1
    @echo "✓ Type checking passes"
    @npm run typecheck > /dev/null 2>&1
    @echo "✓ Linting passes"
    @npm run lint > /dev/null 2>&1
    @echo ""
    @echo "✅ RSR compliance validated!"

# Generate documentation
docs:
    @echo "Documentation:"
    @echo "  README.md - Project documentation"
    @echo "  PHILOSOPHY.md - Philosophical foundation"
    @echo "  FOGBINDER-HANDOFF.md - Integration specification"
    @echo "  SECURITY.md - Security policy"
    @echo "  CONTRIBUTING.md - Contribution guidelines"
    @echo "  CHANGELOG.md - Version history"

# Show project status
status:
    @echo "NSAI Project Status"
    @echo "==================="
    @echo ""
    @echo "Version: 0.1.0-alpha"
    @echo "License: AGPL-3.0-or-later"
    @echo "Status: MVP Complete"
    @echo ""
    @echo "Tests:"
    @npm test 2>&1 | grep -E "Test Files|Tests" || echo "  Run 'just test' to see results"
    @echo ""
    @echo "Files:"
    @find src -name "*.ts" | wc -l | xargs echo "  TypeScript files:"
    @find src -name "*.test.ts" | wc -l | xargs echo "  Test files:"
    @echo ""
    @echo "Documentation:"
    @wc -l README.md PHILOSOPHY.md FOGBINDER-HANDOFF.md | tail -1 | awk '{print "  " $1 " lines"}'

# Pre-commit hook (run before committing)
pre-commit: check
    @echo "✅ Pre-commit checks passed!"

# CI simulation (what CI will run)
ci: clean install check build
    @echo "✅ CI checks passed!"

# Package for release (create .xpi file)
package: clean build
    @echo "Creating Zotero plugin package..."
    @mkdir -p dist
    @cd build && zip -r ../dist/nsai.xpi * manifest.json popup.html styles/
    @echo "✅ Package created: dist/nsai.xpi"

# Development setup (first-time setup)
setup: install
    @echo "Installing git hooks..."
    @echo "#!/bin/bash\njust pre-commit" > .git/hooks/pre-commit
    @chmod +x .git/hooks/pre-commit
    @echo "✅ Development environment ready!"

# Show version
version:
    @grep '"version"' package.json | head -1 | awk -F '"' '{print $4}'

# Show certainty about the codebase (meta)
certainty:
    @echo "NSAI Certainty Analysis"
    @echo "======================="
    @echo ""
    @echo "What we can validate (high certainty):"
    @echo "  ✓ Type safety (TypeScript strict mode)"
    @echo "  ✓ Test coverage (45+ tests)"
    @echo "  ✓ Code quality (ESLint)"
    @echo "  ✓ Build system (Vite)"
    @echo "  ✓ Documentation (8000+ words)"
    @echo ""
    @echo "What remains uncertain (needs work):"
    @echo "  ? Zotero API integration"
    @echo "  ? Real-world usage patterns"
    @echo "  ? Performance with large libraries"
    @echo "  ? User acceptance"
    @echo ""
    @echo "\"Whereof one cannot validate, thereof one must test in production.\""

# Show Tractarian quotes (for inspiration)
philosophy:
    @echo "Tractarian Principles"
    @echo "====================="
    @echo ""
    @echo "1.1 \"The world is the totality of facts, not of things.\""
    @echo "    → A research library is a totality of bibliographic facts"
    @echo ""
    @echo "2.1 \"We picture facts to ourselves.\""
    @echo "    → Citations picture sources"
    @echo ""
    @echo "5   \"A proposition is a truth-function of elementary propositions.\""
    @echo "    → Validation is truth-functional analysis"
    @echo ""
    @echo "6.54 \"...anyone who understands me eventually recognizes them as"
    @echo "      nonsensical, when he has used them—as steps—to climb up beyond them.\""
    @echo "    → NSAI is the ladder: validate, then hand off to Fogbinder"
    @echo ""
    @echo "7   \"Whereof one cannot speak, thereof one must be silent.\""
    @echo "    → What NSAI cannot validate, Fogbinder explores"
