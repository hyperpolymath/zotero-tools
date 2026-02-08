#!/bin/bash
# Zotpress Quick Install Script
# SPDX-License-Identifier: AGPL-3.0-or-later

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║              ZOTPRESS INSTALLER                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Check for WordPress plugins directory
WP_PLUGINS="${1:-}"

if [ -z "$WP_PLUGINS" ]; then
    # Try common locations
    POSSIBLE_PATHS=(
        "/var/www/html/wp-content/plugins"
        "/var/www/wordpress/wp-content/plugins"
        "$HOME/Sites/wordpress/wp-content/plugins"
        "/srv/www/wordpress/wp-content/plugins"
    )

    for path in "${POSSIBLE_PATHS[@]}"; do
        if [ -d "$path" ]; then
            WP_PLUGINS="$path"
            break
        fi
    done
fi

if [ -z "$WP_PLUGINS" ]; then
    echo "Usage: ./install.sh /path/to/wp-content/plugins"
    echo ""
    echo "Could not auto-detect WordPress plugins directory."
    echo "Please provide the path as an argument."
    exit 1
fi

if [ ! -d "$WP_PLUGINS" ]; then
    echo "Error: Directory not found: $WP_PLUGINS"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="$WP_PLUGINS/zotpress"

echo "Source:      $SCRIPT_DIR"
echo "Destination: $TARGET"
echo ""

# Create symlink (for development) or copy (for production)
if [ "${2:-}" = "--copy" ]; then
    echo "Copying files..."
    rm -rf "$TARGET"
    mkdir -p "$TARGET"
    cp -r "$SCRIPT_DIR/lib" "$TARGET/"
    cp -r "$SCRIPT_DIR/css" "$TARGET/" 2>/dev/null || true
    cp -r "$SCRIPT_DIR/js" "$TARGET/" 2>/dev/null || true
    cp -r "$SCRIPT_DIR/dist" "$TARGET/" 2>/dev/null || true
    cp -r "$SCRIPT_DIR/languages" "$TARGET/" 2>/dev/null || true
    cp "$SCRIPT_DIR/zotpress.php" "$TARGET/"
    cp "$SCRIPT_DIR/readme.txt" "$TARGET/" 2>/dev/null || true
    echo "Files copied!"
else
    echo "Creating symlink (use --copy for production install)..."
    rm -f "$TARGET"
    ln -sf "$SCRIPT_DIR" "$TARGET"
    echo "Symlink created!"
fi

echo ""
echo "✓ Zotpress installed successfully!"
echo ""
echo "Next steps:"
echo "  1. Go to WordPress Admin → Plugins"
echo "  2. Find 'Zotpress' and click Activate"
echo "  3. Go to Zotpress → Accounts to add your Zotero credentials"
echo "  4. Use [zotpress] shortcode in any post or page"
echo ""
echo "Quick demo: make demo"
echo ""
