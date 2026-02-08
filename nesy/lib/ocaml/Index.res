/**
 * NSAI: Neurosymbolic validation and preparation for Zotero research data
 *
 * Main entry point
 */

// Re-export types
module Atomic = Atomic
module Validator = Validator

// Convenience exports
let validate = Validator.validate
let validateBatch = Validator.validateBatch
