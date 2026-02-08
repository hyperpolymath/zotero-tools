#!/usr/bin/env bash
# sign-release.sh - Sign all release artifacts with GPG
#
# Usage: ./scripts/sign-release.sh <version>
# Example: ./scripts/sign-release.sh 0.2.0
#
# This script creates signed release artifacts for distribution:
# - tar.gz archive with detached GPG signature
# - zip archive with detached GPG signature
# - SHA256 checksums file (clearsigned)
#
# Prerequisites:
# - GPG configured with signing key
# - Working directory is project root
#
# Output files:
# - zotero-rescript-templater-v<version>.tar.gz
# - zotero-rescript-templater-v<version>.tar.gz.asc (GPG signature)
# - zotero-rescript-templater-v<version>.zip
# - zotero-rescript-templater-v<version>.zip.asc (GPG signature)
# - SHA256SUMS (checksums)
# - SHA256SUMS.asc (signed checksums)

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $*"
}

log_success() {
    echo -e "${GREEN}✓${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $*"
}

log_error() {
    echo -e "${RED}✗${NC} $*" >&2
}

# Check if version argument provided
if [ $# -eq 0 ]; then
    log_error "Version argument required"
    echo ""
    echo "Usage: $0 <version>"
    echo "Example: $0 0.2.0"
    echo ""
    echo "This creates signed release artifacts:"
    echo "  • Tar.gz archive with GPG signature"
    echo "  • ZIP archive with GPG signature"
    echo "  • Clearsigned SHA256 checksums"
    exit 1
fi

VERSION="$1"
PREFIX="zotero-rescript-templater-v${VERSION}"

# Validate version format (basic semver check)
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$ ]]; then
    log_error "Invalid version format: $VERSION"
    echo "Expected semantic version (e.g., 0.2.0, 1.0.0-beta.1)"
    exit 1
fi

# Check prerequisites
log_info "Checking prerequisites..."

if ! command -v gpg &> /dev/null; then
    log_error "GPG not found. Please install GnuPG."
    echo "  Ubuntu/Debian: sudo apt-get install gnupg"
    echo "  macOS: brew install gnupg"
    echo "  Windows: choco install gnupg"
    exit 1
fi

if ! command -v tar &> /dev/null; then
    log_error "tar not found. Please install tar."
    exit 1
fi

if ! command -v zip &> /dev/null; then
    log_error "zip not found. Please install zip."
    exit 1
fi

if ! command -v sha256sum &> /dev/null; then
    # macOS uses shasum instead
    if command -v shasum &> /dev/null; then
        shacmd="shasum -a 256"
    else
        log_error "sha256sum not found. Please install coreutils."
        exit 1
    fi
else
    shacmd="sha256sum"
fi

# Verify GPG can sign
if ! echo "test" | gpg --clearsign &> /dev/null; then
    log_error "GPG signing test failed"
    echo "Ensure GPG is configured with a signing key:"
    echo "  gpg --list-secret-keys"
    echo ""
    echo "If no keys exist, generate one:"
    echo "  gpg --full-generate-key"
    echo ""
    echo "See GPG_SIGNING.md for detailed instructions."
    exit 1
fi

log_success "All prerequisites met"

# Clean up any existing release files
log_info "Cleaning up existing release files..."
rm -f "${PREFIX}".tar.gz "${PREFIX}".tar.gz.asc
rm -f "${PREFIX}".zip "${PREFIX}".zip.asc
rm -f SHA256SUMS SHA256SUMS.asc

# Exclude patterns for archives
EXCLUDE_PATTERNS=(
    '.git'
    '.github/workflows/*.yml'  # Keep workflow files
    'Demo*'
    'node_modules'
    '*.tar.gz'
    '*.tar.gz.asc'
    '*.zip'
    '*.zip.asc'
    'SHA256SUMS*'
    '.DS_Store'
    'Thumbs.db'
    '*.swp'
    '*.swo'
    '*~'
)

# Build tar exclude args
TAR_EXCLUDE_ARGS=()
for pattern in "${EXCLUDE_PATTERNS[@]}"; do
    TAR_EXCLUDE_ARGS+=(--exclude="$pattern")
done

# Build zip exclude args
ZIP_EXCLUDE_ARGS=()
for pattern in "${EXCLUDE_PATTERNS[@]}"; do
    ZIP_EXCLUDE_ARGS+=(-x "$pattern")
done

# Create tar.gz archive
log_info "Creating tar.gz archive..."
if tar -czf "${PREFIX}.tar.gz" "${TAR_EXCLUDE_ARGS[@]}" .; then
    SIZE=$(du -h "${PREFIX}.tar.gz" | cut -f1)
    log_success "Created ${PREFIX}.tar.gz ($SIZE)"
else
    log_error "Failed to create tar.gz archive"
    exit 1
fi

# Create zip archive
log_info "Creating ZIP archive..."
if zip -r "${PREFIX}.zip" . "${ZIP_EXCLUDE_ARGS[@]}" > /dev/null; then
    SIZE=$(du -h "${PREFIX}.zip" | cut -f1)
    log_success "Created ${PREFIX}.zip ($SIZE)"
else
    log_error "Failed to create ZIP archive"
    exit 1
fi

# Generate checksums
log_info "Generating SHA256 checksums..."
if $shacmd "${PREFIX}".tar.gz "${PREFIX}".zip > SHA256SUMS; then
    log_success "Generated SHA256SUMS"
    cat SHA256SUMS
else
    log_error "Failed to generate checksums"
    exit 1
fi

# Sign tar.gz
log_info "Signing tar.gz archive..."
if gpg --armor --detach-sign "${PREFIX}.tar.gz"; then
    log_success "Created ${PREFIX}.tar.gz.asc"
else
    log_error "Failed to sign tar.gz archive"
    exit 1
fi

# Sign zip
log_info "Signing ZIP archive..."
if gpg --armor --detach-sign "${PREFIX}.zip"; then
    log_success "Created ${PREFIX}.zip.asc"
else
    log_error "Failed to sign ZIP archive"
    exit 1
fi

# Sign checksums file
log_info "Signing checksums file..."
if gpg --clearsign SHA256SUMS; then
    log_success "Created SHA256SUMS.asc"
else
    log_error "Failed to sign checksums"
    exit 1
fi

# Display results
echo ""
echo "════════════════════════════════════════════════════════════════"
log_success "Release artifacts signed successfully!"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "📦 Release files for version ${VERSION}:"
echo ""
ls -lh "${PREFIX}".tar.gz "${PREFIX}".tar.gz.asc "${PREFIX}".zip "${PREFIX}".zip.asc SHA256SUMS SHA256SUMS.asc
echo ""
echo "🔐 GPG key used:"
gpg --list-keys "$(gpg --list-signatures SHA256SUMS.asc 2>/dev/null | grep 'Primary key fingerprint:' | awk '{print $NF}' || echo '')"
echo ""
echo "✅ Verification commands:"
echo ""
echo "  # Verify tar.gz signature:"
echo "  gpg --verify ${PREFIX}.tar.gz.asc ${PREFIX}.tar.gz"
echo ""
echo "  # Verify ZIP signature:"
echo "  gpg --verify ${PREFIX}.zip.asc ${PREFIX}.zip"
echo ""
echo "  # Verify and extract checksums:"
echo "  gpg --verify SHA256SUMS.asc"
echo "  gpg --decrypt SHA256SUMS.asc | sha256sum -c"
echo ""
echo "📤 Upload to GitHub release:"
echo ""
echo "  gh release create v${VERSION} \\"
echo "    --title \"Zotero ReScript Templater v${VERSION}\" \\"
echo "    --notes-file CHANGELOG.md \\"
echo "    ${PREFIX}.tar.gz \\"
echo "    ${PREFIX}.tar.gz.asc \\"
echo "    ${PREFIX}.zip \\"
echo "    ${PREFIX}.zip.asc \\"
echo "    SHA256SUMS.asc"
echo ""
echo "════════════════════════════════════════════════════════════════"

# Verify signatures automatically
log_info "Verifying signatures..."
echo ""

if gpg --verify "${PREFIX}.tar.gz.asc" "${PREFIX}.tar.gz" 2>&1 | grep -q "Good signature"; then
    log_success "tar.gz signature verified"
else
    log_warning "Could not verify tar.gz signature (key may not be trusted yet)"
fi

if gpg --verify "${PREFIX}.zip.asc" "${PREFIX}.zip" 2>&1 | grep -q "Good signature"; then
    log_success "ZIP signature verified"
else
    log_warning "Could not verify ZIP signature (key may not be trusted yet)"
fi

if gpg --verify SHA256SUMS.asc 2>&1 | grep -q "Good signature"; then
    log_success "Checksums signature verified"
else
    log_warning "Could not verify checksums signature (key may not be trusted yet)"
fi

echo ""
log_success "All done! Release artifacts are ready for distribution."
