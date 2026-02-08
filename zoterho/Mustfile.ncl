# SPDX-License-Identifier: MIT
# Zoterho Mustfile - Contract-driven enforcement
# Hyperpolymath Language Policy

# Language policy contract
let LanguagePolicy = {
  # Allowed languages and tools
  allowed = {
    languages = [
      "ReScript",
      "Rust",
      "Gleam",
      "Bash",
      "POSIX Shell",
      "JavaScript",  # Only for MCP protocol glue, Deno APIs
      "PHP",         # Only for WordPress (zotpress)
      "Python",      # Only for SaltStack
      "Nickel",
      "Guile Scheme",
      "Julia",
      "OCaml",
      "Ada",
    ],
    runtimes = [
      "Deno",
    ],
    package_managers = [
      "Guix",
      "Nix",
      "Deno",
      "Cargo",
      "Composer",  # PHP only
    ],
    mobile_frameworks = [
      "Tauri 2.0+",
      "Dioxus",
    ],
  },

  # Banned languages and tools
  banned = {
    languages = [
      "TypeScript",
      "Go",
      "Java",
      "Kotlin",
      "Swift",
      "Dart",
    ],
    runtimes = [
      "Node.js",
      "Bun",
    ],
    package_managers = [
      "npm",
      "pnpm",
      "yarn",
    ],
    mobile_frameworks = [
      "React Native",
      "Flutter",
    ],
    build_tools = [
      "Make",
      "Makefile",
    ],
  },

  # File patterns that indicate policy violations
  banned_patterns = [
    "*.ts",
    "*.tsx",
    "*.go",
    "*.java",
    "*.kt",
    "*.swift",
    "*.dart",
    "package.json",
    "package-lock.json",
    "bun.lockb",
    "yarn.lock",
    "pnpm-lock.yaml",
    "go.mod",
    "go.sum",
    "Makefile",
    "makefile",
    "GNUmakefile",
  ],

  # Allowed file patterns
  allowed_patterns = [
    "*.res",
    "*.resi",
    "*.rs",
    "*.gleam",
    "*.ncl",
    "*.scm",
    "*.sh",
    "*.bash",
    "*.php",
    "*.py",  # SaltStack only
    "*.jl",
    "*.ml",
    "*.mli",
    "*.ada",
    "*.adb",
    "*.ads",
    "justfile",
    "Justfile",
    "deno.json",
    "deno.jsonc",
    "Cargo.toml",
    "Cargo.lock",
  ],
}
in

# Security policy contract
let SecurityPolicy = {
  # Banned cryptographic algorithms
  banned_algorithms = [
    "MD5",
    "SHA1",
  ],

  # Required security headers
  required_headers = [
    "SPDX-License-Identifier",
  ],

  # Protocol requirements
  protocols = {
    http = "banned",
    https = "required",
  },

  # Secret handling
  secrets = {
    hardcoded = "banned",
    environment = "allowed",
    vault = "preferred",
  },

  # Dependency pinning
  dependencies = {
    sha_pinned = "required",
    floating_versions = "banned",
  },
}
in

# Project metadata
let Project = {
  name = "zoterho",
  version = "0.1.0",
  description = "Zotero ecosystem — Rhodium-compliant tools for bibliography management",
  license = "MIT OR Palimpsest-0.8",
  organization = "hyperpolymath",

  # Component submodules
  components = [
    {
      name = "zoterho-template",
      description = "Rhodium-compliant Zotero configuration template",
      status = "planned",
    },
    {
      name = "zotpress",
      description = "WordPress plugin for embedding Zotero bibliographies",
      status = "planned",
      exception = "PHP 8.2+ allowed for WordPress",
    },
    {
      name = "zotero-voyant-export",
      description = "Export adapter for Voyant Tools text analysis",
      status = "planned",
    },
    {
      name = "zotero-rescript-templater",
      description = "ReScript-based template generator for Zotero plugins",
      status = "planned",
    },
    {
      name = "zotero-nsai",
      description = "NSAI content detection for AI-generated content",
      status = "planned",
    },
  ],
}
in

# Enforcement contract
let EnforcementContract = {
  pre_commit = {
    check_banned_files = true,
    check_license_headers = true,
    run_linters = true,
  },

  ci = {
    policy_check = "required",
    security_scan = "required",
    test_coverage = "recommended",
  },

  deployment = {
    sbom_generation = "required",
    vulnerability_scan = "required",
    license_compliance = "required",
  },
}
in

# Export the complete configuration
{
  language_policy = LanguagePolicy,
  security_policy = SecurityPolicy,
  project = Project,
  enforcement = EnforcementContract,
}
