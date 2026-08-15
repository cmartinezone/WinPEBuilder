# WinPE Builder — Improvement backlog

Prioritized ideas from a review of the 2.0 tree (`WinPE-Builder.ps1`, docs, repo hygiene).  
Use this as a living backlog; check items off as they land.

---

## P0 — High impact / low friction

| # | Idea | Why |
|---|------|-----|
| 1 | **Auto-load `packages.pe` on `-Build`** | Today every recipe requires `-AddPackage packages.pe`. If the file exists in the project root, use it by default (keep `-NoDefaultPackages` / explicit `-AddPackage` overrides). Matches what docs imply for a “project-based” workflow. |
| 2 | **Warn if `startnet.cmd` lacks `wpeinit`** | Docs say keep `wpeinit`; a build-time check prevents silent non-bootable images. |
| 3 | **Softer failures for drivers / updates** | Optional packages already skip + warn; a single bad INF or `.msu` currently stops the whole build. Offer continue-on-error (or per-item skip with summary), consistent with package handling. |
| 4 | **Add a `LICENSE`** | GitHub reports `license: null`. Clarifies reuse for forks and enterprise adoption. |
| 5 | **`CHANGELOG.md`** | Track 2.0 → next releases; link from README / GitHub Releases. |

---

## P1 — UX & safety

| # | Idea | Why |
|---|------|-----|
| 6 | **Interactive USB confirmation** | `-Force` is required but still easy to mistype a letter. Prompt with disk #, size, bus, volume label before format (skip prompt under `-Quiet`). |
| 7 | **Persistent project config** | Work directory is session-only (`$global:WinPEBuilderWorkDirectory`). A small `winpe-builder.json` / `.winpeproject` could store arch, language, timezone, PCA preference, last ISO path. |
| 8 | **`-WhatIf` / dry-run** | Print resolved paths, package list, driver count, update list, and media target without mounting or formatting. |
| 9 | **Post-build summary file** | Write `WinPE-Logs\last-build.json` (packages, drivers, updates, ISO path, duration, ADK paths) for automation and support. |
| 10 | **Validate wallpaper size** | Recommend 800×600; warn if `winpe.jpg` is missing or unusual dimensions. |
| 11 | **Architecture guidance** | Newer ADKs drop or de-emphasize `x86`. Detect missing OC root and fail with a clear “install WinPE add-on for this arch / use amd64” message (partially present — tighten messaging). |

---

## P2 — Code quality & structure

| # | Idea | Why |
|---|------|-----|
| 12 | **Split the monolith** | `WinPE-Builder.ps1` is ~1300 lines. `.gitignore` already reserves `Core/` and `UI/` — extract ADK helpers, project layout, build steps into a module; keep a thin CLI entry script. |
| 13 | **Ship / revive a GUI** | `-Quiet` / WPF comments suggest a host UI. Either publish a minimal GUI or remove dead references to avoid confusion. |
| 14 | **PSScriptAnalyzer + smoke tests** | `Tests/` is ignored today. Add analyzer CI and mocked unit tests for path resolution, `packages.pe` parsing, USB safety gates (no real DISM required). |
| 15 | **Typed result object** | `New-BuildResult` is useful; document properties for hosts and return consistent exit codes (`$LASTEXITCODE` / `exit 1` on failure) for CI wrappers. |
| 16 | **Idempotent rebuild helpers** | `-Init` wipes `WinPE-Root`. Add something like `-ResetMedia` (copype only) vs full init, or document a safe “rebuild from scratch” recipe more loudly in the banner. |

---

## P3 — Features

| # | Idea | Why |
|---|------|-----|
| 17 | **Named build profiles** | e.g. `profiles\recovery.pe` / `deploy.pe` with package lists + optional script sets. |
| 18 | **Driver catalog / inventory** | Before inject, list INF Provider/Class/Version; optionally refuse unsigned drivers. |
| 19 | **Network / Wi‑Fi recipe** | Documented sample for RNDIS / Dot3Svc / common NIC packs under `COMMON-USES`. |
| 20 | **BitLocker unlock starter** | SecureStartup is default; ship a sample `startnet` snippet + doc for unlock workflow. |
| 21 | **arm64 first-class docs** | Parameter exists; add a short arm64 ADK + Secure Boot note in SIMPLE-GUIDE. |
| 22 | **Optional image optimization** | Export/replace `boot.wim` compression, report size before/after updates cleanup. |
| 23 | **Multi-index `boot.wim` support** | If custom WIM has multiple indexes, allow `-ImageIndex`. |

---

## P4 — Repo & community

| # | Idea | Why |
|---|------|-----|
| 24 | **GitHub Actions** | Lint markdown / PowerShell on PR; no Windows ADK needed for static checks. |
| 25 | **Issue / PR templates** | Bug report: ADK version, arch, log snippet, command line. |
| 26 | **`CONTRIBUTING.md`** | Branch naming, how to test without leaking local `WinPE-Root` artifacts. |
| 27 | **Pin ADK version matrix** | Table of tested ADK + WinPE add-on builds (incl. PCA2023 /bootex requirement). |
| 28 | **Topics / description** | Already good; add license + funding via GitHub standard files if desired. |
| 29 | **Legacy bridge** | Short doc: migrating a v1.1 batch project to 2.0 folders / `packages.pe`. |

---

## Known pain (from history)

- Closed issue: **`-Language` requires matching language pack in the ADK WinPE OCs** (and base `lp.cab` for non-`en-us`). Docs cover this; a preflight that lists available `WinPE_OCs\<lang>` folders would make failures friendlier.

---

## Suggested first slice

If picking one implementation pass:

1. Auto-apply project `packages.pe` on `-Build` when present.  
2. `startnet.cmd` / `wpeinit` warning.  
3. Continue-on-error option for drivers and updates.  
4. `LICENSE` + `CHANGELOG.md`.

That improves the daily CLI loop without a large refactor.
