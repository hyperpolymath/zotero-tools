-- SPDX-License-Identifier: AGPL-3.0-or-later
/-!
# Zotero-FormDB CLI

Command-line interface for the post-truth reference manager.
-/

import ZoteroFormDB

def main (args : List String) : IO Unit := do
  IO.println s!"Zotero-FormDB v{ZoteroFormDB.version}"
  IO.println "Post-truth reference manager with dependently-typed provenance"
  IO.println ""

  match args with
  | ["--help"] | ["-h"] =>
    IO.println "Usage: zotero-formdb <command> [options]"
    IO.println ""
    IO.println "Commands:"
    IO.println "  migrate    Import from Zotero SQLite"
    IO.println "  serve      Start API server"
    IO.println "  verify     Check database integrity"
    IO.println "  export     Export to various formats"
    IO.println ""
    IO.println "Options:"
    IO.println "  --help, -h     Show this help"
    IO.println "  --version, -v  Show version"

  | ["--version"] | ["-v"] =>
    IO.println s!"v{ZoteroFormDB.version}"

  | ["migrate", "--from", sqlitePath, "--to", formdbPath] =>
    IO.println s!"Migrating from {sqlitePath} to {formdbPath}..."
    IO.println "Migration not yet implemented"

  | ["verify", path] =>
    IO.println s!"Verifying database at {path}..."
    IO.println "Verification not yet implemented"

  | ["serve", "--port", port] =>
    IO.println s!"Starting API server on port {port}..."
    IO.println "Server not yet implemented"

  | _ =>
    IO.println "Unknown command. Use --help for usage."
