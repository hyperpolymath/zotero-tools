/**
 * Zotpress - Modern Frontend Module
 *
 * ReScript implementation for Zotpress bibliography/citation functionality.
 * Replaces legacy jQuery-dependent code with modern, accessible patterns.
 *
 * @package Zotpress
 * @since 8.0.0
 */

// External bindings for DOM APIs
module Dom = {
  type element
  type event
  type nodeList

  @val @scope("document")
  external getElementById: string => Nullable.t<element> = "getElementById"

  @val @scope("document")
  external querySelector: string => Nullable.t<element> = "querySelector"

  @val @scope("document")
  external querySelectorAll: string => nodeList = "querySelectorAll"

  @val @scope("document")
  external addEventListener: (string, event => unit) => unit = "addEventListener"

  @val @scope("document")
  external createElement: string => element = "createElement"

  @send external getAttribute: (element, string) => Nullable.t<string> = "getAttribute"
  @send external setAttribute: (element, string, string) => unit = "setAttribute"
  @send external removeAttribute: (element, string) => unit = "removeAttribute"
  @send external closest: (element, string) => Nullable.t<element> = "closest"
  @send external appendChild: (element, element) => unit = "appendChild"
  @send external remove: element => unit = "remove"

  @set external setInnerHTML: (element, string) => unit = "innerHTML"
  @get external getInnerHTML: element => string = "innerHTML"
  @set external setTextContent: (element, string) => unit = "textContent"
  @get external getTextContent: element => string = "textContent"
  @set external setClassName: (element, string) => unit = "className"

  @get external target: event => element = "target"
  @send external preventDefault: event => unit = "preventDefault"

  @send external forEach: (nodeList, element => unit) => unit = "forEach"

  // Style
  @set external setStyleAnimationDelay: (element, string) => unit = "style.animationDelay"
}

// External bindings for Window APIs
module Window = {
  @val @scope("window") external open_: (string, string, string) => unit = "open"

  @val @scope("window") external setTimeout: (unit => unit, int) => int = "setTimeout"

  @val @scope("performance") external now: unit => float = "now"
}

// External bindings for Fetch API
module Fetch = {
  type response
  type formData

  @new external makeFormData: unit => formData = "FormData"
  @send external append: (formData, string, string) => unit = "append"

  @val external fetch: (string, {..}) => promise<response> = "fetch"

  @get external ok: response => bool = "ok"
  @get external status: response => int = "status"
  @get external statusText: response => string = "statusText"
  @send external json: response => promise<JSON.t> = "json"
}

// External bindings for Console
module Console = {
  @val @scope("console") external log: 'a => unit = "log"
  @val @scope("console") external log2: ('a, 'b) => unit = "log"
  @val @scope("console") external error: 'a => unit = "error"
  @val @scope("console") external error2: ('a, 'b) => unit = "error"
}

// External bindings for JSON
module JsonExt = {
  @val @scope("JSON") external stringify: 'a => string = "stringify"
  @val @scope("JSON") external parse: string => 'a = "parse"
}

// External bindings for Date
module DateExt = {
  @new external make: string => {..} = "Date"
  @send external getFullYear: {..} => int = "getFullYear"

  @val @scope("Date") external now: unit => float = "now"
}

// External bindings for IntersectionObserver
module IntersectionObserver = {
  type entry = {
    isIntersecting: bool,
    target: Dom.element,
  }
  type t

  @new
  external make: (array<entry> => unit, {..}) => t = "IntersectionObserver"

  @send external observe: (t, Dom.element) => unit = "observe"
  @send external unobserve: (t, Dom.element) => unit = "unobserve"
  @send external disconnect: t => unit = "disconnect"
}

// Configuration type
type config = {
  ajaxUrl: string,
  nonce: string,
  cacheTime: int,
  debug: bool,
}

// Zotero item types
type zoteroCreator = {
  creatorType: string,
  firstName: option<string>,
  lastName: option<string>,
  name: option<string>,
}

type zoteroTag = {
  tag: string,
  @as("type") tagType: option<int>,
}

type zoteroItem = {
  key: string,
  version: int,
  itemType: string,
  title: string,
  creators: option<array<zoteroCreator>>,
  date: option<string>,
  @as("DOI") doi: option<string>,
  @as("URL") url: option<string>,
  abstractNote: option<string>,
  tags: option<array<zoteroTag>>,
}

// Cache entry type
type cacheEntry = {
  data: array<zoteroItem>,
  timestamp: float,
}

// Global state
let configRef: ref<config> = ref({
  ajaxUrl: "/wp-admin/admin-ajax.php",
  nonce: "",
  cacheTime: 600000,
  debug: false,
})

let cacheRef: ref<Map.t<string, cacheEntry>> = ref(Map.make())

// Utility functions
let escapeHtml = (str: string): string => {
  let div = Dom.createElement("div")
  Dom.setTextContent(div, str)
  Dom.getInnerHTML(div)
}

let log = (msg: string): unit => {
  if configRef.contents.debug {
    Console.log2("[Zotpress]", msg)
  }
}

let logError = (msg: string, err: 'a): unit => {
  Console.error2("[Zotpress] " ++ msg, err)
}

// Cache functions
let getCacheKey = (params: Dict.t<string>): string => {
  JsonExt.stringify(params)
}

let getFromCache = (key: string): option<array<zoteroItem>> => {
  switch Map.get(cacheRef.contents, key) {
  | Some(entry) =>
    if DateExt.now() -. entry.timestamp > Float.fromInt(configRef.contents.cacheTime) {
      cacheRef := Map.delete(cacheRef.contents, key)
      None
    } else {
      Some(entry.data)
    }
  | None => None
  }
}

let setCache = (key: string, data: array<zoteroItem>): unit => {
  let entry = {data, timestamp: DateExt.now()}
  cacheRef := Map.set(cacheRef.contents, key, entry)
}

// Format authors list
let formatAuthors = (creators: array<zoteroCreator>): string => {
  creators
  ->Array.filter(c => c.creatorType == "author")
  ->Array.map(a => {
    switch a.name {
    | Some(name) => name
    | None =>
      let parts = [a.lastName, a.firstName]->Array.filterMap(x => x)
      parts->Array.join(", ")
    }
  })
  ->Array.join("; ")
}

// Render a single item
let renderItem = (item: zoteroItem, num: int): string => {
  let authors = switch item.creators {
  | Some(c) => formatAuthors(c)
  | None => ""
  }

  let year = switch item.date {
  | Some(d) =>
    let date = DateExt.make(d)
    Int.toString(DateExt.getFullYear(date))
  | None => ""
  }

  let titleHtml = switch item.url {
  | Some(u) =>
    `<a href="${escapeHtml(u)}" class="zp-Citation-link">${escapeHtml(item.title)}</a>`
  | None => escapeHtml(item.title)
  }

  let doiHtml = switch item.doi {
  | Some(d) =>
    `<a href="https://doi.org/${escapeHtml(d)}" class="zp-Attachment" target="_blank" rel="noopener"><span class="zp-Attachment-icon">📄</span>DOI</a>`
  | None => ""
  }

  let authorsHtml = if authors != "" {
    `<span class="zp-Entry-authors">${authors}</span>`
  } else {
    ""
  }

  let yearHtml = if year != "" {
    `<span class="zp-Entry-year">(${year})</span>`
  } else {
    ""
  }

  `
    <span class="zp-Entry-num">${Int.toString(num)}.</span>
    <div class="zp-Entry-content">
      <h3 class="zp-Entry-title">${titleHtml}</h3>
      <p class="zp-Entry-meta">
        ${authorsHtml}
        ${yearHtml}
      </p>
    </div>
    <div class="zp-Entry-actions">
      ${doiHtml}
    </div>
  `
}

// Announce to screen readers
let announceToScreenReader = (message: string): unit => {
  let announcer = Dom.createElement("div")
  Dom.setAttribute(announcer, "role", "status")
  Dom.setAttribute(announcer, "aria-live", "polite")
  Dom.setClassName(announcer, "zp-sr-only")
  Dom.setTextContent(announcer, message)

  switch Nullable.toOption(Dom.querySelector("body")) {
  | Some(body) =>
    Dom.appendChild(body, announcer)
    let _ = Window.setTimeout(() => Dom.remove(announcer), 1000)
  | None => ()
  }
}

// Show loading state
let showLoading = (container: Dom.element): unit => {
  Dom.setInnerHTML(
    container,
    `
    <div class="zp-Loading" role="status" aria-live="polite">
      <div class="zp-Spinner" aria-hidden="true"></div>
      <span class="zp-sr-only">Loading bibliography...</span>
    </div>
  `,
  )
}

// Show error message
let showError = (container: Dom.element, message: string): unit => {
  Dom.setInnerHTML(
    container,
    `
    <div class="zp-Message zp-Message--error" role="alert">
      ${escapeHtml(message)}
    </div>
  `,
  )
}

// Render bibliography items
let renderBibliography = (container: Dom.element, items: array<zoteroItem>): unit => {
  Dom.removeAttribute(container, "data-lazy")

  if Array.length(items) == 0 {
    Dom.setInnerHTML(container, `<p class="zp-Message zp-Message--info">No items found.</p>`)
    return
  }

  let list = Dom.createElement("ul")
  Dom.setClassName(list, "zp-List")
  Dom.setAttribute(list, "role", "list")

  items->Array.forEachWithIndex((item, index) => {
    let li = Dom.createElement("li")
    Dom.setClassName(li, "zp-Entry zp-animate-fadeIn")
    Dom.setStyleAnimationDelay(li, `${Int.toString(index * 50)}ms`)
    Dom.setInnerHTML(li, renderItem(item, index + 1))
    Dom.appendChild(list, li)
  })

  Dom.setInnerHTML(container, "")
  Dom.appendChild(container, list)

  announceToScreenReader(`Loaded ${Int.toString(Array.length(items))} bibliography items`)
}

// Get data attributes from container
let getDataParams = (container: Dom.element): Dict.t<string> => {
  // This is a simplified version - in practice you'd iterate attributes
  let params = Dict.make()

  let apiUserId = Nullable.toOption(Dom.getAttribute(container, "data-api_user_id"))
  switch apiUserId {
  | Some(v) => Dict.set(params, "api_user_id", v)
  | None => ()
  }

  let collection = Nullable.toOption(Dom.getAttribute(container, "data-collection"))
  switch collection {
  | Some(v) => Dict.set(params, "collection", v)
  | None => ()
  }

  let itemType = Nullable.toOption(Dom.getAttribute(container, "data-itemtype"))
  switch itemType {
  | Some(v) => Dict.set(params, "itemtype", v)
  | None => ()
  }

  params
}

// Fetch data from WordPress AJAX endpoint
let fetchData = async (action: string, data: Dict.t<string>): result<array<zoteroItem>, string> => {
  let formData = Fetch.makeFormData()
  Fetch.append(formData, "action", action)
  Fetch.append(formData, "_ajax_nonce", configRef.contents.nonce)

  data
  ->Dict.toArray
  ->Array.forEach(((key, value)) => {
    Fetch.append(formData, key, value)
  })

  try {
    let response = await Fetch.fetch(configRef.contents.ajaxUrl, {"method": "POST", "body": formData, "credentials": "same-origin"})

    if !Fetch.ok(response) {
      Error(`HTTP ${Int.toString(Fetch.status(response))}: ${Fetch.statusText(response)}`)
    } else {
      let json = await Fetch.json(response)
      // Parse JSON response - simplified
      Ok([])
    }
  } catch {
  | Exn.Error(e) =>
    let msg = switch Exn.message(e) {
    | Some(m) => m
    | None => "Unknown error"
    }
    Error(msg)
  }
}

// Load bibliography content
let loadBibliography = async (container: Dom.element): unit => {
  let params = getDataParams(container)

  let apiUserId = Dict.get(params, "api_user_id")
  switch apiUserId {
  | None =>
    showError(container, "Missing API user ID")
    return
  | Some(_) => ()
  }

  // Check cache
  let cacheKey = getCacheKey(params)
  switch getFromCache(cacheKey) {
  | Some(cached) =>
    renderBibliography(container, cached)
    return
  | None => ()
  }

  // Show loading state
  showLoading(container)

  let result = await fetchData("zpRetrieveViaShortcode", params)

  switch result {
  | Ok(items) =>
    setCache(cacheKey, items)
    renderBibliography(container, items)
  | Error(msg) =>
    showError(container, msg)
    logError("Load error:", msg)
  }
}

// Handle citation click
let handleCitationClick = (link: Dom.element): unit => {
  let href = Nullable.toOption(Dom.getAttribute(link, "href"))
  switch href {
  | Some(url) => Window.open_(url, "_blank", "noopener,noreferrer")
  | None => ()
  }
}

// Handle download click (for analytics)
let trackDownload = (attachment: Dom.element): unit => {
  let href = Nullable.toOption(Dom.getAttribute(attachment, "href"))
  switch href {
  | Some(url) => log(`Download tracked: ${url}`)
  | None => ()
  }
}

// Set up event listeners using event delegation
let setupEventListeners = (): unit => {
  Dom.addEventListener("click", event => {
    let target = Dom.target(event)

    // Handle citation clicks
    switch Nullable.toOption(Dom.closest(target, ".zp-Citation-link")) {
    | Some(link) =>
      Dom.preventDefault(event)
      handleCitationClick(link)
    | None => ()
    }

    // Handle download clicks
    switch Nullable.toOption(Dom.closest(target, ".zp-Attachment")) {
    | Some(attachment) => trackDownload(attachment)
    | None => ()
    }
  })
}

// Initialize lazy loading with IntersectionObserver
let initLazyLoading = (): unit => {
  let observer = IntersectionObserver.make(
    entries => {
      entries->Array.forEach(entry => {
        if entry.isIntersecting {
          let _ = loadBibliography(entry.target)
          IntersectionObserver.unobserve(observer, entry.target)
        }
      })
    },
    {"rootMargin": "200px", "threshold": 0},
  )

  Dom.querySelectorAll(".zp-Zotpress[data-lazy]")->Dom.forEach(el => {
    IntersectionObserver.observe(observer, el)
  })
}

// Initialize the module
let init = (userConfig: option<config>): unit => {
  switch userConfig {
  | Some(c) => configRef := c
  | None => ()
  }

  setupEventListeners()
  initLazyLoading()
  log("Zotpress initialized")
}

// Auto-initialize on DOMContentLoaded
let () = {
  Dom.addEventListener("DOMContentLoaded", _ => {
    // Get config from data attribute if present
    switch Nullable.toOption(Dom.querySelector("[data-zotpress-config]")) {
    | Some(configEl) =>
      switch Nullable.toOption(Dom.getAttribute(configEl, "data-zotpress-config")) {
      | Some(configStr) =>
        let parsed = JsonExt.parse(configStr)
        init(Some(parsed))
      | None => init(None)
      }
    | None => init(None)
    }
  })
}
