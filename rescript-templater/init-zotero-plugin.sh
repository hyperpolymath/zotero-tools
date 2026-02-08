#!/usr/bin/env bash

# Zotero Plugin Scaffolder - Bash/Shell Version
# For Linux and macOS users
#
# Usage:
#   ./init-zotero-plugin.sh -n ProjectName -a "Author Name" -t template_type [-g]
#
# Options:
#   -n  Project name (required)
#   -a  Author name (required)
#   -t  Template type: practitioner|researcher|student (default: student)
#   -g  Initialize git repository
#   -v  Verify integrity of existing project
#   -h  Show help

set -euo pipefail

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Default values
PROJECT_NAME=""
AUTHOR_NAME=""
TEMPLATE_TYPE="student"
GIT_INIT=false
VERIFY_INTEGRITY=false

# Functions
usage() {
  cat <<EOF
Zotero Plugin Scaffolder - Bash Version

Usage:
  $0 -n ProjectName -a "Author Name" [-t template] [-g] [-v]

Options:
  -n NAME       Project name (required)
  -a AUTHOR     Author name (required)
  -t TEMPLATE   Template type: practitioner|researcher|student (default: student)
  -g            Initialize git repository
  -v            Verify integrity of existing project
  -h            Show this help message

Examples:
  # Create a student plugin
  $0 -n MyPlugin -a "John Doe"

  # Create a practitioner plugin with git
  $0 -n AdvancedPlugin -a "Jane Smith" -t practitioner -g

  # Verify integrity
  $0 -n MyPlugin -v

EOF
  exit 0
}

error() {
  echo -e "${RED}Error: $1${NC}" >&2
  exit 1
}

info() {
  echo -e "${CYAN}$1${NC}"
}

success() {
  echo -e "${GREEN}$1${NC}"
}

warning() {
  echo -e "${YELLOW}$1${NC}"
}

# XXHash64 implementation using xxhsum if available, fallback to sha256
compute_hash() {
  local file="$1"

  if command -v xxhsum &> /dev/null; then
    xxhsum -H64 "$file" | awk '{print $1}'
  elif command -v xxh64sum &> /dev/null; then
    xxh64sum "$file" | awk '{print $1}'
  else
    # Fallback to SHA256 if xxhash not available
    if [[ "$OSTYPE" == "darwin"* ]]; then
      shasum -a 256 "$file" | awk '{print $1}'
    else
      sha256sum "$file" | awk '{print $1}'
    fi
  fi
}

# Verify file integrity
verify_integrity() {
  local project="$1"
  local audit_file="$project/audit-index.json"

  if [[ ! -f "$audit_file" ]]; then
    error "audit-index.json not found in $project"
  fi

  info "Verifying integrity via audit-index.json..."

  local fail_count=0

  # Read audit file and verify each file
  # Note: This uses Python for JSON parsing if available, otherwise falls back to jq
  if command -v python3 &> /dev/null; then
    python3 <<EOF
import json
import sys
import os

with open('$audit_file', 'r') as f:
    audit = json.load(f)

fail_count = 0
for file_entry in audit['files']:
    path = os.path.join('$project', file_entry['path'])
    expected_hash = file_entry['hash']

    if not os.path.exists(path):
        print(f"⚠️  Missing: {file_entry['path']}", file=sys.stderr)
        fail_count += 1
    else:
        # For simplicity, we'll shell out to compute hash
        import subprocess
        actual_hash = subprocess.check_output(['bash', '-c', 'compute_hash "$0"', path]).decode().strip()

        if actual_hash != expected_hash:
            print(f"⚠️  Hash mismatch: {file_entry['path']}", file=sys.stderr)
            print(f"   expected {expected_hash}", file=sys.stderr)
            print(f"   actual   {actual_hash}", file=sys.stderr)
            fail_count += 1

if fail_count > 0:
    print(f"\\n❌ {fail_count} integrity issue(s) detected.", file=sys.stderr)
    sys.exit(1)
else:
    print("✅ All files intact")
EOF
    exit $?
  elif command -v jq &> /dev/null; then
    while IFS= read -r line; do
      local path=$(echo "$line" | jq -r '.path')
      local expected_hash=$(echo "$line" | jq -r '.hash')
      local full_path="$project/$path"

      if [[ ! -f "$full_path" ]]; then
        warning "Missing: $path"
        ((fail_count++))
      else
        local actual_hash=$(compute_hash "$full_path")
        if [[ "$actual_hash" != "$expected_hash" ]]; then
          warning "Hash mismatch: $path"
          echo "  expected $expected_hash"
          echo "  actual   $actual_hash"
          ((fail_count++))
        fi
      fi
    done < <(jq -c '.files[]' "$audit_file")

    if [[ $fail_count -gt 0 ]]; then
      error "$fail_count integrity issue(s) detected"
    fi
    success "✅ All files intact"
  else
    error "Neither python3 nor jq found. Please install one of them for integrity verification."
  fi
}

# Create a file with variable substitution
create_file() {
  local path="$1"
  local content="$2"

  # Create parent directory if needed
  local dir=$(dirname "$path")
  mkdir -p "$dir"

  # Perform variable substitution
  content="${content//\{\{ProjectName\}\}/$PROJECT_NAME}"
  content="${content//\{\{AuthorName\}\}/$AUTHOR_NAME}"
  content="${content//\{\{version\}\}/0.1.0}"

  # Write file
  echo "$content" > "$path"
}

# Generate audit index
generate_audit_index() {
  local project="$1"
  local audit_file="$project/audit-index.json"

  info "Generating audit-index.json..."

  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

  # Start JSON
  echo "{" > "$audit_file"
  echo "  \"generated\": \"$timestamp\"," >> "$audit_file"
  echo "  \"files\": [" >> "$audit_file"

  local first=true
  while IFS= read -r -d '' file; do
    local rel_path="${file#$project/}"

    # Skip audit-index.json itself
    if [[ "$rel_path" == "audit-index.json" ]]; then
      continue
    fi

    local hash=$(compute_hash "$file")

    if [[ "$first" == true ]]; then
      first=false
    else
      echo "," >> "$audit_file"
    fi

    echo -n "    {\"path\": \"$rel_path\", \"hash\": \"$hash\"}" >> "$audit_file"
  done < <(find "$project" -type f -print0)

  echo "" >> "$audit_file"
  echo "  ]" >> "$audit_file"
  echo "}" >> "$audit_file"

  success "audit-index.json generated"
}

# Scaffold project
scaffold_project() {
  if [[ -d "$PROJECT_NAME" ]]; then
    error "Directory '$PROJECT_NAME' already exists"
  fi

  info "Creating project: $PROJECT_NAME"
  info "Template type: $TEMPLATE_TYPE"

  mkdir -p "$PROJECT_NAME"

  # Load template based on type
  case "$TEMPLATE_TYPE" in
    practitioner)
      scaffold_practitioner
      ;;
    researcher)
      scaffold_researcher
      ;;
    student)
      scaffold_student
      ;;
    *)
      error "Unknown template type: $TEMPLATE_TYPE"
      ;;
  esac

  # Generate audit index
  generate_audit_index "$PROJECT_NAME"

  # Git init if requested
  if [[ "$GIT_INIT" == true ]]; then
    info "Initializing git repository..."
    (cd "$PROJECT_NAME" && git init && git add . && git commit -m "chore: initial commit from scaffolder")
  fi

  success "✅ Project '$PROJECT_NAME' created successfully!"
}

# Template implementations
scaffold_student() {
  info "Scaffolding student template..."

  # README.md
  create_file "$PROJECT_NAME/README.md" "# {{ProjectName}}

A learning-focused Zotero plugin by {{AuthorName}}.

## Educational Purpose

This plugin is designed as a learning project for understanding Zotero plugin development.

## Getting Started

1. Read TUTORIAL.md
2. Install dependencies: \`npm install\`
3. Build: \`npm run build\`

## License

MIT © {{AuthorName}}"

  # TUTORIAL.md
  create_file "$PROJECT_NAME/TUTORIAL.md" "# {{ProjectName}} Tutorial

Welcome to your Zotero plugin learning journey!

## Table of Contents

1. [Understanding Zotero Plugins](#understanding-zotero-plugins)
2. [Project Structure](#project-structure)
3. [Your First Modification](#your-first-modification)

## Understanding Zotero Plugins

Zotero plugins extend the functionality of Zotero...

## Project Structure

\`\`\`
{{ProjectName}}/
├── bootstrap.js      # Plugin entry point
├── chrome/          # UI components
│   ├── content/     # JavaScript logic
│   ├── locale/      # Localization
│   └── skin/        # CSS styles
├── manifest.json    # Plugin manifest (Zotero 7-8)
└── src/            # TypeScript sources
\`\`\`

## Your First Modification

Let's add a simple menu item...

Happy coding! 🎓"

  # manifest.json
  create_file "$PROJECT_NAME/manifest.json" "{
  \"manifest_version\": 2,
  \"name\": \"{{ProjectName}} Student Edition\",
  \"version\": \"{{version}}\",
  \"description\": \"Learning-focused Zotero plugin\",
  \"author\": \"{{AuthorName}}\",
  \"homepage_url\": \"https://github.com/{{AuthorName}}/{{ProjectName}}\",
  \"applications\": {
    \"gecko\": {
      \"id\": \"{{ProjectName}}@student.zotero.org\",
      \"strict_min_version\": \"115.0\",
      \"strict_max_version\": \"8.0.*\"
    }
  },
  \"icons\": {
    \"48\": \"chrome/skin/icon.png\"
  },
  \"background\": {
    \"scripts\": [\"bootstrap.js\"]
  }
}"

  # chrome.manifest
  create_file "$PROJECT_NAME/chrome.manifest" "content {{ProjectName}} chrome/content/
locale {{ProjectName}} en-US chrome/locale/en-US/
skin {{ProjectName}} default chrome/skin/
overlay chrome://zotero/content/zoteroPane.xul chrome://{{ProjectName}}/content/overlay.xul"

  # bootstrap.js
  create_file "$PROJECT_NAME/bootstrap.js" "/**
 * Bootstrap Entry Point - Student Edition
 * This file is heavily commented for educational purposes
 */

const { classes: Cc, interfaces: Ci, utils: Cu } = Components;

function startup({ id, version, resourceURI, rootURI = resourceURI.spec }, reason) {
  Cu.import('resource://gre/modules/Services.jsm');

  // Load main script
  Services.scriptloader.loadSubScript(rootURI + 'chrome/content/main.js');

  if (typeof Zotero === 'undefined') {
    Zotero = {};
  }

  // Initialize plugin
  Zotero.{{ProjectName}} = {
    init: function() {
      console.log('{{ProjectName}} initialized!');
      this.initialized = true;
    },
    shutdown: function() {
      this.initialized = false;
    }
  };

  Zotero.{{ProjectName}}.init();
}

function shutdown({ id, version, resourceURI, rootURI = resourceURI.spec }, reason) {
  if (typeof Zotero !== 'undefined' && Zotero.{{ProjectName}}) {
    Zotero.{{ProjectName}}.shutdown();
  }
}

function install(data, reason) {}
function uninstall(data, reason) {}"

  # chrome/content/main.js
  create_file "$PROJECT_NAME/chrome/content/main.js" "/**
 * Main UI Logic - Student Edition
 * Educational examples with extensive comments
 */

(function() {
  'use strict';

  if (!Zotero.{{ProjectName}}) {
    Zotero.{{ProjectName}} = {};
  }

  Zotero.{{ProjectName}}.UI = {
    sayHello: function() {
      const items = ZoteroPane.getSelectedItems();
      alert(\`Hello! You selected \${items.length} item(s)\`);
    }
  };
})();"

  # chrome/content/overlay.xul
  create_file "$PROJECT_NAME/chrome/content/overlay.xul" "<?xml version=\"1.0\"?>
<overlay id=\"{{ProjectName}}-overlay\"
         xmlns=\"http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul\">
  <script src=\"chrome://{{ProjectName}}/content/main.js\"/>
  <menupopup id=\"zotero-itemmenu\">
    <menuitem id=\"{{ProjectName}}-hello\"
              label=\"Say Hello ({{ProjectName}})\"
              oncommand=\"Zotero.{{ProjectName}}.UI.sayHello();\"/>
  </menupopup>
</overlay>"

  # package.json
  create_file "$PROJECT_NAME/package.json" "{
  \"name\": \"{{ProjectName}}\",
  \"version\": \"{{version}}\",
  \"description\": \"Educational Zotero plugin\",
  \"author\": \"{{AuthorName}}\",
  \"license\": \"MIT\",
  \"scripts\": {
    \"build\": \"tsc\",
    \"watch\": \"tsc --watch\"
  },
  \"devDependencies\": {
    \"typescript\": \"^5.0.0\"
  }
}"

  # .gitignore
  create_file "$PROJECT_NAME/.gitignore" "node_modules/
dist/
*.xpi
.DS_Store
*.log"

  success "Student template created"
}

scaffold_practitioner() {
  info "Scaffolding practitioner template..."

  create_directory "$PROJECT_NAME"
  create_directory "$PROJECT_NAME/chrome/content"
  create_directory "$PROJECT_NAME/chrome/locale/en-US"
  create_directory "$PROJECT_NAME/chrome/skin"
  create_directory "$PROJECT_NAME/src"

  # README.md - Practitioner focused
  create_file "$PROJECT_NAME/README.md" "# {{ProjectName}} - Practitioner Edition

A workflow-focused Zotero plugin for professional practitioners.

## Features

- Quick citation insertion
- Batch operations for large libraries
- Custom citation styles
- Integration with common workflows

## Installation

1. Download the latest \`.xpi\` file
2. In Zotero: Tools → Add-ons → Install Add-on From File
3. Select the downloaded \`.xpi\` file
4. Restart Zotero

## Usage

Access plugin features via Tools → {{ProjectName}} menu."

  # manifest.json - Practitioner edition
  create_file "$PROJECT_NAME/manifest.json" "{
  \"manifest_version\": 2,
  \"name\": \"{{ProjectName}} Practitioner Edition\",
  \"version\": \"{{version}}\",
  \"description\": \"Workflow-focused Zotero plugin for practitioners\",
  \"author\": \"{{AuthorName}}\",
  \"homepage_url\": \"https://github.com/{{AuthorName}}/{{ProjectName}}\",
  \"applications\": {
    \"gecko\": {
      \"id\": \"{{ProjectName}}@practitioner.zotero.org\",
      \"strict_min_version\": \"115.0\",
      \"strict_max_version\": \"8.0.*\"
    }
  },
  \"icons\": {
    \"48\": \"chrome/skin/icon.png\"
  },
  \"background\": {
    \"scripts\": [\"bootstrap.js\"]
  }
}"

  # chrome.manifest
  create_file "$PROJECT_NAME/chrome.manifest" "content {{ProjectName}} chrome/content/
locale {{ProjectName}} en-US chrome/locale/en-US/
skin {{ProjectName}} default chrome/skin/
overlay chrome://zotero/content/zoteroPane.xul chrome://{{ProjectName}}/content/overlay.xul"

  # bootstrap.js - Practitioner edition with workflow features
  create_file "$PROJECT_NAME/bootstrap.js" "/**
 * Bootstrap Entry Point - Practitioner Edition
 * Optimized for professional workflows
 */

const { classes: Cc, interfaces: Ci, utils: Cu } = Components;

function startup({ id, version, resourceURI, rootURI = resourceURI.spec }, reason) {
  Cu.import('resource://gre/modules/Services.jsm');
  Services.scriptloader.loadSubScript(rootURI + 'chrome/content/main.js');

  if (typeof Zotero === 'undefined') {
    Zotero = {};
  }

  Zotero.{{ProjectName}} = {
    version: version,
    rootURI: rootURI,
    initialized: false,

    init: function() {
      this.registerMenus();
      this.initialized = true;
      console.log('{{ProjectName}} Practitioner v' + version + ' initialized');
    },

    registerMenus: function() {
      // Register keyboard shortcuts and menus
    },

    shutdown: function() {
      this.initialized = false;
    }
  };

  Zotero.{{ProjectName}}.init();
}

function shutdown({ id, version, resourceURI, rootURI = resourceURI.spec }, reason) {
  if (typeof Zotero !== 'undefined' && Zotero.{{ProjectName}}) {
    Zotero.{{ProjectName}}.shutdown();
  }
}

function install(data, reason) {}
function uninstall(data, reason) {}"

  # chrome/content/main.js - Practitioner workflow features
  create_file "$PROJECT_NAME/chrome/content/main.js" "/**
 * Main Logic - Practitioner Edition
 * Workflow-focused utilities for professional use
 */

(function() {
  'use strict';

  if (!Zotero.{{ProjectName}}) {
    Zotero.{{ProjectName}} = {};
  }

  Zotero.{{ProjectName}}.Workflow = {
    // Quick citation copy to clipboard
    quickCite: function() {
      const items = ZoteroPane.getSelectedItems();
      if (items.length === 0) {
        alert('Please select at least one item');
        return;
      }
      const citations = items.map(item => {
        const creators = item.getCreators();
        const firstAuthor = creators.length > 0 ? creators[0].lastName : 'Unknown';
        const year = item.getField('date').substring(0, 4) || 'n.d.';
        return '(' + firstAuthor + (creators.length > 1 ? ' et al.' : '') + ', ' + year + ')';
      });
      this.copyToClipboard(citations.join('; '));
      alert('Copied ' + citations.length + ' citation(s) to clipboard');
    },

    // Batch tag selected items
    batchTag: function() {
      const items = ZoteroPane.getSelectedItems();
      if (items.length === 0) {
        alert('Please select items to tag');
        return;
      }
      const tag = prompt('Enter tag to add to ' + items.length + ' item(s):');
      if (tag) {
        items.forEach(item => item.addTag(tag));
        alert('Added tag \"' + tag + '\" to ' + items.length + ' item(s)');
      }
    },

    // Export selected items summary
    exportSummary: function() {
      const items = ZoteroPane.getSelectedItems();
      if (items.length === 0) {
        alert('Please select items to summarize');
        return;
      }
      let summary = '# Bibliography Summary\\n\\n';
      items.forEach(item => {
        summary += '- ' + item.getField('title') + ' (' + item.getField('date').substring(0,4) + ')\\n';
      });
      this.copyToClipboard(summary);
      alert('Summary copied to clipboard');
    },

    copyToClipboard: function(text) {
      const clipboard = Cc['@mozilla.org/widget/clipboard;1'].getService(Ci.nsIClipboard);
      const transferable = Cc['@mozilla.org/widget/transferable;1'].createInstance(Ci.nsITransferable);
      const str = Cc['@mozilla.org/supports-string;1'].createInstance(Ci.nsISupportsString);
      str.data = text;
      transferable.addDataFlavor('text/unicode');
      transferable.setTransferData('text/unicode', str, text.length * 2);
      clipboard.setData(transferable, null, Ci.nsIClipboard.kGlobalClipboard);
    }
  };
})();"

  # chrome/content/overlay.xul - Practitioner menus
  create_file "$PROJECT_NAME/chrome/content/overlay.xul" "<?xml version=\"1.0\"?>
<overlay id=\"{{ProjectName}}-overlay\"
         xmlns=\"http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul\">
  <script src=\"chrome://{{ProjectName}}/content/main.js\"/>
  <menupopup id=\"zotero-itemmenu\">
    <menu id=\"{{ProjectName}}-menu\" label=\"{{ProjectName}}\">
      <menupopup>
        <menuitem id=\"{{ProjectName}}-quickcite\"
                  label=\"Quick Cite\"
                  oncommand=\"Zotero.{{ProjectName}}.Workflow.quickCite();\"/>
        <menuitem id=\"{{ProjectName}}-batchtag\"
                  label=\"Batch Tag Selected\"
                  oncommand=\"Zotero.{{ProjectName}}.Workflow.batchTag();\"/>
        <menuseparator/>
        <menuitem id=\"{{ProjectName}}-summary\"
                  label=\"Export Summary\"
                  oncommand=\"Zotero.{{ProjectName}}.Workflow.exportSummary();\"/>
      </menupopup>
    </menu>
  </menupopup>
</overlay>"

  # package.json
  create_file "$PROJECT_NAME/package.json" "{
  \"name\": \"{{ProjectName}}\",
  \"version\": \"{{version}}\",
  \"description\": \"Workflow-focused Zotero plugin for practitioners\",
  \"author\": \"{{AuthorName}}\",
  \"license\": \"MIT\",
  \"scripts\": {
    \"build\": \"tsc\",
    \"watch\": \"tsc --watch\",
    \"package\": \"zip -r {{ProjectName}}.xpi . -x 'node_modules/*' -x 'src/*' -x '*.ts'\"
  },
  \"devDependencies\": {
    \"typescript\": \"^5.0.0\"
  }
}"

  # .gitignore
  create_file "$PROJECT_NAME/.gitignore" "node_modules/
dist/
*.xpi
.DS_Store
*.log"

  success "Practitioner template created"
}

scaffold_researcher() {
  info "Scaffolding researcher template..."

  create_directory "$PROJECT_NAME"
  create_directory "$PROJECT_NAME/chrome/content"
  create_directory "$PROJECT_NAME/chrome/locale/en-US"
  create_directory "$PROJECT_NAME/chrome/skin"
  create_directory "$PROJECT_NAME/src"
  create_directory "$PROJECT_NAME/data"

  # README.md - Researcher focused
  create_file "$PROJECT_NAME/README.md" "# {{ProjectName}} - Researcher Edition

An advanced Zotero plugin for academic researchers with citation analysis features.

## Features

- Citation network analysis
- Duplicate detection and merging
- Metadata validation and enrichment
- Export to multiple formats (BibTeX, RIS, JSON-LD)
- Statistical summaries of your library

## Installation

1. Download the latest \`.xpi\` file
2. In Zotero: Tools → Add-ons → Install Add-on From File
3. Select the downloaded \`.xpi\` file
4. Restart Zotero

## Usage

Access features via:
- Tools → {{ProjectName}} menu
- Right-click context menu on selected items"

  # manifest.json - Researcher edition
  create_file "$PROJECT_NAME/manifest.json" "{
  \"manifest_version\": 2,
  \"name\": \"{{ProjectName}} Researcher Edition\",
  \"version\": \"{{version}}\",
  \"description\": \"Advanced citation analysis for academic researchers\",
  \"author\": \"{{AuthorName}}\",
  \"homepage_url\": \"https://github.com/{{AuthorName}}/{{ProjectName}}\",
  \"applications\": {
    \"gecko\": {
      \"id\": \"{{ProjectName}}@researcher.zotero.org\",
      \"strict_min_version\": \"115.0\",
      \"strict_max_version\": \"8.0.*\"
    }
  },
  \"icons\": {
    \"48\": \"chrome/skin/icon.png\"
  },
  \"background\": {
    \"scripts\": [\"bootstrap.js\"]
  }
}"

  # chrome.manifest
  create_file "$PROJECT_NAME/chrome.manifest" "content {{ProjectName}} chrome/content/
locale {{ProjectName}} en-US chrome/locale/en-US/
skin {{ProjectName}} default chrome/skin/
overlay chrome://zotero/content/zoteroPane.xul chrome://{{ProjectName}}/content/overlay.xul"

  # bootstrap.js - Researcher edition
  create_file "$PROJECT_NAME/bootstrap.js" "/**
 * Bootstrap Entry Point - Researcher Edition
 * Advanced features for academic research workflows
 */

const { classes: Cc, interfaces: Ci, utils: Cu } = Components;

function startup({ id, version, resourceURI, rootURI = resourceURI.spec }, reason) {
  Cu.import('resource://gre/modules/Services.jsm');
  Services.scriptloader.loadSubScript(rootURI + 'chrome/content/main.js');
  Services.scriptloader.loadSubScript(rootURI + 'chrome/content/analysis.js');

  if (typeof Zotero === 'undefined') {
    Zotero = {};
  }

  Zotero.{{ProjectName}} = {
    version: version,
    rootURI: rootURI,
    initialized: false,

    init: async function() {
      await Zotero.uiReadyPromise;
      this.registerMenus();
      this.initialized = true;
      console.log('{{ProjectName}} Researcher v' + version + ' initialized');
    },

    registerMenus: function() {
      // Register menus and keyboard shortcuts
    },

    shutdown: function() {
      this.initialized = false;
    }
  };

  Zotero.{{ProjectName}}.init();
}

function shutdown({ id, version, resourceURI, rootURI = resourceURI.spec }, reason) {
  if (typeof Zotero !== 'undefined' && Zotero.{{ProjectName}}) {
    Zotero.{{ProjectName}}.shutdown();
  }
}

function install(data, reason) {}
function uninstall(data, reason) {}"

  # chrome/content/main.js - Core researcher features
  create_file "$PROJECT_NAME/chrome/content/main.js" "/**
 * Main Logic - Researcher Edition
 * Core utilities for academic researchers
 */

(function() {
  'use strict';

  if (!Zotero.{{ProjectName}}) {
    Zotero.{{ProjectName}} = {};
  }

  Zotero.{{ProjectName}}.Core = {
    // Validate metadata completeness
    validateMetadata: function() {
      const items = ZoteroPane.getSelectedItems();
      if (items.length === 0) {
        alert('Please select items to validate');
        return;
      }

      const issues = [];
      items.forEach(item => {
        const title = item.getField('title');
        const missing = [];
        if (!item.getField('date')) missing.push('date');
        if (!item.getField('DOI') && !item.getField('ISBN')) missing.push('DOI/ISBN');
        if (item.getCreators().length === 0) missing.push('authors');
        if (missing.length > 0) {
          issues.push(title.substring(0, 40) + '... - missing: ' + missing.join(', '));
        }
      });

      if (issues.length === 0) {
        alert('All ' + items.length + ' items have complete metadata!');
      } else {
        alert('Issues found:\\n\\n' + issues.join('\\n'));
      }
    },

    // Find potential duplicates
    findDuplicates: function() {
      const items = ZoteroPane.getSelectedItems();
      if (items.length < 2) {
        alert('Select at least 2 items to check for duplicates');
        return;
      }

      const titles = {};
      const duplicates = [];

      items.forEach(item => {
        const title = item.getField('title').toLowerCase().trim();
        const normalized = title.replace(/[^a-z0-9]/g, '');
        if (titles[normalized]) {
          duplicates.push(item.getField('title'));
        } else {
          titles[normalized] = true;
        }
      });

      if (duplicates.length === 0) {
        alert('No duplicates found among ' + items.length + ' items');
      } else {
        alert('Potential duplicates:\\n\\n' + duplicates.join('\\n'));
      }
    },

    // Export as JSON-LD (schema.org compatible)
    exportJsonLd: function() {
      const items = ZoteroPane.getSelectedItems();
      if (items.length === 0) {
        alert('Please select items to export');
        return;
      }

      const jsonld = items.map(item => ({
        '@context': 'https://schema.org',
        '@type': 'ScholarlyArticle',
        'name': item.getField('title'),
        'datePublished': item.getField('date'),
        'author': item.getCreators().map(c => ({
          '@type': 'Person',
          'familyName': c.lastName,
          'givenName': c.firstName
        })),
        'identifier': item.getField('DOI') ? {
          '@type': 'PropertyValue',
          'propertyID': 'DOI',
          'value': item.getField('DOI')
        } : undefined
      }));

      this.copyToClipboard(JSON.stringify(jsonld, null, 2));
      alert('JSON-LD exported to clipboard (' + items.length + ' items)');
    },

    copyToClipboard: function(text) {
      const clipboard = Cc['@mozilla.org/widget/clipboard;1'].getService(Ci.nsIClipboard);
      const transferable = Cc['@mozilla.org/widget/transferable;1'].createInstance(Ci.nsITransferable);
      const str = Cc['@mozilla.org/supports-string;1'].createInstance(Ci.nsISupportsString);
      str.data = text;
      transferable.addDataFlavor('text/unicode');
      transferable.setTransferData('text/unicode', str, text.length * 2);
      clipboard.setData(transferable, null, Ci.nsIClipboard.kGlobalClipboard);
    }
  };
})();"

  # chrome/content/analysis.js - Statistical analysis features
  create_file "$PROJECT_NAME/chrome/content/analysis.js" "/**
 * Analysis Module - Researcher Edition
 * Statistical and citation analysis features
 */

(function() {
  'use strict';

  if (!Zotero.{{ProjectName}}) {
    Zotero.{{ProjectName}} = {};
  }

  Zotero.{{ProjectName}}.Analysis = {
    // Generate library statistics
    libraryStats: function() {
      const items = ZoteroPane.getSelectedItems();
      const collection = items.length > 0 ? items : Zotero.Items.getAll(Zotero.Libraries.userLibraryID);

      const stats = {
        total: collection.length,
        byType: {},
        byYear: {},
        withDOI: 0,
        withAbstract: 0
      };

      collection.forEach(item => {
        if (item.isRegularItem()) {
          // By type
          const type = item.itemType;
          stats.byType[type] = (stats.byType[type] || 0) + 1;

          // By year
          const year = item.getField('date').substring(0, 4);
          if (year) {
            stats.byYear[year] = (stats.byYear[year] || 0) + 1;
          }

          // Metadata completeness
          if (item.getField('DOI')) stats.withDOI++;
          if (item.getField('abstractNote')) stats.withAbstract++;
        }
      });

      let report = '=== Library Statistics ===\\n\\n';
      report += 'Total items: ' + stats.total + '\\n';
      report += 'With DOI: ' + stats.withDOI + ' (' + Math.round(stats.withDOI/stats.total*100) + '%)\\n';
      report += 'With abstract: ' + stats.withAbstract + ' (' + Math.round(stats.withAbstract/stats.total*100) + '%)\\n\\n';

      report += '--- By Type ---\\n';
      Object.entries(stats.byType).sort((a,b) => b[1]-a[1]).forEach(([type, count]) => {
        report += type + ': ' + count + '\\n';
      });

      report += '\\n--- By Year (top 10) ---\\n';
      Object.entries(stats.byYear).sort((a,b) => b[0]-a[0]).slice(0, 10).forEach(([year, count]) => {
        report += year + ': ' + count + '\\n';
      });

      alert(report);
    },

    // Find items missing abstracts
    findMissingAbstracts: function() {
      const items = ZoteroPane.getSelectedItems();
      if (items.length === 0) {
        alert('Please select items to check');
        return;
      }

      const missing = items.filter(item => !item.getField('abstractNote'));
      if (missing.length === 0) {
        alert('All selected items have abstracts!');
      } else {
        alert(missing.length + ' of ' + items.length + ' items are missing abstracts');
      }
    }
  };
})();"

  # chrome/content/overlay.xul - Researcher menus
  create_file "$PROJECT_NAME/chrome/content/overlay.xul" "<?xml version=\"1.0\"?>
<overlay id=\"{{ProjectName}}-overlay\"
         xmlns=\"http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul\">
  <script src=\"chrome://{{ProjectName}}/content/main.js\"/>
  <script src=\"chrome://{{ProjectName}}/content/analysis.js\"/>
  <menupopup id=\"zotero-itemmenu\">
    <menu id=\"{{ProjectName}}-menu\" label=\"{{ProjectName}}\">
      <menupopup>
        <menuitem id=\"{{ProjectName}}-validate\"
                  label=\"Validate Metadata\"
                  oncommand=\"Zotero.{{ProjectName}}.Core.validateMetadata();\"/>
        <menuitem id=\"{{ProjectName}}-duplicates\"
                  label=\"Find Duplicates\"
                  oncommand=\"Zotero.{{ProjectName}}.Core.findDuplicates();\"/>
        <menuseparator/>
        <menuitem id=\"{{ProjectName}}-stats\"
                  label=\"Library Statistics\"
                  oncommand=\"Zotero.{{ProjectName}}.Analysis.libraryStats();\"/>
        <menuitem id=\"{{ProjectName}}-abstracts\"
                  label=\"Find Missing Abstracts\"
                  oncommand=\"Zotero.{{ProjectName}}.Analysis.findMissingAbstracts();\"/>
        <menuseparator/>
        <menuitem id=\"{{ProjectName}}-jsonld\"
                  label=\"Export as JSON-LD\"
                  oncommand=\"Zotero.{{ProjectName}}.Core.exportJsonLd();\"/>
      </menupopup>
    </menu>
  </menupopup>
</overlay>"

  # package.json
  create_file "$PROJECT_NAME/package.json" "{
  \"name\": \"{{ProjectName}}\",
  \"version\": \"{{version}}\",
  \"description\": \"Advanced citation analysis plugin for academic researchers\",
  \"author\": \"{{AuthorName}}\",
  \"license\": \"MIT\",
  \"scripts\": {
    \"build\": \"tsc\",
    \"watch\": \"tsc --watch\",
    \"package\": \"zip -r {{ProjectName}}.xpi . -x 'node_modules/*' -x 'src/*' -x '*.ts' -x 'data/*'\",
    \"test\": \"echo 'No tests configured'\"
  },
  \"devDependencies\": {
    \"typescript\": \"^5.0.0\"
  }
}"

  # .gitignore
  create_file "$PROJECT_NAME/.gitignore" "node_modules/
dist/
*.xpi
.DS_Store
*.log
data/"

  success "Researcher template created"
}

# Parse command line arguments
while getopts ":n:a:t:gvh" opt; do
  case $opt in
    n)
      PROJECT_NAME="$OPTARG"
      ;;
    a)
      AUTHOR_NAME="$OPTARG"
      ;;
    t)
      TEMPLATE_TYPE="$OPTARG"
      ;;
    g)
      GIT_INIT=true
      ;;
    v)
      VERIFY_INTEGRITY=true
      ;;
    h)
      usage
      ;;
    \?)
      error "Invalid option: -$OPTARG"
      ;;
    :)
      error "Option -$OPTARG requires an argument"
      ;;
  esac
done

# Main execution
main() {
  if [[ "$VERIFY_INTEGRITY" == true ]]; then
    if [[ -z "$PROJECT_NAME" ]]; then
      error "Project name (-n) is required for integrity verification"
    fi
    verify_integrity "$PROJECT_NAME"
    exit 0
  fi

  # Validate required arguments
  if [[ -z "$PROJECT_NAME" ]]; then
    error "Project name (-n) is required"
  fi

  if [[ -z "$AUTHOR_NAME" ]]; then
    error "Author name (-a) is required"
  fi

  # Scaffold the project
  scaffold_project
}

main
