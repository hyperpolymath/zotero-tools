# SPDX-License-Identifier: AGPL-3.0-or-later
"""
Filename pattern matching and metadata extraction

Handles patterns from:
- Social platforms (Instagram, Facebook, Twitter, VK, etc.)
- Messaging apps (WhatsApp, Telegram, Signal)
- AI tools (Copilot, Gemini, DALL-E, Midjourney)
- Screenshots (Android, iOS, Windows, macOS, Linux)
- Generic downloads (timestamps, UUIDs, hashes)
- Asset exports (Figma, Sketch, Adobe)
"""

using Dates

"""
Represents extracted metadata from a filename
"""
struct FilenameMetadata
    platform::Union{String,Nothing}
    username::Union{String,Nothing}
    date::Union{DateTime,Nothing}
    post_id::Union{String,Nothing}
    resolution::Union{String,Nothing}
    dimensions::Union{Tuple{Int,Int},Nothing}
    original_filename::String
    is_generic::Bool
    pattern_matched::String
end

"""
All pattern matchers - order matters (more specific first)
"""
const FILENAME_PATTERNS = [
    # Instagram patterns
    (
        name = "instagram_anonimostory",
        pattern = r"^anonimostory\.com_Instagram_([^_]+)_(\d+)\.(jpe?g|png|gif|webp)$"i,
        extract = (m, fn) -> FilenameMetadata(
            "instagram",
            isempty(m.captures[1]) ? nothing : m.captures[1],
            nothing,
            m.captures[2],
            nothing, nothing, fn, true, "instagram_anonimostory"
        )
    ),
    (
        name = "instagram_direct",
        pattern = r"^(\d+)_(\d+)_(\d+)_n\.(jpe?g|png)$"i,
        extract = (m, fn) -> FilenameMetadata(
            "instagram/facebook",
            nothing,
            nothing,
            "$(m.captures[1])_$(m.captures[2])_$(m.captures[3])",
            nothing, nothing, fn, true, "instagram_direct"
        )
    ),

    # Facebook patterns
    (
        name = "facebook_photo",
        pattern = r"^(\d{9,20})_(\d{17,25})_(\d{16,25})_n\.(jpe?g|png)$"i,
        extract = (m, fn) -> FilenameMetadata(
            "facebook",
            nothing,
            nothing,
            "$(m.captures[1])_$(m.captures[2])_$(m.captures[3])",
            nothing, nothing, fn, true, "facebook_photo"
        )
    ),

    # Twitter/X patterns
    (
        name = "twitter_media",
        pattern = r"^([A-Za-z0-9_-]{15})\.(jpe?g|png|gif)$"i,
        extract = (m, fn) -> begin
            # Twitter media IDs are base64-ish
            id = m.captures[1]
            if all(c -> c in "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-", id)
                FilenameMetadata(
                    "twitter",
                    nothing, nothing,
                    id,
                    nothing, nothing, fn, true, "twitter_media"
                )
            else
                nothing
            end
        end
    ),

    # VK patterns
    (
        name = "vk_photo",
        pattern = r"^(.+)\s*\[VK\]\.(jpe?g|png)$"i,
        extract = (m, fn) -> FilenameMetadata(
            "vk",
            nothing, nothing, nothing, nothing, nothing,
            fn, false, "vk_tagged"  # Already has description
        )
    ),

    # WhatsApp patterns
    (
        name = "whatsapp_image",
        pattern = r"^WhatsApp Image (\d{4})-(\d{2})-(\d{2}) at (\d{1,2})\.(\d{2})\.(\d{2})( \(\d+\))?\.(jpe?g|png)$"i,
        extract = (m, fn) -> begin
            dt = try
                DateTime(parse(Int, m.captures[1]),
                        parse(Int, m.captures[2]),
                        parse(Int, m.captures[3]),
                        parse(Int, m.captures[4]),
                        parse(Int, m.captures[5]),
                        parse(Int, m.captures[6]))
            catch
                nothing
            end
            FilenameMetadata(
                "whatsapp",
                nothing, dt, nothing, nothing, nothing,
                fn, true, "whatsapp_image"
            )
        end
    ),

    # Telegram patterns
    (
        name = "telegram_photo",
        pattern = r"^photo_(\d{4})-(\d{2})-(\d{2})_(\d{2})-(\d{2})-(\d{2})\.(jpe?g|png)$"i,
        extract = (m, fn) -> begin
            dt = try
                DateTime(parse(Int, m.captures[1]),
                        parse(Int, m.captures[2]),
                        parse(Int, m.captures[3]),
                        parse(Int, m.captures[4]),
                        parse(Int, m.captures[5]),
                        parse(Int, m.captures[6]))
            catch
                nothing
            end
            FilenameMetadata(
                "telegram",
                nothing, dt, nothing, nothing, nothing,
                fn, true, "telegram_photo"
            )
        end
    ),

    # Copilot/Bing patterns
    (
        name = "copilot_image",
        pattern = r"^Copilot_(\d{4})(\d{2})(\d{2})_(\d{2})(\d{2})(\d{2})\.(png|jpe?g)$"i,
        extract = (m, fn) -> begin
            dt = try
                DateTime(parse(Int, m.captures[1]),
                        parse(Int, m.captures[2]),
                        parse(Int, m.captures[3]),
                        parse(Int, m.captures[4]),
                        parse(Int, m.captures[5]),
                        parse(Int, m.captures[6]))
            catch
                nothing
            end
            FilenameMetadata(
                "copilot",
                nothing, dt, nothing, nothing, nothing,
                fn, true, "copilot_image"
            )
        end
    ),

    # Gemini patterns
    (
        name = "gemini_image",
        pattern = r"^Gemini_Generated_Image_([a-z0-9]+)\.(png|jpe?g)$"i,
        extract = (m, fn) -> FilenameMetadata(
            "gemini",
            nothing, nothing,
            m.captures[1],
            nothing, nothing, fn, true, "gemini_image"
        )
    ),

    # DALL-E patterns
    (
        name = "dalle_image",
        pattern = r"^DALL[·\-_]?E[_\s-].*\.(png|jpe?g|webp)$"i,
        extract = (m, fn) -> FilenameMetadata(
            "dalle",
            nothing, nothing, nothing, nothing, nothing,
            fn, true, "dalle_image"
        )
    ),

    # Screenshot patterns - Android
    (
        name = "screenshot_android",
        pattern = r"^Screenshot_(\d{4})(\d{2})(\d{2})[-_](\d{2})(\d{2})(\d{2})(-\d+)?\.(png|jpe?g)$"i,
        extract = (m, fn) -> begin
            dt = try
                DateTime(parse(Int, m.captures[1]),
                        parse(Int, m.captures[2]),
                        parse(Int, m.captures[3]),
                        parse(Int, m.captures[4]),
                        parse(Int, m.captures[5]),
                        parse(Int, m.captures[6]))
            catch
                nothing
            end
            FilenameMetadata(
                "screenshot",
                nothing, dt, nothing, nothing, nothing,
                fn, true, "screenshot_android"
            )
        end
    ),

    # Screenshot patterns - macOS/web
    (
        name = "screenshot_macos",
        pattern = r"^Screenshot (\d{4})-(\d{2})-(\d{2}) at (\d{1,2})[-.](\d{2})[-.](\d{2}).*\.(png|jpe?g)$"i,
        extract = (m, fn) -> begin
            dt = try
                DateTime(parse(Int, m.captures[1]),
                        parse(Int, m.captures[2]),
                        parse(Int, m.captures[3]),
                        parse(Int, m.captures[4]),
                        parse(Int, m.captures[5]),
                        parse(Int, m.captures[6]))
            catch
                nothing
            end
            FilenameMetadata(
                "screenshot",
                nothing, dt, nothing, nothing, nothing,
                fn, true, "screenshot_macos"
            )
        end
    ),

    # Unix timestamp in milliseconds (common from messaging apps)
    (
        name = "unix_timestamp_ms",
        pattern = r"^(\d{13})(-[a-f0-9-]+)?\.(jpe?g|png|gif|webp)$"i,
        extract = (m, fn) -> begin
            ts = parse(Int, m.captures[1])
            dt = try
                unix2datetime(ts / 1000)
            catch
                nothing
            end
            FilenameMetadata(
                nothing,
                nothing, dt, m.captures[2], nothing, nothing,
                fn, true, "unix_timestamp_ms"
            )
        end
    ),

    # Unix timestamp in seconds
    (
        name = "unix_timestamp_s",
        pattern = r"^(\d{10})\.(jpe?g|png|gif|webp)$"i,
        extract = (m, fn) -> begin
            ts = parse(Int, m.captures[1])
            dt = try
                unix2datetime(ts)
            catch
                nothing
            end
            FilenameMetadata(
                nothing,
                nothing, dt, nothing, nothing, nothing,
                fn, true, "unix_timestamp_s"
            )
        end
    ),

    # UUID-embedded filenames
    (
        name = "uuid_embedded",
        pattern = r"^(\d+)-([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})\.(jpe?g|png|gif|webp)$"i,
        extract = (m, fn) -> begin
            ts = tryparse(Int, m.captures[1])
            dt = if !isnothing(ts) && ts > 1000000000000
                try unix2datetime(ts / 1000) catch; nothing end
            else
                nothing
            end
            FilenameMetadata(
                nothing,
                nothing, dt,
                m.captures[2],  # UUID as ID
                nothing, nothing, fn, true, "uuid_embedded"
            )
        end
    ),

    # Random hash filenames (base64-ish, 20+ chars)
    (
        name = "random_hash",
        pattern = r"^([A-Za-z0-9_-]{20,})\.(jpe?g|png|gif|webp)$"i,
        extract = (m, fn) -> begin
            id = m.captures[1]
            # Verify it looks like a hash (mixed case, some numbers)
            has_upper = any(isuppercase, id)
            has_lower = any(islowercase, id)
            has_digit = any(isdigit, id)
            if (has_upper || has_lower) && has_digit
                FilenameMetadata(
                    nothing,
                    nothing, nothing,
                    id,
                    nothing, nothing, fn, true, "random_hash"
                )
            else
                nothing
            end
        end
    ),

    # Asset exports (Figma, Sketch, etc.)
    (
        name = "asset_export",
        pattern = r"^(.+)@(\d+)x\.(png|svg|jpe?g)$"i,
        extract = (m, fn) -> FilenameMetadata(
            "asset_export",
            nothing, nothing, nothing,
            "$(m.captures[2])x",
            nothing, fn, true, "asset_export"
        )
    ),

    # Generic "Image" or "images" filenames
    (
        name = "generic_image",
        pattern = r"^images?(\s*\(\d+\))?\.(jpe?g|png|gif|webp)$"i,
        extract = (m, fn) -> FilenameMetadata(
            nothing,
            nothing, nothing, nothing, nothing, nothing,
            fn, true, "generic_image"
        )
    ),

    # Generic "image-proxy" patterns
    (
        name = "image_proxy",
        pattern = r"^image-proxy.*\.(jpe?g|png|gif|webp)$"i,
        extract = (m, fn) -> FilenameMetadata(
            nothing,
            nothing, nothing, nothing, nothing, nothing,
            fn, true, "image_proxy"
        )
    ),

    # Generic "media" filenames
    (
        name = "generic_media",
        pattern = r"^media\.(jpe?g|png|gif|mp4|webm)$"i,
        extract = (m, fn) -> FilenameMetadata(
            nothing,
            nothing, nothing, nothing, nothing, nothing,
            fn, true, "generic_media"
        )
    ),

    # Image with number only
    (
        name = "image_number",
        pattern = r"^image\d{3,}\.(jpe?g|png|gif|webp)$"i,
        extract = (m, fn) -> FilenameMetadata(
            nothing,
            nothing, nothing, nothing, nothing, nothing,
            fn, true, "image_number"
        )
    ),

    # Paper or document patterns
    (
        name = "paper_generic",
        pattern = r"^paper\.?\d*\.(pdf|png|jpe?g)$"i,
        extract = (m, fn) -> FilenameMetadata(
            nothing,
            nothing, nothing, nothing, nothing, nothing,
            fn, true, "paper_generic"
        )
    ),

    # "undefined" prefix (broken exports)
    (
        name = "undefined_prefix",
        pattern = r"^undefined_(.+)\.(png|jpe?g|gif)$"i,
        extract = (m, fn) -> FilenameMetadata(
            nothing,
            nothing, nothing, nothing, nothing, nothing,
            fn, true, "undefined_prefix"
        )
    ),

    # Qwen image patterns
    (
        name = "qwen_image",
        pattern = r"^qwen-image.*\.(png|jpe?g)$"i,
        extract = (m, fn) -> FilenameMetadata(
            "qwen",
            nothing, nothing, nothing, nothing, nothing,
            fn, true, "qwen_image"
        )
    ),
]

"""
    extract_from_filename(filename::String) -> Dict{String,Any}

Extract metadata from a filename using pattern matching.
Returns a dictionary with extracted fields.
"""
function extract_from_filename(filename::String)::Dict{String,Any}
    result = Dict{String,Any}()

    for pat in FILENAME_PATTERNS
        m = match(pat.pattern, filename)
        if !isnothing(m)
            meta = pat.extract(m, filename)
            if !isnothing(meta)
                result["platform"] = meta.platform
                result["username"] = meta.username
                result["extracted_date"] = meta.date
                result["post_id"] = meta.post_id
                result["resolution"] = meta.resolution
                result["original_filename"] = meta.original_filename
                result["is_generic"] = meta.is_generic
                result["pattern_matched"] = meta.pattern_matched
                break
            end
        end
    end

    # If no pattern matched, check if it's still generic
    if isempty(result)
        result["is_generic"] = is_likely_generic(filename)
        result["pattern_matched"] = result["is_generic"] ? "heuristic_generic" : "none"
        result["original_filename"] = filename
    end

    return result
end

"""
    is_likely_generic(filename::String) -> Bool

Heuristic check for likely generic filenames that didn't match specific patterns.
"""
function is_likely_generic(filename::String)::Bool
    # Remove extension
    base = first(splitext(filename))

    # Check various generic indicators
    # All numeric
    all(isdigit, replace(base, "-" => "", "_" => "")) && return true

    # Very short (< 5 chars)
    length(base) < 5 && return true

    # Common generic words
    lowercase(base) in ["image", "photo", "picture", "download", "file",
                        "attachment", "media", "untitled", "document",
                        "img", "pic", "screenshot", "capture"] && return true

    return false
end

"""
    is_well_named(filename::String) -> Bool

Check if a filename is already well-named (descriptive, human-readable).
"""
function is_well_named(filename::String)::Bool
    base = first(splitext(filename))

    # Already has spaces and meaningful words
    if contains(base, " ") || contains(base, "-")
        words = split(replace(base, "-" => " "), " ")
        # Has multiple words, at least one is 4+ chars
        if length(words) >= 2 && any(w -> length(w) >= 4, words)
            return true
        end
    end

    # Check if it matches any generic pattern
    for pat in FILENAME_PATTERNS
        if !isnothing(match(pat.pattern, filename))
            return false  # Matches a generic pattern
        end
    end

    # Heuristic: if it's not generic and has some description, it's fine
    return !is_likely_generic(filename)
end
