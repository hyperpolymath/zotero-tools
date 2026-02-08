// Exporter module - Handle collection export to Voyant format

// Get temporary directory using FileUtils with error recovery
let getTmpDir = (): result<Firefox.nsIFile, string> => {
  try {
    let fileUtils = Firefox.FileUtils.get()
    let tmpDir = fileUtils->Firefox.FileUtils.getFile("TmpD", ["collection"])
    tmpDir.createUnique(Firefox.nsIFile_DIRECTORY_TYPE, 0o755)
    Ok(tmpDir)
  } catch {
  | exn => {
      let error = exn->Obj.magic
      Error(`Failed to create temporary directory: ${error}`)
    }
  }
}

// Create subdirectory with validation
let mkdir = (startDir: Firefox.nsIFile, dirName: string): result<Firefox.nsIFile, string> => {
  try {
    let newDir = startDir.clone()
    newDir.append(dirName)

    // Use error recovery to ensure directory exists
    switch ErrorRecovery.ensureDirectory(newDir) {
    | Ok(_) => Ok(newDir)
    | Error(msg) => Error(msg)
    }
  } catch {
  | exn => {
      let error = exn->Obj.magic
      Error(`Failed to create directory ${dirName}: ${error}`)
    }
  }
}

// Get file reference in directory
let fileInDir = (startDir: Firefox.nsIFile, fileName: string): Firefox.nsIFile => {
  let newFile = startDir.clone()
  newFile.append(fileName)
  newFile
}

// Copy file to directory with new name - with validation
let copyFileTo = (sourceFile: Firefox.nsIFile, targetDir: Firefox.nsIFile, newName: string): result<unit, string> => {
  try {
    // Validate source file exists and is readable
    if !ErrorRecovery.validateFile(sourceFile) {
      Error(`Source file is not valid or readable: ${sourceFile.path}`)
    } else {
      sourceFile.copyTo(targetDir, newName)
      Ok()
    }
  } catch {
  | exn => {
      let error = exn->Obj.magic
      Error(`Failed to copy file ${sourceFile.path}: ${error}`)
    }
  }
}

// Process a single item with retry logic and error recovery
let processItem = async (item: Zotero.item, dataDir: Firefox.nsIFile): promise<bool> => {
  Zotero.debug(`Processing item ${Belt.Int.toString(item.id)}`)

  let operation = async () => {
    let attResult = await item.getBestAttachment()

    switch attResult->Js.Nullable.toOption {
    | None => {
        ErrorRecovery.handleMissingAttachment(item.id)
        Error("No attachment found")
      }
    | Some(att) => {
        let pathResult = await att.getFilePathAsync()

        switch pathResult->Js.Nullable.toOption {
        | None => {
            Zotero.debug(`No file path for attachment on item ${Belt.Int.toString(item.id)}`)
            Error("No file path")
          }
        | Some(attPath) => {
            let attFile = Zotero.File.pathToFile(attPath)
            let itemID = Belt.Int.toString(item.id)

            Zotero.debug(`Saving item ${itemID}`)

            // Create item directory with validation
            switch mkdir(dataDir, itemID) {
            | Error(msg) => Error(msg)
            | Ok(itemOutDir) => {
                // Generate metadata
                let mods = Format.generateMODS(item)
                let dc = Format.generateDC(item)

                let modsFile = fileInDir(itemOutDir, "MODS.bin")
                let dcFile = fileInDir(itemOutDir, "DC.xml")

                Zotero.File.putContents(modsFile, mods)
                Zotero.File.putContents(dcFile, dc)

                // Copy attachment with validation
                switch copyFileTo(attFile, itemOutDir, "CWRC.bin") {
                | Ok(_) => Ok()
                | Error(msg) => Error(msg)
                }
              }
            }
          }
        }
      }
    }
  }

  // Use error recovery retry logic
  let result = await ErrorRecovery.retry(operation)

  switch result {
  | Ok(_) => {
      Zotero.debug(`Successfully processed item ${Belt.Int.toString(item.id)}`)
      true
    }
  | Error(msg) => {
      Zotero.debug(`Failed to process item ${Belt.Int.toString(item.id)}: ${msg}`)
      false
    }
  }
}

// Export collection to Voyant format with performance tracking and error recovery
let doExport = async (): unit => {
  let startTime = Js.Date.now()
  Zotero.debug("[Voyant Export] Starting export")

  switch Zotero.getZoteroPane() {
  | None => Zotero.debug("[Voyant Export] Could not get Zotero pane")
  | Some(pane) => {
      let collectionResult = pane.getSelectedCollection()

      switch collectionResult->Js.Nullable.toOption {
      | None => Zotero.debug("[Voyant Export] No collection selected")
      | Some(collection) => {
          let name = collection.name
          let items = collection.getChildItems()
          let itemCount = items->Array.length

          Zotero.debug(`[Voyant Export] Collection: ${name}, ${Belt.Int.toString(itemCount)} items`)

          // Performance warning for large collections
          if itemCount > 100 {
            Zotero.debug(`[Voyant Export] Warning: Large collection (${Belt.Int.toString(itemCount)} items) - this may take a while`)
          }

          // Show file picker
          let outFile = UI.showFilePicker(name)

          switch outFile->Js.Nullable.toOption {
          | None => Zotero.debug("[Voyant Export] Export cancelled")
          | Some(file) => {
              // Create temporary directory with error handling
              switch getTmpDir() {
              | Error(msg) => Zotero.debug(`[Voyant Export] Failed to create temp directory: ${msg}`)
              | Ok(outDir) => {
                  Zotero.debug(`[Voyant Export] Using tmp dir: ${outDir.path}`)

                  // Check disk space defensively
                  let estimatedBytes = itemCount * 1024 * 1024 // Rough estimate: 1MB per item
                  if !ErrorRecovery.hasEnoughDiskSpace(estimatedBytes) {
                    Zotero.debug("[Voyant Export] Warning: May not have enough disk space")
                  }

                  // Create bagit.txt
                  let bagitFile = fileInDir(outDir, "bagit.txt")
                  Zotero.File.putContents(bagitFile, "BagIt-Version: 1.0\nTag-File-Character-Encoding: UTF-8\n")

                  // Create data directory with validation
                  switch mkdir(outDir, "data") {
                  | Error(msg) => Zotero.debug(`[Voyant Export] Failed to create data directory: ${msg}`)
                  | Ok(dataDir) => {
                      // Process all items with progress tracking
                      let successCount = ref(0)
                      let failureCount = ref(0)

                      for i in 0 to itemCount - 1 {
                        let success = await processItem(items[i], dataDir)
                        if success {
                          successCount := successCount.contents + 1
                        } else {
                          failureCount := failureCount.contents + 1
                        }

                        // Log progress every 10 items
                        if mod(i + 1, 10) == 0 {
                          Zotero.debug(`[Voyant Export] Progress: ${Belt.Int.toString(i + 1)}/${Belt.Int.toString(itemCount)} items`)
                        }
                      }

                      Zotero.debug(
                        `[Voyant Export] Processing complete: ${Belt.Int.toString(successCount.contents)} succeeded, ${Belt.Int.toString(failureCount.contents)} failed`
                      )

                      // Zip the directory with retry logic
                      let zipOperation = async () => {
                        await Zotero.File.zipDirectory(outDir.path, file.path)
                        Ok()
                      }

                      let zipResult = await ErrorRecovery.retry(zipOperation)

                      switch zipResult {
                      | Ok(_) => {
                          let endTime = Js.Date.now()
                          let duration = (endTime -. startTime) /. 1000.0
                          Zotero.debug(
                            `[Voyant Export] Export complete: ${file.path} (${Belt.Float.toString(duration)}s, ${Belt.Int.toString(successCount.contents)}/${Belt.Int.toString(itemCount)} items)`
                          )
                        }
                      | Error(msg) => Zotero.debug(`[Voyant Export] Failed to create zip file: ${msg}`)
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
