# SPDX-License-Identifier: MIT OR Apache-2.0
# SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
#
# Nickel configuration for Zotero plugin update manifest
# Generates the updates.json for Zotero's update checker

# Configuration parameters (can be overridden via --field)
let version | default = "2.0.0" in
let hash | default = "sha256:placeholder" in

let updates = {
  addons = {
    "zoterho-template@metadatstastician.art" = {
      updates = [
        {
          version = version,
          update_link = "https://github.com/metadatstastician/zoterho-template/releases/download/v${version}/zoterho-template-${version}.xpi",
          update_hash = hash,
          applications = {
            zotero = {
              strict_min_version = "7.0",
              strict_max_version = "7.99"
            }
          }
        }
      ]
    }
  }
}
in updates
