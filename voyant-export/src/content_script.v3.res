// Manifest V3 Content Script
// Runs in Zotero UI context, handles DOM manipulation
// Communicates with service worker via messages

// This replaces the direct UI manipulation in background.res for V3

// Send message to service worker
@val @scope(("chrome", "runtime"))
external sendMessage: ('a, 'b => unit) => unit = "sendMessage"

// Handle menu click - send message to service worker
let handleMenuClick = (): unit => {
  Zotero.debug("[Voyant Export] Menu clicked, sending message to service worker")

  sendMessage(
    {"type": "export-collection"},
    response => {
      let resp = response->Obj.magic
      Zotero.debug(`[Voyant Export] Response from service worker: ${resp["status"]}`)

      switch resp["status"] {
      | "success" => Zotero.debug("[Voyant Export] Export started successfully")
      | "error" =>
        switch resp["message"]->Js.Nullable.toOption {
        | Some(msg) => Zotero.debug(`[Voyant Export] Error: ${msg}`)
        | None => Zotero.debug("[Voyant Export] Unknown error")
        }
      | _ => Zotero.debug("[Voyant Export] Unexpected response")
      }
    },
  )
}

// Initialize content script
let init = async () => {
  // Wait for Zotero to be ready
  await Zotero.initializationPromise

  Zotero.debug("[Voyant Export] Content script loaded (V3)")

  // Insert menu item (same logic as V2, but calls handleMenuClick)
  UI.insertExportMenuItem(handleMenuClick)

  Zotero.debug("[Voyant Export] Menu item added (V3)")
}

// Run initialization
init()->ignore
