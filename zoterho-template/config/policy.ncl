# SPDX-License-Identifier: MIT OR Apache-2.0
# SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
#
# Hyperpolymath Rhodium Standard - Policy Configuration
# Defines language and tooling policies for the project

let policy = {
  # Project metadata
  project = {
    name = "zoterho-template",
    version = "2.0.0",
    tier = "plugin",
    standard = "Rhodium"
  },

  # Allowed languages and tools
  allowed = {
    languages = [
      "ReScript",      # Primary application code
      "Rust",          # Performance-critical, systems, WASM
      "Gleam",         # Backend services (BEAM or JS)
      "Bash",          # Scripts, automation (minimal)
      "JavaScript",    # Only where ReScript cannot (MCP glue, Deno APIs)
      "Python",        # SaltStack only
      "Nickel",        # Configuration language
      "Guile",         # State/meta files (STATE.scm, META.scm)
      "Julia",         # Batch scripts, data processing
      "OCaml",         # AffineScript compiler
      "Ada"            # Safety-critical systems
    ],
    runtimes = [
      "Deno"           # Primary JavaScript runtime
    ],
    package_managers = [
      "Guix",          # Primary
      "Nix",           # Fallback
      "Deno"           # JS deps via deno.json
    ],
    mobile = [
      "Tauri 2.0+",    # Web UI + Rust backend
      "Dioxus"         # Pure Rust native UI
    ]
  },

  # Banned languages and tools
  banned = {
    languages = [
      "TypeScript",    # Use ReScript
      "Go",            # Use Rust
      "Java",          # Use Rust/Tauri/Dioxus
      "Kotlin",        # Use Rust/Tauri/Dioxus
      "Swift",         # Use Tauri/Dioxus
      "Dart"           # Use Tauri/Dioxus
    ],
    runtimes = [
      "Node.js",       # Use Deno
      "Bun"            # Use Deno
    ],
    package_managers = [
      "npm",           # Use Deno
      "yarn",          # Use Deno
      "pnpm",          # Use Deno
      "bun"            # Use Deno
    ],
    build_tools = [
      "Makefile",      # Use justfile
      "GNUmakefile"    # Use justfile
    ],
    mobile = [
      "React Native",  # Use Tauri/Dioxus
      "Flutter"        # Use Tauri/Dioxus
    ]
  },

  # Security requirements
  security = {
    hash_algorithms = ["SHA256", "SHA384", "SHA512", "BLAKE2", "BLAKE3"],
    banned_hash_algorithms = ["MD5", "SHA1"],
    require_https = true,
    no_hardcoded_secrets = true,
    require_spdx_headers = true,
    require_sha_pinned_deps = true
  },

  # File patterns
  patterns = {
    # ReScript output (allowed JavaScript)
    rescript_output = "*.res.js",
    # Generated files (allowed)
    generated = "*.gen.*",
    # Banned file extensions
    banned_extensions = [".ts", ".tsx", ".go", ".kt", ".swift"]
  }
}
in policy
