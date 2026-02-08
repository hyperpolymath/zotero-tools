# Publishing Guide

This document describes how to publish the Zotero ReScript Templater to various package repositories and distribution channels.

## Table of Contents

- [PowerShell Gallery](#powershell-gallery)
- [Racket Package Catalog](#racket-package-catalog)
- [GitHub Releases](#github-releases)
- [Container Registry](#container-registry)
- [Nix Flakes](#nix-flakes)
- [Software Heritage](#software-heritage)
- [Zenodo (Academic Archive)](#zenodo-academic-archive)
- [Pre-Release Checklist](#pre-release-checklist)

## PowerShell Gallery

The PowerShell Gallery is the official repository for PowerShell modules and scripts.

### Prerequisites

1. **PowerShell Gallery Account**: Create an account at https://www.powershellgallery.com/
2. **API Key**: Generate an API key from your account settings
3. **Module Manifest**: Ensure `ZoteroReScriptTemplater.psd1` is up-to-date

### Publishing Steps

```powershell
# 1. Test the manifest locally
Test-ModuleManifest -Path ./ZoteroReScriptTemplater.psd1

# 2. Set your API key (store securely, don't commit!)
$apiKey = Read-Host -AsSecureString -Prompt "Enter PSGallery API Key"
$apiKeyPlain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($apiKey)
)

# 3. Publish to PowerShell Gallery
Publish-Module -Path . -NuGetApiKey $apiKeyPlain -Verbose

# 4. Verify publication
Find-Module -Name ZoteroReScriptTemplater
```

### Updating an Existing Package

```powershell
# 1. Update version in ZoteroReScriptTemplater.psd1
# 2. Update CHANGELOG.md with new changes
# 3. Run tests to ensure everything works
just test

# 4. Publish updated version
Publish-Module -Path . -NuGetApiKey $apiKeyPlain -Force -Verbose
```

### Installation by Users

```powershell
# Install from PowerShell Gallery
Install-Module -Name ZoteroReScriptTemplater -Scope CurrentUser

# Import and use
Import-Module ZoteroReScriptTemplater
New-ZoteroPlugin -ProjectName "MyPlugin" -AuthorName "Your Name" -TemplateType practitioner
```

## Racket Package Catalog

The Racket Package Catalog is the official repository for Racket packages.

### Prerequisites

1. **GitHub Repository**: Package must be in a Git repository
2. **info.rkt**: Package metadata file (already created)
3. **Racket Account**: Create account at https://pkgs.racket-lang.org/

### Publishing Steps

#### Option 1: Automatic from GitHub

```bash
# 1. Push to GitHub (triggers catalog indexing)
git tag v0.2.0
git push origin v0.2.0

# 2. Register package at https://pkgs.racket-lang.org/
# Use GitHub URL: https://github.com/Hyperpolymath/zotero-rescript-templater.git
```

#### Option 2: Manual with raco

```bash
# 1. Create package archive
raco pkg create zotero-rescript-templater

# 2. Upload to package catalog
# Visit: https://pkgs.racket-lang.org/manage/upload/
# Upload the generated .zip file
```

#### Option 3: Direct from Git

Users can install directly from the repository:

```bash
raco pkg install git://github.com/Hyperpolymath/zotero-rescript-templater
```

### Updating an Existing Package

```bash
# 1. Update version in info.rkt
# 2. Update CHANGELOG.md
# 3. Run tests
just test-racket

# 4. Create new git tag
git tag v0.2.1
git push origin v0.2.1

# Package catalog will auto-update from GitHub
```

### Installation by Users

```bash
# Install from Racket package catalog
raco pkg install zotero-rescript-templater

# Use the scaffolder
racket -l zotero-rescript-templater/init-raczotbuild.rkt -n MyPlugin -a "Your Name"

# Or if launcher is configured:
raczotbuild -n MyPlugin -a "Your Name"
```

## GitHub Releases

GitHub Releases provide versioned distribution with downloadable assets.

### Creating a Release

```bash
# 1. Ensure all changes are committed and pushed
git status

# 2. Run full validation
just validate

# 3. Create annotated tag
git tag -a v0.2.0 -m "Release version 0.2.0 - RSR Platinum compliance"

# 4. Push tag (triggers release workflow)
git push origin v0.2.0
```

The `.github/workflows/release.yml` workflow will automatically:
- Create a GitHub release
- Generate release artifacts
- Compute SHA256 checksums
- Run final validation tests

### Manual Release Creation

If automatic release fails, create manually:

```bash
# 1. Create release archive
tar -czf zotero-rescript-templater-v0.2.0.tar.gz \
    --exclude='.git' \
    --exclude='Demo*' \
    --exclude='node_modules' \
    .

# 2. Generate checksum
sha256sum zotero-rescript-templater-v0.2.0.tar.gz > checksums.txt

# 3. Create release on GitHub
gh release create v0.2.0 \
    --title "Zotero ReScript Templater v0.2.0" \
    --notes-file CHANGELOG.md \
    zotero-rescript-templater-v0.2.0.tar.gz \
    checksums.txt
```

## Container Registry

Publish container images to GitHub Container Registry (ghcr.io).

### Prerequisites

1. **GitHub Personal Access Token** with `write:packages` scope
2. **Containerfile** (already created)

### Publishing Steps

```bash
# 1. Build container image
podman build -t ghcr.io/hyperpolymath/zotero-rescript-templater:v0.2.0 \
    -t ghcr.io/hyperpolymath/zotero-rescript-templater:latest \
    -f Containerfile .

# 2. Login to GitHub Container Registry
echo $GITHUB_TOKEN | podman login ghcr.io -u USERNAME --password-stdin

# 3. Push images
podman push ghcr.io/hyperpolymath/zotero-rescript-templater:v0.2.0
podman push ghcr.io/hyperpolymath/zotero-rescript-templater:latest

# 4. Make image public (via GitHub web interface)
# Navigate to: https://github.com/users/Hyperpolymath/packages/container/zotero-rescript-templater/settings
# Change visibility to "Public"
```

### Using Published Container

```bash
# Pull and run
podman pull ghcr.io/hyperpolymath/zotero-rescript-templater:latest
podman run -it --rm \
    -v $(pwd):/workspace \
    ghcr.io/hyperpolymath/zotero-rescript-templater:latest \
    pwsh -c "New-ZoteroPlugin -ProjectName MyPlugin -AuthorName 'Your Name'"
```

## Nix Flakes

The project is already configured as a Nix flake (`flake.nix`).

### Publishing to FlakeHub

```bash
# 1. Register at https://flakehub.com/
# 2. Add GitHub repository
# 3. FlakeHub automatically indexes new releases

# Users can then install with:
nix profile install github:Hyperpolymath/zotero-rescript-templater
```

### Direct Nix Usage (No Publication Required)

```bash
# Users can use directly from GitHub:
nix develop github:Hyperpolymath/zotero-rescript-templater
nix build github:Hyperpolymath/zotero-rescript-templater
nix run github:Hyperpolymath/zotero-rescript-templater
```

## Software Heritage

Software Heritage provides long-term archival of source code.

### Automatic Archival

Software Heritage automatically crawls GitHub, but you can request immediate archival:

```bash
# Request archival via API
curl -X POST https://archive.softwareheritage.org/api/1/origin/save/git/url/https://github.com/Hyperpolymath/zotero-rescript-templater/

# Check archival status
curl https://archive.softwareheritage.org/api/1/origin/https://github.com/Hyperpolymath/zotero-rescript-templater/visits/
```

### Adding SWH Badge to README

Once archived, add the Software Heritage badge:

```markdown
[![Software Heritage](https://archive.softwareheritage.org/badge/origin/https://github.com/Hyperpolymath/zotero-rescript-templater/)](https://archive.softwareheritage.org/browse/origin/?origin_url=https://github.com/Hyperpolymath/zotero-rescript-templater)
```

## Zenodo (Academic Archive)

Zenodo provides DOIs for academic citation and long-term preservation.

### One-Time Setup

1. **Connect GitHub to Zenodo**:
   - Login to https://zenodo.org/ with GitHub
   - Navigate to https://zenodo.org/account/settings/github/
   - Enable the `zotero-rescript-templater` repository

2. **Configure Repository**:
   - Zenodo will create a webhook in your GitHub repository
   - Each new release will automatically trigger Zenodo archival

### Creating a Zenodo Release

```bash
# 1. Create GitHub release (as described above)
git tag v0.2.0
git push origin v0.2.0

# 2. Zenodo automatically creates archive and issues DOI
# 3. Update CITATION.cff with DOI:
#
# identifiers:
#   - type: doi
#     value: "10.5281/zenodo.XXXXXX"
#     description: "Zenodo DOI for version 0.2.0"
```

### Metadata Upload

Zenodo pulls metadata from:
- Repository description
- README.md
- CITATION.cff (if present)
- LICENSE file

Ensure `CITATION.cff` is complete before creating releases.

### Updating Existing Zenodo Record

```bash
# Each new release creates a new version in Zenodo
# The DOI concept remains the same, with version-specific DOIs

# Latest version DOI: 10.5281/zenodo.XXXXXX (always points to latest)
# Specific version DOI: 10.5281/zenodo.XXXXXY (version 0.2.0)
```

## Pre-Release Checklist

Before creating any release, ensure:

### Code Quality

- [ ] All tests pass: `just test`
- [ ] Linters pass: `just lint`
- [ ] Full validation passes: `just validate`
- [ ] CI/CD pipeline is green
- [ ] Property-based tests pass: `just test`

### Documentation

- [ ] CHANGELOG.md updated with new version
- [ ] Version bumped in:
  - [ ] `ZoteroReScriptTemplater.psd1` (ModuleVersion)
  - [ ] `info.rkt` (version)
  - [ ] `CITATION.cff` (version, date-released)
  - [ ] `flake.nix` (version)
- [ ] README.md reflects current features
- [ ] CONTRIBUTING.md is up-to-date
- [ ] All new features documented

### RSR Compliance

- [ ] RSR_COMPLIANCE.md updated with current scores
- [ ] .well-known/security.txt not expired
- [ ] MAINTAINERS.md reflects current team
- [ ] TPCF.md governance model current

### Security

- [ ] No secrets in repository: `git grep -i "password\s*="`
- [ ] SECURITY.md policy current
- [ ] Dependencies reviewed for vulnerabilities
- [ ] GPG signature prepared (if using)

### Metadata

- [ ] CITATION.cff complete with author info
- [ ] LICENSE file present and correct
- [ ] .gitignore excludes build artifacts
- [ ] .gitattributes properly configured

### Testing

```bash
# Comprehensive pre-release testing
just ci                    # Simulate CI/CD
just scaffold-demos        # Create all demo projects
just verify-integrity DemoPractitioner
just verify-integrity DemoResearcher
just verify-integrity DemoStudent
just clean-demos           # Clean up
```

## Release Workflow

Recommended workflow for creating a release:

```bash
# 1. Feature freeze and final testing
just validate
just test-coverage

# 2. Update all version numbers and documentation
# Edit: ZoteroReScriptTemplater.psd1, info.rkt, CITATION.cff, flake.nix, CHANGELOG.md

# 3. Commit version bump
git add .
git commit -m "chore: bump version to 0.2.0"
git push

# 4. Create and push tag
git tag -a v0.2.0 -m "Release version 0.2.0 - RSR Platinum compliance"
git push origin v0.2.0

# 5. Publish to package repositories
# PowerShell Gallery
Publish-Module -Path . -NuGetApiKey $apiKey

# Racket Package Catalog (automatic from git tag)
# Just wait for catalog to index the new tag

# 6. Verify releases
# Check GitHub releases page
# Check PowerShell Gallery: Find-Module ZoteroReScriptTemplater
# Check Racket Package Catalog: https://pkgs.racket-lang.org/package/zotero-rescript-templater
# Check Zenodo: https://zenodo.org/ (if configured)

# 7. Announce release
# Post to GitHub Discussions
# Update project homepage (if separate)
# Notify TPCF Perimeter 2 maintainers
```

## Troubleshooting

### PowerShell Gallery: "Module already exists"

```powershell
# Ensure version number is incremented
Test-ModuleManifest ./ZoteroReScriptTemplater.psd1 | Select-Object Version

# Use -Force to update existing version (not recommended for published packages)
Publish-Module -Path . -NuGetApiKey $apiKey -Force
```

### Racket Package Catalog: "Package not found"

```bash
# Verify info.rkt is valid
raco pkg create --help

# Check package catalog manually:
# https://pkgs.racket-lang.org/

# Re-register package at:
# https://pkgs.racket-lang.org/manage/
```

### GitHub Release: Workflow fails

```bash
# Check workflow logs
gh run list --workflow=release.yml

# View specific run
gh run view <run-id>

# Manually create release if automation fails
gh release create v0.2.0 --generate-notes
```

### Container Registry: Authentication fails

```bash
# Regenerate GitHub token with correct scopes:
# - write:packages
# - read:packages
# - delete:packages (optional)

# Test login
echo $GITHUB_TOKEN | podman login ghcr.io -u USERNAME --password-stdin
```

## Post-Release Tasks

After successful release:

1. **Monitor Issues**: Watch for user reports of problems
2. **Update Documentation**: Ensure online docs reflect new version
3. **Notify Community**: Announce in TPCF discussions
4. **Update Dependencies**: Check for dependency updates
5. **Plan Next Release**: Add items to CHANGELOG.md "Unreleased" section

## Security Considerations

- **API Keys**: Never commit API keys; use environment variables or secure vaults
- **GPG Signing**: Sign releases with GPG for verification:
  ```bash
  git tag -s v0.2.0 -m "Signed release v0.2.0"
  ```
- **Checksums**: Always provide SHA256 checksums for release artifacts
- **Provenance**: Use GitHub's artifact attestation for supply chain security

## License Compliance

This project is licensed under **AGPL-3.0-only**. When publishing:

- Ensure LICENSE file is included in all distribution packages
- PowerShell Gallery manifest includes license URI
- Racket info.rkt specifies AGPL-3.0-only
- Container images include LICENSE in /usr/share/licenses/
- Release notes mention AGPL-3.0 requirements

## Questions?

- **General**: Open a [Discussion](https://github.com/Hyperpolymath/zotero-rescript-templater/discussions)
- **Publishing Issues**: Open an [Issue](https://github.com/Hyperpolymath/zotero-rescript-templater/issues)
- **Security**: Follow [SECURITY.md](SECURITY.md) disclosure policy
- **Governance**: See [MAINTAINERS.md](MAINTAINERS.md) and [TPCF.md](TPCF.md)

---

**Last Updated**: 2024-11-22
**Maintainer**: See [MAINTAINERS.md](MAINTAINERS.md)
**License**: AGPL-3.0-only
