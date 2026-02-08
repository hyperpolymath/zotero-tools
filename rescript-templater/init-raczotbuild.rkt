#lang racket

;; RacZotBuild - A Racket-based Zotero plugin scaffolder
;; Creates new Zotero plugin projects from templates

(require racket/cmdline
         racket/path
         racket/file
         racket/date
         racket/system
         json
         file/sha1)

;; === Command-line parameters ===
(define proj-name (make-parameter #f))
(define proj-author (make-parameter #f))
(define proj-desc (make-parameter "RacZotBuild – a Racket-based Zotero plugin scaffolder"))
(define do-gitinit? (make-parameter #f))
(define do-verify? (make-parameter #f))
(define template-type (make-parameter "practitioner"))

(command-line
 #:program "init-raczotbuild.rkt"
 #:once-each
 [("-n" "--name") name "Project directory & package name"
  (proj-name name)]
 [("-a" "--author") author "Author name"
  (proj-author author)]
 [("-d" "--desc") desc "Project description"
  (proj-desc desc)]
 [("-t" "--template") tpl "Template type: practitioner, researcher, student"
  (template-type tpl)]
 [("-g" "--git-init") "Run git init + first commit"
  (do-gitinit? #t)]
 [("-v" "--verify") "Verify integrity of existing project"
  (do-verify? #t)])

;; === Utility functions ===
(define (mkdirs path)
  (unless (directory-exists? path)
    (make-directory* path)))

(define (write-file path content)
  (define dir (path-only path))
  (when dir (mkdirs dir))
  (call-with-output-file path
    (λ (out) (display content out))
    #:exists 'replace))

(define (year) (date-year (current-date)))

(define (file-sha256 path)
  (call-with-input-file path
    (λ (in) (sha1 in))))

(define (path-join base . parts)
  (apply build-path (cons base parts)))

;; === Template substitution ===
(define (substitute-vars content project author version)
  (define s1 (string-replace content "{{ProjectName}}" project))
  (define s2 (string-replace s1 "{{AuthorName}}" author))
  (string-replace s2 "{{version}}" version))

;; === Templates ===
(define practitioner-template
  (hasheq
   'version "0.1.0"
   'files (hasheq
           "README.md" "# {{ProjectName}}\n\nA professional Zotero plugin created by {{AuthorName}}.\n\n## Features\n\n- Modern plugin architecture\n- Type-safe development\n- Production-ready structure\n\n## Installation\n\n1. Download the latest `.xpi` from releases\n2. In Zotero, go to Tools → Add-ons\n3. Click the gear icon → Install Add-on From File\n4. Select the downloaded `.xpi` file\n\n## License\n\nMIT © {{AuthorName}}"
           "manifest.json" "{\n  \"manifest_version\": 2,\n  \"name\": \"{{ProjectName}}\",\n  \"version\": \"{{version}}\",\n  \"description\": \"A professional Zotero plugin\",\n  \"author\": \"{{AuthorName}}\",\n  \"homepage_url\": \"https://github.com/{{AuthorName}}/{{ProjectName}}\",\n  \"applications\": {\n    \"gecko\": {\n      \"id\": \"{{ProjectName}}@zotero.org\",\n      \"strict_min_version\": \"115.0\",\n      \"strict_max_version\": \"8.0.*\"\n    }\n  },\n  \"icons\": {\n    \"48\": \"chrome/skin/icon.png\",\n    \"96\": \"chrome/skin/icon@2x.png\"\n  },\n  \"background\": {\n    \"scripts\": [\"bootstrap.js\"]\n  }\n}"
           "bootstrap.js" "/* Bootstrap entry point for Zotero plugin */\nconst { classes: Cc, interfaces: Ci, utils: Cu } = Components;\n\nfunction install(data, reason) {}\nfunction uninstall(data, reason) {}\n\nfunction startup({ id, version, resourceURI, rootURI = resourceURI.spec }, reason) {\n  Cu.import('resource://gre/modules/Services.jsm');\n  Services.scriptloader.loadSubScript(rootURI + 'chrome/content/{{ProjectName}}.js');\n  if (typeof Zotero === 'undefined') { Zotero = {}; }\n  Zotero.{{ProjectName}} = {\n    init: function() { this.initialized = true; console.log('{{ProjectName}} initialized'); },\n    shutdown: function() { this.initialized = false; }\n  };\n  Zotero.{{ProjectName}}.init();\n}\n\nfunction shutdown({ id, version, resourceURI, rootURI = resourceURI.spec }, reason) {\n  if (typeof Zotero !== 'undefined' && Zotero.{{ProjectName}}) {\n    Zotero.{{ProjectName}}.shutdown();\n  }\n}"
           "chrome.manifest" "content {{ProjectName}} chrome/content/\nlocale {{ProjectName}} en-US chrome/locale/en-US/\nskin {{ProjectName}} default chrome/skin/"
           "chrome/content/main.js" "/* Main plugin logic */\n(function() {\n  'use strict';\n  if (!Zotero.{{ProjectName}}) { Zotero.{{ProjectName}} = {}; }\n  Zotero.{{ProjectName}}.handleAction = function() {\n    const items = ZoteroPane.getSelectedItems();\n    if (!items.length) { alert('Please select items.'); return; }\n    items.forEach(item => console.log('Processing:', item.getField('title')));\n    alert('Processed ' + items.length + ' item(s)');\n  };\n})();"
           "chrome/locale/en-US/overlay.dtd" "<!ENTITY {{ProjectName}}.label \"{{ProjectName}}\">"
           "chrome/skin/overlay.css" "/* Plugin styles */\n#{{ProjectName}}-menuitem { font-weight: bold; }"
           ".gitignore" "node_modules/\n*.xpi\n.DS_Store\naudit-index.json")))

(define researcher-template
  (hasheq
   'version "0.1.0"
   'files (hasheq
           "README.md" "# {{ProjectName}}\n\nA research-focused Zotero plugin by {{AuthorName}}.\n\n## Features\n\n- Citation network analysis\n- Metadata extraction\n- Research workflow optimization\n\n## Citation\n\nIf you use this plugin in your research, please cite:\n\n```\n{{AuthorName}}. (2024). {{ProjectName}}: A Zotero Plugin for Research.\n```\n\n## License\n\nMIT © {{AuthorName}}"
           "manifest.json" "{\n  \"manifest_version\": 2,\n  \"name\": \"{{ProjectName}} Research Edition\",\n  \"version\": \"{{version}}\",\n  \"description\": \"A research-focused Zotero plugin with citation analysis\",\n  \"author\": \"{{AuthorName}}\",\n  \"homepage_url\": \"https://github.com/{{AuthorName}}/{{ProjectName}}\",\n  \"applications\": {\n    \"gecko\": {\n      \"id\": \"{{ProjectName}}@research.zotero.org\",\n      \"strict_min_version\": \"115.0\",\n      \"strict_max_version\": \"8.0.*\"\n    }\n  },\n  \"icons\": {\n    \"48\": \"chrome/skin/icon.png\"\n  },\n  \"background\": {\n    \"scripts\": [\"bootstrap.js\"]\n  }\n}"
           "bootstrap.js" "const { classes: Cc, interfaces: Ci, utils: Cu } = Components;\nfunction install(data, reason) {}\nfunction uninstall(data, reason) {}\nfunction startup({ id, version, resourceURI, rootURI = resourceURI.spec }, reason) {\n  Cu.import('resource://gre/modules/Services.jsm');\n  Services.scriptloader.loadSubScript(rootURI + 'chrome/content/main.js');\n  if (typeof Zotero === 'undefined') { Zotero = {}; }\n  Zotero.{{ProjectName}} = {\n    init: async function() { this.initialized = true; console.log('{{ProjectName}} Research Edition initialized'); },\n    analyzeCitations: async function(item) { return []; },\n    shutdown: async function() { this.initialized = false; }\n  };\n  Zotero.{{ProjectName}}.init();\n}\nfunction shutdown({ id, version, resourceURI, rootURI = resourceURI.spec }, reason) {\n  if (typeof Zotero !== 'undefined' && Zotero.{{ProjectName}}) { Zotero.{{ProjectName}}.shutdown(); }\n}"
           "chrome.manifest" "content {{ProjectName}} chrome/content/\nlocale {{ProjectName}} en-US chrome/locale/en-US/"
           "chrome/content/main.js" "/* Research plugin logic */\n(function() {\n  'use strict';\n  if (!Zotero.{{ProjectName}}) { Zotero.{{ProjectName}} = {}; }\n  Zotero.{{ProjectName}}.UI = {\n    showAnalysis: function() {\n      const items = ZoteroPane.getSelectedItems();\n      items.forEach(async item => {\n        const citations = await Zotero.{{ProjectName}}.analyzeCitations(item);\n        console.log('Found ' + citations.length + ' citations');\n      });\n    },\n    extractMetadata: function() {\n      const items = ZoteroPane.getSelectedItems();\n      return items.map(item => ({ title: item.getField('title'), doi: item.getField('DOI') }));\n    }\n  };\n})();"
           ".gitignore" "node_modules/\n*.xpi\n.DS_Store\n*.log\naudit-index.json")))

(define student-template
  (hasheq
   'version "0.1.0"
   'files (hasheq
           "README.md" "# {{ProjectName}}\n\nA learning-focused Zotero plugin by {{AuthorName}}.\n\n## Educational Purpose\n\nThis plugin is designed as a learning project for understanding Zotero plugin development.\n\n## Getting Started\n\n1. Read TUTORIAL.md\n2. Build the plugin\n3. Load in Zotero for testing\n\n## License\n\nMIT © {{AuthorName}}"
           "TUTORIAL.md" "# {{ProjectName}} Tutorial\n\nWelcome! This tutorial will guide you through understanding and extending this Zotero plugin.\n\n## Understanding the Structure\n\nA Zotero plugin consists of several key files:\n\n### install.rdf\nThe plugin manifest - tells Zotero about your plugin.\n\n### bootstrap.js\nThe entry point - Zotero calls startup() when loading.\n\n### chrome/content/main.js\nYour main plugin logic and UI handlers.\n\n## Your First Modification\n\nTry adding a new menu item in the overlay and implementing its handler!\n\n## Resources\n\n- [Zotero Plugin Documentation](https://www.zotero.org/support/dev/client_coding)\n- [JavaScript API Reference](https://www.zotero.org/support/dev/client_coding/javascript_api)\n\nHappy coding! 🎓"
           "manifest.json" "{\n  \"manifest_version\": 2,\n  \"name\": \"{{ProjectName}} Student Edition\",\n  \"version\": \"{{version}}\",\n  \"description\": \"A learning-focused Zotero plugin for students\",\n  \"author\": \"{{AuthorName}}\",\n  \"homepage_url\": \"https://github.com/{{AuthorName}}/{{ProjectName}}\",\n  \"applications\": {\n    \"gecko\": {\n      \"id\": \"{{ProjectName}}@student.zotero.org\",\n      \"strict_min_version\": \"115.0\",\n      \"strict_max_version\": \"8.0.*\"\n    }\n  },\n  \"icons\": {\n    \"48\": \"chrome/skin/icon.png\"\n  },\n  \"background\": {\n    \"scripts\": [\"bootstrap.js\"]\n  }\n}"
           "bootstrap.js" "/**\n * Bootstrap Entry Point - Well Commented for Learning!\n */\nconst { classes: Cc, interfaces: Ci, utils: Cu } = Components;\n\n// Called when the plugin is installed\nfunction install(data, reason) {\n  console.log('{{ProjectName}} installed');\n}\n\n// Called when the plugin is uninstalled\nfunction uninstall(data, reason) {\n  console.log('{{ProjectName}} uninstalled');\n}\n\n// Called when Zotero starts with the plugin enabled\nfunction startup({ id, version, resourceURI, rootURI = resourceURI.spec }, reason) {\n  Cu.import('resource://gre/modules/Services.jsm');\n  Services.scriptloader.loadSubScript(rootURI + 'chrome/content/main.js');\n  if (typeof Zotero === 'undefined') { Zotero = {}; }\n  Zotero.{{ProjectName}} = {\n    version: version,\n    init: function() {\n      console.log('Initializing {{ProjectName}} v' + this.version);\n      this.initialized = true;\n    },\n    countItems: function() {\n      return ZoteroPane.getSelectedItems().length;\n    },\n    shutdown: function() {\n      this.initialized = false;\n      console.log('{{ProjectName}} shut down');\n    }\n  };\n  Zotero.{{ProjectName}}.init();\n}\n\n// Called when Zotero shuts down\nfunction shutdown({ id, version, resourceURI, rootURI = resourceURI.spec }, reason) {\n  if (typeof Zotero !== 'undefined' && Zotero.{{ProjectName}}) {\n    Zotero.{{ProjectName}}.shutdown();\n  }\n}"
           "chrome.manifest" "content {{ProjectName}} chrome/content/\nlocale {{ProjectName}} en-US chrome/locale/en-US/"
           "chrome/content/main.js" "/**\n * Main UI Logic - Well Commented for Learning!\n */\n(function() {\n  'use strict';\n  \n  if (!Zotero.{{ProjectName}}) { Zotero.{{ProjectName}} = {}; }\n  \n  // UI functions namespace\n  Zotero.{{ProjectName}}.UI = {\n    // Display a greeting with selected item info\n    sayHello: function() {\n      const items = ZoteroPane.getSelectedItems();\n      if (!items || items.length === 0) {\n        alert('Hello! Please select some items first.');\n        return;\n      }\n      const title = items[0].getField('title');\n      alert('Hello! You selected: \"' + title + '\"');\n    },\n    \n    // Count selected items\n    countSelected: function() {\n      const items = ZoteroPane.getSelectedItems();\n      if (!items || items.length === 0) {\n        alert('No items selected.');\n        return;\n      }\n      alert('You selected ' + items.length + ' item(s)');\n    }\n  };\n})();"
           "chrome/locale/en-US/overlay.dtd" "<!ENTITY {{ProjectName}}.label \"{{ProjectName}}\">\n<!ENTITY {{ProjectName}}.hello \"Say Hello\">"
           ".gitignore" "node_modules/\ndist/\n*.xpi\n.DS_Store\naudit-index.json")))

(define templates
  (hash "practitioner" practitioner-template
        "researcher" researcher-template
        "student" student-template))

;; === Core functions ===

;; Scaffold a new project from template
(define (scaffold project author template-name)
  (unless (hash-has-key? templates template-name)
    (error 'scaffold "Unknown template: ~a. Use: practitioner, researcher, or student" template-name))

  (define tpl (hash-ref templates template-name))
  (define version (hash-ref tpl 'version))
  (define files (hash-ref tpl 'files))

  (when (directory-exists? project)
    (error 'scaffold "Directory '~a' already exists" project))

  (mkdirs project)
  (printf "Creating project '~a' with ~a template...\n" project template-name)

  (for ([(rel-path content) (in-hash files)])
    (define full-path (path-join project rel-path))
    (define substituted (substitute-vars content project author version))
    (write-file full-path substituted)
    (printf "  Created ~a\n" rel-path))

  (printf "✓ Project '~a' created successfully!\n" project))

;; Create audit-index.json with file hashes
(define (create-audit project)
  (unless (directory-exists? project)
    (error 'create-audit "Directory '~a' does not exist" project))

  (define audit-path (path-join project "audit-index.json"))
  (define files-data '())

  (for ([file (in-directory project)])
    (when (file-exists? file)
      (define rel (find-relative-path (string->path project) file))
      (define rel-str (path->string rel))
      ;; Skip audit-index.json itself
      (unless (string=? rel-str "audit-index.json")
        (define hash (file-sha256 file))
        (set! files-data (cons (hasheq 'path rel-str 'hash hash) files-data)))))

  (define audit
    (hasheq 'generated (date->string (current-date) #t)
            'files (reverse files-data)))

  (call-with-output-file audit-path
    (λ (out) (write-json audit out))
    #:exists 'replace)

  (printf "✓ audit-index.json created with ~a files\n" (length files-data)))

;; Verify project integrity against audit-index.json
(define (verify-audit project)
  (define audit-path (path-join project "audit-index.json"))
  (unless (file-exists? audit-path)
    (error 'verify-audit "audit-index.json not found in '~a'" project))

  (define audit
    (call-with-input-file audit-path
      (λ (in) (read-json in))))

  (define files (hash-ref audit 'files))
  (define failures 0)

  (printf "Verifying ~a files...\n" (length files))

  (for ([rec (in-list files)])
    (define rel-path (hash-ref rec 'path))
    (define expected-hash (hash-ref rec 'hash))
    (define full-path (path-join project rel-path))

    (cond
      [(not (file-exists? full-path))
       (printf "  ✗ MISSING: ~a\n" rel-path)
       (set! failures (add1 failures))]
      [else
       (define actual-hash (file-sha256 full-path))
       (if (string=? actual-hash expected-hash)
           (printf "  ✓ ~a\n" rel-path)
           (begin
             (printf "  ✗ MISMATCH: ~a\n    expected: ~a\n    actual:   ~a\n"
                     rel-path expected-hash actual-hash)
             (set! failures (add1 failures))))]))

  (if (zero? failures)
      (printf "✓ All files verified successfully!\n")
      (error 'verify-audit "~a integrity issue(s) detected" failures)))

;; === Main entry point ===
(define (main)
  (cond
    ;; Verify mode
    [(do-verify?)
     (unless (proj-name)
       (error 'args "Project name required for verification (-n)"))
     (verify-audit (proj-name))]

    ;; Scaffold mode
    [else
     (unless (and (proj-name) (proj-author))
       (error 'args "Both --name and --author are required"))

     (scaffold (proj-name) (proj-author) (template-type))
     (create-audit (proj-name))

     (when (do-gitinit?)
       (printf "\nInitializing git repository...\n")
       (parameterize ([current-directory (proj-name)])
         (system "git init .")
         (system "git add .")
         (system (format "git commit -m \"chore: init ~a\"" (proj-name)))))

     (printf "\n🎉 Done! Your Zotero plugin project is ready.\n")
     (printf "   cd ~a && start developing!\n" (proj-name))]))

(main)
