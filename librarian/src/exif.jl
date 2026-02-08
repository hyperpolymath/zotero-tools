# SPDX-License-Identifier: AGPL-3.0-or-later
"""
EXIF and file metadata extraction

Uses exiftool if available, falls back to basic file info.
"""

using Dates

"""
    extract_exif(filepath::String) -> Dict{String,Any}

Extract EXIF and metadata from an image file.
"""
function extract_exif(filepath::String)::Dict{String,Any}
    result = Dict{String,Any}()

    if !isfile(filepath)
        return result
    end

    # Try exiftool first (most comprehensive)
    if has_exiftool()
        return extract_with_exiftool(filepath)
    end

    # Fallback to basic file info
    result["file_size"] = filesize(filepath)
    result["file_mtime"] = Dates.unix2datetime(mtime(filepath))

    return result
end

"""
Check if exiftool is available on the system
"""
function has_exiftool()::Bool
    try
        run(pipeline(`which exiftool`, devnull))
        return true
    catch
        return false
    end
end

"""
Extract metadata using exiftool
"""
function extract_with_exiftool(filepath::String)::Dict{String,Any}
    result = Dict{String,Any}()

    try
        # Run exiftool with JSON output
        output = read(`exiftool -json -DateTimeOriginal -CreateDate -GPSLatitude -GPSLongitude -Make -Model -ImageWidth -ImageHeight -Orientation -Copyright -Artist -Description -Title "$filepath"`, String)

        # Parse JSON (first element of array)
        data = JSON3.read(output)
        if !isempty(data)
            info = data[1]

            # Extract relevant fields
            if haskey(info, :DateTimeOriginal)
                result["exif_date"] = parse_exif_date(string(info.DateTimeOriginal))
            elseif haskey(info, :CreateDate)
                result["exif_date"] = parse_exif_date(string(info.CreateDate))
            end

            if haskey(info, :GPSLatitude) && haskey(info, :GPSLongitude)
                result["gps_lat"] = info.GPSLatitude
                result["gps_lon"] = info.GPSLongitude
            end

            if haskey(info, :Make)
                result["camera_make"] = info.Make
            end
            if haskey(info, :Model)
                result["camera_model"] = info.Model
            end

            if haskey(info, :ImageWidth) && haskey(info, :ImageHeight)
                result["dimensions"] = (info.ImageWidth, info.ImageHeight)
            end

            if haskey(info, :Artist)
                result["artist"] = info.Artist
            end
            if haskey(info, :Copyright)
                result["copyright"] = info.Copyright
            end
            if haskey(info, :Description)
                result["description"] = info.Description
            end
            if haskey(info, :Title)
                result["title"] = info.Title
            end
        end
    catch e
        # Silently fail - not critical
        result["exif_error"] = string(e)
    end

    return result
end

"""
Parse EXIF date format to DateTime
"""
function parse_exif_date(datestr::String)::Union{DateTime,Nothing}
    # Common EXIF date format: "2025:01:15 14:30:00"
    try
        return DateTime(datestr, "yyyy:mm:dd HH:MM:SS")
    catch
        try
            return DateTime(datestr, "yyyy-mm-dd HH:MM:SS")
        catch
            return nothing
        end
    end
end

"""
    get_image_dimensions(filepath::String) -> Union{Tuple{Int,Int},Nothing}

Get image dimensions without full EXIF parse (faster).
Uses file header parsing for common formats.
"""
function get_image_dimensions(filepath::String)::Union{Tuple{Int,Int},Nothing}
    if !isfile(filepath)
        return nothing
    end

    try
        open(filepath, "r") do io
            # Read first 32 bytes for header inspection
            header = read(io, 32)

            # PNG: bytes 16-19 = width, 20-23 = height (big endian)
            if length(header) >= 24 && header[1:8] == UInt8[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
                width = Int(header[17]) << 24 | Int(header[18]) << 16 | Int(header[19]) << 8 | Int(header[20])
                height = Int(header[21]) << 24 | Int(header[22]) << 16 | Int(header[23]) << 8 | Int(header[24])
                return (width, height)
            end

            # JPEG: more complex, need to find SOF marker
            if length(header) >= 2 && header[1:2] == UInt8[0xFF, 0xD8]
                return parse_jpeg_dimensions(io)
            end

            # GIF: bytes 6-7 = width, 8-9 = height (little endian)
            if length(header) >= 10 && (header[1:3] == UInt8[0x47, 0x49, 0x46])  # "GIF"
                width = Int(header[7]) | Int(header[8]) << 8
                height = Int(header[9]) | Int(header[10]) << 8
                return (width, height)
            end
        end
    catch
        return nothing
    end

    return nothing
end

"""
Parse JPEG dimensions from file stream
"""
function parse_jpeg_dimensions(io::IO)::Union{Tuple{Int,Int},Nothing}
    # Reset and skip SOI
    seek(io, 2)

    while !eof(io)
        marker = read(io, UInt8)
        if marker != 0xFF
            continue
        end

        marker_type = read(io, UInt8)

        # Skip padding
        while marker_type == 0xFF
            marker_type = read(io, UInt8)
        end

        # SOF markers (baseline, progressive, etc.)
        if marker_type in [0xC0, 0xC1, 0xC2, 0xC3, 0xC5, 0xC6, 0xC7, 0xC9, 0xCA, 0xCB, 0xCD, 0xCE, 0xCF]
            length = Int(read(io, UInt8)) << 8 | Int(read(io, UInt8))
            precision = read(io, UInt8)
            height = Int(read(io, UInt8)) << 8 | Int(read(io, UInt8))
            width = Int(read(io, UInt8)) << 8 | Int(read(io, UInt8))
            return (width, height)
        end

        # Skip to next marker
        if marker_type == 0xD9  # EOI
            break
        elseif marker_type in [0xD0:0xD7..., 0x01, 0x00]
            continue
        else
            length = Int(read(io, UInt8)) << 8 | Int(read(io, UInt8))
            skip(io, length - 2)
        end
    end

    return nothing
end
