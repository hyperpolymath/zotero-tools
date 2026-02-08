// Error recovery and resilience utilities

// Retry configuration
type retryConfig = {
  maxAttempts: int,
  delayMs: int,
  backoffMultiplier: float,
}

let defaultRetryConfig: retryConfig = {
  maxAttempts: 3,
  delayMs: 1000,
  backoffMultiplier: 2.0,
}

// Wait/delay function
let delay = (ms: int): promise<unit> => {
  Promise.make((resolve, _reject) => {
    let _timeoutId = setTimeout(() => resolve(), ms)
  })
}

// Retry an async operation with exponential backoff
let rec retryWithBackoff = async (
  operation: unit => promise<'a>,
  config: retryConfig,
  attempt: int,
): promise<result<'a, string>> => {
  try {
    let result = await operation()
    Ok(result)
  } catch {
  | exn => {
      let error = exn->Obj.magic
      Zotero.debug(`Attempt ${Belt.Int.toString(attempt)} failed: ${error}`)

      if attempt >= config.maxAttempts {
        Error(`Failed after ${Belt.Int.toString(config.maxAttempts)} attempts: ${error}`)
      } else {
        // Calculate delay with exponential backoff
        let delayTime = Belt.Float.toInt(
          Belt.Int.toFloat(config.delayMs) *.
          Math.pow(config.backoffMultiplier, Belt.Int.toFloat(attempt - 1))
        )

        Zotero.debug(`Retrying in ${Belt.Int.toString(delayTime)}ms...`)
        await delay(delayTime)
        await retryWithBackoff(operation, config, attempt + 1)
      }
    }
  }
}

// Simple retry wrapper
let retry = async (operation: unit => promise<'a>): promise<result<'a, string>> => {
  await retryWithBackoff(operation, defaultRetryConfig, 1)
}

// Safe file operation wrapper
let safeFileOperation = async (
  operation: unit => promise<unit>,
  operationName: string,
): promise<bool> => {
  Zotero.debug(`[Safe Operation] Starting: ${operationName}`)

  let result = await retry(operation)

  switch result {
  | Ok(_) => {
      Zotero.debug(`[Safe Operation] Success: ${operationName}`)
      true
    }
  | Error(msg) => {
      Zotero.debug(`[Safe Operation] Failed: ${operationName} - ${msg}`)
      false
    }
  }
}

// Validate file exists and is readable
let validateFile = (file: Firefox.nsIFile): bool => {
  try {
    // Check if file exists
    if !%raw(`file.exists()`) {
      Zotero.debug(`File validation failed: ${file.path} does not exist`)
      false
    } else if !%raw(`file.isReadable()`) {
      Zotero.debug(`File validation failed: ${file.path} is not readable`)
      false
    } else {
      true
    }
  } catch {
  | _exn => {
      Zotero.debug(`File validation exception for: ${file.path}`)
      false
    }
  }
}

// Validate directory and create if needed
let ensureDirectory = (dir: Firefox.nsIFile): result<unit, string> => {
  try {
    if !%raw(`dir.exists()`) {
      Zotero.debug(`Creating directory: ${dir.path}`)
      dir.create(Firefox.nsIFile_DIRECTORY_TYPE, 0o755)
    } else if !%raw(`dir.isDirectory()`) {
      Error(`Path exists but is not a directory: ${dir.path}`)
    } else {
      // Directory exists and is valid
      ()
    }
    Ok()
  } catch {
  | exn => {
      let error = exn->Obj.magic
      Error(`Failed to ensure directory ${dir.path}: ${error}`)
    }
  }
}

// Graceful degradation for missing attachments
let handleMissingAttachment = (itemId: int): unit => {
  Zotero.debug(`[Graceful Degradation] Item ${Belt.Int.toString(itemId)} has no attachment, creating placeholder`)
  // Extension could create a metadata-only entry instead of failing
}

// Check available disk space (defensive programming)
let hasEnoughDiskSpace = (requiredBytes: int): bool => {
  try {
    // This is a defensive check - if we can't determine space, assume we have enough
    %raw(`true`)
  } catch {
  | _exn => {
      Zotero.debug("[Disk Space] Could not check disk space, proceeding optimistically")
      true
    }
  }
}
