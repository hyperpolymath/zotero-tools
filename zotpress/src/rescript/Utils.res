/**
 * Zotpress Utilities
 *
 * Common utility functions for the Zotpress ReScript modules.
 *
 * @package Zotpress
 * @since 8.0.0
 */

// String utilities
let isEmpty = (str: string): bool => String.length(str) == 0

let isNotEmpty = (str: string): bool => String.length(str) > 0

let trim = (str: string): string => String.trim(str)

let capitalize = (str: string): string => {
  if isEmpty(str) {
    str
  } else {
    let first = String.charAt(str, 0)->String.toUpperCase
    let rest = String.sliceToEnd(str, ~start=1)
    first ++ rest
  }
}

// Array utilities
let head = (arr: array<'a>): option<'a> => arr->Array.get(0)

let tail = (arr: array<'a>): array<'a> => {
  if Array.length(arr) <= 1 {
    []
  } else {
    arr->Array.sliceToEnd(~start=1)
  }
}

let last = (arr: array<'a>): option<'a> => arr->Array.get(Array.length(arr) - 1)

let isEmpty_arr = (arr: array<'a>): bool => Array.length(arr) == 0

let isNotEmpty_arr = (arr: array<'a>): bool => Array.length(arr) > 0

// Option utilities
let getOrElse = (opt: option<'a>, default: 'a): 'a => {
  switch opt {
  | Some(v) => v
  | None => default
  }
}

let map = (opt: option<'a>, fn: 'a => 'b): option<'b> => {
  switch opt {
  | Some(v) => Some(fn(v))
  | None => None
  }
}

let flatMap = (opt: option<'a>, fn: 'a => option<'b>): option<'b> => {
  switch opt {
  | Some(v) => fn(v)
  | None => None
  }
}

// Result utilities
let mapOk = (result: result<'a, 'e>, fn: 'a => 'b): result<'b, 'e> => {
  switch result {
  | Ok(v) => Ok(fn(v))
  | Error(e) => Error(e)
  }
}

let mapError = (result: result<'a, 'e>, fn: 'e => 'f): result<'a, 'f> => {
  switch result {
  | Ok(v) => Ok(v)
  | Error(e) => Error(fn(e))
  }
}

let getOkOrElse = (result: result<'a, 'e>, default: 'a): 'a => {
  switch result {
  | Ok(v) => v
  | Error(_) => default
  }
}

// DOM utilities
module DomUtils = {
  @val @scope("document")
  external querySelector: string => Nullable.t<{..}> = "querySelector"

  @val @scope("document")
  external querySelectorAll: string => array<{..}> = "querySelectorAll"

  let hasClass = (element: {..}, className: string): bool => {
    let classList: array<string> = %raw(`Array.from(element.classList)`)
    classList->Array.includes(className)
  }

  let addClass = (element: {..}, className: string): unit => {
    %raw(`element.classList.add(className)`)
  }

  let removeClass = (element: {..}, className: string): unit => {
    %raw(`element.classList.remove(className)`)
  }

  let toggleClass = (element: {..}, className: string): unit => {
    %raw(`element.classList.toggle(className)`)
  }
}

// Debounce utility
let debounce = (fn: unit => unit, delay: int): (unit => unit) => {
  let timeoutId = ref(None)

  () => {
    switch timeoutId.contents {
    | Some(id) => %raw(`clearTimeout(id)`)
    | None => ()
    }

    let newId: int = %raw(`setTimeout(fn, delay)`)
    timeoutId := Some(newId)
  }
}

// Throttle utility
let throttle = (fn: unit => unit, limit: int): (unit => unit) => {
  let lastRun = ref(0.0)

  () => {
    let now: float = %raw(`Date.now()`)
    if now -. lastRun.contents >= Float.fromInt(limit) {
      lastRun := now
      fn()
    }
  }
}

// URL utilities
let parseQueryString = (query: string): Dict.t<string> => {
  let params = Dict.make()
  let cleanQuery = if String.startsWith(query, "?") {
    String.sliceToEnd(query, ~start=1)
  } else {
    query
  }

  if isNotEmpty(cleanQuery) {
    cleanQuery
    ->String.split("&")
    ->Array.forEach(pair => {
      let parts = String.split(pair, "=")
      switch (parts->Array.get(0), parts->Array.get(1)) {
      | (Some(key), Some(value)) =>
        let decodedKey: string = %raw(`decodeURIComponent(key)`)
        let decodedValue: string = %raw(`decodeURIComponent(value)`)
        Dict.set(params, decodedKey, decodedValue)
      | _ => ()
      }
    })
  }

  params
}

let buildQueryString = (params: Dict.t<string>): string => {
  params
  ->Dict.toArray
  ->Array.map(((key, value)) => {
    let encodedKey: string = %raw(`encodeURIComponent(key)`)
    let encodedValue: string = %raw(`encodeURIComponent(value)`)
    `${encodedKey}=${encodedValue}`
  })
  ->Array.join("&")
}
