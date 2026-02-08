# CLAUDE.md - Zotero ReScript Templater

## Project Overview

This is a **Zotero Plugin Scaffolding System** that provides templating tools for creating Zotero plugins. It offers two main implementation approaches:

1. **RacZotBuild** - A Racket-based scaffolder with homoiconic project specifications
2. **PowerShell Scaffolder** - A Windows-native bootstrapping tool with integrity verification

## Project Purpose

The project helps developers quickly bootstrap Zotero plugins with pre-configured templates for different use cases:
- **Practitioner** - Professional plugin development
- **Researcher** - Research-focused plugin development
- **Student** - Educational/learning plugin development

## Key Technologies

- **Languages**: Racket (Scheme dialect), PowerShell, ReScript/ReasonML
- **Tools**: Git, Deno, Dhall, Erlang/OTP, Elixir, PostgreSQL
- **Features**:
  - Template interpolation with variable substitution
  - File integrity verification using XXHash64
  - CI/CD via GitHub Actions
  - Containerization support

## Repository Structure

```
.
├── LICENSE                              # GNU AGPL v3 license
├── init-raczotbuild.rkt                # Racket scaffolding tool
├── init-raczotbuild.bak                # Backup of Racket tool
├── init-zotero-rscript-plugin.ps1      # PowerShell scaffolding tool
└── zotero-template-dependencies.ps1    # Dependency installer for Windows
```

## Core Components

### 1. RacZotBuild (init-raczotbuild.rkt:1-31)

A Racket-based scaffolder that:
- Creates a complete project structure using homoiconic specifications
- Generates `info.rkt`, main modules, templates, tests, and examples
- Supports automatic Git initialization and first commit
- Creates CI/CD workflows for GitHub Actions

**Usage**:
```bash
racket init-raczotbuild.rkt -n ProjectName -a "Author Name" [-g]
```

**Template structure** (init-raczotbuild.rkt:25):
- `raczotbuild/` - Core scaffolding library
- `templates/` - JSON-based template files with variable interpolation
- `tests/` - Rackunit test files
- `examples/` - Example usage scripts
- `.github/workflows/` - CI configuration

### 2. PowerShell Scaffolder (init-zotero-rscript-plugin.ps1:1-185)

A Windows-native tool with advanced features:

**Scaffolding Mode** (init-zotero-rscript-plugin.ps1:99-128):
- Creates project structure from embedded JSON templates
- Variable substitution: `{{ProjectName}}`, `{{AuthorName}}`, `{{version}}`
- Supports three template types: practitioner, researcher, student

**Integrity Verification** (init-zotero-rscript-plugin.ps1:71-97):
- Generates `audit-index.json` with XXHash64 checksums
- Verifies file integrity against stored hashes
- Detects missing files and content modifications

**Git Integration** (init-zotero-rscript-plugin.ps1:131-160):
- Creates `.gitignore`, `LICENSE`, Containerfile
- Sets up `.github/workflows/` for CI/CD

**Usage**:
```powershell
# Create new project
.\init-zotero-rscript-plugin.ps1 -ProjectName MyPlugin -AuthorName "Your Name" -TemplateType practitioner -GitInit

# Verify integrity
.\init-zotero-rscript-plugin.ps1 -ProjectName MyPlugin -VerifyIntegrity
```

### 3. Dependency Installer (zotero-template-dependencies.ps1:1-172)

Bootstraps the development environment on Windows:

**Required Tools**:
- PowerShell 7+
- Git
- PostgreSQL 12+
- Deno
- Dhall CLI
- Erlang/OTP
- Elixir

**Optional Tools** (with `-Optional` flag):
- Node.js LTS + AssemblyScript + axe-cli
- Rust toolchain + wasm-pack
- PowerShell modules: Pester, TomlPS

**Usage**:
```powershell
# Required only
.\zotero-template-dependencies.ps1

# With optional tools
.\zotero-template-dependencies.ps1 -Optional
```

## Template Structure

Templates are defined as JSON with three main properties (init-zotero-rscript-plugin.ps1:58-68):

```json
{
  "version": "0.1.0",
  "files": {
    "README.md": "# {{ProjectName}}\n...",
    "install.rdf": "<RDF>...",
    "chrome.manifest": "content {{ProjectName}} chrome/",
    "src/plugin.re": "// ReasonML code"
  }
}
```

Variables are replaced during scaffolding:
- `{{ProjectName}}` → Project directory name
- `{{AuthorName}}` → Author's name
- `{{version}}` → Template version

## Integrity System

The PowerShell scaffolder includes file integrity verification:

1. **audit-index.json generation** (init-zotero-rscript-plugin.ps1:162-176):
   - Computed after scaffolding
   - Contains XXHash64 checksums for all files
   - Includes generation timestamp

2. **Verification process** (init-zotero-rscript-plugin.ps1:71-97):
   - Checks file existence
   - Compares current hash with stored hash
   - Reports any mismatches or missing files

## License

GNU Affero General Public License v3.0 (AGPL-3.0)

Key implications:
- Network use triggers source disclosure requirement
- Modifications must be released under same license
- Source code must be made available to users
- Strong copyleft provisions

## Development Workflow

### Creating a New Template

1. Edit the `$templates` hashtable in `init-zotero-rscript-plugin.ps1`
2. Add new template type with JSON structure
3. Define files with content and variable placeholders
4. Test scaffolding: `.\init-zotero-rscript-plugin.ps1 -ProjectName Test -AuthorName "Test" -TemplateType newtype`

### Extending the Racket Scaffolder

1. Modify the `project-spec` in `init-raczotbuild.rkt:25`
2. Use homoiconic Racket syntax: `(dir name (file name content)...)`
3. Format strings use `~a` placeholders
4. Test with: `racket init-raczotbuild.rkt -n TestProject -a "Author"`

## Common Tasks

### Adding a New File to Templates
- **PowerShell**: Add entry to `$templates.<type>.files` object
- **Racket**: Add `(file "path" "content")` to `project-spec`

### Modifying CI/CD Workflow
- Edit `ci-txt` in `init-raczotbuild.rkt:23`
- Or the `.github/workflows/` section in GitInit block

### Changing License
- Modify `license-tpl` in Racket scaffolder
- Or the LICENSE content in PowerShell GitInit block

## Code Patterns

### Variable Substitution (Sequential Replace)
```powershell
$content = $raw
$content = $content.Replace('{{ProjectName}}', $ProjectName)
$content = $content.Replace('{{AuthorName}}',  $AuthorName)
$content = $content.Replace('{{version}}',     $tpl.version)
```

Sequential replacement prevents parser errors with nested patterns.

### Homoiconic Project Specifications
```racket
(define project-spec
  `(dir ,proj-name
    (dir "src"
      (file "main.rkt" ,(format template proj-name)))
    (file "README.md" ,(format readme proj-name))))
```

Code is data; project structure is defined as nested lists.

## Important Notes

- Both tools create similar output but use different approaches
- PowerShell version includes XXHash-based integrity verification
- Racket version emphasizes homoiconic specifications
- Templates support ReScript (.re), ReasonML, JavaScript, and TypeScript
- The project targets Zotero plugin development specifically

## Getting Help

For issues or questions:
1. Check template JSON syntax if scaffolding fails
2. Verify all required tools are installed (use dependency installer)
3. Ensure you have write permissions in the target directory
4. Run with `-Verbose` flag in PowerShell for detailed logging

## Architecture Decisions

1. **Dual Implementation**: Provides both Racket and PowerShell versions for flexibility
2. **Embedded Templates**: Templates are embedded in scripts for portability
3. **Integrity Verification**: XXHash chosen for speed and collision resistance
4. **Variable Substitution**: Simple string replacement over complex templating engines
5. **Homoiconic Design**: Racket version leverages code-as-data for flexibility
