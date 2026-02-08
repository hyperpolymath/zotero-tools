# GPG Signing Guide

This document explains how to sign releases, commits, and artifacts with GPG for cryptographic verification.

## Table of Contents

- [Why GPG Signing?](#why-gpg-signing)
- [Prerequisites](#prerequisites)
- [Setting Up GPG](#setting-up-gpg)
- [Signing Git Commits](#signing-git-commits)
- [Signing Git Tags](#signing-git-tags)
- [Signing Release Artifacts](#signing-release-artifacts)
- [Verifying Signatures](#verifying-signatures)
- [GitHub Integration](#github-integration)
- [Key Management](#key-management)
- [Troubleshooting](#troubleshooting)

## Why GPG Signing?

GPG (GNU Privacy Guard) signatures provide:

- **Authenticity**: Prove that releases come from trusted maintainers
- **Integrity**: Detect tampering with code or artifacts
- **Non-repudiation**: Signers cannot deny creating signatures
- **Supply chain security**: Critical for RSR Platinum compliance

## Prerequisites

```bash
# Install GPG
# Ubuntu/Debian
sudo apt-get install gnupg

# macOS
brew install gnupg

# Windows (via Chocolatey)
choco install gnupg

# Verify installation
gpg --version
```

## Setting Up GPG

### Generate a New GPG Key

```bash
# Start key generation wizard
gpg --full-generate-key

# Recommended settings:
# - Key type: RSA and RSA (default)
# - Key size: 4096 bits
# - Expiration: 2 years (can be renewed)
# - Real name: Your full name (as in MAINTAINERS.md)
# - Email: Your commit email (check with 'git config user.email')
# - Comment: "Zotero ReScript Templater Signing Key" (optional)
```

Example session:
```
gpg (GnuPG) 2.4.0; Copyright (C) 2021 Free Software Foundation, Inc.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Please select what kind of key you want:
   (1) RSA and RSA (default)
   (2) DSA and Elgamal
   (3) DSA (sign only)
   (4) RSA (sign only)
Your selection? 1

RSA keys may be between 1024 and 4096 bits long.
What keysize do you want? (3072) 4096

Key is valid for? (0) 2y

Real name: Jane Doe
Email address: jane.doe@example.com
Comment: Zotero ReScript Templater Signing Key

Change (N)ame, (C)omment, (E)mail or (O)kay/(Q)uit? O

# Enter a strong passphrase when prompted
```

### List Your Keys

```bash
# List public keys
gpg --list-keys

# Output:
# pub   rsa4096 2024-11-22 [SC] [expires: 2026-11-22]
#       ABCD1234ABCD1234ABCD1234ABCD1234ABCD1234
# uid           [ultimate] Jane Doe (Zotero ReScript Templater Signing Key) <jane.doe@example.com>
# sub   rsa4096 2024-11-22 [E] [expires: 2026-11-22]

# List secret keys
gpg --list-secret-keys

# Get your key ID (use the 40-character fingerprint)
gpg --list-keys --keyid-format LONG
```

Your key ID is the 40-character string (e.g., `ABCD1234ABCD1234ABCD1234ABCD1234ABCD1234`).

### Export Public Key

```bash
# Export ASCII-armored public key
gpg --armor --export YOUR_KEY_ID > public-key.asc

# Or export to keyserver
gpg --keyserver keys.openpgp.org --send-keys YOUR_KEY_ID
```

## Signing Git Commits

### Configure Git for GPG Signing

```bash
# Set your GPG key for Git
git config --global user.signingkey YOUR_KEY_ID

# Enable automatic signing of all commits
git config --global commit.gpgsign true

# Enable automatic signing of all tags
git config --global tag.gpgsign true

# Configure GPG program (if not auto-detected)
git config --global gpg.program gpg
```

### Sign Individual Commits

```bash
# Sign a commit explicitly
git commit -S -m "feat: add new feature"

# Verify it worked
git log --show-signature -1
```

### Verify Commit Signatures

```bash
# Check signature of latest commit
git verify-commit HEAD

# Check signature of specific commit
git verify-commit abc123

# Show signature in log
git log --show-signature
```

## Signing Git Tags

### Create Signed Tags

```bash
# Create signed annotated tag
git tag -s v0.2.0 -m "Release version 0.2.0 - RSR Platinum compliance"

# Or sign existing tag
git tag -s v0.2.0 HEAD

# List tags with signatures
git tag -v v0.2.0
```

### Verify Tag Signatures

```bash
# Verify signed tag
git verify-tag v0.2.0

# Show tag with signature
git show v0.2.0
```

## Signing Release Artifacts

### Sign Tar Archives

```bash
# Create release archive
tar -czf zotero-rescript-templater-v0.2.0.tar.gz \
    --exclude='.git' \
    --exclude='Demo*' \
    --exclude='node_modules' \
    .

# Create detached signature
gpg --armor --detach-sign zotero-rescript-templater-v0.2.0.tar.gz

# This creates: zotero-rescript-templater-v0.2.0.tar.gz.asc
```

### Sign ZIP Archives

```bash
# Create ZIP archive
zip -r zotero-rescript-templater-v0.2.0.zip . \
    -x '.git/*' 'Demo*' 'node_modules/*'

# Sign ZIP file
gpg --armor --detach-sign zotero-rescript-templater-v0.2.0.zip

# This creates: zotero-rescript-templater-v0.2.0.zip.asc
```

### Sign Checksums File

```bash
# Generate checksums
sha256sum zotero-rescript-templater-v0.2.0.* > SHA256SUMS

# Sign checksums file
gpg --clearsign SHA256SUMS

# This creates: SHA256SUMS.asc (signed checksums)
```

### Complete Release Signing Workflow

```bash
#!/bin/bash
# sign-release.sh - Sign all release artifacts

set -e

VERSION="$1"
if [ -z "$VERSION" ]; then
    echo "Usage: $0 <version>"
    echo "Example: $0 0.2.0"
    exit 1
fi

PREFIX="zotero-rescript-templater-v${VERSION}"

echo "📦 Creating release archive..."
tar -czf "${PREFIX}.tar.gz" \
    --exclude='.git' \
    --exclude='Demo*' \
    --exclude='node_modules' \
    --exclude='*.tar.gz' \
    --exclude='*.zip' \
    .

echo "📦 Creating ZIP archive..."
zip -r "${PREFIX}.zip" . \
    -x '.git/*' 'Demo*' 'node_modules/*' '*.tar.gz' '*.zip'

echo "🔐 Generating checksums..."
sha256sum "${PREFIX}".{tar.gz,zip} > SHA256SUMS

echo "✍️  Signing artifacts..."
gpg --armor --detach-sign "${PREFIX}.tar.gz"
gpg --armor --detach-sign "${PREFIX}.zip"
gpg --clearsign SHA256SUMS

echo "✅ Release artifacts signed:"
ls -lh "${PREFIX}"* SHA256SUMS*

echo ""
echo "Verify with:"
echo "  gpg --verify ${PREFIX}.tar.gz.asc ${PREFIX}.tar.gz"
echo "  gpg --verify ${PREFIX}.zip.asc ${PREFIX}.zip"
echo "  gpg --verify SHA256SUMS.asc"
```

Save as `scripts/sign-release.sh` and use:
```bash
chmod +x scripts/sign-release.sh
./scripts/sign-release.sh 0.2.0
```

## Verifying Signatures

### Verify Detached Signatures

```bash
# Verify tar.gz signature
gpg --verify zotero-rescript-templater-v0.2.0.tar.gz.asc \
             zotero-rescript-templater-v0.2.0.tar.gz

# Expected output:
# gpg: Signature made ...
# gpg: Good signature from "Jane Doe ..."
```

### Verify Clearsigned Files

```bash
# Verify signed checksums
gpg --verify SHA256SUMS.asc

# Extract verified checksums
gpg --decrypt SHA256SUMS.asc > SHA256SUMS.verified

# Check file integrity
sha256sum -c SHA256SUMS.verified
```

### Import Maintainer Public Keys

```bash
# Import from file
gpg --import public-key.asc

# Import from keyserver
gpg --keyserver keys.openpgp.org --recv-keys ABCD1234ABCD1234ABCD1234ABCD1234ABCD1234

# Trust the key (after verifying fingerprint!)
gpg --edit-key ABCD1234ABCD1234ABCD1234ABCD1234ABCD1234
# At the gpg> prompt:
gpg> trust
# Select trust level (5 = ultimate for your own keys, 4 = full for verified maintainers)
gpg> quit
```

## GitHub Integration

### Add GPG Key to GitHub

1. **Export public key**:
   ```bash
   gpg --armor --export YOUR_KEY_ID
   ```

2. **Add to GitHub**:
   - Navigate to: https://github.com/settings/keys
   - Click "New GPG key"
   - Paste the entire output (including `-----BEGIN PGP PUBLIC KEY BLOCK-----`)
   - Click "Add GPG key"

3. **Verify**:
   - Signed commits will show "Verified" badge on GitHub
   - Example: https://github.com/user/repo/commit/abc123

### Configure GitHub Actions for Signing

Add to `.github/workflows/release.yml`:

```yaml
jobs:
  release:
    steps:
      - name: Import GPG key
        uses: crazy-max/ghaction-import-gpg@v6
        with:
          gpg_private_key: ${{ secrets.GPG_PRIVATE_KEY }}
          passphrase: ${{ secrets.GPG_PASSPHRASE }}
          git_user_signingkey: true
          git_commit_gpgsign: true
          git_tag_gpgsign: true

      - name: Sign release artifacts
        run: |
          gpg --armor --detach-sign release-artifact.tar.gz
          sha256sum release-artifact.tar.gz > SHA256SUMS
          gpg --clearsign SHA256SUMS
```

**Required secrets** (Settings > Secrets and variables > Actions):
- `GPG_PRIVATE_KEY`: Export with `gpg --armor --export-secret-keys YOUR_KEY_ID`
- `GPG_PASSPHRASE`: Your key's passphrase

⚠️ **Security**: Only add private keys to trusted CI/CD systems. Consider using separate subkeys for automation.

## Key Management

### Create Subkeys for Different Purposes

```bash
# Edit your key
gpg --edit-key YOUR_KEY_ID

# Add signing subkey
gpg> addkey
# Choose: (4) RSA (sign only)
# Key size: 4096
# Expiration: 1y

# Save changes
gpg> save
```

### Backup Your Keys

```bash
# Backup private key (KEEP SECURE!)
gpg --armor --export-secret-keys YOUR_KEY_ID > private-key-backup.asc

# Backup public key
gpg --armor --export YOUR_KEY_ID > public-key-backup.asc

# Backup trust database
gpg --export-ownertrust > trustdb-backup.txt

# Store backups in secure location:
# - Encrypted USB drive
# - Password manager with file attachments
# - Hardware security key
# - Offline paper backup (for recovery code)
```

### Revoke a Compromised Key

```bash
# Generate revocation certificate (do this when creating key!)
gpg --output revoke-cert.asc --gen-revoke YOUR_KEY_ID

# If key is compromised, import and send revocation:
gpg --import revoke-cert.asc
gpg --keyserver keys.openpgp.org --send-keys YOUR_KEY_ID

# Notify in SECURITY.md and create issue in repository
```

### Renew Expiring Keys

```bash
# Edit key
gpg --edit-key YOUR_KEY_ID

# Select key to renew (0 for primary, or subkey number)
gpg> key 0

# Extend expiration
gpg> expire
# Enter new expiration (e.g., 2y)

# Save
gpg> save

# Re-export public key
gpg --armor --export YOUR_KEY_ID > public-key-updated.asc

# Update GitHub and keyservers
gpg --keyserver keys.openpgp.org --send-keys YOUR_KEY_ID
```

## Troubleshooting

### "gpg: signing failed: Inappropriate ioctl for device"

```bash
# Fix: Set GPG_TTY
export GPG_TTY=$(tty)

# Add to ~/.bashrc or ~/.zshrc:
echo 'export GPG_TTY=$(tty)' >> ~/.bashrc
```

### "gpg: signing failed: No secret key"

```bash
# Check if key exists
gpg --list-secret-keys

# Verify Git is configured with correct key
git config --global user.signingkey

# Import key if missing
gpg --import private-key-backup.asc
```

### "error: gpg failed to sign the data"

```bash
# Test GPG signing manually
echo "test" | gpg --clearsign

# If it asks for passphrase, configure GPG agent
echo 'use-agent' >> ~/.gnupg/gpg.conf

# Restart GPG agent
gpgconf --kill gpg-agent
gpgconf --launch gpg-agent
```

### GitHub Not Showing "Verified" Badge

1. Ensure public key is added to GitHub: https://github.com/settings/keys
2. Verify commit email matches key email:
   ```bash
   git config user.email
   gpg --list-keys
   ```
3. Check signature:
   ```bash
   git verify-commit HEAD
   ```

### Passphrase Caching

```bash
# Configure GPG agent for caching
echo 'default-cache-ttl 34560000' >> ~/.gnupg/gpg-agent.conf
echo 'max-cache-ttl 34560000' >> ~/.gnupg/gpg-agent.conf

# Reload agent
gpgconf --reload gpg-agent
```

## Best Practices

### For Maintainers

1. **Use strong passphrases**: 20+ characters, mix of character types
2. **Set expiration dates**: 1-2 years, renewable
3. **Create revocation certificate**: Store securely offline
4. **Backup keys**: Encrypted, multiple secure locations
5. **Publish fingerprint**: In MAINTAINERS.md and on personal website
6. **Sign all releases**: Tags and artifacts
7. **Use hardware keys**: For high-security environments (YubiKey, Nitrokey)

### For Users

1. **Verify fingerprints**: Cross-check with MAINTAINERS.md and multiple sources
2. **Import from keyservers**: Prefer keys.openpgp.org or keybase.io
3. **Check signatures**: Before installing or running code
4. **Update keys**: Periodically refresh from keyservers
5. **Report issues**: If signatures don't verify

## Maintainer Key Registry

Current signing keys for Perimeter 1 (Core Team) maintainers:

```
# Format: Name <email>
# Fingerprint: ABCD 1234 ABCD 1234 ABCD  1234 ABCD 1234 ABCD 1234
# Key ID: ABCD1234ABCD1234
# Expires: YYYY-MM-DD
# Usage: S (signing), C (certification), E (encryption)

# To be filled when maintainers set up GPG keys
# See MAINTAINERS.md for current list
```

## Additional Resources

- **GPG Manual**: https://www.gnupg.org/documentation/
- **GitHub GPG Guide**: https://docs.github.com/en/authentication/managing-commit-signature-verification
- **GPG Best Practices**: https://riseup.net/en/security/message-security/openpgp/gpg-best-practices
- **Keybase**: https://keybase.io/ (alternative key distribution)
- **Keys.openpgp.org**: https://keys.openpgp.org/ (recommended keyserver)

## Quick Reference

```bash
# Generate key
gpg --full-generate-key

# List keys
gpg --list-keys
gpg --list-secret-keys

# Export public key
gpg --armor --export YOUR_KEY_ID

# Sign commit
git commit -S -m "message"

# Sign tag
git tag -s v1.0.0 -m "Release v1.0.0"

# Sign file
gpg --armor --detach-sign file.tar.gz

# Verify signature
gpg --verify file.tar.gz.asc file.tar.gz

# Import key
gpg --import public-key.asc

# Send to keyserver
gpg --keyserver keys.openpgp.org --send-keys YOUR_KEY_ID
```

---

**Last Updated**: 2024-11-22
**Maintainer**: See [MAINTAINERS.md](MAINTAINERS.md)
**License**: AGPL-3.0-only
**Related**: [SECURITY.md](SECURITY.md), [PUBLISHING.md](PUBLISHING.md), [MAINTAINERS.md](MAINTAINERS.md)
