// Zotero API bindings for ReScript

// Core Zotero object
@val @scope("window")
external initializationPromise: promise<unit> = "Zotero.initializationPromise"

@val @scope("window")
external debug: string => unit = "Zotero.debug"

// Zotero.File module
module File = {
  @val @scope(("window", "Zotero", "File"))
  external pathToFile: string => Firefox.nsIFile = "pathToFile"

  @val @scope(("window", "Zotero", "File"))
  external putContents: (Firefox.nsIFile, string) => unit = "putContents"

  @val @scope(("window", "Zotero", "File"))
  external zipDirectory: (string, string) => promise<unit> = "zipDirectory"
}

// Zotero.getActiveZoteroPane
@val @scope(("window", "Zotero"))
external getActiveZoteroPane: unit => Js.Nullable.t<zoteroPane> = "getActiveZoteroPane"

// Collection type
and type rec collection = {
  name: string,
  getChildItems: unit => array<item>,
}

// Item type
and item = {
  id: int,
  libraryKey: string,
  getDisplayTitle: unit => string,
  getCreators: unit => array<creator>,
  getBestAttachment: unit => promise<Js.Nullable.t<attachment>>,
}

// Creator type
and creator = {
  firstName: option<string>,
  lastName: string,
  creatorType: string,
}

// Attachment type
and attachment = {
  getFilePathAsync: unit => promise<Js.Nullable.t<string>>,
}

// ZoteroPane methods
and zoteroPane = {
  document: Dom.document,
  loaded: bool,
  show: unit => unit,
  getSelectedCollection: unit => Js.Nullable.t<collection>,
}

let getZoteroPane = (): option<zoteroPane> => {
  let pane = getActiveZoteroPane()
  switch pane->Js.Nullable.toOption {
  | None => None
  | Some(p) => Some(p)
  }
}
