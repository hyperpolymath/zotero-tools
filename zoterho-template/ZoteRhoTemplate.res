/**
 * @file ZoteRhoTemplate.res
 * @description Core Zotero plugin functionality.
 * Provides UI integration, menu items, and theme management.
 * SPDX-License-Identifier: MIT OR Apache-2.0
 * SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
 */

// Zotero-specific bindings (simplified for example)
@module("zotero") @val
external zotero: {
  "debug": string => unit,
  "getMainWindows": () => array<Js.t<'window>>,
  "Prefs": {
    "get": (string, bool) => Js.t<'a>,
  },
} = "Zotero"

// DOM bindings (simplified for Zotero's context)
type window
type document
type element

@send external document: (Js.t<'window>, string) => Js.Nullable.t<element> = "getElementById"
@send external querySelector: (Js.t<'window>, string) => Js.Nullable.t<element> = "querySelector"
@send external createElement: (Js.t<'window>, string) => element = "createElement"
@send external setAttribute: (element, string, string) => unit = "setAttribute"
@send external addEventListener: (element, string, unit => unit) => unit = "addEventListener"
@send external appendChild: (element, element) => unit = "appendChild"
@send external remove: (element) => unit = "remove"
@val external documentElement: Js.t<'window> = "documentElement"

// Zotero XULElement utility
@send external insertFTLIfNeeded: (element, string) => unit = "insertFTLIfNeeded"

// --- ZoteRhoTemplate Module ---

let id: Ref<option<string>> = RescriptCore.ref(None)
let version: Ref<option<string>> = RescriptCore.ref(None)
let rootURI: Ref<option<string>> = RescriptCore.ref(None)
let initialized: Ref<bool> = RescriptCore.ref(false)
let addedElementIDs: Ref<array<string>> = RescriptCore.ref([])

let log = (msg: string): unit => {
  zotero["debug"](`ZoteRho Template: ${msg}`)
}

let storeAddedElement = (elem: element): unit => {
  let elemId = %raw("elem.id")
  if elemId == "" {
    log("Element must have an ID")
  }
  addedElementIDs := RescriptCore.Array.concat(addedElementIDs.contents, [elemId])
}

let toggleGreen = (window: Js.t<'window>, enabled: bool): unit => {
  let docElement = documentElement(window)
  let docElementRes = Js.toOption(docElement)

  switch docElementRes {
  | Some(elem) =>
    if enabled {
      setAttribute(elem, "data-green-instead", "true")
      log("Enabled Green Mode")
    } else {
      // Direct JS interop for removeAttribute
      %raw("elem.removeAttribute('data-green-instead')")
      log("Disabled Green Mode (Default: Red)")
    }
  | None => log("Error: Could not find document element for toggleGreen")
  }
}

let addToWindow = (window: Js.t<'window>): unit => {
  let doc = %raw("window.document")
  let docRes = Js.toOption(doc)

  switch docRes {
  | Some(document) =>
    // 1. Add a stylesheet link
    let link = createElement(document, "link")
    setAttribute(link, "id", "zoterho-template-stylesheet")
    setAttribute(link, "type", "text/css")
    setAttribute(link, "rel", "stylesheet")
    let uri = RescriptCore.Option.getOr(rootURI.contents, "")
    setAttribute(link, "href", uri ++ "style.css")
    appendChild(documentElement(window), link)
    storeAddedElement(link)

    // 2. Use Fluent for localization
    %raw("window.MozXULElement.insertFTLIfNeeded(\"zoterho-template.ftl\")") // RENAME: Update FTL filename (must rename file manually)

    // 3. Add menu option
    let menuitem = createElement(document, "menuitem")
    setAttribute(menuitem, "id", "zoterho-template-green-instead") // RENAME: Update element ID
    setAttribute(menuitem, "type", "checkbox")
    setAttribute(menuitem, "data-l10n-id", "zoterho-template-green-instead") // RENAME: Update l10n ID

    // Add event listener (accessing menuitem.checked via raw JS)
    let handler = () => {
      let isChecked = %raw("menuitem.checked")
      toggleGreen(window, isChecked)
    }
    addEventListener(menuitem, "command", handler)

    let viewPopup = document(document, "menu_viewPopup")
    switch Js.toOption(viewPopup) {
    | Some(popup) =>
      appendChild(popup, menuitem)
      storeAddedElement(menuitem)
    | None => log("Error: Could not find menu_viewPopup")
    }

  | None => log("Error: Could not find document")
  }
}

let addToAllWindows = (): unit => {
  let windows = zotero["getMainWindows"]()
  windows->RescriptCore.Array.forEach(win => {
    // Check for win.ZoteroPane using raw JS for host object check
    let hasPane = %raw("win.ZoteroPane")
    if hasPane {
      addToWindow(win)
    }
  })
}

let removeFromWindow = (window: Js.t<'window>): unit => {
  let doc = %raw("window.document")
  let docRes = Js.toOption(doc)

  switch docRes {
  | Some(document) =>
    // Remove all elements added to DOM
    addedElementIDs.contents->RescriptCore.Array.forEach(id => {
      let elem = document(document, id)
      switch Js.toOption(elem) {
      | Some(e) => remove(e)
      | None => ()
      }
    })
    addedElementIDs := [] // Reset stored IDs

    // Remove FTL link element
    let ftlLink = querySelector(document, "link[href$=\"zoterho-template.ftl\"]") // RENAME: Update FTL filename
    switch Js.toOption(ftlLink) {
    | Some(link) => remove(link)
    | None => log("Warning: FTL link not found during removal")
    }
  | None => log("Error: Could not find document for removal")
  }
}

let removeFromAllWindows = (): unit => {
  let windows = zotero["getMainWindows"]()
  windows->RescriptCore.Array.forEach(win => {
    let hasPane = %raw("win.ZoteroPane")
    if hasPane {
      removeFromWindow(win)
    }
  })
}

let init = ({id: newId, version: newVersion, rootURI: newRootURI}: {id: string, version: string, rootURI: string}): unit => {
  if initialized.contents {
    ()
  } else {
    id := Some(newId)
    version := Some(newVersion)
    rootURI := Some(newRootURI)
    initialized := true
  }
}

let main = (): Js.Promise.t<unit> => {
  let intensityPref = zotero["Prefs"]["get"]("extensions.zoterho-template.intensity", true)
  log(`Intensity is ${%identity(intensityPref)}`)

  // Example of using Zotero's URL utility (translated from the old TS file)
  let host = %raw("new URL('https://foo.com/path').host")
  log(`Host is ${host}`)

  Js.Promise.resolve()
}

// Module exports for the JS shim (ZoteRhoTemplate.js) to access
let toggleGreen_ = toggleGreen
let addToWindow_ = addToWindow
let addToAllWindows_ = addToAllWindows
let removeFromWindow_ = removeFromWindow
let removeFromAllWindows_ = removeFromAllWindows
let init_ = init
let main_ = main

// Exports all functions required by bootstrap.res
// ReScript generates ZoteRhoTemplate.res.js which is copied to ZoteRhoTemplate.js during packaging
