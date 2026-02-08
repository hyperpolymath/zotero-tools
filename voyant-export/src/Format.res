// Format module - Generate MODS and Dublin Core XML from Zotero items

let modsNS = "http://www.loc.gov/mods/v3"
let dcNS = "http://purl.org/dc/elements/1.1/"

// DOMParser type
type domParser = {parseFromString: (string, string) => Dom.document}

@new
external makeDOMParser: unit => domParser = "DOMParser"

// XMLSerializer type
type xmlSerializer = {serializeToString: Dom.document => string}

@new
external makeXMLSerializer: unit => xmlSerializer = "XMLSerializer"

// Create XML document from string
let createXMLDocument = (rootElement: string): Dom.document => {
  let parser = makeDOMParser()
  let xmlDecl = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
  parser.parseFromString(`${xmlDecl}${rootElement}`, "text/xml")
}

// Create element with namespace
let createElement = (doc: Dom.document, namespace: string, tagName: string): Dom.element => {
  doc->Dom.Document.createElementNS(namespace, tagName)
}

// Create text node
let createTextNode = (doc: Dom.document, text: string): Dom.node => {
  doc->Dom.Document.createTextNode(text)
}

// Append child to parent
let appendChild = (parent: Dom.element, child: Dom.node): unit => {
  parent->Dom.Element.appendChild(child)
}

// Set attribute on element
let setAttribute = (element: Dom.element, name: string, value: string): unit => {
  element->Dom.Element.setAttribute(name, value)
}

// Serialize document to string
let serializeToString = (doc: Dom.document): string => {
  let serializer = makeXMLSerializer()
  serializer.serializeToString(doc)
}

// Get document element
let getDocumentElement = (doc: Dom.document): Dom.element => {
  doc->%raw(`function(d) { return d.documentElement }`)
}

// Map property to XML element
let mapProperty = (
  doc: Dom.document,
  ns: string,
  parent: Dom.element,
  elementName: string,
  property: option<string>,
): unit => {
  switch property {
  | None => ()
  | Some(value) => {
      let element = createElement(doc, ns, elementName)
      let textNode = createTextNode(doc, value)
      appendChild(element, textNode)
      appendChild(parent, element->Obj.magic)
    }
  }
}

// Generate MODS XML for an item
let generateMODS = (item: Zotero.item): string => {
  let modsEl = `<mods xmlns="${modsNS}" xmlns:mods="${modsNS}" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xlink="http://www.w3.org/1999/xlink" xsi:schemaLocation="${modsNS} http://www.loc.gov/standards/mods/mods.xsd" />`

  let doc = createXMLDocument(modsEl)
  let mods = getDocumentElement(doc)

  // Add title
  let title = item.getDisplayTitle()
  if title != "" {
    let titleInfo = createElement(doc, modsNS, "titleInfo")
    mapProperty(doc, modsNS, titleInfo, "title", Some(title))
    appendChild(mods, titleInfo->Obj.magic)
  }

  // Add creators
  let creators = item.getCreators()
  for i in 0 to creators->Array.length - 1 {
    let creator = creators[i]
    let fullName = switch creator.firstName {
    | Some(first) => `${first} ${creator.lastName}`
    | None => creator.lastName
    }

    let name = createElement(doc, modsNS, "name")
    setAttribute(name, "type", "personal")
    mapProperty(doc, modsNS, name, "namePart", Some(fullName))
    appendChild(mods, name->Obj.magic)
  }

  serializeToString(doc)
}

// Generate Dublin Core XML for an item
let generateDC = (item: Zotero.item): string => {
  let dcEl = `<oai_dc:dc xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" xmlns:dc="${dcNS}" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd" />`

  let doc = createXMLDocument(dcEl)
  let dc = getDocumentElement(doc)

  mapProperty(doc, dcNS, dc, "dc:identifier", Some(item.libraryKey))

  serializeToString(doc)
}
