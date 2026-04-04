# TEST-NEEDS.md — zotero-tools

## CRG Grade: C — ACHIEVED 2026-04-04

## Current Test State

| Category | Count | Notes |
|----------|-------|-------|
| Zig FFI tests | 5 | zoterho, zoterho-template, formbd, librarian, nesy |
| ReScript tests | Present | rescript-templater test framework |
| Shell tests | Present | rescript-templater bash test suite |
| Vitest config | Present | nesy vitest.config.js |

## What's Covered

- [x] Zig FFI integration tests (multiple subprojects)
- [x] ReScript test framework
- [x] Shell-based integration tests
- [x] JavaScript test configuration

## Still Missing (for CRG B+)

- [ ] Zotero API integration tests
- [ ] Bibliography format conversion tests
- [ ] Property-based metadata validation
- [ ] Performance benchmarks
- [ ] End-to-end citation workflow tests

## Run Tests

```bash
cd /var/mnt/eclipse/repos/zotero-tools && npm test
```
