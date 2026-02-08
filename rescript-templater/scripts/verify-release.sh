#!/usr/bin/env bash
# verify-release.sh - Verify GPG signatures of release artifacts
#
# Usage: ./scripts/verify-release.sh <version> [maintainer-key-id]
# Example: ./scripts/verify-release.sh 0.2.0
# Example: ./scripts/verify-release.sh 0.2.0 ABCD1234ABCD1234
#
# This script verifies:
# - GPG signatures on tar.gz and zip archives
# - Clearsigned SHA256 checksums
# - File integrity against checksums
#
# Prerequisites:
# - GPG configured
# - Release artifacts in current directory
# - Maintainer's public key imported (or will attempt to fetch)

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

# Check arguments
if [ $# -eq 0 ]; then
    log_error "Version argument required"
    echo ""
    echo "Usage: $0 <version> [maintainer-key-id]"
    echo "Example: $0 0.2.0"
    echo "Example: $0 0.2.0 ABCD1234ABCD1234  # With specific key ID"
    echo ""
    echo "This verifies GPG signatures on release artifacts:"
    echo "  • tar.gz archive signature"
    echo "  • ZIP archive signature"
    echo "  • SHA256 checksums signature"
    echo "  • File integrity against checksums"
    exit 1
fi

VERSION="$1"
MAINTAINER_KEY="${2:-}"  # Optional maintainer key ID
PREFIX="zotero-rescript-templater-v${VERSION}"

# Check prerequisites
log_info "Checking prerequisites..."

if ! command -v gpg &> /dev/null; then
    log_error "GPG not found. Please install GnuPG."
    exit 1
fi

if ! command -v sha256sum &> /dev/null; then
    if command -v shasum &> /dev/null; then
        shacmd="shasum -a 256 -c"
    else
        log_error "sha256sum not found. Please install coreutils."
        exit 1
    fi
else
    shacmd="sha256sum -c"
fi

log_success "Prerequisites met"

# Check if files exist
log_info "Checking for release files..."

REQUIRED_FILES=(
    "${PREFIX}.tar.gz"
    "${PREFIX}.tar.gz.asc"
    "${PREFIX}.zip"
    "${PREFIX}.zip.asc"
    "SHA256SUMS.asc"
)

MISSING_FILES=()
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        MISSING_FILES+=("$file")
    fi
done

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    log_error "Missing required files:"
    for file in "${MISSING_FILES[@]}"; do
        echo "  - $file"
    done
    echo ""
    echo "Download release files from:"
    echo "  https://github.com/Hyperpolymath/zotero-rescript-templater/releases/tag/v${VERSION}"
    exit 1
fi

log_success "All required files present"

# Import maintainer key if provided
if [ -n "$MAINTAINER_KEY" ]; then
    log_info "Attempting to import maintainer key ${MAINTAINER_KEY}..."
    if gpg --keyserver keys.openpgp.org --recv-keys "$MAINTAINER_KEY" &> /dev/null; then
        log_success "Imported key from keyserver"
    else
        log_warning "Could not import key from keyserver (may already be imported)"
    fi
fi

# Display header
echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  Verifying Release: ${VERSION}"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Verify tar.gz signature
log_info "Verifying tar.gz signature..."
if gpg --verify "${PREFIX}.tar.gz.asc" "${PREFIX}.tar.gz" 2>&1 | tee /tmp/gpg-verify-tar.log | grep -q "Good signature"; then
    log_success "tar.gz signature is valid"

    # Extract and display signer info
    SIGNER=$(grep "using" /tmp/gpg-verify-tar.log | head -1 || echo "Unknown")
    echo "  Signed by: $SIGNER"

    # Check if key is trusted
    if grep -q "WARNING" /tmp/gpg-verify-tar.log; then
        log_warning "Key is not marked as trusted in your keyring"
        echo "  To trust this key, verify the fingerprint in MAINTAINERS.md"
        echo "  Then run: gpg --edit-key <KEY_ID>"
        echo "           gpg> trust"
        echo "           (select trust level)"
        echo "           gpg> quit"
    fi
else
    log_error "tar.gz signature verification FAILED"
    cat /tmp/gpg-verify-tar.log
    echo ""
    log_error "DO NOT USE THIS RELEASE - signature is invalid!"
    exit 1
fi
echo ""

# Verify ZIP signature
log_info "Verifying ZIP signature..."
if gpg --verify "${PREFIX}.zip.asc" "${PREFIX}.zip" 2>&1 | tee /tmp/gpg-verify-zip.log | grep -q "Good signature"; then
    log_success "ZIP signature is valid"

    SIGNER=$(grep "using" /tmp/gpg-verify-zip.log | head -1 || echo "Unknown")
    echo "  Signed by: $SIGNER"

    if grep -q "WARNING" /tmp/gpg-verify-zip.log; then
        log_warning "Key is not marked as trusted in your keyring"
    fi
else
    log_error "ZIP signature verification FAILED"
    cat /tmp/gpg-verify-zip.log
    echo ""
    log_error "DO NOT USE THIS RELEASE - signature is invalid!"
    exit 1
fi
echo ""

# Verify checksums signature and extract
log_info "Verifying checksums signature..."
if gpg --verify SHA256SUMS.asc 2>&1 | tee /tmp/gpg-verify-sums.log | grep -q "Good signature"; then
    log_success "Checksums signature is valid"

    SIGNER=$(grep "using" /tmp/gpg-verify-sums.log | head -1 || echo "Unknown")
    echo "  Signed by: $SIGNER"

    if grep -q "WARNING" /tmp/gpg-verify-sums.log; then
        log_warning "Key is not marked as trusted in your keyring"
    fi
else
    log_error "Checksums signature verification FAILED"
    cat /tmp/gpg-verify-sums.log
    echo ""
    log_error "DO NOT USE THIS RELEASE - signature is invalid!"
    exit 1
fi
echo ""

# Extract verified checksums
log_info "Extracting verified checksums..."
if gpg --decrypt SHA256SUMS.asc > /tmp/SHA256SUMS.verified 2>/dev/null; then
    log_success "Checksums extracted"
else
    log_error "Failed to decrypt checksums file"
    exit 1
fi

# Verify file integrity
log_info "Verifying file integrity against checksums..."
echo ""

if cd "$(dirname "$0")/.." && $shacmd /tmp/SHA256SUMS.verified 2>&1; then
    echo ""
    log_success "All files match checksums"
else
    echo ""
    log_error "File integrity check FAILED"
    echo ""
    log_error "Files have been tampered with or corrupted!"
    log_error "DO NOT USE THIS RELEASE"
    exit 1
fi

echo ""

# Display verification summary
echo "════════════════════════════════════════════════════════════════"
log_success "Verification PASSED"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "✓ All signatures are valid"
echo "✓ All files match checksums"
echo "✓ Release artifacts are authentic and unmodified"
echo ""

# Show key fingerprint
log_info "Signer key fingerprint:"
FINGERPRINT=$(gpg --with-colons --list-sigs SHA256SUMS.asc 2>/dev/null | grep '^sig' | head -1 | cut -d: -f5)
if [ -n "$FINGERPRINT" ]; then
    gpg --fingerprint "$FINGERPRINT" | grep -A1 "fingerprint" || echo "  $FINGERPRINT"
    echo ""
    echo "⚠️  IMPORTANT: Verify this fingerprint matches the one in MAINTAINERS.md"
    echo "   or on the maintainer's personal website/keybase profile."
    echo ""
else
    log_warning "Could not extract key fingerprint"
fi

echo "📖 Safe to use this release!"
echo ""

# Cleanup temp files
rm -f /tmp/gpg-verify-*.log /tmp/SHA256SUMS.verified

log_success "Verification complete"
