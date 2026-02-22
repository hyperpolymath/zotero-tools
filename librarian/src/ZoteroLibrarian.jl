# SPDX-License-Identifier: PMPL-1.0-or-later
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <jonathan.jewell@open.ac.uk>

"""
ZoteroLibrarian — Verified Research Data Management.

This Julia module provides the analytical layer for the Zotero-Tools 
ecosystem. It manages the lifecycle of bibliographic data and associated 
attachments, ensuring long-term integrity and semantic searchability.

CAPABILITIES:
1. **API Integration**: Synchronizes metadata with the Zotero cloud servers.
2. **Local DB Bridge**: Direct, read-only access to the Zotero SQLite store.
3. **Integrity Tracking**: Uses cryptographic hashes to detect file rot or corruption.
4. **Linguistic Analysis**: Employs pattern matching to classify paper topics.
"""
module ZoteroLibrarian

using Serd
using HTTP
using JSON
using Graphs
using MetaGraphs
using ReservoirComputing
using Flux
using SparseArrays
using LinearAlgebra

# --- SUBSYSTEMS ---
include("zotero_api.jl")    # Cloud synchronization
include("zotero_db.jl")     # SQLite local access
include("hash_tracker.jl")  # Integrity monitoring
include("exif.jl")          # Attachment metadata extraction
include("patterns.jl")      # NLP-based categorization

# --- INTERFACE ---
include("port_interface.jl") # Elixir/Ephapax connectivity

# PUBLIC API
export ZoteroClient, get_attachments, verify_item_hashes

end # module
