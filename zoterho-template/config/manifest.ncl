# SPDX-License-Identifier: MIT OR Apache-2.0
# SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
#
# Nickel configuration for Zotero plugin manifest
# Type-safe, declarative configuration replacing fragile JSON

let manifest = {
  manifest_version = 2,
  name = "ZoteRho Template",
  version = "2.0.0",
  description = "A sample Zotero 7+ plugin demonstrating the Rhodium Standard for FOSS development",

  applications = {
    zotero = {
      id = "zoterho-template@metadatstastician.art",
      update_url = "https://metadatstastician.art/zoterho-template/updates.json",
      strict_min_version = "7.0",
      strict_max_version = "7.99"
    }
  },

  author = "Jonathan D.A. Jewell <jonathan@hyperpolymath.io>",
  homepage_url = "https://github.com/metadatstastician/zoterho-template",

  # Zotero 7+ bootstrapped plugin configuration
  bootstrap = true,
  legacy = false,

  # Content scripts and styles
  content_scripts = [
    {
      matches = ["*://www.zotero.org/*"],
      js = ["ZoteRhoTemplate.res.js"],
      css = ["style.css"]
    }
  ]
}
in manifest
