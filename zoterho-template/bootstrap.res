/**
 * @file Bootstrap.res
 * @description Zotero 7 Bootstrapped Add-on entry point.
 * Calls the ZoteRhoTemplate module compiled from ReScript.
 * SPDX-License-Identifier: MIT OR Apache-2.0
 * SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
 */

@module("./ZoteRhoTemplate.js") external zoteRhoTemplate: {
  ..
  "init": ({
    "id": string,
    "version": string,
    "rootURI": string,
  }) => unit,
  "addToAllWindows": () => unit,
  "main": () => Js.Promise.t<unit>,
  "removeFromAllWindows": () => unit,
  "addToWindow": ({ "window": Js.t<'a> }) => unit,
  "removeFromWindow": ({ "window": Js.t<'a> }) => unit,
} = "ZoteRhoTemplate"

@module("zotero") @val
external zotero: {
  "debug": string => unit,
  "PreferencePanes": {
    "register": ({
      "pluginID": string,
      "src": string,
      "scripts": array<string>,
    }) => unit,
  },
} = "Zotero"

@module("services") @val
external services: { "scriptloader": { "loadSubScript": string => unit } } = "Services"

let log = (msg: string): unit => {
  zotero["debug"](`ZoteRho Template: ${msg}`)
}

let install = (): unit => {
  log("Installed 2.0 (Rescript)")
}

let startup = ({id, version, rootURI}: {id: string, version: string, rootURI: string}): Js.Promise.t<unit> => {
  log("Starting 2.0 (Rescript)")

  zotero["PreferencePanes"]["register"]({
    pluginID: "zoterho-template@metadatstastician.art",
    src: rootURI + "preferences.xhtml",
    scripts: [rootURI + "preferences.js"],
  })

  // Load the main ReScript-compiled module
  services["scriptloader"]["loadSubScript"](rootURI + "ZoteRhoTemplate.js")

  zoteRhoTemplate["init"]({id: id, version: version, rootURI: rootURI})
  zoteRhoTemplate["addToAllWindows"]()

  // Wait for the main logic to run
  zoteRhoTemplate["main"]()
}

let onMainWindowLoad = ({window}: {window: Js.t<'a>}): unit => {
  zoteRhoTemplate["addToWindow"]({window: window})
}

let onMainWindowUnload = ({window}: {window: Js.t<'a>}): unit => {
  zoteRhoTemplate["removeFromWindow"]({window: window})
}

let shutdown = (): unit => {
  log("Shutting down 2.0 (ReScript)")
  zoteRhoTemplate["removeFromAllWindows"]()
}

let uninstall = (): unit => {
  log("Uninstalled 2.0 (Rescript)")
}

// Export functions for Zotero's bootstrap loader (The names must match the Zotero API)
let install_ = install
let startup_ = startup
let onMainWindowLoad_ = onMainWindowLoad
let onMainWindowUnload_ = onMainWindowUnload
let shutdown_ = shutdown
let uninstall_ = uninstall
