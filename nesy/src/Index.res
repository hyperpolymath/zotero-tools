/**
 * NSAI — Neuro-Symbolic AI Data Orchestrator (ReScript).
 *
 * This module is the primary interface for the NSAI toolset. It provides 
 * high-assurance validation and preparation pipelines for Zotero 
 * research data, bridging linguistic models with symbolic logic.
 *
 * KEY EXPORTS:
 * - `Atomic`: Minimal unit operations for bibliographic records.
 * - `Validator`: Deterministic schema and logic-rule enforcement.
 */

// EXPORT MAP: Provides a unified namespace for consumers.
module Atomic = Atomic
module Validator = Validator

// CONVENIENCE: Direct access to primary validation logic.
let validate = Validator.validate
let validateBatch = Validator.validateBatch
