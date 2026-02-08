# SPDX-License-Identifier: MIT OR Apache-2.0
# SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
#
# Nickel configuration for Zotero plugin preferences
# Generates preferences schema and default values

let preferences = {
  # Plugin identifier
  plugin_id = "zoterho-template@metadatstastician.art",

  # Preference branch (Zotero convention)
  branch = "extensions.zoterho-template",

  # Preference definitions with types and defaults
  prefs = {
    # Whether the plugin colorizer is enabled
    enabled = {
      type = "bool",
      default = true,
      label = "Enable ZoteRho Template",
      description = "Enable or disable the plugin functionality"
    },

    # Primary theme color
    themeColor = {
      type = "string",
      default = "rhodium",
      label = "Theme Color",
      description = "Primary color theme for the plugin",
      options = ["rhodium", "green", "blue", "custom"]
    },

    # Custom color (when themeColor is "custom")
    customColor = {
      type = "string",
      default = "#e8e8e8",
      label = "Custom Color",
      description = "Custom hex color (when Theme Color is set to 'custom')"
    },

    # Show notifications
    showNotifications = {
      type = "bool",
      default = true,
      label = "Show Notifications",
      description = "Display notifications for plugin actions"
    },

    # Linter integration
    linter = {
      enabled = {
        type = "bool",
        default = false,
        label = "Enable Linter",
        description = "Enable the Rhodium code linter integration"
      },
      strictMode = {
        type = "bool",
        default = false,
        label = "Strict Mode",
        description = "Enforce strict Rhodium Standard compliance"
      }
    }
  },

  # Generate Zotero prefs.js format
  toPrefsJs =
    let flatten = fun prefix prefs acc =>
      std.record.fold_left
        (fun key val inner_acc =>
          if std.is_record val && std.record.has_field "type" val then
            inner_acc @ ["pref(\"${prefix}.${key}\", ${
              if val.type == "bool" then std.to_string val.default
              else if val.type == "string" then "\"${val.default}\""
              else std.to_string val.default
            });"]
          else if std.is_record val then
            flatten "${prefix}.${key}" val inner_acc
          else
            inner_acc
        )
        acc
        prefs
    in
    std.string.join "\n" (flatten branch prefs [])
}
in preferences
