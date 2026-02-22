<!-- SPDX-License-Identifier: PMPL-1.0-or-later -->
<!-- TOPOLOGY.md — Project architecture map and completion dashboard -->
<!-- Last updated: 2026-02-19 -->

# Zotero Tools (zotero-tools) — Project Topology

## System Architecture

```
                        ┌─────────────────────────────────────────┐
                        │              RESEARCHER / USER          │
                        │        (Zotero App / WordPress HUD)     │
                        └───────────────────┬─────────────────────┘
                                            │ API / Event
                                            ▼
                        ┌─────────────────────────────────────────┐
                        │           ZOTERO TOOLING HUB            │
                        │                                         │
                        │  ┌───────────┐  ┌───────────────────┐  │
                        │  │ zoterho/  │  │  librarian/       │  │
                        │  │ (Core)    │  │  (Auto-mgmt)      │  │
                        │  └─────┬─────┘  └────────┬──────────┘  │
                        │        │                 │              │
                        │  ┌─────▼─────┐  ┌────────▼──────────┐  │
                        │  │ formbd/   │  │  nesy/            │  │
                        │  │ (Forms)   │  │  (Neurosymbolic)  │  │
                        │  └─────┬─────┘  └────────┬──────────┘  │
                        └────────│─────────────────│──────────────┘
                                 │                 │
                                 ▼                 ▼
                        ┌─────────────────────────────────────────┐
                        │           EXTERNAL INTERFACES           │
                        │  ┌───────────┐  ┌───────────────────┐  │
                        │  │ voyant-   │  │  zotpress/        │  │
                        │  │ export/   │  │  (WordPress)      │  │
                        │  └───────────┘  └───────────────────┘  │
                        └─────────────────────────────────────────┘

                        ┌─────────────────────────────────────────┐
                        │          REPO INFRASTRUCTURE            │
                        │  Justfile Automation  .machine_readable/  │
                        │  ReScript Templater   0-AI-MANIFEST.a2ml  │
                        └─────────────────────────────────────────┘
```

## Completion Dashboard

```
COMPONENT                          STATUS              NOTES
─────────────────────────────────  ──────────────────  ─────────────────────────────────
CORE TOOLING
  zoterho (Core Integration)        ████████░░  80%    API bindings stable
  librarian (Auto-mgmt)             ██████░░░░  60%    Library rules active
  formbd (Data Entry)               ████░░░░░░  40%    Initial form stubs
  rescript-templater                ██████████ 100%    Template engine stable

INTEGRATIONS
  voyant-export                     ██████████ 100%    Text analysis bridge active
  zotpress (WordPress)              ████████░░  80%    Sync logic verified
  nesy (Neurosymbolic)              ████░░░░░░  40%    Initial semantic stubs
  safe-storage                      ██████░░░░  60%    Encrypted store active

REPO INFRASTRUCTURE
  Justfile Automation               ██████████ 100%    Standard tasks active
  .machine_readable/                ██████████ 100%    STATE tracking active
  0-AI-MANIFEST.a2ml                ██████████ 100%    AI entry point verified

─────────────────────────────────────────────────────────────────────────────
OVERALL:                            ███████░░░  ~70%   Stable toolset, Integrations maturing
```

## Key Dependencies

```
Zotero API ──────► zoterho Core ───────► librarian / formbd ──► Library
     │                 │                   │                    │
     ▼                 ▼                   ▼                    ▼
Voyant Export ◄──► Templater ───────► zotpress ──────────► WordPress
```

## Update Protocol

This file is maintained by both humans and AI agents. When updating:

1. **After completing a component**: Change its bar and percentage
2. **After adding a component**: Add a new row in the appropriate section
3. **After architectural changes**: Update the ASCII diagram
4. **Date**: Update the `Last updated` comment at the top of this file

Progress bars use: `█` (filled) and `░` (empty), 10 characters wide.
Percentages: 0%, 10%, 20%, ... 100% (in 10% increments).
