<p align="center">
  <img src="assets/logo.jpg" alt="WinPE Builder logo" width="180" />
</p>

# WinPE Builder 2.0 — Usage Reference

> **Full options and technical detail.**  
> First project → [SIMPLE-GUIDE.md](SIMPLE-GUIDE.md) · Recipes → [COMMON-USES.md](COMMON-USES.md)

| | |
|--|--|
| **Script** | `WinPE-Builder.ps1` |
| **Version** | **2.0** |
| **Needs** | Windows ADK + **WinPE add-on**, PowerShell **as Administrator** |
| **Download** | [ADK + WinPE add-on](https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install) |

---

## Contents

1. [Project folder resolution](#project-folder-resolution)  
2. [Project folders](#project-folders)  
3. [Commands](#commands)  
4. [Options](#options)  
5. [Default packages](#default-packages)  
6. [packages.pe (project package list)](#packagespe-project-package-list)  
7. [Custom boot.wim (`-BootWimPath`)](#custom-bootwim--bootwimpath)  
8. [Build order](#build-order)  
9. [Secure Boot / PCA2023](#secure-boot--pca2023)  
10. [Rules](#rules)  
11. [Automation](#automation)  
12. [Under the hood](#under-the-hood)  
13. [Glossary](#glossary)  
14. [Cheat sheet](#cheat-sheet)

---

## Project folder resolution

Every run picks a project folder in this order:

| # | Source |
|---|--------|
| 1 | `-WorkDirectory` if passed (sets session for this PowerShell window) |
| 2 | Session from a previous command in **this** window |
| 3 | Current directory if it looks like a project |
| 4 | Folder that contains `WinPE-Builder.ps1` |

| Action | Meaning |
|--------|---------|
| `-WorkDirectory` alone | **Resume** existing project for this session (no rebuild) |
| `-Init` | Create or **rebuild** tree (can overwrite `WinPE-Root`) |

No path is written to disk. Closing the shell clears the session.

---

## Project folders

Created under the project by `-Init`:

| Folder / file | Contents | Applied |
|---------------|----------|---------|
| `Add-Drivers\` | Driver packages (`.inf` + files), recursive | `-Build` |
| `Add-Scripts\` | `startnet.cmd`, `winpe.jpg`, `unattend.xml`, tools | `-Build` |
| `Add-Scripts\System32\` | → image `Windows\System32` | `-Build` |
| `Add-Scripts\Root\` | → image root (`X:\`) | `-Build` |
| `Add-Scripts\Media\` | → `WinPE-Root\media` | `-Build` |
| `Add-Updates\` | `.msu`, `.cab` | `-Build` |
| `packages.pe` | Optional-component list (defaults on; uncomment more) | `-Build` when passed via `-AddPackage` (CLI) or auto from UI |
| `WinPE-Root\` | `copype` working tree | Managed |
| `WinPE-ISO\` | Output ISOs | `-Build -ISO` |
| `WinPE-Logs\` | Logs | Every run |

---

## Commands

| Command | Does | Notes |
|---------|------|--------|
| `-Init` | Folders + `copype` | Rebuilds `WinPE-Root`; does **not** leave image mounted |
| `-WorkDirectory path` | Resume project (no other switch) | Validates project layout; no overwrite |
| `-Mount` | Mount `boot.wim` read/write | Manual edit path: `...\mount` |
| `-Save` | Unmount + **commit** | After manual edits |
| `-Discard` | Unmount + **discard** | Bad edits / recovery |
| `-Build` | Packages, locale/TZ, drivers, scripts, updates | Core customize step |
| `-ISO` | Create ISO after build | Requires `-Build` |
| `-USB F:` | Create USB (formats) | Requires `-Build` and `-Force` |
| `-Clean` | Clear mounts | `-Force` = global DISM cleanup |

Incompatible mixes (script will error): `-Discard` with `-Init`/`-Build`/`-Save`; `-Save` with `-ISO`/`-USB`; media without `-Build`.

---

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `-WorkDirectory` | Project root | Session → cwd if project → script folder |
| `-Architecture` | `amd64`, `x86`, `arm64` | `amd64` |
| `-ScratchSpace` | 32 / 64 / 128 / 256 / 512 MB | `256` |
| `-Language` | Package lang cabs + `/Set-AllIntl` | `en-us` |
| `-TimeZone` | `/Set-TimeZone` (`tzutil /l`) | `Eastern Standard Time` |
| `-AddPackage` | Extra OC names and/or a `packages.pe` list file | none |
| `-NoDefaultPackages` | Skip built-in default package list | off |
| `-BootWimPath` | Custom `boot.wim` on `-Init` (alias: `-CustomBootWimPath`) | ADK default |
| `-PCA2023` | Sign boot files with UEFI CA 2023 | off (PCA 2011) |
| `-Force` | Overwrite ISO / format USB / global clean | off |

Language codes must look like `en-us` / `de-de` (pattern `xx-yy`). Time zone IDs must match `tzutil /l` (e.g. `Eastern Standard Time`, `UTC`).

---

## Default packages

Installed on every `-Build` when you **do not** pass a list file, unless `-NoDefaultPackages` (dependency order):

`WinPE-WMI`, `WinPE-NetFx`, `WinPE-Scripting`, `WinPE-PowerShell`, `WinPE-DismCmdlets`, `WinPE-StorageWMI`, `WinPE-SecureBootCmdlets`, `WinPE-HTA`, `WinPE-FMAPI`, `WinPE-SecureStartup`, `WinPE-EnhancedStorage`

Language cabs under `WinPE_OCs\<Language>\` are added when present.

---

## packages.pe (project package list)

### When it is created

`-Init` creates **`<WorkDirectory>\packages.pe`** if the file is **missing**. Re-Init does **not** overwrite an existing file (your edits stay).

Optional package names are scanned from your ADK `WinPE_OCs\*.cab` for the chosen architecture. WinRE-only packages that are not separate ADK cabs (e.g. Rejuv, SRT, WiFi) are **not** listed.

### File layout

```text
# short header + docs link + usage

# Default Components
WinPE-WMI
...

# Optional Components
# WinPE-WDS-Tools
# WinPE-Dot3Svc
...
```

| Line | Meaning |
|------|---------|
| `WinPE-Name` (no `#`) | **Install** this package (order = install order) |
| `# WinPE-Name` | **Skip** (uncomment to enable) |
| `# prose...` | Documentation only |

### How `-AddPackage` works with the file

| You pass | Result |
|----------|--------|
| Nothing | Built-in default list (+ any bare names if you add them) |
| `-AddPackage packages.pe` | **Active lines in the file only** (file is the set; defaults are not re-merged) |
| `-AddPackage packages.pe,WinPE-Dot3Svc` | File actives, then extra name(s) |
| `-AddPackage WinPE-WDS-Tools` | Defaults + that name |
| `-NoDefaultPackages -AddPackage …` | No built-in defaults; only what you pass (names and/or file) |

Bare `packages.pe` resolves under **WorkDirectory** first, then the current location. Full paths work too.

If a cab is **missing** or install **fails**, the engine logs a **warning and continues** with the rest.

```powershell
# Open packages.pe in any text editor, then:
.\WinPE-Builder.ps1 -Build -ISO -Force -AddPackage packages.pe
.\WinPE-Builder.ps1 -Build -ISO -Force -AddPackage packages.pe,WinPE-Dot3Svc
.\WinPE-Builder.ps1 -Build -ISO -Force -AddPackage WinPE-WDS-Tools
```
Microsoft OC reference: [WinPE optional components](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/winpe-add-packages--optional-components-reference).

---

## Custom boot.wim (`-BootWimPath`)

Use **only with `-Init`**. Alias: `-CustomBootWimPath`.

1. Init runs **copype** (standard ADK tree).  
2. If `-BootWimPath` is set, that file is **copied over** `WinPE-Root\media\sources\boot.wim`.  
3. Later `-Build` / `-Mount` use that WIM (index **1**).

```powershell
.\WinPE-Builder.ps1 -Init -WorkDirectory . `
  -Architecture amd64 `
  -BootWimPath ".\path\to\your\boot.wim"

.\WinPE-Builder.ps1 -Build -ISO -Force -AddPackage packages.pe
```

| Rule | Detail |
|------|--------|
| Init only | Passing the path on `-Build` alone does nothing |
| Path must exist | Otherwise: `Custom boot.wim not found` |
| Architecture | Match `-Architecture` to the WIM (usually `amd64`) |
| Image type | Must be a **WinPE** (or similar) boot.wim — not `install.wim` |
| Re-Init | Rebuilds `WinPE-Root`; pass `-BootWimPath` again to re-apply your file |

---

## Build order

When you run `-Build` (with optional `-ISO` / `-USB`):

1. Mount `boot.wim`  
2. Set scratch space  
3. Add optional packages (+ language cabs)  
4. Set locale (`/Set-AllIntl`) and time zone  
5. Inject drivers from `Add-Drivers`  
6. Copy scripts from `Add-Scripts`  
7. Apply updates from `Add-Updates` (then component cleanup if any)  
8. If `-ISO` or `-USB` or `-Save`: commit image  
9. Create ISO and/or USB if requested  

`-Build` alone (no media, no `-Save`) leaves the image **mounted** until you `-Save` or `-Discard`.

---

## Secure Boot / PCA2023

| Mode | Signing | Boots on |
|------|---------|----------|
| Default (no switch) | Windows Production **PCA 2011** | Nearly all Secure Boot PCs today |
| `-PCA2023` | Windows UEFI CA **2023** | Only devices that already trust the 2023 CA |

PCA 2011 certificates **expire October 2026**. Prefer `-PCA2023` only after fleet firmware/DB updates include the 2023 CA; otherwise media may not boot on older machines.

```powershell
.\WinPE-Builder.ps1 -Build -ISO -PCA2023 -Force -AddPackage packages.pe
.\WinPE-Builder.ps1 -Build -USB F: -PCA2023 -Force -AddPackage packages.pe
```

Check a running Windows PC:

```powershell
[System.Text.Encoding]::ASCII.GetString((Get-SecureBootUEFI db).bytes) -match 'Windows UEFI CA 2023'
```

**Requires:** ADK **10.1.26100.2454** (Dec 2024) or later (`MakeWinPEMedia` `/bootex`). The script errors if `/bootex` is missing.

Reference: [KB5062710 — Secure Boot certificate expiration](https://support.microsoft.com/en-us/topic/windows-secure-boot-certificate-expiration-and-ca-updates-7ff40d33-95dc-4c3c-8725-a9b95457578e)

---

## Rules

**Do**

- Run as Administrator  
- `-Init` once per new project; resume with `-WorkDirectory` alone  
- Put **your** content in `Add-Drivers` / `Add-Scripts` / `Add-Updates` before `-Build`  
- Edit `packages.pe` then pass `-AddPackage packages.pe` on Build when using the file  
- Use `-Force` for USB  
- Use `-BootWimPath` only with `-Init`  

**Don’t**

- Re-run `-Init` on a project you want to keep (rebuilds tree; keeps `packages.pe`)  
- Use `-ISO` / `-USB` without `-Build`  
- Use `-USB` without `-Force`  
- Expect a custom boot.wim path on `-Build` alone to do anything  

**Logs:** `<project>\WinPE-Logs\WinPEBuilder_yyyyMMdd_HHmmss.log`

---

## Automation

Capture the result object from the engine (works with or without `-Quiet`):

```powershell
$result = .\WinPE-Builder.ps1 -Build -ISO -Force -WorkDirectory C:\MyWinPE-Project -AddPackage packages.pe
if ($result.Success) {
    $result.ISOPath
    $result.LogPath
    $result.PackagesAdded
    $result.DriversAdded
}
```

Useful properties: `Success`, `Action`, `Version` (`2.0`), `WorkDirectory`, `ISOPath`, `USBDrive`, `PackagesAdded`, `DriversAdded`, `UpdatesAdded`, `IsMounted`, `LogPath`, `Error`.

`-Quiet` / `-NonInteractive` suppresses console UI (log file still written) for host apps.

In CI, pass `-WorkDirectory` every time (no interactive session).

---

## Under the hood

| Task | Engine |
|------|--------|
| Mount / packages / drivers | PowerShell DISM module |
| Base tree / ISO / USB | ADK `copype`, `MakeWinPEMedia` |
| Locale / time zone / scratch | `dism.exe` |
| Session project path | `$global:WinPEBuilderWorkDirectory` (this process only) |

---

## Glossary

| Term | Meaning |
|------|---------|
| WinPE | Small bootable Windows for repair/deployment |
| ADK | Microsoft kit that provides WinPE tools + WinPE add-on OCs |
| Mount | Open image as a folder to edit |
| Commit / Save | Write mount changes into `boot.wim` |
| Discard | Close mount without saving |
| OC / package | Optional WinPE component (`.cab` under `WinPE_OCs`) |
| `packages.pe` | Project file: uncomment OCs to install; pass with `-AddPackage` |
| PCA 2011 / 2023 | Boot-file signing certificate generations |
| Scratch space | Temporary space size inside running PE |

---

## Cheat sheet

```powershell
.\WinPE-Builder.ps1 -Init -WorkDirectory .
.\WinPE-Builder.ps1 -Init -WorkDirectory C:\MyWinPE-Project
.\WinPE-Builder.ps1 -Init -WorkDirectory . -BootWimPath ".\path\to\your\boot.wim"
.\WinPE-Builder.ps1 -WorkDirectory .                           # resume
.\WinPE-Builder.ps1 -Mount
.\WinPE-Builder.ps1 -Save
.\WinPE-Builder.ps1 -Discard
.\WinPE-Builder.ps1 -Build -ISO -Force -AddPackage packages.pe
.\WinPE-Builder.ps1 -Build -ISO -Force                         # built-in defaults only
.\WinPE-Builder.ps1 -Build -ISO -PCA2023 -Force -AddPackage packages.pe
.\WinPE-Builder.ps1 -Build -USB F: -Force -AddPackage packages.pe
.\WinPE-Builder.ps1 -Build -ISO -Force -AddPackage WinPE-WDS-Tools
.\WinPE-Builder.ps1 -Build -ISO -Force -Language de-de -TimeZone 'W. Europe Standard Time'
.\WinPE-Builder.ps1 -Clean -Force
```
