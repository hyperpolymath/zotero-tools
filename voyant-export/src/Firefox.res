// Firefox Components and Interfaces bindings

// Components.classes
module Classes = {
  @val @scope(("window", "Components", "classes"))
  external filePicker: string = "\"@mozilla.org/filepicker;1\""
}

// Components.interfaces
module Interfaces = {
  type nsIFilePicker = {
    modeSave: int,
    returnOK: int,
    returnReplace: int,
  }

  @val @scope(("window", "Components", "interfaces"))
  external nsIFilePicker: nsIFilePicker = "nsIFilePicker"
}

// nsIFilePicker instance
type filePicker = {
  defaultString: string,
  defaultExtension: string,
  appendFilter: (string, string) => unit,
  init: (Dom.window, string, int) => unit,
  show: unit => int,
  file: nsIFile,
}

// nsIFile interface
and nsIFile = {
  path: string,
  clone: unit => nsIFile,
  append: string => unit,
  create: (int, int) => unit,
  copyTo: (nsIFile, string) => unit,
  createUnique: (int, int) => unit,
}

@val @scope(("window", "Components", "classes"))
external createFilePicker: string => filePicker = "\"@mozilla.org/filepicker;1\"[\"createInstance\"](Components.interfaces.nsIFilePicker)"

// ChromeUtils
module ChromeUtils = {
  @val @scope("window")
  external importESModule: string => {..} = "ChromeUtils.importESModule"
}

// FileUtils from Firefox
module FileUtils = {
  type t

  @val
  external get: unit => t = "ChromeUtils.importESModule(\"resource://gre/modules/FileUtils.sys.mjs\").FileUtils"

  @send
  external getFile: (t, string, array<string>) => nsIFile = "getFile"
}

// Services
module Services = {
  type windowMediator = {getMostRecentWindow: string => Dom.window}

  @val @scope(("window", "Services"))
  external wm: windowMediator = "wm"
}

// Constants
let nsIFile_DIRECTORY_TYPE = 0x01
let nsIFile_NORMAL_FILE_TYPE = 0x00
