/**
 * @file Preferences.res
 * @description Zotero plugin preferences management module.
 * Handles reading/writing preferences and providing UI bindings.
 * SPDX-License-Identifier: MIT OR Apache-2.0
 * SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
 */

// --- External Bindings ---

@module("zotero") @val
external zotero: {
  "Prefs": {
    "get": (string, 'a) => 'a,
    "set": (string, 'a) => unit,
    "clear": string => unit,
  },
  "debug": string => unit,
} = "Zotero"

// --- Preference Keys ---

let prefBranch = "extensions.zoterho-template"

module Keys = {
  let enabled = `${prefBranch}.enabled`
  let themeColor = `${prefBranch}.themeColor`
  let customColor = `${prefBranch}.customColor`
  let showNotifications = `${prefBranch}.showNotifications`
  let linterEnabled = `${prefBranch}.linter.enabled`
  let linterStrictMode = `${prefBranch}.linter.strictMode`
}

// --- Type Definitions ---

type themeColor = Rhodium | Green | Blue | Custom

type linterPrefs = {
  enabled: bool,
  strictMode: bool,
}

type preferences = {
  enabled: bool,
  themeColor: themeColor,
  customColor: string,
  showNotifications: bool,
  linter: linterPrefs,
}

// --- Helper Functions ---

let log = (msg: string): unit => {
  zotero["debug"](`ZoteRho Preferences: ${msg}`)
}

let themeColorFromString = (s: string): themeColor => {
  switch s {
  | "green" => Green
  | "blue" => Blue
  | "custom" => Custom
  | _ => Rhodium
  }
}

let themeColorToString = (t: themeColor): string => {
  switch t {
  | Rhodium => "rhodium"
  | Green => "green"
  | Blue => "blue"
  | Custom => "custom"
  }
}

// --- Preference Accessors ---

let getEnabled = (): bool => {
  zotero["Prefs"]["get"](Keys.enabled, true)
}

let setEnabled = (value: bool): unit => {
  zotero["Prefs"]["set"](Keys.enabled, value)
  log(`Set enabled: ${value ? "true" : "false"}`)
}

let getThemeColor = (): themeColor => {
  let value = zotero["Prefs"]["get"](Keys.themeColor, "rhodium")
  themeColorFromString(value)
}

let setThemeColor = (value: themeColor): unit => {
  zotero["Prefs"]["set"](Keys.themeColor, themeColorToString(value))
  log(`Set themeColor: ${themeColorToString(value)}`)
}

let getCustomColor = (): string => {
  zotero["Prefs"]["get"](Keys.customColor, "#e8e8e8")
}

let setCustomColor = (value: string): unit => {
  zotero["Prefs"]["set"](Keys.customColor, value)
  log(`Set customColor: ${value}`)
}

let getShowNotifications = (): bool => {
  zotero["Prefs"]["get"](Keys.showNotifications, true)
}

let setShowNotifications = (value: bool): unit => {
  zotero["Prefs"]["set"](Keys.showNotifications, value)
}

let getLinterEnabled = (): bool => {
  zotero["Prefs"]["get"](Keys.linterEnabled, false)
}

let setLinterEnabled = (value: bool): unit => {
  zotero["Prefs"]["set"](Keys.linterEnabled, value)
}

let getLinterStrictMode = (): bool => {
  zotero["Prefs"]["get"](Keys.linterStrictMode, false)
}

let setLinterStrictMode = (value: bool): unit => {
  zotero["Prefs"]["set"](Keys.linterStrictMode, value)
}

// --- Bulk Operations ---

let getAll = (): preferences => {
  {
    enabled: getEnabled(),
    themeColor: getThemeColor(),
    customColor: getCustomColor(),
    showNotifications: getShowNotifications(),
    linter: {
      enabled: getLinterEnabled(),
      strictMode: getLinterStrictMode(),
    },
  }
}

let resetToDefaults = (): unit => {
  log("Resetting preferences to defaults")
  setEnabled(true)
  setThemeColor(Rhodium)
  setCustomColor("#e8e8e8")
  setShowNotifications(true)
  setLinterEnabled(false)
  setLinterStrictMode(false)
}

// --- UI Event Handlers (for preferences.xhtml bindings) ---

let onEnabledChange = (event: 'a): unit => {
  let target = event["target"]
  let checked = target["checked"]
  setEnabled(checked)
}

let onThemeColorChange = (event: 'a): unit => {
  let target = event["target"]
  let value = target["value"]
  setThemeColor(themeColorFromString(value))
}

let onCustomColorChange = (event: 'a): unit => {
  let target = event["target"]
  let value = target["value"]
  setCustomColor(value)
}

let onLinterEnabledChange = (event: 'a): unit => {
  let target = event["target"]
  let checked = target["checked"]
  setLinterEnabled(checked)
}

let onLinterStrictModeChange = (event: 'a): unit => {
  let target = event["target"]
  let checked = target["checked"]
  setLinterStrictMode(checked)
}

let onResetClick = (_event: 'a): unit => {
  resetToDefaults()
}

// --- Exports for JavaScript interop ---

let preferences = {
  "getAll": getAll,
  "resetToDefaults": resetToDefaults,
  "getEnabled": getEnabled,
  "setEnabled": setEnabled,
  "getThemeColor": getThemeColor,
  "setThemeColor": setThemeColor,
  "getCustomColor": getCustomColor,
  "setCustomColor": setCustomColor,
  "onEnabledChange": onEnabledChange,
  "onThemeColorChange": onThemeColorChange,
  "onCustomColorChange": onCustomColorChange,
  "onLinterEnabledChange": onLinterEnabledChange,
  "onLinterStrictModeChange": onLinterStrictModeChange,
  "onResetClick": onResetClick,
}
