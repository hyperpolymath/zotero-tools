/**
 * @file RhodiumLinter.res
 * @description Rhodium Standard code linter integration.
 * Provides linting capabilities for ReScript code following the Rhodium Standard.
 * SPDX-License-Identifier: MIT OR Apache-2.0
 * SPDX-FileCopyrightText: 2025 Jonathan D.A. Jewell
 */

// --- External Bindings ---

@module("zotero") @val
external zotero: {
  "debug": string => unit,
} = "Zotero"

// --- Types ---

type severity = Error | Warning | Info

type lintResult = {
  file: string,
  line: int,
  column: int,
  severity: severity,
  message: string,
  rule: string,
}

type linterConfig = {
  strictMode: bool,
  enabledRules: array<string>,
  ignorePaths: array<string>,
}

// --- Logging ---

let log = (msg: string): unit => {
  zotero["debug"](`Rhodium Linter: ${msg}`)
}

// --- Default Configuration ---

let defaultConfig: linterConfig = {
  strictMode: false,
  enabledRules: [
    "no-typescript",
    "no-makefile",
    "deno-only",
    "https-only",
    "no-hardcoded-secrets",
    "spdx-headers",
  ],
  ignorePaths: [
    "node_modules",
    ".git",
    "build",
    "lib",
  ],
}

// --- Rule Definitions ---

module Rules = {
  let noTypeScript = "no-typescript"
  let noMakefile = "no-makefile"
  let denoOnly = "deno-only"
  let httpsOnly = "https-only"
  let noHardcodedSecrets = "no-hardcoded-secrets"
  let spdxHeaders = "spdx-headers"
  let sha256Required = "sha256-required"
}

// --- Linter State ---

let mutable config: linterConfig = defaultConfig
let mutable results: array<lintResult> = []

// --- Configuration ---

let setConfig = (newConfig: linterConfig): unit => {
  config = newConfig
  log("Configuration updated")
}

let getConfig = (): linterConfig => {
  config
}

let setStrictMode = (enabled: bool): unit => {
  config = {...config, strictMode: enabled}
  log(`Strict mode: ${enabled ? "enabled" : "disabled"}`)
}

// --- Result Management ---

let clearResults = (): unit => {
  results = []
}

let getResults = (): array<lintResult> => {
  results
}

let addResult = (result: lintResult): unit => {
  results = Js.Array2.concat(results, [result])
}

// --- Severity Helpers ---

let severityToString = (s: severity): string => {
  switch s {
  | Error => "error"
  | Warning => "warning"
  | Info => "info"
  }
}

let severityFromString = (s: string): severity => {
  switch s {
  | "error" => Error
  | "warning" => Warning
  | _ => Info
  }
}

// --- Linting Functions (Stubs) ---

// These are placeholder implementations.
// In a full implementation, these would analyze actual file contents.

let lintFile = (_path: string): array<lintResult> => {
  log("Linting file (stub implementation)")
  []
}

let lintDirectory = (_path: string): array<lintResult> => {
  log("Linting directory (stub implementation)")
  []
}

let lintProject = (): array<lintResult> => {
  log("Linting project (stub implementation)")
  clearResults()
  // In a full implementation:
  // - Scan for .ts/.tsx files (should be 0)
  // - Check for Makefiles (should be 0)
  // - Verify package manager usage (Deno only)
  // - Check for HTTP URLs
  // - Verify SPDX headers
  results
}

// --- Validation Helpers ---

let isTypeScriptFile = (path: string): bool => {
  Js.String2.endsWith(path, ".ts") || Js.String2.endsWith(path, ".tsx")
}

let isMakefile = (path: string): bool => {
  let name = Js.String2.toLowerCase(path)
  name == "makefile" || name == "gnumakefile" || Js.String2.endsWith(name, ".mk")
}

let hasHttpUrl = (content: string): bool => {
  // Simple check - real implementation would use regex
  Js.String2.includes(content, "http://") &&
    !Js.String2.includes(content, "http://localhost") &&
    !Js.String2.includes(content, "http://127.0.0.1")
}

let hasSpdxHeader = (content: string): bool => {
  Js.String2.includes(content, "SPDX-License-Identifier")
}

// --- Exports for JavaScript interop ---

let rhodiumLinter = {
  "setConfig": setConfig,
  "getConfig": getConfig,
  "setStrictMode": setStrictMode,
  "clearResults": clearResults,
  "getResults": getResults,
  "lintFile": lintFile,
  "lintDirectory": lintDirectory,
  "lintProject": lintProject,
  "isTypeScriptFile": isTypeScriptFile,
  "isMakefile": isMakefile,
  "hasHttpUrl": hasHttpUrl,
  "hasSpdxHeader": hasSpdxHeader,
}
