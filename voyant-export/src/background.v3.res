// Manifest V3 Service Worker Entry Point
// This will be used when Zotero migrates to Manifest V3

// Service workers are episodic (start/stop as needed)
// They have no DOM access - must use message passing

// Message types
type exportMessage = {
  @as("type") type_: string,
  collectionId: option<int>,
}

type responseMessage = {
  status: string,
  message: option<string>,
}

// Handle messages from content script
let handleMessage = (
  message: exportMessage,
  _sender: 'a,
  sendResponse: responseMessage => unit,
): bool => {
  switch message.type_ {
  | "export-collection" => {
      // Trigger export asynchronously
      Exporter.doExport()
        ->Promise.then(() => {
          sendResponse({
            status: "success",
            message: Some("Export started"),
          })
          Promise.resolve()
        })
        ->Promise.catch(err => {
          sendResponse({
            status: "error",
            message: Some(`Export failed: ${err->Obj.magic}`),
          })
          Promise.resolve()
        })
        ->ignore

      // Return true to indicate async response
      true
    }
  | "ping" => {
      sendResponse({status: "pong", message: None})
      false
    }
  | _ => {
      sendResponse({
        status: "error",
        message: Some(`Unknown message type: ${message.type_}`),
      })
      false
    }
  }
}

// Register message listener
@val @scope(("chrome", "runtime", "onMessage"))
external addListener: ((exportMessage, 'a, responseMessage => unit) => bool) => unit = "addListener"

// Initialize service worker
let init = () => {
  Zotero.debug("[Voyant Export] Service worker initializing (V3)")

  // Register message handler
  addListener(handleMessage)

  Zotero.debug("[Voyant Export] Service worker ready (V3)")
}

// Service workers auto-start, no need for explicit invocation
init()
