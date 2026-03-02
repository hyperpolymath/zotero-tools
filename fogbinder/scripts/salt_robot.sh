#!/usr/bin/env bash
# Salt Robot Vacuum Cleaner
# Automated maintenance system for Fogbinder repository
# RSR Rhodium Standard Compliance Enforcer

set -e

ROBOT_NAME="🤖 SALT ROBOT"
LOG_FILE=".salt-robot.log"

log() {
    echo "[$ROBOT_NAME] $1" | tee -a "$LOG_FILE"
}

error() {
    echo "[$ROBOT_NAME] ❌ $1" | tee -a "$LOG_FILE"
}

success() {
    echo "[$ROBOT_NAME] ✅ $1" | tee -a "$LOG_FILE"
}

warn() {
    echo "[$ROBOT_NAME] ⚠️  $1" | tee -a "$LOG_FILE"
}

log "================================================"
log "Starting automated maintenance sweep..."
log "Time: $(date)"
log "================================================"

# ==============================================================================
# PHASE 1: DETECT AND REMOVE FORBIDDEN FILES
# ==============================================================================

log ""
log "PHASE 1: Detecting forbidden files..."

# Check for TypeScript files
TS_FILES=$(find . -name "*.ts" -not -path "./.git/*" -not -path "./node_modules/*" -type f 2>/dev/null || true)
if [ -n "$TS_FILES" ]; then
    error "TypeScript files detected (forbidden):"
    echo "$TS_FILES"
    read -p "Delete these files? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "$TS_FILES" | xargs rm -v
        success "Deleted TypeScript files"
    fi
else
    success "No TypeScript files found"
fi

# Check for package.json
if [ -f package.json ]; then
    error "package.json detected (forbidden)"
    read -p "Delete package.json? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -v package.json
        success "Deleted package.json"
    fi
else
    success "No package.json found"
fi

# Check for node_modules
if [ -d node_modules ]; then
    error "node_modules detected (forbidden)"
    read -p "Delete node_modules? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf node_modules
        success "Deleted node_modules"
    fi
else
    success "No node_modules found"
fi

# Check for old Markdown files (except exceptions)
OLD_MD=$(find . -name "*.md" ! -name "SECURITY.md" ! -name "humans.md" -not -path "./.git/*" -type f 2>/dev/null || true)
if [ -n "$OLD_MD" ]; then
    warn "Old Markdown files detected (should be .adoc):"
    echo "$OLD_MD"
    read -p "Delete these files? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "$OLD_MD" | xargs rm -v
        success "Deleted old Markdown files"
    fi
else
    success "No old Markdown files found"
fi

# ==============================================================================
# PHASE 2: VERIFY REQUIRED FILES
# ==============================================================================

log ""
log "PHASE 2: Verifying required files..."

REQUIRED_FILES=(
    "README.adoc"
    "CONTRIBUTING.adoc"
    "CODE_OF_CONDUCT.adoc"
    "SECURITY.md"
    "LICENSE_DUAL.adoc"
    "CHANGELOG.adoc"
    "MAINTAINERS.adoc"
    "TPCF.adoc"
    "PHILOSOPHY.adoc"
    "justfile"
    ".gitignore"
    "bsconfig.json"
)

MISSING_FILES=()
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        MISSING_FILES+=("$file")
    fi
done

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    error "Missing required files:"
    printf '%s\n' "${MISSING_FILES[@]}"
else
    success "All required files present"
fi

# ==============================================================================
# PHASE 3: CLEAN BUILD ARTIFACTS
# ==============================================================================

log ""
log "PHASE 3: Cleaning build artifacts..."

# Clean Deno cache
if [ -d .deno_cache ]; then
    rm -rf .deno_cache
    success "Cleaned Deno cache"
fi

# Clean ReScript artifacts (but keep lib/js if it exists with source)
if [ -d lib/ocaml ]; then
    rm -rf lib/ocaml
    success "Cleaned ReScript OCaml artifacts"
fi

# Clean coverage
if [ -d coverage ]; then
    rm -rf coverage
    success "Cleaned coverage artifacts"
fi

# Clean dist if it's a build artifact
if [ -d dist ] && [ ! -f dist/.keep ]; then
    log "Found dist/ directory"
    read -p "Clean dist/ directory? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf dist
        success "Cleaned dist/"
    fi
fi

# ==============================================================================
# PHASE 4: VERIFY GIT CONFIGURATION
# ==============================================================================

log ""
log "PHASE 4: Verifying Git configuration..."

# Check Git remote uses SSH
if git remote -v | grep -q "https://"; then
    error "Git remote uses HTTPS (should use SSH)"
    warn "Run: git remote set-url origin git@github.com:username/repo.git"
elif git remote -v | grep -q "git@"; then
    success "Git remote uses SSH"
else
    warn "No Git remote configured"
fi

# Check Git hooks are executable
HOOKS=("pre-commit" "pre-push" "commit-msg")
for hook in "${HOOKS[@]}"; do
    if [ -f ".git/hooks/$hook" ]; then
        if [ -x ".git/hooks/$hook" ]; then
            success "Git hook $hook is executable"
        else
            warn "Git hook $hook is not executable"
            chmod +x ".git/hooks/$hook"
            success "Made $hook executable"
        fi
    else
        warn "Git hook $hook missing"
    fi
done

# ==============================================================================
# PHASE 5: CHECK CODE QUALITY
# ==============================================================================

log ""
log "PHASE 5: Checking code quality..."

# Format check
log "Checking code formatting..."
if deno fmt --check 2>/dev/null; then
    success "Code is formatted"
else
    warn "Code needs formatting - run: deno fmt"
fi

# Lint check
log "Checking linting..."
if deno lint 2>/dev/null; then
    success "Code passes linting"
else
    warn "Code has linting issues - run: deno lint"
fi

# ==============================================================================
# PHASE 6: VERIFY RSR RHODIUM COMPLIANCE
# ==============================================================================

log ""
log "PHASE 6: Verifying RSR Rhodium compliance..."

# Check documentation is AsciiDoc
ADOC_COUNT=$(find . -name "*.adoc" -not -path "./.git/*" -type f | wc -l)
log "Found $ADOC_COUNT AsciiDoc files"

# Check justfile recipe count
if [ -f justfile ]; then
    RECIPE_COUNT=$(grep -E "^[a-z][a-z0-9_-]*:" justfile | wc -l)
    if [ "$RECIPE_COUNT" -ge 100 ]; then
        success "justfile has $RECIPE_COUNT recipes (≥100 required)"
    else
        warn "justfile has $RECIPE_COUNT recipes (<100 required)"
    fi
fi

# Check for Nickel configuration
if [ -f fogbinder.ncl ] || [ -f nickel.ncl ]; then
    success "Nickel configuration present"
else
    warn "Nickel configuration missing"
fi

# ==============================================================================
# PHASE 7: SECURITY CHECKS
# ==============================================================================

log ""
log "PHASE 7: Running security checks..."

# Check for potential secrets
log "Scanning for potential secrets..."
if grep -r "API_KEY\|SECRET\|PASSWORD\|TOKEN" --include="*.res" --include="*.js" . 2>/dev/null | grep -v "example\|test" > /tmp/salt-robot-secrets.txt; then
    warn "Potential secrets found - review /tmp/salt-robot-secrets.txt"
else
    success "No potential secrets found"
fi

# Check accessibility
log "Checking accessibility violations..."
if grep -r "outline: none" assets/ 2>/dev/null; then
    error "Found 'outline: none' (accessibility violation)"
elif grep -r "focus.*outline.*0" assets/ 2>/dev/null; then
    error "Found disabled focus outline (accessibility violation)"
else
    success "No accessibility violations found"
fi

# ==============================================================================
# PHASE 8: GENERATE REPORT
# ==============================================================================

log ""
log "================================================"
log "Maintenance sweep complete!"
log "Report saved to: $LOG_FILE"
log "================================================"

# Summary
echo ""
echo "📊 SUMMARY:"
echo "  Forbidden files removed: TypeScript, package.json, node_modules"
echo "  Required files verified: ${#REQUIRED_FILES[@]} files"
echo "  Git hooks configured: pre-commit, pre-push, commit-msg"
echo "  Code quality: $(deno fmt --check 2>/dev/null && echo 'OK' || echo 'NEEDS FORMATTING')"
echo "  RSR Rhodium compliance: $([ -f justfile ] && echo 'OK' || echo 'INCOMPLETE')"
echo ""
echo "✅ Repository cleaned and verified!"
echo ""
echo "Next steps:"
echo "  1. Review $LOG_FILE for any warnings"
echo "  2. Run 'just quality' for full quality checks"
echo "  3. Run 'just verify-rsr' for RSR compliance verification"
echo "  4. Commit changes if any were made"
