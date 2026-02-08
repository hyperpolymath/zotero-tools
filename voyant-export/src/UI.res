// UI module - Handle menu items and file picker

// Get the most recent window
let getMostRecentWindow = (): Dom.window => {
  Firefox.Services.wm.getMostRecentWindow("navigator:browser")
}

// Create and show file picker
let showFilePicker = (collectionName: string): Js.Nullable.t<Firefox.nsIFile> => {
  let nsIFilePicker = Firefox.Interfaces.nsIFilePicker

  // Create file picker instance
  let fp: Firefox.filePicker = %raw(`
    Components.classes["@mozilla.org/filepicker;1"]
      .createInstance(Components.interfaces.nsIFilePicker)
  `)

  // Configure file picker
  fp.defaultString = collectionName ++ ".zip"
  fp.defaultExtension = "zip"
  fp.appendFilter("ZIP", "*.zip")

  let window = getMostRecentWindow()
  fp.init(window, "Export to Voyant", nsIFilePicker.modeSave)

  // Show dialog and return file or null
  let rv = fp.show()
  if rv == nsIFilePicker.returnOK || rv == nsIFilePicker.returnReplace {
    Js.Nullable.return(fp.file)
  } else {
    Js.Nullable.null
  }
}

// Get collection menu element
let getCollectionMenu = (): option<Dom.element> => {
  switch Zotero.getZoteroPane() {
  | None => None
  | Some(pane) => {
      let doc = pane.document
      doc
      ->Dom.Document.getElementById("zotero-collectionmenu")
      ->Js.Nullable.toOption
    }
  }
}

// Check if menu item already exists
let menuItemExists = (menu: Dom.element): bool => {
  menu
  ->Dom.Element.querySelector("#voyant-export")
  ->Js.Nullable.toOption
  ->Option.isSome
}

// Create menu item element with accessibility features
let createMenuItem = (doc: Dom.document, onclick: unit => unit): Dom.element => {
  let menuitem = doc->Dom.Document.createElement("menuitem")

  // Basic attributes
  menuitem->Dom.Element.setAttribute("id", "voyant-export")
  menuitem->Dom.Element.setAttribute("label", "Export Collection to Voyant...")

  // Accessibility attributes (WCAG 2.1 compliance)
  menuitem->Dom.Element.setAttribute("role", "menuitem")
  menuitem->Dom.Element.setAttribute("aria-label", "Export Collection to Voyant Tools")
  menuitem->Dom.Element.setAttribute("aria-describedby", "voyant-export-desc")
  menuitem->Dom.Element.setAttribute("tabindex", "0")

  // Keyboard accessibility
  menuitem->Dom.Element.setAttribute("accesskey", "v")

  // Set onclick handler - this is the one remaining raw JS we need
  menuitem->%raw(`function(el, handler) {
    el.onclick = handler;
    // Also support keyboard activation
    el.onkeydown = function(e) {
      if (e.key === 'Enter' || e.key === ' ') {
        e.preventDefault();
        handler();
      }
    };
  }`)

  menuitem
}

// Load CSS stylesheet into document
let loadStylesheet = (doc: Dom.document): unit => {
  // Check if stylesheet already loaded
  let existingStyle = doc->Dom.Document.getElementById("voyant-export-styles")

  switch existingStyle->Js.Nullable.toOption {
  | Some(_) => () // Already loaded
  | None => {
      // Create link element for external stylesheet
      let link = doc->Dom.Document.createElement("link")
      link->Dom.Element.setAttribute("id", "voyant-export-styles")
      link->Dom.Element.setAttribute("rel", "stylesheet")
      link->Dom.Element.setAttribute("type", "text/css")
      link->Dom.Element.setAttribute("href", "chrome://zotero-voyant-export/content/ui/styles.css")

      // Append to document head
      let head = doc->%raw(`function(d) { return d.head || d.documentElement }`)
      head->Dom.Element.appendChild(link)

      Zotero.debug("[Voyant Export] Stylesheet loaded")
    }
  }
}

// Insert export menu item
let insertExportMenuItem = (onclick: unit => unit): unit => {
  switch getCollectionMenu() {
  | None => Zotero.debug("[Voyant Export] Could not get collection menu")
  | Some(menu) =>
    if !menuItemExists(menu) {
      let doc = menu->Dom.Element.ownerDocument

      // Load stylesheet first
      loadStylesheet(doc)

      // Create and insert menu item
      let menuitem = createMenuItem(doc, onclick)
      menu->Dom.Element.appendChild(menuitem)

      Zotero.debug("[Voyant Export] Menu item added with accessibility features")
    }
  }
}

// Remove export menu item
let removeExportMenuItem = (): unit => {
  switch getCollectionMenu() {
  | None => ()
  | Some(menu) => {
      let menuitem = menu->Dom.Element.querySelector("#voyant-export")
      switch menuitem->Js.Nullable.toOption {
      | None => ()
      | Some(item) => {
          let parent = item->Dom.Element.parentNode->Js.Nullable.toOption
          switch parent {
          | None => ()
          | Some(p) => {
              p->Dom.Node.removeChild(item)->ignore
              Zotero.debug("[Voyant Export] Menu item removed")
            }
          }
        }
      }
    }
  }
}
