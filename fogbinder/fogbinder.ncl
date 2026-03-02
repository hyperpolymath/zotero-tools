# Fogbinder Configuration
# Nickel configuration language - Type-safe configuration
# License: MIT OR AGPL-3.0 (with Palimpsest)

{
  # Project metadata
  project = {
    name = "fogbinder",
    version = "0.2.0",
    description = "Zotero plugin for exploring epistemic ambiguity in research",
    license = "MIT OR AGPL-3.0",
    authors = ["Jonathan <email@example.com>"],
    repository = "git@github.com:Hyperpolymath/fogbinder.git",

    rsr_tier = "Rhodium",
    rsr_compliance = 200,
  },

  # Build configuration
  build = {
    # ReScript configuration
    rescript = {
      compiler_version = "11.0.0",
      source_dirs = ["src"],
      output_dir = "lib/js",
      package_specs = [{
        module = "es6",
        in_source = false,
      }],
      suffix = ".bs.js",
      warnings = {
        number = "+A-42-48-102",
      },
    },

    # WASM configuration
    wasm = {
      enabled = true,
      target = "wasm32-unknown-unknown",
      modules = [
        {
          name = "crypto",
          path = "src/wasm/crypto",
          features = ["ed448", "kyber1024", "shake256", "argon2id"],
        },
        {
          name = "contradiction_detector",
          path = "src/wasm/contradiction_detector",
        },
        {
          name = "graph_algorithms",
          path = "src/wasm/graph_algorithms",
        },
        {
          name = "string_similarity",
          path = "src/wasm/string_similarity",
        },
      ],
      optimization_level = "z", # Size optimization
      lto = true, # Link-time optimization
    },

    # Deno configuration
    deno = {
      version = "1.40.0",
      permissions = {
        allow_read = true,
        allow_write = false,
        allow_net = false,
        allow_env = false,
        allow_run = false,
        allow_all = false, # NEVER true for security
      },
      unstable = false,
      import_map = null,
    },
  },

  # Security configuration
  security = {
    # Post-quantum cryptography
    crypto = {
      signature_algorithm = "Ed448",
      signature_bits = 448,

      hash_algorithm = "SHAKE256",
      hash_output_length = 256,

      secondary_hash = "BLAKE3",

      kem_algorithm = "Kyber-1024",
      kem_security_level = 5,

      password_hash = "Argon2id",
      argon2_params = {
        memory_kib = 65536, # 64 MB
        iterations = 3,
        parallelism = 4,
        output_length = 32,
      },

      aead = "ChaCha20-Poly1305",
      kdf = "HKDF-SHAKE256",
    },

    # Git configuration
    git = {
      ssh_only = true,
      require_signed_commits = true,
      signing_key_type = "ed25519",
      require_gpg = false, # Use SSH signing
    },

    # TLS/SSL configuration
    tls = {
      min_version = "1.3",
      cipher_suites = [
        "TLS_AES_256_GCM_SHA384",
        "TLS_CHACHA20_POLY1305_SHA256",
      ],
      certificate_type = "ed25519",
      ocsp_stapling = true,
      hsts = {
        enabled = true,
        max_age_seconds = 63072000, # 2 years
        include_subdomains = true,
        preload = true,
      },
    },

    # Security headers
    headers = {
      csp = "default-src 'none'; script-src 'self'; connect-src 'self'; img-src 'self' data:; style-src 'self'; frame-ancestors 'none'",
      coep = "require-corp",
      coop = "same-origin",
      corp = "same-origin",
      permissions_policy = "geolocation=(), microphone=(), camera=()",
      referrer_policy = "no-referrer",
      x_content_type_options = "nosniff",
      x_frame_options = "DENY",
    },
  },

  # Testing configuration
  testing = {
    framework = "deno_test",
    coverage_threshold = 80, # Minimum 80% coverage

    property_based = {
      enabled = true,
      iterations = 100,
    },

    test_dirs = ["src", "tests"],
    test_pattern = "*.test.res.js",

    benchmarks = {
      enabled = true,
      save_results = true,
      results_dir = "benchmarks/results",
    },
  },

  # Documentation configuration
  documentation = {
    format = "asciidoc",
    exceptions = ["SECURITY.md", "humans.md", "LICENSE.txt", "funding.yml"],

    required_files = [
      "README.adoc",
      "CONTRIBUTING.adoc",
      "CODE_OF_CONDUCT.adoc",
      "SECURITY.md",
      "LICENSE_DUAL.adoc",
      "CHANGELOG.adoc",
      "MAINTAINERS.adoc",
      "TPCF.adoc",
      "PHILOSOPHY.adoc",
      "API.adoc",
      "DEVELOPMENT.adoc",
    ],

    api_docs = {
      generate = true,
      output_dir = "docs",
      format = "asciidoc",
    },
  },

  # RSR Rhodium Standard configuration
  rsr = {
    tier = "Rhodium",
    compliance_percentage = 200,

    requirements = {
      type_safety = "rescript", # 100% type-safe
      memory_safety = true,
      no_typescript = true,
      no_nodejs = true,
      no_npm = true,

      build_system = "justfile",
      min_recipes = 100,

      documentation_format = "asciidoc",

      security = {
        post_quantum_crypto = true,
        git_ssh_only = true,
        tls_min_version = "1.3",
      },

      testing = {
        unit_tests = true,
        integration_tests = true,
        property_based_tests = true,
        benchmarks = true,
      },

      accessibility = {
        wcag_level = "AA",
        wcag_version = "2.1",
      },

      licensing = {
        type = "dual",
        options = ["MIT", "AGPL-3.0"],
        philosophical_overlay = "Palimpsest",
      },

      formal_verification = {
        enabled = true,
        tools = ["TLA+", "Coq"],
      },
    },
  },

  # Browser configuration
  browser = {
    future_proofing = {
      cross_origin_isolation = true,

      apis = [
        "WebGPU",
        "WebTransport",
        "WebCodecs",
        "ComputePressure",
        "FileSystemAccess",
        "WebShare",
        "StorageBuckets",
      ],

      accessibility = {
        prefers_reduced_motion = true,
        prefers_color_scheme = true,
        prefers_contrast = true,
      },
    },
  },

  # CI/CD configuration
  ci = {
    platform = "github_actions",

    required_checks = [
      "test",
      "quality",
      "security",
      "rsr-compliance",
      "accessibility",
      "documentation",
      "philosophy",
      "benchmarks",
    ],

    branch_protection = {
      enabled = true,
      required_reviews = 2,
      require_code_owner_review = true,
      dismiss_stale_reviews = true,
      require_status_checks = true,
      strict_status_checks = true,
      require_signed_commits = true,
      require_linear_history = true,
      allow_force_pushes = false,
      allow_deletions = false,
    },
  },

  # Development configuration
  development = {
    editor_config = {
      indent_style = "space",
      indent_size = 2,
      end_of_line = "lf",
      charset = "utf-8",
      trim_trailing_whitespace = true,
      insert_final_newline = true,
      max_line_length = 100,
    },

    git_hooks = {
      pre_commit = ".git/hooks/pre-commit",
      pre_push = ".git/hooks/pre-push",
      commit_msg = ".git/hooks/commit-msg",
    },

    automation = {
      salt_robot = "scripts/salt_robot.sh",
      run_on = ["daily", "pre-push", "manual"],
    },
  },

  # Zotero plugin configuration
  zotero = {
    manifest_version = 2,
    min_zotero_version = "7.0",

    features = [
      "contradiction_detection",
      "mood_scoring",
      "mystery_clustering",
      "fogtrail_visualization",
    ],

    ui = {
      accessibility = true,
      keyboard_navigation = true,
      screen_reader_support = true,
      high_contrast_mode = true,
    },
  },

  # Philosophy configuration
  philosophy = {
    foundations = ["wittgenstein", "austin"],

    concepts = {
      language_games = true,
      speech_acts = true,
      family_resemblance = true,
      ordinary_language = true,
      epistemic_humility = true,
    },

    anti_patterns = [
      "strict_definitions",
      "over_formalization",
      "essence_based_categorization",
      "logical_positivism",
    ],
  },
}
