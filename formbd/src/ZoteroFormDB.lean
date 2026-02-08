-- SPDX-License-Identifier: AGPL-3.0-or-later
/-!
# Zotero-FormDB

A post-truth reference manager built on dependently-typed FormDB.

## Core Principles

1. **Provenance by construction** - Items cannot exist without attribution
2. **Evidence quality** - PROMPT scores with compile-time bounds
3. **Reversibility** - All operations have proven inverses
4. **Cloud-safe** - Append-only storage for sync safety
-/

import ZoteroFormDB.Types
import ZoteroFormDB.Provenance
import ZoteroFormDB.Prompt
import ZoteroFormDB.Journal
import ZoteroFormDB.Items

namespace ZoteroFormDB

/-- Library version -/
def version : String := "0.1.0"

end ZoteroFormDB
