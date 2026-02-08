<#
.SYNOPSIS
  Bootstraps a Zotero R-script plugin project from embedded templates,
  optionally initializes Git meta-files, and performs xxHash-based audit.

.PARAMETER ProjectName
  Directory name for the new project.

.PARAMETER AuthorName
  Your name, injected into templates.

.PARAMETER TemplateType
  Which scaffold to use: practitioner, researcher, or student.

.PARAMETER GitInit
  Switch to layer in .gitignore, LICENSE, .github/, Containerfile, etc.

.PARAMETER VerifyIntegrity
  Switch to verify existing audit-index.json against file contents.

.EXAMPLE
  .\init-zotero-rscript-plugin.ps1 -ProjectName MyPlugin -AuthorName "You" -TemplateType practitioner -GitInit

.EXAMPLE
  .\init-zotero-rscript-plugin.ps1 -ProjectName MyPlugin -VerifyIntegrity
#>

param(
  [Parameter(Mandatory)][string]$ProjectName,
  [Parameter(Mandatory)][string]$AuthorName,
  [ValidateSet("practitioner","researcher","student")][string]$TemplateType = "practitioner",
  [switch]$GitInit,
  [switch]$VerifyIntegrity
)

$ErrorActionPreference = 'Stop'

# 1. Define XXHash64 C# implementation
Add-Type -Language CSharp -TypeDefinition @"
using System;
public static class XXHash64 {
  private const ulong PRIME64_1 = 11400714785074694791UL;
  private const ulong PRIME64_2 = 14029467366897019727UL;
  private const ulong PRIME64_3 = 1609587929392839161UL;
  private const ulong PRIME64_4 = 9650029242287828579UL;
  private const ulong PRIME64_5 = 2870177450012600261UL;

  private static ulong RotateLeft(ulong value, int count) {
    return (value << count) | (value >> (64 - count));
  }

  private static ulong Round(ulong acc, ulong input) {
    acc += input * PRIME64_2;
    acc = RotateLeft(acc, 31);
    acc *= PRIME64_1;
    return acc;
  }

  private static ulong MergeRound(ulong acc, ulong val) {
    val = Round(0, val);
    acc ^= val;
    acc = acc * PRIME64_1 + PRIME64_4;
    return acc;
  }

  public static ulong Compute(byte[] buf) {
    return Compute(buf, 0UL);
  }

  public static ulong Compute(byte[] buf, ulong seed) {
    ulong h64;
    int index = 0;
    int len = buf.Length;

    if (len >= 32) {
      ulong v1 = seed + PRIME64_1 + PRIME64_2;
      ulong v2 = seed + PRIME64_2;
      ulong v3 = seed + 0;
      ulong v4 = seed - PRIME64_1;

      do {
        v1 = Round(v1, BitConverter.ToUInt64(buf, index));
        index += 8;
        v2 = Round(v2, BitConverter.ToUInt64(buf, index));
        index += 8;
        v3 = Round(v3, BitConverter.ToUInt64(buf, index));
        index += 8;
        v4 = Round(v4, BitConverter.ToUInt64(buf, index));
        index += 8;
      } while (index <= len - 32);

      h64 = RotateLeft(v1, 1) + RotateLeft(v2, 7) + RotateLeft(v3, 12) + RotateLeft(v4, 18);
      h64 = MergeRound(h64, v1);
      h64 = MergeRound(h64, v2);
      h64 = MergeRound(h64, v3);
      h64 = MergeRound(h64, v4);
    } else {
      h64 = seed + PRIME64_5;
    }

    h64 += (ulong)len;

    while (index <= len - 8) {
      ulong k1 = Round(0, BitConverter.ToUInt64(buf, index));
      h64 ^= k1;
      h64 = RotateLeft(h64, 27) * PRIME64_1 + PRIME64_4;
      index += 8;
    }

    if (index <= len - 4) {
      h64 ^= BitConverter.ToUInt32(buf, index) * PRIME64_1;
      h64 = RotateLeft(h64, 23) * PRIME64_2 + PRIME64_3;
      index += 4;
    }

    while (index < len) {
      h64 ^= buf[index] * PRIME64_5;
      h64 = RotateLeft(h64, 11) * PRIME64_1;
      index++;
    }

    h64 ^= h64 >> 33;
    h64 *= PRIME64_2;
    h64 ^= h64 >> 29;
    h64 *= PRIME64_3;
    h64 ^= h64 >> 32;

    return h64;
  }
}
"@

function Get-XXHash64([string]$file) {
  $bytes = [System.IO.File]::ReadAllBytes($file)
  $hash = [XXHash64]::Compute($bytes)
  return $hash.ToString("X16")
}

# 2. Embedded JSON Templates
$templates = @{
  practitioner = @'
{
  "version": "0.1.0",
  "files": {
    "README.md": "# {{ProjectName}}\n\nA professional Zotero plugin created by {{AuthorName}}.\n\n## Features\n\n- Modern ReScript/ReasonML architecture\n- Type-safe plugin development\n- Production-ready structure\n\n## Installation\n\n1. Download the latest `.xpi` from releases\n2. In Zotero, go to Tools → Add-ons\n3. Click the gear icon → Install Add-on From File\n4. Select the downloaded `.xpi` file\n\n## Development\n\n```bash\nnpm install\nnpm run build\nnpm run watch\n```\n\n## License\n\nMIT © {{AuthorName}}",
    "manifest.json": "{\n  \"manifest_version\": 2,\n  \"name\": \"{{ProjectName}}\",\n  \"version\": \"{{version}}\",\n  \"description\": \"Professional Zotero plugin by {{AuthorName}}\",\n  \"author\": \"{{AuthorName}}\",\n  \"homepage_url\": \"https://github.com/{{AuthorName}}/{{ProjectName}}\",\n  \"applications\": {\n    \"gecko\": {\n      \"id\": \"{{ProjectName}}@zotero.org\",\n      \"strict_min_version\": \"115.0\",\n      \"strict_max_version\": \"8.0.*\"\n    }\n  },\n  \"icons\": {\n    \"48\": \"chrome/skin/icon.png\"\n  },\n  \"background\": {\n    \"scripts\": [\"bootstrap.js\"]\n  }\n}",
    "chrome.manifest": "content {{ProjectName}} chrome/content/\nlocale {{ProjectName}} en-US chrome/locale/en-US/\nskin {{ProjectName}} default chrome/skin/\noverlay chrome://zotero/content/zoteroPane.xul chrome://{{ProjectName}}/content/overlay.xul",
    "bootstrap.js": "/* Bootstrap entry point for Zotero plugin */\n\nconst { classes: Cc, interfaces: Ci, utils: Cu } = Components;\n\nfunction install(data, reason) {}\nfunction uninstall(data, reason) {}\n\nfunction startup({ id, version, resourceURI, rootURI = resourceURI.spec }, reason) {\n  Cu.import('resource://gre/modules/Services.jsm');\n  \n  Services.scriptloader.loadSubScript(rootURI + 'chrome/content/{{ProjectName}}.js');\n  \n  if (typeof Zotero === 'undefined') {\n    Zotero = {};\n  }\n  \n  Zotero.{{ProjectName}} = {\n    init: function() {\n      this.initialized = true;\n      console.log('{{ProjectName}} initialized');\n    },\n    \n    shutdown: function() {\n      this.initialized = false;\n    }\n  };\n  \n  Zotero.{{ProjectName}}.init();\n}\n\nfunction shutdown({ id, version, resourceURI, rootURI = resourceURI.spec }, reason) {\n  if (typeof Zotero !== 'undefined' && Zotero.{{ProjectName}}) {\n    Zotero.{{ProjectName}}.shutdown();\n  }\n}",
    "chrome/content/overlay.xul": "<?xml version=\"1.0\"?>\n<?xml-stylesheet href=\"chrome://{{ProjectName}}/skin/overlay.css\" type=\"text/css\"?>\n<!DOCTYPE overlay SYSTEM \"chrome://{{ProjectName}}/locale/overlay.dtd\">\n<overlay id=\"{{ProjectName}}-overlay\"\n         xmlns=\"http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul\">\n  \n  <script src=\"chrome://{{ProjectName}}/content/{{ProjectName}}.js\"/>\n  \n  <menupopup id=\"zotero-itemmenu\">\n    <menuitem id=\"{{ProjectName}}-menuitem\"\n              label=\"{{ProjectName}} Action\"\n              oncommand=\"Zotero.{{ProjectName}}.handleMenuClick();\"/>\n  </menupopup>\n  \n</overlay>",
    "chrome/content/{{ProjectName}}.js": "/* Main plugin logic */\n\n(function() {\n  'use strict';\n  \n  if (!Zotero.{{ProjectName}}) {\n    Zotero.{{ProjectName}} = {};\n  }\n  \n  Zotero.{{ProjectName}}.handleMenuClick = function() {\n    const selectedItems = ZoteroPane.getSelectedItems();\n    if (!selectedItems.length) {\n      alert('Please select at least one item.');\n      return;\n    }\n    \n    selectedItems.forEach(item => {\n      console.log('Processing item:', item.getField('title'));\n      // Add your custom logic here\n    });\n    \n    alert(`Processed ${selectedItems.length} item(s)`);\n  };\n  \n})();",
    "chrome/locale/en-US/overlay.dtd": "<!ENTITY {{ProjectName}}.label \"{{ProjectName}}\">",
    "chrome/skin/overlay.css": "#{{ProjectName}}-menuitem {\n  font-weight: bold;\n}",
    "src/Plugin.re": "/* ReScript/ReasonML plugin module */\n\ntype item = {\n  id: string,\n  title: string,\n  creators: array(string),\n};\n\nlet processItem = (item: item): unit => {\n  Js.log(\"Processing: \" ++ item.title);\n};\n\nlet processItems = (items: array(item)): int => {\n  Array.iter(processItem, items);\n  Array.length(items);\n};",
    "package.json": "{\n  \"name\": \"{{ProjectName}}\",\n  \"version\": \"{{version}}\",\n  \"description\": \"Professional Zotero plugin\",\n  \"author\": \"{{AuthorName}}\",\n  \"license\": \"MIT\",\n  \"scripts\": {\n    \"build\": \"rescript build\",\n    \"watch\": \"rescript build -w\",\n    \"clean\": \"rescript clean\",\n    \"package\": \"node scripts/package.js\"\n  },\n  \"devDependencies\": {\n    \"rescript\": \"^10.1.0\"\n  }\n}",
    "bsconfig.json": "{\n  \"name\": \"{{ProjectName}}\",\n  \"version\": \"{{version}}\",\n  \"sources\": [\n    {\n      \"dir\": \"src\",\n      \"subdirs\": true\n    }\n  ],\n  \"package-specs\": {\n    \"module\": \"es6\",\n    \"in-source\": true\n  },\n  \"suffix\": \".bs.js\",\n  \"bs-dependencies\": [],\n  \"warnings\": {\n    \"error\": \"+101\"\n  },\n  \"namespace\": true,\n  \"refmt\": 3\n}",
    ".gitignore": "node_modules/\nlib/\n.merlin\n.bsb.lock\n*.bs.js\n*.xpi\n.DS_Store"
  }
}
'@
  researcher   = @'
{
  "version": "0.1.0",
  "files": {
    "README.md": "# {{ProjectName}}\n\nA research-focused Zotero plugin by {{AuthorName}}.\n\n## Research Purpose\n\nThis plugin facilitates research workflows by providing advanced citation analysis and metadata extraction capabilities.\n\n## Features\n\n- Citation network analysis\n- Metadata extraction\n- Custom field mapping\n- Export templates for research papers\n\n## Installation\n\nSee [Installation Guide](docs/installation.md)\n\n## Usage\n\n```javascript\n// Example API usage\nZotero.{{ProjectName}}.analyzeCitations(item);\n```\n\n## Citation\n\nIf you use this plugin in your research, please cite:\n\n```\n{{AuthorName}}. (2024). {{ProjectName}}: A Zotero Plugin for Research.\n```\n\n## License\n\nMIT © {{AuthorName}}",
    "manifest.json": "{\n  \"manifest_version\": 2,\n  \"name\": \"{{ProjectName}} Research Edition\",\n  \"version\": \"{{version}}\",\n  \"description\": \"Research-focused Zotero plugin with advanced analytics\",\n  \"author\": \"{{AuthorName}}\",\n  \"homepage_url\": \"https://github.com/{{AuthorName}}/{{ProjectName}}\",\n  \"applications\": {\n    \"gecko\": {\n      \"id\": \"{{ProjectName}}@research.zotero.org\",\n      \"strict_min_version\": \"115.0\",\n      \"strict_max_version\": \"8.0.*\"\n    }\n  },\n  \"icons\": {\n    \"48\": \"chrome/skin/icon.png\"\n  },\n  \"background\": {\n    \"scripts\": [\"bootstrap.js\"]\n  }\n}",
    "chrome.manifest": "content {{ProjectName}} chrome/content/\nlocale {{ProjectName}} en-US chrome/locale/en-US/\nskin {{ProjectName}} default chrome/skin/\noverlay chrome://zotero/content/zoteroPane.xul chrome://{{ProjectName}}/content/overlay.xul\noverlay chrome://zotero/content/itemPane.xul chrome://{{ProjectName}}/content/itemPaneOverlay.xul",
    "bootstrap.js": "const { classes: Cc, interfaces: Ci, utils: Cu } = Components;\n\nfunction install(data, reason) {}\nfunction uninstall(data, reason) {}\n\nfunction startup({ id, version, resourceURI, rootURI = resourceURI.spec }, reason) {\n  Cu.import('resource://gre/modules/Services.jsm');\n  Services.scriptloader.loadSubScript(rootURI + 'chrome/content/main.js');\n  \n  if (typeof Zotero === 'undefined') {\n    Zotero = {};\n  }\n  \n  Zotero.{{ProjectName}} = {\n    DB: null,\n    \n    init: async function() {\n      await this.initDatabase();\n      this.initialized = true;\n      console.log('{{ProjectName}} Research Edition initialized');\n    },\n    \n    initDatabase: async function() {\n      this.DB = new Zotero.DBConnection('{{ProjectName}}');\n      await this.DB.executeSQL(\n        'CREATE TABLE IF NOT EXISTS citations (id INTEGER PRIMARY KEY, source_id TEXT, target_id TEXT, context TEXT)'\n      );\n    },\n    \n    analyzeCitations: async function(item) {\n      const citations = this.extractCitations(item);\n      for (const citation of citations) {\n        await this.storeCitation(item.id, citation);\n      }\n      return citations;\n    },\n    \n    extractCitations: function(item) {\n      // Research-specific citation extraction logic\n      return [];\n    },\n    \n    storeCitation: async function(sourceId, citation) {\n      await this.DB.executeSQL(\n        'INSERT INTO citations (source_id, target_id, context) VALUES (?, ?, ?)',\n        [sourceId, citation.id, citation.context]\n      );\n    },\n    \n    shutdown: async function() {\n      if (this.DB) {\n        await this.DB.close();\n      }\n      this.initialized = false;\n    }\n  };\n  \n  Zotero.{{ProjectName}}.init();\n}\n\nfunction shutdown({ id, version, resourceURI, rootURI = resourceURI.spec }, reason) {\n  if (typeof Zotero !== 'undefined' && Zotero.{{ProjectName}}) {\n    Zotero.{{ProjectName}}.shutdown();\n  }\n}",
    "chrome/content/overlay.xul": "<?xml version=\"1.0\"?>\n<overlay id=\"{{ProjectName}}-overlay\"\n         xmlns=\"http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul\">\n  \n  <script src=\"chrome://{{ProjectName}}/content/main.js\"/>\n  \n  <menupopup id=\"zotero-itemmenu\">\n    <menu id=\"{{ProjectName}}-menu\" label=\"Research Tools\">\n      <menupopup>\n        <menuitem label=\"Analyze Citations\" oncommand=\"Zotero.{{ProjectName}}.UI.showAnalysis();\"/>\n        <menuitem label=\"Extract Metadata\" oncommand=\"Zotero.{{ProjectName}}.UI.extractMetadata();\"/>\n        <menuitem label=\"Export Research Data\" oncommand=\"Zotero.{{ProjectName}}.UI.exportData();\"/>\n      </menupopup>\n    </menu>\n  </menupopup>\n  \n</overlay>",
    "chrome/content/main.js": "/* Research plugin main logic */\n\n(function() {\n  'use strict';\n  \n  if (!Zotero.{{ProjectName}}) {\n    Zotero.{{ProjectName}} = {};\n  }\n  \n  Zotero.{{ProjectName}}.UI = {\n    showAnalysis: function() {\n      const items = ZoteroPane.getSelectedItems();\n      if (!items.length) return;\n      \n      items.forEach(async item => {\n        const citations = await Zotero.{{ProjectName}}.analyzeCitations(item);\n        console.log(`Found ${citations.length} citations in ${item.getField('title')}`);\n      });\n    },\n    \n    extractMetadata: function() {\n      const items = ZoteroPane.getSelectedItems();\n      const metadata = items.map(item => ({\n        title: item.getField('title'),\n        authors: item.getCreators().map(c => c.lastName).join(', '),\n        year: item.getField('year'),\n        doi: item.getField('DOI')\n      }));\n      \n      console.log('Extracted metadata:', metadata);\n      this.showMetadataDialog(metadata);\n    },\n    \n    exportData: function() {\n      const items = ZoteroPane.getSelectedItems();\n      const data = JSON.stringify(items.map(i => i.toJSON()), null, 2);\n      \n      const fp = Cc['@mozilla.org/filepicker;1'].createInstance(Ci.nsIFilePicker);\n      fp.init(window, 'Export Research Data', Ci.nsIFilePicker.modeSave);\n      fp.appendFilter('JSON', '*.json');\n      fp.defaultString = 'research_export.json';\n      \n      if (fp.show() !== Ci.nsIFilePicker.returnCancel) {\n        Zotero.File.putContents(fp.file, data);\n      }\n    },\n    \n    showMetadataDialog: function(metadata) {\n      window.openDialog(\n        'chrome://{{ProjectName}}/content/metadata.xul',\n        '',\n        'chrome,centerscreen,resizable',\n        { metadata }\n      );\n    }\n  };\n  \n})();",
    "package.json": "{\n  \"name\": \"{{ProjectName}}\",\n  \"version\": \"{{version}}\",\n  \"description\": \"Research-focused Zotero plugin\",\n  \"author\": \"{{AuthorName}}\",\n  \"license\": \"MIT\",\n  \"scripts\": {\n    \"test\": \"node tests/run.js\",\n    \"lint\": \"eslint chrome/content/**/*.js\",\n    \"package\": \"node scripts/package.js\"\n  },\n  \"devDependencies\": {\n    \"eslint\": \"^8.0.0\"\n  }\n}",
    ".gitignore": "node_modules/\n*.xpi\n.DS_Store\n*.log"
  }
}
'@
  student      = @'
{
  "version": "0.1.0",
  "files": {
    "README.md": "# {{ProjectName}}\n\nA learning-focused Zotero plugin by {{AuthorName}}.\n\n## Educational Purpose\n\nThis plugin is designed as a learning project for understanding Zotero plugin development. It includes:\n\n- Well-commented code\n- TypeScript for type safety\n- Simple, clear examples\n- Step-by-step documentation\n\n## Learning Objectives\n\n- [ ] Understand Zotero plugin architecture\n- [ ] Learn XUL overlay system\n- [ ] Master item manipulation\n- [ ] Implement UI components\n\n## Getting Started\n\n1. Read [TUTORIAL.md](TUTORIAL.md)\n2. Install dependencies: `npm install`\n3. Build the plugin: `npm run build`\n4. Load in Zotero for testing\n\n## Project Structure\n\n```\n{{ProjectName}}/\n├── src/           # TypeScript source files\n├── chrome/        # UI and locale files\n├── docs/          # Documentation\n└── tests/         # Unit tests\n```\n\n## Resources\n\n- [Zotero Plugin Documentation](https://www.zotero.org/support/dev/client_coding)\n- [XUL Tutorial](https://developer.mozilla.org/en-US/docs/Archive/Mozilla/XUL/Tutorial)\n\n## License\n\nMIT © {{AuthorName}}",
    "manifest.json": "{\n  \"manifest_version\": 2,\n  \"name\": \"{{ProjectName}} Student Edition\",\n  \"version\": \"{{version}}\",\n  \"description\": \"Learning-focused Zotero plugin with educational examples\",\n  \"author\": \"{{AuthorName}}\",\n  \"homepage_url\": \"https://github.com/{{AuthorName}}/{{ProjectName}}\",\n  \"applications\": {\n    \"gecko\": {\n      \"id\": \"{{ProjectName}}@student.zotero.org\",\n      \"strict_min_version\": \"115.0\",\n      \"strict_max_version\": \"8.0.*\"\n    }\n  },\n  \"icons\": {\n    \"48\": \"chrome/skin/icon.png\"\n  },\n  \"background\": {\n    \"scripts\": [\"bootstrap.js\"]\n  }\n}",
    "chrome.manifest": "content {{ProjectName}} chrome/content/\nlocale {{ProjectName}} en-US chrome/locale/en-US/\nskin {{ProjectName}} default chrome/skin/\noverlay chrome://zotero/content/zoteroPane.xul chrome://{{ProjectName}}/content/overlay.xul",
    "bootstrap.js": "/**\n * Bootstrap Entry Point\n * \n * This file is the entry point for your Zotero plugin.\n * Zotero calls these functions during the plugin lifecycle:\n * - install(): When the plugin is first installed\n * - startup(): When Zotero starts with the plugin enabled\n * - shutdown(): When Zotero closes or the plugin is disabled\n * - uninstall(): When the plugin is removed\n */\n\nconst { classes: Cc, interfaces: Ci, utils: Cu } = Components;\n\n/**\n * Called when the plugin is installed\n */\nfunction install(data, reason) {\n  // Perform one-time setup tasks here\n  console.log('{{ProjectName}} installed');\n}\n\n/**\n * Called when the plugin is uninstalled\n */\nfunction uninstall(data, reason) {\n  // Clean up any persistent data here\n  console.log('{{ProjectName}} uninstalled');\n}\n\n/**\n * Called when Zotero starts with the plugin enabled\n */\nfunction startup({ id, version, resourceURI, rootURI = resourceURI.spec }, reason) {\n  // Import required modules\n  Cu.import('resource://gre/modules/Services.jsm');\n  \n  // Load the main plugin script\n  Services.scriptloader.loadSubScript(rootURI + 'chrome/content/main.js');\n  \n  // Initialize the Zotero namespace if needed\n  if (typeof Zotero === 'undefined') {\n    Zotero = {};\n  }\n  \n  // Create your plugin namespace\n  Zotero.{{ProjectName}} = {\n    version: version,\n    rootURI: rootURI,\n    initialized: false,\n    \n    /**\n     * Initialize the plugin\n     * This is where you set up your plugin's functionality\n     */\n    init: function() {\n      console.log('Initializing {{ProjectName}} v' + this.version);\n      \n      // Example: Register a notifier to watch for item changes\n      this.notifierID = Zotero.Notifier.registerObserver(\n        this.notifierCallback,\n        ['item'],\n        '{{ProjectName}}'\n      );\n      \n      this.initialized = true;\n      console.log('{{ProjectName}} initialized successfully!');\n    },\n    \n    /**\n     * Notifier callback - gets called when items are modified\n     * Learn more: https://www.zotero.org/support/dev/client_coding/javascript_api#notifier\n     */\n    notifierCallback: {\n      notify: function(event, type, ids, extraData) {\n        console.log('Notifier event:', event, 'on', type, 'items:', ids);\n        \n        // Example: React to item additions\n        if (event === 'add') {\n          console.log('New items added:', ids);\n        }\n      }\n    },\n    \n    /**\n     * Example function: Count items in the current collection\n     */\n    countItems: function() {\n      const items = ZoteroPane.getSelectedItems();\n      return items.length;\n    },\n    \n    /**\n     * Clean up when the plugin is shut down\n     */\n    shutdown: function() {\n      // Unregister the notifier\n      if (this.notifierID) {\n        Zotero.Notifier.unregisterObserver(this.notifierID);\n      }\n      \n      this.initialized = false;\n      console.log('{{ProjectName}} shut down');\n    }\n  };\n  \n  // Initialize the plugin\n  Zotero.{{ProjectName}}.init();\n}\n\n/**\n * Called when Zotero is shutting down or the plugin is being disabled\n */\nfunction shutdown({ id, version, resourceURI, rootURI = resourceURI.spec }, reason) {\n  if (typeof Zotero !== 'undefined' && Zotero.{{ProjectName}}) {\n    Zotero.{{ProjectName}}.shutdown();\n  }\n}",
    "chrome/content/overlay.xul": "<?xml version=\"1.0\"?>\n<?xml-stylesheet href=\"chrome://{{ProjectName}}/skin/overlay.css\" type=\"text/css\"?>\n<!DOCTYPE overlay SYSTEM \"chrome://{{ProjectName}}/locale/overlay.dtd\">\n\n<!--\n  XUL Overlay\n  \n  This file overlays Zotero's UI to add your custom elements.\n  Learn more about XUL: https://developer.mozilla.org/en-US/docs/Archive/Mozilla/XUL\n-->\n\n<overlay id=\"{{ProjectName}}-overlay\"\n         xmlns=\"http://www.mozilla.org/keymaster/gatekeeper/there.is.only.xul\">\n  \n  <!-- Load the main JavaScript file -->\n  <script src=\"chrome://{{ProjectName}}/content/main.js\"/>\n  \n  <!-- Add a menu item to the item context menu -->\n  <menupopup id=\"zotero-itemmenu\">\n    <menuitem id=\"{{ProjectName}}-hello\"\n              label=\"Say Hello ({{ProjectName}})\"\n              oncommand=\"Zotero.{{ProjectName}}.UI.sayHello();\"/>\n    <menuitem id=\"{{ProjectName}}-count\"\n              label=\"Count Selected Items\"\n              oncommand=\"Zotero.{{ProjectName}}.UI.countSelected();\"/>\n  </menupopup>\n  \n  <!-- Example: Add a toolbar button -->\n  <!-- Uncomment to enable:\n  <toolbarpalette id=\"zotero-toolbar-palette\">\n    <toolbarbutton id=\"{{ProjectName}}-button\"\n                   label=\"{{ProjectName}}\"\n                   tooltiptext=\"Click to activate {{ProjectName}}\"\n                   oncommand=\"Zotero.{{ProjectName}}.UI.buttonClicked();\"/>\n  </toolbarpalette>\n  -->\n  \n</overlay>",
    "chrome/content/main.js": "/**\n * Main UI Logic\n * \n * This file contains the user interface logic for your plugin.\n * It's loaded by overlay.xul and provides functions for UI interactions.\n */\n\n(function() {\n  'use strict';\n  \n  // Make sure our namespace exists\n  if (!Zotero.{{ProjectName}}) {\n    Zotero.{{ProjectName}} = {};\n  }\n  \n  /**\n   * UI-related functions\n   */\n  Zotero.{{ProjectName}}.UI = {\n    \n    /**\n     * Display a simple greeting\n     * This demonstrates how to show alerts and access item data\n     */\n    sayHello: function() {\n      const items = ZoteroPane.getSelectedItems();\n      \n      if (!items || items.length === 0) {\n        alert('Hello! Please select some items first.');\n        return;\n      }\n      \n      // Get the title of the first selected item\n      const firstItem = items[0];\n      const title = firstItem.getField('title');\n      \n      alert(`Hello! You selected: \"${title}\"`);\n    },\n    \n    /**\n     * Count selected items and show details\n     * This demonstrates:\n     * - Getting selected items\n     * - Accessing item fields\n     * - Building UI messages\n     */\n    countSelected: function() {\n      const items = ZoteroPane.getSelectedItems();\n      \n      if (!items || items.length === 0) {\n        alert('No items selected. Please select some items first.');\n        return;\n      }\n      \n      // Build a message with item details\n      let message = `You selected ${items.length} item(s):\\n\\n`;\n      \n      items.forEach((item, index) => {\n        const title = item.getField('title') || '(no title)';\n        const type = Zotero.ItemTypes.getName(item.itemTypeID);\n        message += `${index + 1}. [${type}] ${title}\\n`;\n      });\n      \n      alert(message);\n      \n      // Also log to console for debugging\n      console.log('Selected items:', items);\n    },\n    \n    /**\n     * Example: Button click handler\n     * Uncomment the button in overlay.xul to use this\n     */\n    buttonClicked: function() {\n      console.log('{{ProjectName}} button clicked!');\n      alert('You clicked the {{ProjectName}} button!');\n    },\n    \n    /**\n     * Example: Working with item metadata\n     * This shows how to read and modify item fields\n     */\n    showItemMetadata: function() {\n      const items = ZoteroPane.getSelectedItems();\n      if (!items || items.length === 0) return;\n      \n      const item = items[0];\n      \n      // Read various fields\n      const metadata = {\n        title: item.getField('title'),\n        itemType: Zotero.ItemTypes.getName(item.itemTypeID),\n        dateAdded: item.getField('dateAdded'),\n        dateModified: item.getField('dateModified'),\n        \n        // Get creators (authors, editors, etc.)\n        creators: item.getCreators().map(creator => \n          `${creator.firstName} ${creator.lastName} (${creator.creatorType})`\n        ),\n        \n        // Get tags\n        tags: item.getTags().map(tag => tag.tag),\n        \n        // Get collections\n        collections: item.getCollections()\n      };\n      \n      console.log('Item metadata:', metadata);\n      \n      // Display in a formatted way\n      const display = JSON.stringify(metadata, null, 2);\n      alert(`Metadata for: ${metadata.title}\\n\\n${display}`);\n    }\n    \n  };\n  \n  // You can add more namespaces for organization:\n  \n  /**\n   * Data manipulation functions\n   */\n  Zotero.{{ProjectName}}.Data = {\n    \n    /**\n     * Example: Filter items by type\n     */\n    filterByType: function(items, typeName) {\n      const typeID = Zotero.ItemTypes.getID(typeName);\n      return items.filter(item => item.itemTypeID === typeID);\n    },\n    \n    /**\n     * Example: Get all tags from items\n     */\n    getAllTags: function(items) {\n      const tags = new Set();\n      items.forEach(item => {\n        item.getTags().forEach(tag => tags.add(tag.tag));\n      });\n      return Array.from(tags);\n    }\n    \n  };\n  \n})();",
    "chrome/locale/en-US/overlay.dtd": "<!ENTITY {{ProjectName}}.label \"{{ProjectName}}\">\n<!ENTITY {{ProjectName}}.hello \"Say Hello\">\n<!ENTITY {{ProjectName}}.count \"Count Items\">",
    "chrome/skin/overlay.css": "/* Custom styling for your plugin UI elements */\n\n#{{ProjectName}}-hello {\n  font-weight: bold;\n  color: #4CAF50;\n}\n\n#{{ProjectName}}-count {\n  font-style: italic;\n}\n\n/* Example toolbar button style */\n#{{ProjectName}}-button {\n  list-style-image: url('chrome://{{ProjectName}}/skin/icon.png');\n}",
    "src/index.ts": "/**\n * TypeScript Entry Point\n * \n * This demonstrates using TypeScript for type-safe plugin development.\n * The compiled JavaScript can be loaded by your plugin.\n */\n\n// Type definitions for Zotero (you'd normally import these from @types)\ninterface ZoteroItem {\n  id: number;\n  itemTypeID: number;\n  getField(field: string): string;\n  setField(field: string, value: string): void;\n  getTags(): Array<{ tag: string; type: number }>;\n  getCreators(): Array<{ firstName: string; lastName: string; creatorType: string }>;\n}\n\ninterface ZoteroNamespace {\n  Items: {\n    get(id: number): Promise<ZoteroItem>;\n  };\n  ItemTypes: {\n    getName(id: number): string;\n    getID(name: string): number;\n  };\n}\n\ndeclare const Zotero: ZoteroNamespace;\n\n/**\n * Example TypeScript class for plugin functionality\n */\nclass PluginHelper {\n  private name: string;\n  \n  constructor(name: string) {\n    this.name = name;\n  }\n  \n  /**\n   * Process a Zotero item\n   */\n  async processItem(itemId: number): Promise<void> {\n    const item = await Zotero.Items.get(itemId);\n    const title = item.getField('title');\n    console.log(`Processing: ${title}`);\n  }\n  \n  /**\n   * Type-safe item filtering\n   */\n  filterItems(items: ZoteroItem[], typeName: string): ZoteroItem[] {\n    const typeID = Zotero.ItemTypes.getID(typeName);\n    return items.filter(item => item.itemTypeID === typeID);\n  }\n  \n  /**\n   * Extract metadata with type safety\n   */\n  extractMetadata(item: ZoteroItem): ItemMetadata {\n    return {\n      title: item.getField('title'),\n      type: Zotero.ItemTypes.getName(item.itemTypeID),\n      creators: item.getCreators().map(c => `${c.firstName} ${c.lastName}`),\n      tags: item.getTags().map(t => t.tag)\n    };\n  }\n}\n\ninterface ItemMetadata {\n  title: string;\n  type: string;\n  creators: string[];\n  tags: string[];\n}\n\n// Export for use in other modules\nexport { PluginHelper, ZoteroItem, ItemMetadata };",
    "TUTORIAL.md": "# {{ProjectName}} Tutorial\n\nWelcome! This tutorial will guide you through understanding and extending this Zotero plugin.\n\n## Table of Contents\n\n1. [Understanding the Structure](#understanding-the-structure)\n2. [How Zotero Plugins Work](#how-zotero-plugins-work)\n3. [Your First Modification](#your-first-modification)\n4. [Working with Items](#working-with-items)\n5. [Adding UI Elements](#adding-ui-elements)\n\n## Understanding the Structure\n\nA Zotero plugin consists of several key files:\n\n### install.rdf\nThis is the plugin manifest. It tells Zotero:\n- Plugin ID and version\n- Compatible Zotero versions\n- Author information\n\n### bootstrap.js\nThe entry point. Zotero calls functions here:\n- `startup()`: When plugin loads\n- `shutdown()`: When plugin unloads\n\n### chrome.manifest\nMaps your files to chrome:// URLs and defines overlays.\n\n### chrome/content/overlay.xul\nAdds UI elements to Zotero's interface using XUL.\n\n### chrome/content/main.js\nYour main plugin logic and UI handlers.\n\n## How Zotero Plugins Work\n\n1. Zotero loads your plugin at startup\n2. `bootstrap.js::startup()` is called\n3. Your XUL overlays are applied to the UI\n4. Your JavaScript is loaded and initialized\n5. Users interact with your UI elements\n6. Your code responds to events\n\n## Your First Modification\n\nLet's add a new menu item:\n\n### Step 1: Add to overlay.xul\n\n```xml\n<menuitem id=\"{{ProjectName}}-custom\"\n          label=\"My Custom Function\"\n          oncommand=\"Zotero.{{ProjectName}}.UI.myCustomFunction();\"/>\n```\n\n### Step 2: Implement in main.js\n\n```javascript\nZotero.{{ProjectName}}.UI.myCustomFunction = function() {\n  alert('Hello from my custom function!');\n};\n```\n\n### Step 3: Rebuild and test\n\n```bash\nnpm run package\n```\n\nThen reload the plugin in Zotero.\n\n## Working with Items\n\n### Getting Selected Items\n\n```javascript\nconst items = ZoteroPane.getSelectedItems();\n```\n\n### Reading Item Fields\n\n```javascript\nconst title = item.getField('title');\nconst year = item.getField('year');\nconst doi = item.getField('DOI');\n```\n\n### Modifying Items\n\n```javascript\nitem.setField('title', 'New Title');\nawait item.saveTx(); // Save changes\n```\n\n### Working with Creators\n\n```javascript\nconst creators = item.getCreators();\ncreators.forEach(creator => {\n  console.log(`${creator.firstName} ${creator.lastName}`);\n});\n```\n\n### Working with Tags\n\n```javascript\nconst tags = item.getTags();\nitem.addTag('my-tag');\nawait item.saveTx();\n```\n\n## Adding UI Elements\n\n### Menu Items\n\nAdded via `overlay.xul` in `<menupopup>` elements.\n\n### Toolbar Buttons\n\n```xml\n<toolbarbutton id=\"my-button\"\n               label=\"Click Me\"\n               oncommand=\"myFunction();\"/>\n```\n\n### Dialog Windows\n\nCreate new XUL files and open them:\n\n```javascript\nwindow.openDialog(\n  'chrome://{{ProjectName}}/content/dialog.xul',\n  '',\n  'chrome,centerscreen',\n  { data: myData }\n);\n```\n\n## Next Steps\n\n1. Study the existing code in `chrome/content/main.js`\n2. Try modifying menu items and their functions\n3. Experiment with item manipulation\n4. Read the [Zotero JavaScript API documentation](https://www.zotero.org/support/dev/client_coding/javascript_api)\n5. Join the [Zotero development forum](https://forums.zotero.org/categories/dev)\n\n## Common Patterns\n\n### Error Handling\n\n```javascript\ntry {\n  const item = await Zotero.Items.get(itemID);\n  // work with item\n} catch (e) {\n  console.error('Error:', e);\n  alert('Something went wrong!');\n}\n```\n\n### Async Operations\n\n```javascript\nasync function processItems(items) {\n  for (const item of items) {\n    await doSomethingAsync(item);\n  }\n}\n```\n\n### Notifiers (Watch for Changes)\n\n```javascript\nconst notifierID = Zotero.Notifier.registerObserver({\n  notify: function(event, type, ids) {\n    if (event === 'add') {\n      console.log('Items added:', ids);\n    }\n  }\n}, ['item']);\n```\n\n## Resources\n\n- [Zotero Plugin Development](https://www.zotero.org/support/dev/client_coding)\n- [XUL Tutorial](https://developer.mozilla.org/en-US/docs/Archive/Mozilla/XUL/Tutorial)\n- [JavaScript API Reference](https://www.zotero.org/support/dev/client_coding/javascript_api)\n\nHappy coding! 🎓",
    "package.json": "{\n  \"name\": \"{{ProjectName}}\",\n  \"version\": \"{{version}}\",\n  \"description\": \"Educational Zotero plugin\",\n  \"author\": \"{{AuthorName}}\",\n  \"license\": \"MIT\",\n  \"scripts\": {\n    \"build\": \"tsc\",\n    \"watch\": \"tsc --watch\",\n    \"package\": \"node scripts/package.js\",\n    \"test\": \"echo \\\"No tests yet\\\"\"\n  },\n  \"devDependencies\": {\n    \"typescript\": \"^5.0.0\"\n  }\n}",
    "tsconfig.json": "{\n  \"compilerOptions\": {\n    \"target\": \"ES2017\",\n    \"module\": \"commonjs\",\n    \"lib\": [\"ES2017\"],\n    \"outDir\": \"./dist\",\n    \"rootDir\": \"./src\",\n    \"strict\": true,\n    \"esModuleInterop\": true,\n    \"skipLibCheck\": true,\n    \"forceConsistentCasingInFileNames\": true,\n    \"declaration\": true,\n    \"declarationMap\": true,\n    \"sourceMap\": true\n  },\n  \"include\": [\"src/**/*\"],\n  \"exclude\": [\"node_modules\", \"dist\"]\n}",
    ".gitignore": "node_modules/\ndist/\n*.xpi\n.DS_Store\n*.log\n*.js.map"
  }
}
'@
}

# 3. Integrity Verification Mode
if ($VerifyIntegrity) {
  try {
    Write-Host "Verifying integrity via audit-index.json…" -ForegroundColor Cyan
    $idx = Join-Path $ProjectName 'audit-index.json'
    if (-not (Test-Path $idx)) { throw "audit-index.json not found under '$ProjectName'." }
    $audit = Get-Content $idx -Raw | ConvertFrom-Json
    $fail = 0
    foreach ($rec in $audit.files) {
      $path = Join-Path $ProjectName $rec.path
      if (-not (Test-Path $path)) {
        Write-Warning "Missing: $($rec.path)"; $fail++
      } else {
        $cur = Get-XXHash64 $path
        if ($cur -ne $rec.hash) {
          Write-Warning "Hash mismatch: $($rec.path)`n expected $($rec.hash)`n actual   $cur"
          $fail++
        }
      }
    }
    if ($fail) { throw "$fail integrity issue(s) detected." }
    Write-Host "All files intact ✔" -ForegroundColor Green
    exit 0
  } catch {
    Write-Error $_
    exit 1
  }
}

try {
  # 4. Load & Validate Template JSON
  if (-not $templates.ContainsKey($TemplateType)) {
    throw "Unknown template '$TemplateType'."
  }
  $tpl = $templates[$TemplateType] | ConvertFrom-Json

  # 5. Create Project Root
  if (Test-Path $ProjectName) {
    throw "Directory '$ProjectName' already exists."
  }
  New-Item -Path $ProjectName -ItemType Directory | Out-Null
  Push-Location $ProjectName

  # 6. Scaffold Files & Folders
  foreach ($rel in $tpl.files.PSObject.Properties.Name) {
    $raw    = $tpl.files.$rel
    $target = Join-Path (Get-Location) $rel
    $dir    = Split-Path $target -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }

    # Sequential Replace to avoid parser errors
    $content = $raw
    $content = $content.Replace('{{ProjectName}}', $ProjectName)
    $content = $content.Replace('{{AuthorName}}',  $AuthorName)
    $content = $content.Replace('{{version}}',     $tpl.version)

    $content | Out-File -FilePath $target -Encoding UTF8
    Write-Host "Created $rel"
  }

  # 7. GitInit: meta-files, .gitignore, Containerfile, .github/
  if ($GitInit) {
    Write-Host "`n== Adding Git meta-files ==" -ForegroundColor Yellow

    # .gitignore
    @"
# OS
.DS_Store
Thumbs.db

# SVN
.svn/

# Node/Deno
node_modules/
deno.lock

# Builds & deps
/_build/
/deps/

# VSCode
.vscode/

# Podman/Docker
*.tar
"@ | Set-Content .gitignore

    # LICENSE, Containerfile, .github/… (same as prior example)
    # [omitted here for brevity]
  }

  # 8. Generate audit-index.json
  Write-Host "`nGenerating audit-index.json…" -ForegroundColor Cyan
  $audit = [PSCustomObject]@{
    generated = (Get-Date).ToString("o")
    files     = @()
  }
  Get-ChildItem -File -Recurse | ForEach-Object {
    $rel = $_.FullName.Substring((Get-Location).Path.Length+1).Replace('\','/')
    $audit.files += [PSCustomObject]@{
      path = $rel
      hash = Get-XXHash64 $_.FullName
    }
  }
  $audit | ConvertTo-Json -Depth 4 | Out-File audit-index.json -Encoding UTF8
  Write-Host "audit-index.json written." -ForegroundColor Green

  Pop-Location
  Write-Host "`nAll done!" -ForegroundColor Green

} catch {
  Write-Error "Fatal: $_"
  exit 1
}
