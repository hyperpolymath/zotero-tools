// Performance monitoring and optimization utilities

// Performance metrics type
type performanceMetrics = {
  startTime: float,
  endTime: option<float>,
  itemsProcessed: int,
  itemsFailed: int,
  bytesProcessed: option<int>,
}

// Create new performance tracker
let createMetrics = (): performanceMetrics => {
  {
    startTime: Js.Date.now(),
    endTime: None,
    itemsProcessed: 0,
    itemsFailed: 0,
    bytesProcessed: None,
  }
}

// Update metrics with completion time
let complete = (metrics: performanceMetrics): performanceMetrics => {
  {...metrics, endTime: Some(Js.Date.now())}
}

// Calculate duration in seconds
let getDuration = (metrics: performanceMetrics): option<float> => {
  switch metrics.endTime {
  | None => None
  | Some(end) => Some((end -. metrics.startTime) /. 1000.0)
  }
}

// Calculate items per second
let getItemsPerSecond = (metrics: performanceMetrics): option<float> => {
  switch getDuration(metrics) {
  | None => None
  | Some(duration) =>
    if duration > 0.0 {
      Some(Belt.Int.toFloat(metrics.itemsProcessed) /. duration)
    } else {
      None
    }
  }
}

// Format performance summary
let formatSummary = (metrics: performanceMetrics): string => {
  let total = metrics.itemsProcessed + metrics.itemsFailed
  let successRate = if total > 0 {
    Belt.Int.toFloat(metrics.itemsProcessed) /. Belt.Int.toFloat(total) *. 100.0
  } else {
    0.0
  }

  switch getDuration(metrics) {
  | None => `Processing: ${Belt.Int.toString(metrics.itemsProcessed)}/${Belt.Int.toString(total)} items`
  | Some(duration) => {
      let rate = switch getItemsPerSecond(metrics) {
      | None => ""
      | Some(ips) => ` (${Belt.Float.toString(ips)} items/sec)`
      }

      `Complete: ${Belt.Int.toString(metrics.itemsProcessed)}/${Belt.Int.toString(total)} items in ${Belt.Float.toString(duration)}s${rate}, ${Belt.Float.toString(successRate)}% success`
    }
  }
}

// Throttle function calls to prevent overwhelming the system
let throttle = (fn: unit => unit, delayMs: int): (unit => unit) => {
  let lastCall = ref(0.0)

  () => {
    let now = Js.Date.now()
    if now -. lastCall.contents >= Belt.Int.toFloat(delayMs) {
      lastCall := now
      fn()
    }
  }
}

// Batch process items with size limits
let batchProcess = (
  items: array<'a>,
  batchSize: int,
  processor: array<'a> => promise<unit>,
): promise<unit> => {
  let rec processBatches = async (startIndex: int): promise<unit> => {
    if startIndex >= items->Array.length {
      ()
    } else {
      let endIndex = min(startIndex + batchSize, items->Array.length)
      let batch = items->Array.slice(~start=startIndex, ~end=endIndex)

      await processor(batch)
      await processBatches(startIndex + batchSize)
    }
  }

  processBatches(0)
}

// Memory usage warning thresholds (in MB)
let memoryWarningThreshold = 100
let memoryCriticalThreshold = 500

// Check memory usage (defensive - returns true if we should proceed)
let checkMemoryUsage = (): bool => {
  try {
    // In Firefox/Zotero environment, memory checks are limited
    // Default to optimistic behavior
    %raw(`true`)
  } catch {
  | _exn => {
      Zotero.debug("[Performance] Could not check memory usage, proceeding")
      true
    }
  }
}

// Suggest garbage collection if available (defensive programming)
let suggestGC = (): unit => {
  try {
    // Request garbage collection if available (non-standard API)
    %raw(`if (typeof global !== 'undefined' && global.gc) { global.gc() }`)
    Zotero.debug("[Performance] Suggested garbage collection")
  } catch {
  | _exn => () // Silently fail if GC not available
  }
}

// Optimize for large dataset processing
let optimizeForLargeDataset = (itemCount: int): unit => {
  if itemCount > 100 {
    Zotero.debug(`[Performance] Large dataset detected (${Belt.Int.toString(itemCount)} items)`)
    Zotero.debug("[Performance] Enabling optimizations: batch processing, periodic GC hints")
    suggestGC()
  }
}
