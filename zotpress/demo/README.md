# Zotpress Demo

Minimal examples showing Zotero integration with WordPress.

## Quick Start

### 1. Get Your Zotero Credentials

1. Go to [zotero.org/settings/keys](https://www.zotero.org/settings/keys)
2. Note your **User ID** (numeric, shown at top)
3. Create a new **API Key** with read access

### 2. Test the API (No WordPress Needed)

Open `standalone.html` in your browser and enter your credentials to test.

```bash
# Or use curl directly:
curl "https://api.zotero.org/users/YOUR_USER_ID/items?limit=5&format=json" \
  -H "Zotero-API-Key: YOUR_API_KEY"
```

### 3. WordPress Shortcodes

Once Zotpress is installed and your account is configured:

```
# Basic bibliography (10 items)
[zotpress limit="10"]

# Specific collection
[zotpress collection="ABCD1234"]

# By author
[zotpress author="Smith"]

# By tag
[zotpress tag="machine-learning"]

# Specific item
[zotpress item="XYZ12345"]

# With APA style (default)
[zotpress style="apa"]

# Chicago style
[zotpress style="chicago-note-bibliography"]

# MLA style
[zotpress style="modern-language-association"]
```

### 4. In-Text Citations

```
According to [zotpressInText item="ABC123"], the research shows...

Multiple sources [zotpressInText items="DEF456,GHI789"] confirm this.

[zotpressInTextBib]  <!-- Bibliography at end -->
```

## Citation Styles

Zotpress supports 1000+ CSL citation styles. Common ones:

| Style | Shortcode Value |
|-------|-----------------|
| APA 7th | `apa` |
| Chicago (notes) | `chicago-note-bibliography` |
| MLA 9th | `modern-language-association` |
| Harvard | `harvard-cite-them-right` |
| IEEE | `ieee` |
| Vancouver | `vancouver` |
| Nature | `nature` |

Browse all at: https://www.zotero.org/styles
