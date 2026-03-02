# URGENT: ReScript Migration Required

**Generated:** 2026-03-02
**Current stable ReScript:** 12.2.0
**Pre-release:** 13.0.0-alpha.2 (2025-02-27)

This repo has ReScript code that needs migration. Address in priority order.

## HIGH: Partial Migration (both bsconfig.json and rescript.json)

These have both config files — migration was started but not completed.

- `fogbinder`

**Action required:**
1. Delete the leftover `bsconfig.json` files
2. Ensure `rescript.json` has all needed config migrated
3. Verify build still works with `rescript.json` only

## LOW: ReScript 12.0.x/12.1.x → 12.2.0

Already on v12 but not latest patch. Minor bump.

- `fogbinder (^12.0.2)`

**Action:** Update `package.json` to `"rescript": "^12.2.0"`

## CHECK: Version Unknown or Unpinned

- `zoterho-template (no version pinned)`
- `nesy (no version pinned)`
- `voyant-export (no version pinned)`
- `zotpress (no version pinned)`

**Action:** Pin to `"rescript": "^12.2.0"` explicitly.

---

## ReScript 13 Preparation (v13.0.0-alpha.2 available)

v13 is in alpha. These breaking changes are CONFIRMED — prepare now:

1. **`bsconfig.json` support removed** — must use `rescript.json` only
2. **`rescript-legacy` command removed** — only modern build system
3. **`bs-dependencies`/`bs-dev-dependencies`/`bsc-flags` config keys removed**
4. **Uncurried `(. args) => ...` syntax removed** — use standard `(args) => ...`
5. **`es6`/`es6-global` module format names removed** — use `esmodule`
6. **`external-stdlib` config option removed**
7. **`--dev`, `--create-sourcedirs`, `build -w` CLI flags removed**
8. **`Int.fromString`/`Float.fromString` API changes** — no explicit radix arg
9. **`js-post-build` behaviour changed** — now passes correct output paths

**Migration path:** Complete all v12 migration FIRST, then test against v13-alpha.
