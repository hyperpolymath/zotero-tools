// Main background script for Zotero Voyant Export

let main = async () => {
  // Wait for Zotero to initialize
  await Zotero.initializationPromise

  Zotero.debug("[Voyant Export] Plugin loaded")

  // Store startup time in browser storage
  let data = %raw(`{ "lastStarted": Date.now() }`)
  %raw(`browser.storage.local.set(data)`)

  Zotero.debug("[Voyant Export] Set start time in browser.storage.")

  // Add export menu item
  UI.insertExportMenuItem(() => {
    Exporter.doExport()->ignore
  })

  Zotero.debug("[Voyant Export] Initialization complete")
}

// Run main function
main()->ignore
