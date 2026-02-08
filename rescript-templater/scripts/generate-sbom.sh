#!/usr/bin/env bash
# generate-sbom.sh - Generate Software Bill of Materials (SBOM)
#
# Usage: ./scripts/generate-sbom.sh [format]
# Example: ./scripts/generate-sbom.sh spdx
# Example: ./scripts/generate-sbom.sh cyclonedx
# Example: ./scripts/generate-sbom.sh all
#
# Generates SBOM in multiple formats:
# - SPDX 2.3 (JSON) - Industry standard, NTIA compliant
# - CycloneDX 1.5 (JSON) - OWASP standard for supply chain
# - Custom (JSON) - Project-specific format
#
# Prerequisites:
# - jq (JSON processing)
# - Optional: syft (for automated dependency scanning)
#
# Output files:
# - sbom-spdx.json (SPDX format)
# - sbom-cyclonedx.json (CycloneDX format)
# - sbom-custom.json (Custom format)

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

# Format argument (default: all)
FORMAT="${1:-all}"

# Validate format
case "$FORMAT" in
    spdx|cyclonedx|custom|all)
        ;;
    *)
        log_error "Invalid format: $FORMAT"
        echo "Valid formats: spdx, cyclonedx, custom, all"
        exit 1
        ;;
esac

# Check prerequisites
log_info "Checking prerequisites..."

if ! command -v jq &> /dev/null; then
    log_error "jq not found. Please install jq."
    echo "  Ubuntu/Debian: sudo apt-get install jq"
    echo "  macOS: brew install jq"
    echo "  Windows: choco install jq"
    exit 1
fi

log_success "Prerequisites met"

# Project metadata
PROJECT_NAME="zotero-rescript-templater"
PROJECT_VERSION="0.2.0"
PROJECT_URL="https://github.com/Hyperpolymath/zotero-rescript-templater"
PROJECT_LICENSE="AGPL-3.0-only"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Generate SPDX SBOM
generate_spdx() {
    log_info "Generating SPDX 2.3 SBOM..."

    cat > sbom-spdx.json << EOF
{
  "SPDXID": "SPDXRef-DOCUMENT",
  "spdxVersion": "SPDX-2.3",
  "creationInfo": {
    "created": "${TIMESTAMP}",
    "creators": [
      "Tool: generate-sbom.sh",
      "Organization: Zotero ReScript Templater Project"
    ],
    "licenseListVersion": "3.21"
  },
  "name": "${PROJECT_NAME}",
  "dataLicense": "CC0-1.0",
  "documentNamespace": "${PROJECT_URL}/sbom/spdx/${PROJECT_VERSION}",
  "documentDescribes": [
    "SPDXRef-Package-${PROJECT_NAME}"
  ],
  "packages": [
    {
      "SPDXID": "SPDXRef-Package-${PROJECT_NAME}",
      "name": "${PROJECT_NAME}",
      "versionInfo": "${PROJECT_VERSION}",
      "downloadLocation": "${PROJECT_URL}/archive/refs/tags/v${PROJECT_VERSION}.tar.gz",
      "homepage": "${PROJECT_URL}",
      "licenseConcluded": "${PROJECT_LICENSE}",
      "licenseDeclared": "${PROJECT_LICENSE}",
      "copyrightText": "Copyright (c) 2024 Zotero ReScript Templater Contributors",
      "summary": "Scaffolding system for Zotero plugins with RSR compliance",
      "description": "Comprehensive scaffolding system for creating Zotero plugins with type-safe, memory-safe, and offline-first architecture. Implements the Rhodium Standard Repository (RSR) framework.",
      "supplier": "Organization: Zotero ReScript Templater Project",
      "filesAnalyzed": true,
      "externalRefs": [
        {
          "referenceCategory": "PACKAGE-MANAGER",
          "referenceType": "purl",
          "referenceLocator": "pkg:github/Hyperpolymath/${PROJECT_NAME}@${PROJECT_VERSION}"
        }
      ]
    },
    {
      "SPDXID": "SPDXRef-Package-PowerShell",
      "name": "PowerShell",
      "versionInfo": "7.4+",
      "downloadLocation": "https://github.com/PowerShell/PowerShell",
      "licenseConcluded": "MIT",
      "licenseDeclared": "MIT",
      "copyrightText": "Copyright (c) Microsoft Corporation",
      "summary": "PowerShell runtime for scaffolder",
      "externalRefs": [
        {
          "referenceCategory": "PACKAGE-MANAGER",
          "referenceType": "purl",
          "referenceLocator": "pkg:github/PowerShell/PowerShell@7.4"
        }
      ]
    },
    {
      "SPDXID": "SPDXRef-Package-Racket",
      "name": "Racket",
      "versionInfo": "8.12+",
      "downloadLocation": "https://racket-lang.org/",
      "licenseConcluded": "Apache-2.0 OR MIT",
      "licenseDeclared": "Apache-2.0 OR MIT",
      "copyrightText": "Copyright (c) PLT Design Inc.",
      "summary": "Racket runtime for homoiconic scaffolder",
      "externalRefs": [
        {
          "referenceCategory": "PACKAGE-MANAGER",
          "referenceType": "purl",
          "referenceLocator": "pkg:generic/racket@8.12"
        }
      ]
    },
    {
      "SPDXID": "SPDXRef-Package-Pester",
      "name": "Pester",
      "versionInfo": "5.5.0",
      "downloadLocation": "https://pester.dev/",
      "licenseConcluded": "Apache-2.0",
      "licenseDeclared": "Apache-2.0",
      "copyrightText": "Copyright (c) Pester Team",
      "summary": "PowerShell testing framework",
      "externalRefs": [
        {
          "referenceCategory": "PACKAGE-MANAGER",
          "referenceType": "purl",
          "referenceLocator": "pkg:nuget/Pester@5.5.0"
        }
      ]
    },
    {
      "SPDXID": "SPDXRef-Package-rackunit",
      "name": "rackunit",
      "versionInfo": "bundled",
      "downloadLocation": "https://docs.racket-lang.org/rackunit/",
      "licenseConcluded": "Apache-2.0 OR MIT",
      "licenseDeclared": "Apache-2.0 OR MIT",
      "copyrightText": "Copyright (c) PLT Design Inc.",
      "summary": "Racket unit testing framework"
    },
    {
      "SPDXID": "SPDXRef-Package-rackcheck",
      "name": "rackcheck",
      "versionInfo": "latest",
      "downloadLocation": "https://docs.racket-lang.org/rackcheck/",
      "licenseConcluded": "Apache-2.0 OR MIT",
      "licenseDeclared": "Apache-2.0 OR MIT",
      "copyrightText": "Copyright (c) Racket contributors",
      "summary": "Property-based testing for Racket"
    }
  ],
  "relationships": [
    {
      "spdxElementId": "SPDXRef-DOCUMENT",
      "relationshipType": "DESCRIBES",
      "relatedSpdxElement": "SPDXRef-Package-${PROJECT_NAME}"
    },
    {
      "spdxElementId": "SPDXRef-Package-${PROJECT_NAME}",
      "relationshipType": "DEPENDS_ON",
      "relatedSpdxElement": "SPDXRef-Package-PowerShell"
    },
    {
      "spdxElementId": "SPDXRef-Package-${PROJECT_NAME}",
      "relationshipType": "DEPENDS_ON",
      "relatedSpdxElement": "SPDXRef-Package-Racket"
    },
    {
      "spdxElementId": "SPDXRef-Package-${PROJECT_NAME}",
      "relationshipType": "TEST_DEPENDENCY_OF",
      "relatedSpdxElement": "SPDXRef-Package-Pester"
    },
    {
      "spdxElementId": "SPDXRef-Package-${PROJECT_NAME}",
      "relationshipType": "TEST_DEPENDENCY_OF",
      "relatedSpdxElement": "SPDXRef-Package-rackunit"
    },
    {
      "spdxElementId": "SPDXRef-Package-${PROJECT_NAME}",
      "relationshipType": "TEST_DEPENDENCY_OF",
      "relatedSpdxElement": "SPDXRef-Package-rackcheck"
    }
  ]
}
EOF

    # Validate JSON
    if jq empty sbom-spdx.json 2>/dev/null; then
        log_success "Generated sbom-spdx.json (SPDX 2.3)"
    else
        log_error "Failed to generate valid SPDX SBOM"
        return 1
    fi
}

# Generate CycloneDX SBOM
generate_cyclonedx() {
    log_info "Generating CycloneDX 1.5 SBOM..."

    cat > sbom-cyclonedx.json << EOF
{
  "bomFormat": "CycloneDX",
  "specVersion": "1.5",
  "serialNumber": "urn:uuid:$(uuidgen 2>/dev/null || echo "00000000-0000-0000-0000-000000000000")",
  "version": 1,
  "metadata": {
    "timestamp": "${TIMESTAMP}",
    "tools": [
      {
        "vendor": "Zotero ReScript Templater",
        "name": "generate-sbom.sh",
        "version": "1.0.0"
      }
    ],
    "component": {
      "type": "application",
      "bom-ref": "pkg:github/Hyperpolymath/${PROJECT_NAME}@${PROJECT_VERSION}",
      "name": "${PROJECT_NAME}",
      "version": "${PROJECT_VERSION}",
      "description": "Comprehensive scaffolding system for creating Zotero plugins with type-safe, memory-safe, and offline-first architecture",
      "licenses": [
        {
          "license": {
            "id": "${PROJECT_LICENSE}"
          }
        }
      ],
      "purl": "pkg:github/Hyperpolymath/${PROJECT_NAME}@${PROJECT_VERSION}",
      "externalReferences": [
        {
          "type": "website",
          "url": "${PROJECT_URL}"
        },
        {
          "type": "vcs",
          "url": "${PROJECT_URL}.git"
        },
        {
          "type": "issue-tracker",
          "url": "${PROJECT_URL}/issues"
        },
        {
          "type": "documentation",
          "url": "${PROJECT_URL}/blob/main/README.md"
        }
      ]
    }
  },
  "components": [
    {
      "type": "application",
      "bom-ref": "pkg:github/PowerShell/PowerShell@7.4",
      "name": "PowerShell",
      "version": "7.4+",
      "description": "Cross-platform automation and configuration tool",
      "licenses": [
        {
          "license": {
            "id": "MIT"
          }
        }
      ],
      "purl": "pkg:github/PowerShell/PowerShell@7.4",
      "externalReferences": [
        {
          "type": "website",
          "url": "https://github.com/PowerShell/PowerShell"
        }
      ]
    },
    {
      "type": "application",
      "bom-ref": "pkg:generic/racket@8.12",
      "name": "Racket",
      "version": "8.12+",
      "description": "General-purpose programming language in the Lisp-Scheme family",
      "licenses": [
        {
          "expression": "Apache-2.0 OR MIT"
        }
      ],
      "purl": "pkg:generic/racket@8.12",
      "externalReferences": [
        {
          "type": "website",
          "url": "https://racket-lang.org/"
        }
      ]
    },
    {
      "type": "library",
      "bom-ref": "pkg:nuget/Pester@5.5.0",
      "name": "Pester",
      "version": "5.5.0",
      "description": "PowerShell testing and mocking framework",
      "scope": "required",
      "licenses": [
        {
          "license": {
            "id": "Apache-2.0"
          }
        }
      ],
      "purl": "pkg:nuget/Pester@5.5.0",
      "externalReferences": [
        {
          "type": "website",
          "url": "https://pester.dev/"
        }
      ]
    },
    {
      "type": "library",
      "bom-ref": "pkg:racket/rackunit",
      "name": "rackunit",
      "description": "Unit testing framework for Racket",
      "scope": "required",
      "licenses": [
        {
          "expression": "Apache-2.0 OR MIT"
        }
      ]
    },
    {
      "type": "library",
      "bom-ref": "pkg:racket/rackcheck",
      "name": "rackcheck",
      "description": "Property-based testing for Racket (QuickCheck-style)",
      "scope": "optional",
      "licenses": [
        {
          "expression": "Apache-2.0 OR MIT"
        }
      ]
    }
  ],
  "dependencies": [
    {
      "ref": "pkg:github/Hyperpolymath/${PROJECT_NAME}@${PROJECT_VERSION}",
      "dependsOn": [
        "pkg:github/PowerShell/PowerShell@7.4",
        "pkg:generic/racket@8.12",
        "pkg:nuget/Pester@5.5.0",
        "pkg:racket/rackunit",
        "pkg:racket/rackcheck"
      ]
    }
  ],
  "compositions": {
    "aggregate": "complete"
  }
}
EOF

    # Validate JSON
    if jq empty sbom-cyclonedx.json 2>/dev/null; then
        log_success "Generated sbom-cyclonedx.json (CycloneDX 1.5)"
    else
        log_error "Failed to generate valid CycloneDX SBOM"
        return 1
    fi
}

# Generate custom SBOM
generate_custom() {
    log_info "Generating custom SBOM..."

    cat > sbom-custom.json << EOF
{
  "project": {
    "name": "${PROJECT_NAME}",
    "version": "${PROJECT_VERSION}",
    "url": "${PROJECT_URL}",
    "license": "${PROJECT_LICENSE}",
    "description": "Scaffolding system for Zotero plugins with RSR framework compliance",
    "generated": "${TIMESTAMP}"
  },
  "rsr_compliance": {
    "level": "Platinum",
    "score": "93.5%",
    "framework_version": "1.0"
  },
  "governance": {
    "model": "TPCF",
    "version": "1.0",
    "perimeters": 3
  },
  "languages": {
    "primary": [
      {"name": "PowerShell", "version": "7.4+", "purpose": "Windows scaffolder"},
      {"name": "Racket", "version": "8.12+", "purpose": "Homoiconic scaffolder"},
      {"name": "Bash", "version": "5.0+", "purpose": "Linux/macOS scaffolder"}
    ],
    "generated": [
      {"name": "ReScript", "purpose": "Practitioner template"},
      {"name": "TypeScript", "purpose": "Student template"},
      {"name": "JavaScript", "purpose": "Researcher template"}
    ]
  },
  "dependencies": {
    "runtime": [
      {
        "name": "PowerShell",
        "version": "7.4+",
        "license": "MIT",
        "url": "https://github.com/PowerShell/PowerShell",
        "required": true,
        "platform": ["Windows", "Linux", "macOS"]
      },
      {
        "name": "Racket",
        "version": "8.12+",
        "license": "Apache-2.0 OR MIT",
        "url": "https://racket-lang.org/",
        "required": true,
        "platform": ["Windows", "Linux", "macOS"]
      },
      {
        "name": "Bash",
        "version": "5.0+",
        "license": "GPL-3.0+",
        "url": "https://www.gnu.org/software/bash/",
        "required": false,
        "platform": ["Linux", "macOS"]
      }
    ],
    "testing": [
      {
        "name": "Pester",
        "version": "5.5.0",
        "license": "Apache-2.0",
        "url": "https://pester.dev/",
        "purpose": "PowerShell unit testing"
      },
      {
        "name": "rackunit",
        "version": "bundled",
        "license": "Apache-2.0 OR MIT",
        "url": "https://docs.racket-lang.org/rackunit/",
        "purpose": "Racket unit testing"
      },
      {
        "name": "rackcheck",
        "version": "latest",
        "license": "Apache-2.0 OR MIT",
        "url": "https://docs.racket-lang.org/rackcheck/",
        "purpose": "Property-based testing"
      }
    ],
    "build": [
      {
        "name": "just",
        "version": "1.0+",
        "license": "CC0-1.0",
        "url": "https://github.com/casey/just",
        "purpose": "Build automation"
      },
      {
        "name": "nix",
        "version": "2.0+",
        "license": "LGPL-2.1",
        "url": "https://nixos.org/",
        "purpose": "Reproducible builds"
      }
    ],
    "optional": [
      {
        "name": "podman",
        "license": "Apache-2.0",
        "url": "https://podman.io/",
        "purpose": "Container development"
      },
      {
        "name": "docker",
        "license": "Apache-2.0",
        "url": "https://www.docker.com/",
        "purpose": "Container development"
      }
    ]
  },
  "security": {
    "gpg_signing": true,
    "integrity_verification": "XXHash64",
    "vulnerability_disclosure": ".well-known/security.txt",
    "security_policy": "SECURITY.md"
  },
  "distribution": {
    "channels": [
      {"name": "PowerShell Gallery", "url": "https://www.powershellgallery.com/packages/ZoteroReScriptTemplater"},
      {"name": "Racket Package Catalog", "url": "https://pkgs.racket-lang.org/package/zotero-rescript-templater"},
      {"name": "GitHub Releases", "url": "${PROJECT_URL}/releases"},
      {"name": "GitHub Container Registry", "url": "ghcr.io/hyperpolymath/zotero-rescript-templater"},
      {"name": "Nix Flakes", "url": "github:Hyperpolymath/zotero-rescript-templater"}
    ],
    "archival": [
      {"name": "Software Heritage", "url": "https://archive.softwareheritage.org/"},
      {"name": "Zenodo", "url": "https://zenodo.org/", "doi": "10.5281/zenodo.XXXXXX"}
    ]
  },
  "files": {
    "scaffolders": [
      "init-zotero-rscript-plugin.ps1",
      "init-raczotbuild.rkt",
      "init-zotero-plugin.sh"
    ],
    "documentation": [
      "README.md",
      "CONTRIBUTING.md",
      "CODE_OF_CONDUCT.md",
      "SECURITY.md",
      "CHANGELOG.md",
      "MAINTAINERS.md",
      "RSR_COMPLIANCE.md",
      "TPCF.md",
      "CLAUDE.md",
      "PUBLISHING.md",
      "GPG_SIGNING.md",
      "ARCHIVAL.md"
    ],
    "configuration": [
      "justfile",
      "flake.nix",
      "Containerfile",
      ".editorconfig",
      ".gitignore",
      ".gitattributes",
      "CITATION.cff",
      ".zenodo.json"
    ]
  }
}
EOF

    # Validate JSON
    if jq empty sbom-custom.json 2>/dev/null; then
        log_success "Generated sbom-custom.json (custom format)"
    else
        log_error "Failed to generate valid custom SBOM"
        return 1
    fi
}

# Generate requested formats
case "$FORMAT" in
    spdx)
        generate_spdx
        ;;
    cyclonedx)
        generate_cyclonedx
        ;;
    custom)
        generate_custom
        ;;
    all)
        generate_spdx
        generate_cyclonedx
        generate_custom
        ;;
esac

# Display summary
echo ""
echo "════════════════════════════════════════════════════════════════"
log_success "SBOM generation complete"
echo "════════════════════════════════════════════════════════════════"
echo ""
echo "Generated files:"
ls -lh sbom-*.json 2>/dev/null || echo "  (none)"
echo ""
echo "📦 SBOM Formats:"
echo "  • SPDX 2.3:      Industry standard, NTIA compliant"
echo "  • CycloneDX 1.5: OWASP standard for supply chain"
echo "  • Custom:        Project-specific metadata"
echo ""
echo "🔍 Validation:"
echo "  jq . sbom-spdx.json"
echo "  jq . sbom-cyclonedx.json"
echo "  jq . sbom-custom.json"
echo ""
echo "📤 Include in releases:"
echo "  gh release upload v${PROJECT_VERSION} sbom-*.json"
echo ""
echo "════════════════════════════════════════════════════════════════"
