<!--
SPDX-License-Identifier: MPL-2.0
Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->
# Changelog

All notable changes to `zotero-tools` will be documented in this file.

This file is generated from conventional commits by the
[`changelog-reusable.yml`](https://github.com/hyperpolymath/standards/blob/main/.github/workflows/changelog-reusable.yml)
workflow (`hyperpolymath/standards#206`). Adopt the workflow in this repo's CI to keep this file in sync automatically — see
[`templates/cliff.toml`](https://github.com/hyperpolymath/standards/blob/main/templates/cliff.toml)
for the canonical config.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
this project aims to follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- feat(crg): add crg-grade and crg-badge justfile recipes
- feat: add stapeln.toml container definition
- feat: add UX Justfile with doctor, tour, help-me, assail recipes
- feat: deploy UX Manifesto infrastructure
- feat: Zotero 8 compatibility, ReScript 12 migration, orphan adoption
- feat: add CLADE.a2ml — clade taxonomy declaration
- feat: add mirror.yml workflow for GitLab/Bitbucket mirroring
- feat: consolidate 9 Zotero repos into zotero-tools monorepo

### Fixed

- fix(ci): sync hypatia-scan.yml to canonical (413: env.HOME+Phase-2+SARIF) (#13)
- fix(ci): build Hypatia escript from repo root (estate dogfood drift)
- fix(ci): build Hypatia escript from repo root (estate dogfood drift)
- fix(ci): rsr-antipattern.yml duplicate heredoc (#8)
- fix(ci): repair YAML block-scalar in workflow-linter Check Permissions step (#9)
- fix(ci): move secret-scanner Cargo.toml gate from job-level if: to step-level (#10)
- fix(lithoglyph): replace sorry with fuel-based WF induction proof
- fix(scorecard): enforce granular permissions and add fuzzing placeholder
- fix(ci): Resolve workflow-linter self-matching and metadata issues
- fix: correct email jonathan.jewell → j.d.a.jewell

### Changed

- refactor: migrate 6SCM → 6A2 (.scm → .a2ml format)
- refactor: convert vite/vitest configs from .ts to .js (language policy)

### Documentation

- docs: record tech-debt audit findings (2026-05-26) (#17)
- docs: add TEST-NEEDS.md (CRG C)
- docs: add EXPLAINME.adoc — prove-it file backing README claims
- docs: add 0-AI-MANIFEST.a2ml (RSR compliance)

### CI

- ci: fix nonexistent actions/upload-artifact SHA pin (#12)
- ci(secret-scanner): drop duplicate --fail from trufflehog extra_args (#7)
- ci(antipattern): fix top-level dir matching + benchmarks/lsp/bench filename allowlists (#6)
- ci(antipattern): TS check reads .claude/CLAUDE.md exemption table (#5)
- ci(antipattern): broaden TS allowlist (cli/, mod.ts, lsp-server, *vscode*, deno-*) (#4)

## Pre-history

Prior commits to this file's introduction are recorded in git history but not formally classified into Keep-a-Changelog sections. To backfill, run `git cliff -o CHANGELOG.md` locally using the canonical [`cliff.toml`](https://github.com/hyperpolymath/standards/blob/main/templates/cliff.toml) — this is one-shot mechanical work.

---

<!-- This file was seeded by the 2026-05-26 estate tech-debt audit follow-up (Row-2 Phase 3); see [`hyperpolymath/standards/docs/audits/2026-05-26-estate-documentation-debt.md`](https://github.com/hyperpolymath/standards/blob/main/docs/audits/2026-05-26-estate-documentation-debt.md). -->
