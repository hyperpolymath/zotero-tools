-- SPDX-License-Identifier: AGPL-3.0-or-later
import Lake
open Lake DSL

package «zotero-formdb» where
  version := v!"0.1.0"
  keywords := #["database", "zotero", "formdb", "dependent-types", "reference-manager"]
  description := "Post-truth reference manager with dependently-typed provenance"

require mathlib from git
  "https://github.com/leanprover-community/mathlib4.git"

@[default_target]
lean_lib «ZoteroFormDB» where
  srcDir := "src"
  roots := #[`ZoteroFormDB]

lean_exe «zotero-formdb» where
  root := `Main
  supportInterpreter := true
