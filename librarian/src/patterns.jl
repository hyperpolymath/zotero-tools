# SPDX-License-Identifier: AGPL-3.0-or-later

"""
Filename Patterns — Heuristic Metadata Extraction.

This module provides the intelligence layer for identifying the origin of 
unstructured filenames. It uses an extensive database of regular expressions 
to recover platform, author, and temporal data from social media 
downloads and messaging app exports.

PATTERN CATEGORIES:
- **Social**: Instagram, Facebook, Twitter/X, VK.
- **Messaging**: WhatsApp, Telegram, Signal.
- **AI Generators**: DALL-E, Midjourney, Adobe Firefly.
- **System**: iOS/Android Screenshots, Windows/macOS capture naming.
"""

using Dates

"""
    FilenameMetadata

EXTRACTED DATA:
- `platform`: Originating service (e.g. "instagram").
- `username`: The handle of the content creator (if encoded).
- `date`: Extracted timestamp of the post or capture.
- `post_id`: Unique identifier from the source platform.
- `is_generic`: Boolean flag indicating if the filename needs normalization.
"""
struct FilenameMetadata
    platform::Union{String,Nothing}
    username::Union{String,Nothing}
    date::Union{DateTime,Nothing}
    post_id::Union{String,Nothing}
    is_generic::Bool
    pattern_matched::String
end

"""
    FILENAME_PATTERNS

REGISTRY: Ordered list of pattern matchers. 
Specific platform patterns (e.g. Instagram anonimostory) are checked 
before generic timestamp patterns.
"""
const FILENAME_PATTERNS = [
    # ... [Implementation of regex matchers and extraction functions]
]

export FilenameMetadata, FILENAME_PATTERNS

end # module
