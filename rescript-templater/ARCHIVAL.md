# Long-Term Archival Guide

This document describes the project's long-term preservation strategy using Software Heritage and Zenodo.

## Table of Contents

- [Why Long-Term Archival?](#why-long-term-archival)
- [Software Heritage](#software-heritage)
- [Zenodo Academic Archive](#zenodo-academic-archive)
- [Archive Status](#archive-status)
- [Verification](#verification)
- [Citation](#citation)

## Why Long-Term Archival?

Long-term archival ensures:

- **Permanence**: Code remains accessible even if GitHub goes offline
- **Research reproducibility**: Academic papers can reference stable, citable versions
- **Legal compliance**: AGPL-3.0 requires source availability; archives guarantee this
- **Historical record**: Software becomes part of humanity's digital heritage
- **RSR compliance**: Required for Platinum-level RSR framework compliance

## Software Heritage

[Software Heritage](https://www.softwareheritage.org/) is a non-profit initiative to collect, preserve, and make accessible all publicly available source code.

### What is Software Heritage?

- **Mission**: Universal archive of all public source code
- **Longevity**: Designed for multi-decade preservation
- **Governance**: Operated by UNESCO and INRIA
- **Format**: Merkle DAG (Git-compatible)
- **Identifier**: Software Heritage ID (SWHID) for every artifact

### Automatic Archival

Software Heritage automatically crawls GitHub repositories. To ensure archival:

1. **Keep repository public** - Private repos are not archived
2. **Use standard formats** - Git, Mercurial, SVN all supported
3. **Regular commits** - Active repos are crawled more frequently

### Manual Archival Request

To request immediate archival:

```bash
# Request archival via API
curl -X POST \
  https://archive.softwareheritage.org/api/1/origin/save/git/url/https://github.com/Hyperpolymath/zotero-rescript-templater/

# Expected response:
# {
#   "origin_url": "https://github.com/Hyperpolymath/zotero-rescript-templater",
#   "save_request_date": "2024-11-22T12:00:00Z",
#   "save_request_status": "accepted",
#   "save_task_status": "scheduled"
# }
```

### Check Archival Status

```bash
# Check if repository is archived
curl https://archive.softwareheritage.org/api/1/origin/https://github.com/Hyperpolymath/zotero-rescript-templater/visits/

# Or visit in browser:
# https://archive.softwareheritage.org/browse/origin/?origin_url=https://github.com/Hyperpolymath/zotero-rescript-templater
```

### Software Heritage Identifiers (SWHIDs)

Each object gets a persistent identifier:

```
# Repository snapshot
swh:1:snp:abcd1234...

# Specific commit
swh:1:rev:ef567890...

# Specific file
swh:1:cnt:12345678...

# Directory tree
swh:1:dir:abcdef12...
```

Use SWHIDs in academic papers for permanent references.

### Adding SWH Badge

Once archived, add badge to README.md:

```markdown
[![Software Heritage](https://archive.softwareheritage.org/badge/origin/https://github.com/Hyperpolymath/zotero-rescript-templater/)](https://archive.softwareheritage.org/browse/origin/?origin_url=https://github.com/Hyperpolymath/zotero-rescript-templater)
```

### Automation

The `.github/workflows/publish.yml` workflow automatically requests archival on each release:

```yaml
- name: Request Software Heritage archival
  run: |
    curl -X POST \
      "https://archive.softwareheritage.org/api/1/origin/save/git/url/${{ github.server_url }}/${{ github.repository }}/"
```

## Zenodo Academic Archive

[Zenodo](https://zenodo.org/) is a research data repository operated by CERN, providing DOIs for software releases.

### What is Zenodo?

- **Purpose**: Academic citation and preservation
- **DOI**: Digital Object Identifier for each release
- **Versioning**: Concept DOI (all versions) + Version DOI (specific version)
- **Metadata**: Rich metadata for discoverability
- **Integration**: GitHub integration for automatic archival

### One-Time Setup

#### 1. Create Zenodo Account

1. Visit https://zenodo.org/
2. Sign up with GitHub account (recommended)
3. Verify email address

#### 2. Enable GitHub Integration

1. Navigate to: https://zenodo.org/account/settings/github/
2. Click "Sync now" to fetch repositories
3. Toggle switch for `zotero-rescript-templater`
4. Zenodo creates webhook in GitHub repository

#### 3. Configure Metadata

Zenodo pulls metadata from:
- `.zenodo.json` (project root) - **Primary source**
- `CITATION.cff` (fallback)
- Repository description
- `README.md`
- `LICENSE` file

The `.zenodo.json` file in this repository provides comprehensive metadata.

### Creating Archived Releases

Once GitHub integration is enabled:

```bash
# 1. Create and push a git tag
git tag v0.2.0
git push origin v0.2.0

# 2. Create GitHub release (or wait for automatic release workflow)
gh release create v0.2.0 --title "Zotero ReScript Templater v0.2.0" --notes-file CHANGELOG.md

# 3. Zenodo automatically:
#    - Detects the new release
#    - Downloads release archive
#    - Extracts metadata from .zenodo.json
#    - Mints a DOI
#    - Creates archival record
```

### DOI Structure

Zenodo provides two DOIs:

1. **Concept DOI** (permanent, all versions):
   ```
   https://doi.org/10.5281/zenodo.CONCEPT_ID
   ```
   Always points to latest version

2. **Version DOI** (specific release):
   ```
   https://doi.org/10.5281/zenodo.VERSION_ID
   ```
   Immutable, specific to v0.2.0, v0.2.1, etc.

### Updating CITATION.cff

After first release, update `CITATION.cff` with DOI:

```yaml
identifiers:
  - type: doi
    value: "10.5281/zenodo.CONCEPT_ID"
    description: "Zenodo DOI (all versions)"

preferred-citation:
  type: software
  doi: "10.5281/zenodo.VERSION_ID"
  version: "0.2.0"
```

### Editing Zenodo Metadata

If you need to update metadata after publishing:

1. Login to https://zenodo.org/
2. Navigate to: https://zenodo.org/deposit
3. Click on your upload
4. Click "Edit" (creates new version with updated metadata)

### Zenodo Communities

To increase discoverability, submit to communities:

```json
// In .zenodo.json
"communities": [
  {"identifier": "zenodo"},
  {"identifier": "software-engineering"},
  {"identifier": "research-software"}
]
```

Browse communities: https://zenodo.org/communities/

## Archive Status

### Current Status

| Archive | Status | Identifier | Link |
|---------|--------|------------|------|
| **Software Heritage** | ⏳ Pending | `swh:1:ori:...` | [Browse](https://archive.softwareheritage.org/browse/origin/?origin_url=https://github.com/Hyperpolymath/zotero-rescript-templater) |
| **Zenodo** | ⏳ Not configured | `10.5281/zenodo.XXXXXX` | [Setup](https://zenodo.org/account/settings/github/) |

### Checking Status

**Software Heritage**:
```bash
curl https://archive.softwareheritage.org/api/1/origin/https://github.com/Hyperpolymath/zotero-rescript-templater/visits/
```

**Zenodo**:
- Visit https://zenodo.org/
- Search for "Zotero ReScript Templater"
- Or check: https://zenodo.org/record/CONCEPT_ID

## Verification

### Verify Software Heritage Archive

```bash
# 1. Get repository SWHID
curl https://archive.softwareheritage.org/api/1/origin/https://github.com/Hyperpolymath/zotero-rescript-templater/get/ | jq

# 2. Browse specific commit
# https://archive.softwareheritage.org/browse/revision/COMMIT_SHA/

# 3. Download from archive
git clone https://archive.softwareheritage.org/browse/origin/directory/?origin_url=https://github.com/Hyperpolymath/zotero-rescript-templater
```

### Verify Zenodo Archive

```bash
# 1. Get DOI metadata
curl -LH "Accept: application/vnd.citationstyles.csl+json" https://doi.org/10.5281/zenodo.CONCEPT_ID

# 2. Download release from Zenodo
curl -LO https://zenodo.org/record/VERSION_ID/files/Hyperpolymath/zotero-rescript-templater-v0.2.0.zip

# 3. Verify checksum (Zenodo provides MD5)
md5sum zotero-rescript-templater-v0.2.0.zip
```

## Citation

### Citing from Software Heritage

```
@misc{zotero_rescript_templater_swh,
  author = {(Author Name)},
  title = {Zotero ReScript Templater},
  year = {2024},
  howpublished = {Software Heritage},
  url = {https://archive.softwareheritage.org/swh:1:dir:...},
  note = {swh:1:dir:...}
}
```

### Citing from Zenodo

```
@software{zotero_rescript_templater_2024,
  author = {(Author Name)},
  title = {Zotero ReScript Templater: A Scaffolding System for Zotero Plugins},
  year = {2024},
  publisher = {Zenodo},
  version = {0.2.0},
  doi = {10.5281/zenodo.VERSION_ID},
  url = {https://doi.org/10.5281/zenodo.VERSION_ID}
}
```

### Recommended Citation

Use the Zenodo DOI for academic papers (provides version-specific citation):

**APA**:
```
(Author Name). (2024). Zotero ReScript Templater: A scaffolding system for
  Zotero plugins (Version 0.2.0) [Computer software]. Zenodo.
  https://doi.org/10.5281/zenodo.VERSION_ID
```

**IEEE**:
```
[1] (Author Name), "Zotero ReScript Templater: A Scaffolding System for
    Zotero Plugins," version 0.2.0, Zenodo, 2024. [Online].
    Available: https://doi.org/10.5281/zenodo.VERSION_ID
```

## Benefits of Dual Archival

| Aspect | Software Heritage | Zenodo |
|--------|------------------|--------|
| **Primary goal** | Universal source code archive | Academic research data |
| **Identifier** | SWHID (intrinsic, content-based) | DOI (assigned, mutable) |
| **Longevity** | Multi-century (UNESCO) | Decades (CERN) |
| **Granularity** | File, directory, commit, snapshot | Release archive |
| **Metadata** | Minimal (extracted from Git) | Rich (custom .zenodo.json) |
| **Citation** | SWHID in papers | DOI in papers |
| **Version tracking** | All commits | Tagged releases only |
| **Automation** | Automatic crawling | GitHub integration |

**Recommendation**: Use both for maximum preservation and citability.

## Troubleshooting

### Software Heritage: "Origin not found"

```bash
# Repository not yet archived - request immediate archival
curl -X POST https://archive.softwareheritage.org/api/1/origin/save/git/url/https://github.com/Hyperpolymath/zotero-rescript-templater/

# Wait 10-60 minutes for crawling
# Check status:
curl https://archive.softwareheritage.org/api/1/origin/save/git/url/https://github.com/Hyperpolymath/zotero-rescript-templater/ | jq
```

### Zenodo: "Release not archived"

1. Check GitHub integration: https://zenodo.org/account/settings/github/
2. Verify webhook exists in repository settings
3. Toggle repository switch off and on
4. Create a new release (triggers archival)

### Zenodo: "Wrong metadata"

1. Fix `.zenodo.json` in repository
2. Create new git tag and release
3. Or edit on Zenodo website (creates new version)

### Software Heritage: Rate limiting

```bash
# If you get 429 Too Many Requests:
# Wait 1 hour and try again
# Or check status instead of requesting:
curl https://archive.softwareheritage.org/api/1/origin/https://github.com/Hyperpolymath/zotero-rescript-templater/visits/
```

## Maintenance

### Annual Tasks

1. **Verify archival status** (both SWH and Zenodo)
2. **Update .zenodo.json** if metadata changes
3. **Refresh CITATION.cff** with latest DOIs
4. **Check archive completeness** (all releases archived)
5. **Update README badges** with latest status

### When Moving Repositories

If repository URL changes:

**Software Heritage**:
```bash
# Request archival at new URL
curl -X POST https://archive.softwareheritage.org/api/1/origin/save/git/url/NEW_URL/
```

**Zenodo**:
1. Disable old repository in Zenodo settings
2. Enable new repository
3. Update DOI landing page with new URL (via Zenodo website)

### When Deprecating Project

If project becomes deprecated:

1. Create final release with deprecation notice
2. Ensure both archives have captured final state
3. Add deprecation notice to:
   - README.md
   - Zenodo metadata (edit record)
   - Software Heritage (via commit message)
4. Update CITATION.cff with deprecated status
5. Lock GitHub repository (optional)

## Additional Resources

- **Software Heritage API**: https://archive.softwareheritage.org/api/
- **Software Heritage Documentation**: https://docs.softwareheritage.org/
- **Zenodo Documentation**: https://help.zenodo.org/
- **Zenodo API**: https://developers.zenodo.org/
- **DOI Handbook**: https://www.doi.org/the-identifier/resources/handbook
- **SWHID Specification**: https://docs.softwareheritage.org/devel/swh-model/persistent-identifiers.html

## Quick Reference

```bash
# Request Software Heritage archival
curl -X POST https://archive.softwareheritage.org/api/1/origin/save/git/url/https://github.com/Hyperpolymath/zotero-rescript-templater/

# Check Software Heritage status
curl https://archive.softwareheritage.org/api/1/origin/https://github.com/Hyperpolymath/zotero-rescript-templater/visits/

# Create Zenodo-archived release
git tag v0.2.0
git push origin v0.2.0
gh release create v0.2.0

# Verify Zenodo integration
# Visit: https://zenodo.org/account/settings/github/
```

---

**Last Updated**: 2024-11-22
**Maintainer**: See [MAINTAINERS.md](MAINTAINERS.md)
**License**: AGPL-3.0-only
**Related**: [PUBLISHING.md](PUBLISHING.md), [CITATION.cff](CITATION.cff), [.zenodo.json](.zenodo.json)
