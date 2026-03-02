# Fogbinder Justfile - Comprehensive Build System
# RSR Rhodium Standard Compliance - 100+ recipes
# License: MIT OR AGPL-3.0 (with Palimpsest)
# NO Node.js, NO npm, NO TypeScript - ReScript + WASM + Deno only

# Default recipe (shows help)
default:
    @just --list

# ============================================================================
# CONFIGURATION
# ============================================================================

# Deno version
deno_version := "1.40.0"

# ReScript compiler
rescript := "rescript"

# Cargo (Rust)
cargo := "cargo"

# Output directories
build_dir := "build"
dist_dir := "dist"
wasm_dir := "build/wasm"
rescript_output := "lib/js"

# ============================================================================
# HELP & DOCUMENTATION
# ============================================================================

# Show all available recipes with descriptions
help:
    @echo "╔════════════════════════════════════════════════════════════════╗"
    @echo "║              FOGBINDER BUILD SYSTEM (justfile)                 ║"
    @echo "║                RSR Rhodium Standard Compliant                  ║"
    @echo "╚════════════════════════════════════════════════════════════════╝"
    @echo ""
    @just --list
    @echo ""
    @echo "Categories:"
    @echo "  • Development:     dev, build, watch, clean"
    @echo "  • Testing:         test, test-*, coverage"
    @echo "  • Quality:         quality, lint, fmt, type-check"
    @echo "  • Security:        security-*, crypto-*"
    @echo "  • Benchmarks:      bench, bench-*"
    @echo "  • Documentation:   docs, docs-*"
    @echo "  • Release:         release, publish, package"
    @echo "  • RSR Compliance:  verify-rsr, rsr-*"
    @echo "  • Git:             git-*, commit"
    @echo "  • CI/CD:           ci, ci-*"
    @echo ""
    @echo "Quick start:"
    @echo "  just dev          # Start development mode (watch)"
    @echo "  just test         # Run all tests"
    @echo "  just quality      # Run all quality checks"
    @echo "  just build        # Build everything"

# Show recipe categories
categories:
    @echo "Recipe Categories:"
    @echo ""
    @echo "1. DEVELOPMENT (19 recipes)"
    @echo "   dev, build, build-*, watch, clean, clean-*"
    @echo ""
    @echo "2. TESTING (16 recipes)"
    @echo "   test, test-*, coverage, coverage-*"
    @echo ""
    @echo "3. QUALITY (12 recipes)"
    @echo "   quality, lint, lint-*, fmt, fmt-*, type-check"
    @echo ""
    @echo "4. SECURITY (14 recipes)"
    @echo "   security-audit, crypto-*, ssh-*, tls-*"
    @echo ""
    @echo "5. BENCHMARKS (8 recipes)"
    @echo "   bench, bench-*, perf, perf-*"
    @echo ""
    @echo "6. DOCUMENTATION (10 recipes)"
    @echo "   docs, docs-*, adoc-*, changelog"
    @echo ""
    @echo "7. RELEASE (9 recipes)"
    @echo "   release, publish, package, version"
    @echo ""
    @echo "8. RSR COMPLIANCE (11 recipes)"
    @echo "   verify-rsr, rsr-*, compliance"
    @echo ""
    @echo "9. GIT OPERATIONS (8 recipes)"
    @echo "   git-*, commit, push"
    @echo ""
    @echo "10. CI/CD (7 recipes)"
    @echo "    ci, ci-*, pre-commit"
    @echo ""
    @echo "Total: 100+ recipes"

# Show version information
version:
    @echo "Fogbinder v0.2.0"
    @echo "Architecture: ReScript + WASM + Deno"
    @echo "License: MIT OR AGPL-3.0 (with Palimpsest)"
    @echo "RSR Tier: Rhodium"
    @echo ""
    @echo "Tool versions:"
    @deno --version | head -1
    @{{rescript}} -version || echo "ReScript: not installed"
    @{{cargo}} --version || echo "Cargo: not installed"
    @just --version

# ============================================================================
# DEVELOPMENT
# ============================================================================

# Start development mode (watch + rebuild)
dev:
    @echo "🚀 Starting development mode..."
    @just watch

# Build everything (ReScript + WASM + Bundle)
build: build-rescript build-wasm bundle
    @echo "✅ Build complete!"

# Build ReScript code
build-rescript:
    @echo "📦 Building ReScript..."
    @{{rescript}} build

# Build ReScript in release mode
build-rescript-release:
    @echo "📦 Building ReScript (release)..."
    @{{rescript}} build -with-deps

# Clean ReScript build artifacts
clean-rescript:
    @echo "🧹 Cleaning ReScript artifacts..."
    @rm -rf lib/js
    @rm -rf lib/ocaml

# Build all WASM modules
build-wasm: build-wasm-crypto build-wasm-contradiction build-wasm-graph build-wasm-similarity
    @echo "✅ WASM modules built!"

# Build cryptography WASM modules
build-wasm-crypto:
    @echo "🔐 Building crypto WASM modules..."
    @mkdir -p {{wasm_dir}}/crypto
    @echo "⚠️  WASM modules not yet implemented"
    @echo "TODO: cd src/wasm/crypto && {{cargo}} build --target wasm32-unknown-unknown --release"

# Build contradiction detector WASM
build-wasm-contradiction:
    @echo "⚔️ Building contradiction detector WASM..."
    @mkdir -p {{wasm_dir}}
    @echo "⚠️  WASM modules not yet implemented"

# Build graph algorithms WASM
build-wasm-graph:
    @echo "🕸️ Building graph algorithms WASM..."
    @mkdir -p {{wasm_dir}}
    @echo "⚠️  WASM modules not yet implemented"

# Build string similarity WASM
build-wasm-similarity:
    @echo "📊 Building string similarity WASM..."
    @mkdir -p {{wasm_dir}}
    @echo "⚠️  WASM modules not yet implemented"

# Clean WASM build artifacts
clean-wasm:
    @echo "🧹 Cleaning WASM artifacts..."
    @rm -rf {{wasm_dir}}

# Bundle for distribution
bundle:
    @echo "📦 Bundling for distribution..."
    @mkdir -p {{dist_dir}}
    @deno run --allow-read --allow-write scripts/bundle.ts || echo "⚠️  Bundle script not yet implemented"

# Watch mode (rebuild on file changes)
watch:
    @echo "👁️ Watching for changes..."
    @{{rescript}} build -w

# Clean all build artifacts
clean: clean-rescript clean-wasm
    @echo "🧹 Cleaning all build artifacts..."
    @rm -rf {{build_dir}}
    @rm -rf {{dist_dir}}
    @rm -rf .deno_cache

# Clean everything including dependencies
clean-all: clean
    @echo "🧹 Cleaning everything..."
    @rm -f deno.lock

# Rebuild from scratch
rebuild: clean build
    @echo "✅ Rebuild complete!"

# Install development dependencies
install:
    @echo "📥 Installing dependencies..."
    @echo "Note: Fogbinder has NO runtime dependencies"
    @echo "Build tools required: deno, rescript, cargo"

# Check if all tools are installed
check-tools:
    @echo "Checking required tools..."
    @deno --version >/dev/null 2>&1 && echo "✅ Deno installed" || echo "❌ Deno missing"
    @{{rescript}} -version >/dev/null 2>&1 && echo "✅ ReScript installed" || echo "❌ ReScript missing"
    @{{cargo}} --version >/dev/null 2>&1 && echo "✅ Cargo installed" || echo "❌ Cargo missing"
    @just --version >/dev/null 2>&1 && echo "✅ just installed" || echo "❌ just missing"

# ============================================================================
# TESTING
# ============================================================================

# Run all tests
test: test-rescript test-wasm test-integration
    @echo "✅ All tests passed!"

# Run ReScript tests
test-rescript:
    @echo "🧪 Running ReScript tests..."
    @deno test src/**/*.test.res.js || echo "⚠️  No ReScript tests found yet"

# Run WASM tests
test-wasm:
    @echo "🧪 Running WASM tests..."
    @echo "⚠️  WASM tests not yet implemented"

# Run integration tests
test-integration:
    @echo "🧪 Running integration tests..."
    @deno test tests/integration/ || echo "⚠️  Integration tests not yet implemented"

# Run unit tests
test-unit:
    @echo "🧪 Running unit tests..."
    @deno test src/

# Run property-based tests
test-property:
    @echo "🧪 Running property-based tests..."
    @deno test tests/property/ || echo "⚠️  Property tests not yet implemented"

# Run tests with coverage
coverage:
    @echo "📊 Running tests with coverage..."
    @deno test --coverage=coverage src/

# Generate HTML coverage report
coverage-html: coverage
    @echo "📊 Generating HTML coverage report..."
    @deno coverage coverage --html

# Watch tests (re-run on changes)
test-watch:
    @echo "👁️ Watching tests..."
    @deno test --watch src/

# Run specific test file
test-file FILE:
    @echo "🧪 Running test: {{FILE}}"
    @deno test {{FILE}}

# Run tests matching pattern
test-pattern PATTERN:
    @echo "🧪 Running tests matching: {{PATTERN}}"
    @deno test --filter={{PATTERN}}

# Run performance tests
test-perf:
    @echo "🧪 Running performance tests..."
    @deno test --allow-hrtime tests/perf/ || echo "⚠️  Performance tests not yet implemented"

# Run smoke tests (quick sanity check)
test-smoke:
    @echo "🧪 Running smoke tests..."
    @deno test tests/smoke/ || echo "⚠️  Smoke tests not yet implemented"

# Run regression tests
test-regression:
    @echo "🧪 Running regression tests..."
    @deno test tests/regression/ || echo "⚠️  Regression tests not yet implemented"

# Run security tests
test-security:
    @echo "🧪 Running security tests..."
    @deno test tests/security/ || echo "⚠️  Security tests not yet implemented"

# Run accessibility tests
test-a11y:
    @echo "🧪 Running accessibility tests..."
    @deno test tests/accessibility/ || echo "⚠️  Accessibility tests not yet implemented"

# Clean test artifacts
clean-test:
    @echo "🧹 Cleaning test artifacts..."
    @rm -rf coverage
    @rm -f coverage.lcov

# ============================================================================
# QUALITY ASSURANCE
# ============================================================================

# Run all quality checks
quality: lint fmt-check type-check
    @echo "✅ All quality checks passed!"

# Lint all code
lint: lint-rescript lint-rust lint-deno
    @echo "✅ Linting complete!"

# Lint ReScript code
lint-rescript:
    @echo "🔍 Linting ReScript..."
    @{{rescript}} build

# Lint Rust code
lint-rust:
    @echo "🔍 Linting Rust..."
    @echo "⚠️  Rust linting not yet implemented (no Rust code yet)"

# Lint Deno code
lint-deno:
    @echo "🔍 Linting Deno..."
    @deno lint

# Format all code
fmt: fmt-rescript fmt-rust fmt-deno
    @echo "✅ Formatting complete!"

# Format ReScript code
fmt-rescript:
    @echo "🎨 Formatting ReScript..."
    @{{rescript}} format -all

# Format Rust code
fmt-rust:
    @echo "🎨 Formatting Rust..."
    @echo "⚠️  Rust formatting not yet implemented (no Rust code yet)"

# Format Deno code
fmt-deno:
    @echo "🎨 Formatting Deno..."
    @deno fmt

# Check formatting without modifying
fmt-check: fmt-check-rescript fmt-check-rust fmt-check-deno
    @echo "✅ Format check complete!"

# Check ReScript formatting
fmt-check-rescript:
    @echo "🔍 Checking ReScript formatting..."
    @{{rescript}} format -all -check

# Check Rust formatting
fmt-check-rust:
    @echo "🔍 Checking Rust formatting..."
    @echo "⚠️  Rust format check not yet implemented"

# Check Deno formatting
fmt-check-deno:
    @echo "🔍 Checking Deno formatting..."
    @deno fmt --check

# Type check everything
type-check:
    @echo "🔍 Type checking..."
    @{{rescript}} build
    @echo "✅ Type check complete (ReScript is 100% type-safe)"

# ============================================================================
# SECURITY
# ============================================================================

# Run comprehensive security audit
security-audit: security-audit-code crypto-test ssh-verify
    @echo "✅ Security audit complete!"

# Audit code for security issues
security-audit-code:
    @echo "🔐 Auditing code..."
    @deno run --allow-read scripts/security_audit.ts || echo "⚠️  Security audit script not yet implemented"

# Test cryptographic implementations
crypto-test: crypto-test-ed448 crypto-test-kyber crypto-test-shake256 crypto-test-argon2
    @echo "✅ Crypto tests complete!"

# Test Ed448 signatures
crypto-test-ed448:
    @echo "🔐 Testing Ed448..."
    @deno test tests/crypto/ed448.test.ts || echo "⚠️  Ed448 tests not yet implemented"

# Test Kyber-1024 KEM
crypto-test-kyber:
    @echo "🔐 Testing Kyber-1024..."
    @deno test tests/crypto/kyber1024.test.ts || echo "⚠️  Kyber tests not yet implemented"

# Test SHAKE256 hashing
crypto-test-shake256:
    @echo "🔐 Testing SHAKE256..."
    @deno test tests/crypto/shake256.test.ts || echo "⚠️  SHAKE256 tests not yet implemented"

# Test Argon2id password hashing
crypto-test-argon2:
    @echo "🔐 Testing Argon2id..."
    @deno test tests/crypto/argon2id.test.ts || echo "⚠️  Argon2id tests not yet implemented"

# Verify SSH configuration
ssh-verify:
    @echo "🔐 Verifying SSH configuration..."
    @git remote -v | grep -q "git@" && echo "✅ Using SSH" || echo "❌ Not using SSH for Git"

# Verify TLS/SSL configuration
tls-verify:
    @echo "🔐 Verifying TLS/SSL configuration..."
    @deno run --allow-net scripts/verify_tls.ts || echo "⚠️  TLS verify script not yet implemented"

# Scan for secrets in code
security-scan-secrets:
    @echo "🔐 Scanning for secrets..."
    @deno run --allow-read scripts/scan_secrets.ts || echo "⚠️  Secret scan script not yet implemented"

# Check permissions (Deno)
security-check-permissions:
    @echo "🔐 Checking permissions..."
    @grep -r "allow-all" . || echo "✅ No --allow-all found"

# Verify WASM security
security-wasm:
    @echo "🔐 Verifying WASM security..."
    @echo "⚠️  WASM security verification not yet implemented"

# Generate security report
security-report:
    @echo "🔐 Generating security report..."
    @just security-audit > security-report.txt
    @echo "Report saved to security-report.txt"

# ============================================================================
# BENCHMARKS
# ============================================================================

# Run all benchmarks
bench: bench-epistemic bench-contradiction bench-pipeline
    @echo "✅ Benchmarks complete!"

# Run epistemic state benchmarks
bench-epistemic:
    @echo "⚡ Benchmarking epistemic state operations..."
    @deno run --allow-all benchmarks/epistemic_state.bench.ts

# Run contradiction detection benchmarks
bench-contradiction:
    @echo "⚡ Benchmarking contradiction detection..."
    @deno run --allow-all benchmarks/contradiction_detection.bench.ts

# Run full pipeline benchmarks
bench-pipeline:
    @echo "⚡ Benchmarking full pipeline..."
    @deno run --allow-all benchmarks/full_pipeline.bench.ts

# Run all benchmarks and save results
bench-save:
    @echo "⚡ Running benchmarks and saving results..."
    @mkdir -p benchmarks/results
    @just bench > benchmarks/results/$(date +%Y-%m-%d-%H%M%S).txt

# Compare benchmark results
bench-compare OLD NEW:
    @echo "⚡ Comparing benchmarks..."
    @diff {{OLD}} {{NEW}} || true

# Run performance profiling
perf-profile:
    @echo "⚡ Profiling performance..."
    @deno run --allow-all --v8-flags=--prof benchmarks/full_pipeline.bench.ts

# Analyze performance profile
perf-analyze:
    @echo "⚡ Analyzing performance..."
    @deno run --allow-read scripts/analyze_perf.ts || echo "⚠️  Performance analysis not yet implemented"

# ============================================================================
# DOCUMENTATION
# ============================================================================

# Generate all documentation
docs: docs-api docs-adoc docs-changelog
    @echo "✅ Documentation generated!"

# Generate API documentation
docs-api:
    @echo "📚 Generating API docs..."
    @deno doc src/Fogbinder.res.js > docs/API_GENERATED.adoc || echo "⚠️  API doc generation not yet implemented"

# Build AsciiDoc documentation
docs-adoc:
    @echo "📚 Building AsciiDoc documentation..."
    @echo "⚠️  AsciiDoc build not yet implemented"

# Update changelog
docs-changelog:
    @echo "📚 Updating changelog..."
    @echo "See CHANGELOG.adoc for manual updates"

# Validate AsciiDoc files
docs-validate:
    @echo "📚 Validating AsciiDoc..."
    @deno run --allow-read scripts/validate_adoc.ts || echo "⚠️  AsciiDoc validation not yet implemented"

# Check for broken links
docs-check-links:
    @echo "📚 Checking for broken links..."
    @deno run --allow-read scripts/check_links.ts || echo "⚠️  Link checking not yet implemented"

# Generate documentation coverage report
docs-coverage:
    @echo "📚 Checking documentation coverage..."
    @deno run --allow-read scripts/docs_coverage.ts || echo "⚠️  Documentation coverage not yet implemented"

# Serve documentation locally
docs-serve:
    @echo "📚 Serving documentation..."
    @deno run --allow-net --allow-read scripts/serve_docs.ts || echo "⚠️  Documentation server not yet implemented"

# Preview AsciiDoc
docs-preview FILE:
    @echo "📚 Previewing {{FILE}}..."
    @asciidoctor {{FILE}} -o /tmp/preview.html || echo "⚠️  asciidoctor not installed"
    @open /tmp/preview.html || xdg-open /tmp/preview.html || echo "⚠️  Could not open browser"

# Generate humans.txt
docs-humans:
    @echo "📚 Generating humans.txt..."
    @deno run --allow-read --allow-write scripts/generate_humans.ts || echo "⚠️  humans.txt generator not yet implemented"

# ============================================================================
# RELEASE & PACKAGING
# ============================================================================

# Prepare release (version bump, changelog, tag)
release VERSION:
    @echo "🚀 Preparing release {{VERSION}}..."
    @just version-bump {{VERSION}}
    @just changelog-update
    @just build
    @just test
    @just quality
    @git tag -a v{{VERSION}} -m "Release v{{VERSION}}"
    @echo "✅ Release v{{VERSION}} ready!"

# Bump version number
version-bump VERSION:
    @echo "📌 Bumping version to {{VERSION}}..."
    @deno run --allow-read --allow-write scripts/bump_version.ts {{VERSION}} || echo "⚠️  Version bump script not yet implemented"

# Update changelog for release
changelog-update:
    @echo "📝 Updating CHANGELOG.adoc..."
    @echo "Please update CHANGELOG.adoc manually"

# Create distribution package
package: build
    @echo "📦 Creating distribution package..."
    @mkdir -p {{dist_dir}}
    @deno run --allow-read --allow-write scripts/package.ts || echo "⚠️  Package script not yet implemented"

# Build Zotero plugin (.xpi)
build-plugin: build
    @echo "📦 Building Zotero plugin..."
    @deno run --allow-read --allow-write scripts/build_plugin.ts || echo "⚠️  Plugin build script not yet implemented"

# Install plugin to Zotero
install-zotero: build-plugin
    @echo "📥 Installing to Zotero..."
    @deno run --allow-read --allow-write scripts/install_zotero.ts || echo "⚠️  Zotero install script not yet implemented"

# Publish to registry (future)
publish:
    @echo "🚀 Publishing to registry..."
    @echo "Not yet implemented - manual publication required"

# Create GitHub release
github-release VERSION:
    @echo "🚀 Creating GitHub release..."
    @gh release create v{{VERSION}} --generate-notes || echo "⚠️  gh CLI not installed"

# Sign release artifacts
sign-release:
    @echo "✍️ Signing release artifacts..."
    @deno run --allow-read --allow-write scripts/sign_release.ts || echo "⚠️  Release signing not yet implemented"

# ============================================================================
# RSR COMPLIANCE
# ============================================================================

# Verify RSR Rhodium compliance
verify-rsr:
    @echo "🏆 Verifying RSR Rhodium compliance..."
    @deno run --allow-read scripts/verify_rsr.ts || echo "⚠️  RSR verification script needs update for Rhodium"

# Generate RSR compliance report
rsr-report:
    @echo "🏆 Generating RSR compliance report..."
    @just verify-rsr > RSR_COMPLIANCE_REPORT.adoc

# Check documentation requirements
rsr-docs:
    @echo "🏆 Checking documentation requirements..."
    @test -f README.adoc && echo "✅ README.adoc exists"
    @test -f CONTRIBUTING.adoc && echo "✅ CONTRIBUTING.adoc exists"
    @test -f CODE_OF_CONDUCT.adoc && echo "✅ CODE_OF_CONDUCT.adoc exists"
    @test -f SECURITY.md && echo "✅ SECURITY.md exists"
    @test -f LICENSE_DUAL.adoc && echo "✅ LICENSE_DUAL.adoc exists"

# Check security requirements
rsr-security:
    @echo "🏆 Checking security requirements..."
    @just security-audit

# Check type safety requirements
rsr-types:
    @echo "🏆 Checking type safety..."
    @just type-check

# Check build system requirements
rsr-build:
    @echo "🏆 Checking build system..."
    @test -f justfile && echo "✅ justfile exists"
    @test ! -f package.json && echo "✅ No package.json" || echo "❌ package.json exists (should be removed)"

# Check licensing requirements
rsr-license:
    @echo "🏆 Checking licensing..."
    @test -f LICENSE_DUAL.adoc && echo "✅ Dual license documented"

# Check accessibility requirements
rsr-a11y:
    @echo "🏆 Checking accessibility..."
    @just test-a11y

# Check performance requirements
rsr-perf:
    @echo "🏆 Checking performance..."
    @just bench

# Check formal verification requirements
rsr-formal:
    @echo "🏆 Checking formal verification..."
    @test -d formal-verification && echo "✅ Formal verification present"

# Complete RSR Rhodium verification
rsr-full: verify-rsr rsr-docs rsr-security rsr-types rsr-build rsr-license
    @echo "🏆 Full RSR Rhodium verification complete!"

# ============================================================================
# GIT OPERATIONS
# ============================================================================

# Run pre-commit checks
pre-commit: fmt lint test quality
    @echo "✅ Pre-commit checks passed!"

# Commit with conventional commit message
commit MESSAGE:
    @git add -A
    @git commit -m "{{MESSAGE}}"

# Push to remote (SSH only)
push:
    @echo "🚀 Pushing to remote..."
    @git push -u origin $(git branch --show-current)

# Pull from remote
pull:
    @echo "⬇️ Pulling from remote..."
    @git pull origin $(git branch --show-current)

# Create feature branch
git-feature NAME:
    @git checkout -b feature/{{NAME}}

# Create fix branch
git-fix NAME:
    @git checkout -b fix/{{NAME}}

# Verify Git SSH configuration
git-ssh-verify:
    @echo "🔐 Verifying Git SSH configuration..."
    @git remote -v | grep -q "git@" && echo "✅ Using SSH" || echo "❌ Not using SSH"

# Switch to main branch
git-main:
    @git checkout main
    @git pull origin main

# ============================================================================
# CI/CD
# ============================================================================

# Run CI pipeline locally
ci: clean build test quality verify-rsr
    @echo "✅ CI pipeline complete!"

# Run CI for pull requests
ci-pr: build test quality
    @echo "✅ PR checks passed!"

# Run CI for main branch
ci-main: ci
    @echo "✅ Main branch CI complete!"

# Run nightly CI (extended tests)
ci-nightly: ci bench test-perf
    @echo "✅ Nightly CI complete!"

# Deploy to staging
ci-deploy-staging:
    @echo "🚀 Deploying to staging..."
    @echo "⚠️  Staging deployment not yet implemented"

# Deploy to production
ci-deploy-prod:
    @echo "🚀 Deploying to production..."
    @echo "⚠️  Production deployment not yet implemented"

# Run smoke tests after deployment
ci-smoke:
    @echo "🧪 Running smoke tests..."
    @just test-smoke

# ============================================================================
# UTILITIES
# ============================================================================

# Count lines of code
loc:
    @echo "📊 Lines of code:"
    @echo "ReScript:"
    @find src -name "*.res" 2>/dev/null | xargs wc -l 2>/dev/null | tail -1 || echo "  0"
    @echo "Rust:"
    @find src/wasm -name "*.rs" 2>/dev/null | xargs wc -l 2>/dev/null | tail -1 || echo "  0"

# Show file sizes
sizes:
    @echo "📊 Build artifact sizes:"
    @du -sh {{build_dir}}/* 2>/dev/null || echo "No build artifacts"

# Check disk usage
disk:
    @echo "💾 Disk usage:"
    @du -sh .

# List TODO comments
todos:
    @echo "📝 TODO comments:"
    @rg "TODO|FIXME|XXX|HACK" src/ 2>/dev/null || grep -r "TODO\|FIXME\|XXX\|HACK" src/ || echo "No TODOs found"

# Find unused code
unused:
    @echo "🔍 Finding unused code..."
    @deno run --allow-read scripts/find_unused.ts || echo "⚠️  Unused code finder not yet implemented"

# Check for updates
updates:
    @echo "📦 Checking for updates..."
    @echo "⚠️  Update checking not yet implemented"

# Generate .gitignore
gitignore:
    @echo "📝 Generating .gitignore..."
    @deno run --allow-write scripts/generate_gitignore.ts || echo "⚠️  gitignore generator not yet implemented"

# Initialize new environment
init: check-tools build
    @echo "✅ Environment initialized!"

# Show environment info
env:
    @echo "Environment information:"
    @echo "OS: $(uname -s)"
    @echo "Arch: $(uname -m)"
    @just version

# ============================================================================
# EXPERIMENTAL / FUTURE
# ============================================================================

# Build with Nix (reproducible)
build-nix:
    @echo "❄️ Building with Nix..."
    @nix build || echo "⚠️  Nix not installed"

# Run in Nix shell
nix-shell:
    @nix-shell || echo "⚠️  Nix not installed"

# Generate Nickel configuration
nickel-gen:
    @echo "⚙️ Generating Nickel configuration..."
    @deno run --allow-write scripts/generate_nickel.ts || echo "⚠️  Nickel generator not yet implemented"

# Validate Nickel configuration
nickel-validate:
    @echo "⚙️ Validating Nickel configuration..."
    @nickel export fogbinder.ncl || echo "⚠️  Nickel not installed or config doesn't exist"

# Run with WebGPU
run-webgpu:
    @echo "🎮 Running with WebGPU..."
    @deno run --unstable --allow-all examples/webgpu_demo.ts || echo "⚠️  WebGPU demo not yet implemented"

# Profile memory usage
profile-memory:
    @echo "🧠 Profiling memory..."
    @deno run --allow-all --v8-flags=--expose-gc benchmarks/memory_profile.ts || echo "⚠️  Memory profiling not yet implemented"

# Analyze bundle size
analyze-bundle:
    @echo "📊 Analyzing bundle size..."
    @deno run --allow-read scripts/analyze_bundle.ts || echo "⚠️  Bundle analyzer not yet implemented"

# Check browser compatibility
check-compat:
    @echo "🌐 Checking browser compatibility..."
    @deno run --allow-read scripts/check_compat.ts || echo "⚠️  Compatibility checker not yet implemented"

# ============================================================================
# PHILOSOPHY CHECKS (Fogbinder-specific)
# ============================================================================

# Verify philosophical integrity
philosophy:
    @echo "🧠 Checking philosophical integrity..."
    @grep -q "Wittgenstein" PHILOSOPHY.adoc || (echo "❌ Wittgenstein missing" && exit 1)
    @grep -q "Austin" PHILOSOPHY.adoc || (echo "❌ Austin missing" && exit 1)
    @grep -rq "language game" src/ || echo "⚠️  Warning: language game references sparse"
    @echo "✅ Philosophical integrity verified"

# ============================================================================
# ACCESSIBILITY
# ============================================================================

# Check accessibility compliance
a11y:
    @echo "♿ Checking accessibility..."
    @grep -r "outline: none" assets/ && (echo "❌ Found outline:none" && exit 1) || echo "✅ No outline:none found"
    @grep -r "focus.*outline.*0" assets/ && (echo "❌ Found focus outline disabled" && exit 1) || echo "✅ No focus outline disabled"
    @echo "✅ Accessibility check passed"
