# WinPE Builder - Usage Guide

Guide for common and advanced workflows.  
**Script:** `WinPE-Builder.ps1`  
**Needs:** Windows ADK + WinPE add-on, **Administrator** PowerShell

For the shortest recipes, see **[COMMON-USES.md](COMMON-USES.md)**.

---

## Table of contents

1. [Quick start](#1-quick-start)
2. [Project folders](#2-project-folders)
3. [Commands reference](#3-commands-reference)
4. [Use case: first-time project](#4-use-case-first-time-project)
5. [Use case: add drivers, scripts, updates](#5-use-case-add-drivers-scripts-updates)
6. [Use case: inspect the image (-Mount)](#6-use-case-inspect-the-image--mount)
7. [Use case: full build + ISO](#7-use-case-full-build--iso)
8. [Use case: bootable USB](#8-use-case-bootable-usb)
9. [Use case: custom boot.wim](#9-use-case-custom-bootwim)
10. [Use case: custom background](#10-use-case-custom-background)
11. [Use case: only some packages](#11-use-case-only-some-packages)
12. [Use case: PCA2023 / modern Secure Boot](#12-use-case-pca2023--modern-secure-boot)
13. [Use case: recover from a bad mount](#13-use-case-recover-from-a-bad-mount)
14. [Rules and tips](#14-rules-and-tips)

---

## 1. Quick start

```powershell
# Always run PowerShell as Administrator
cd <path-to>\WinPE-Builder2.0

# 1) Create folders + WinPE tree
.\WinPE-Builder.ps1 -Init -WorkDirectory C:\WinPE-Projects\MyPE

# 2) Put your files in Add-Drivers, Add-Scripts, Add-Updates

# 3) Build ISO
.\WinPE-Builder.ps1 -Build -ISO -Force -WorkDirectory C:\WinPE-Projects\MyPE
```

ISO output:

```text
C:\WinPE-Projects\MyPE\WinPE-ISO\WinPE_amd64_yyyyMMdd_HHmm.iso
```

---

## 2. Project folders

Created by **`-Init`** (under `-WorkDirectory`):

| Folder | What to put there | When applied |
|--------|-------------------|--------------|
| `Add-Drivers\` | Driver packages (`.inf` + files), any subfolders | `-Build` (`Add-WindowsDriver -Recurse`) |
| `Add-Scripts\` | `startnet.cmd`, `winpe.jpg`, `unattend.xml`, tools | `-Build` |
| `Add-Scripts\System32\` | Files -> mounted `Windows\System32` | `-Build` |
| `Add-Scripts\Root\` | Files -> image root (`X:\`) | `-Build` |
| `Add-Scripts\Media\` | Files -> `WinPE-Root\media` | `-Build` |
| `Add-Updates\` | Windows updates (`.msu`, `.cab`) | `-Build` |
| `WinPE-Root\` | Working tree from `copype` (auto) | - |
| `WinPE-ISO\` | Generated ISO files | `-Build -ISO` |
| `Logs\` | Build logs | always |

---

## 3. Commands reference

### Main actions

| Command | Does |
|---------|------|
| `-Init` | Create folders + run `copype`. **Does not leave the image mounted.** |
| `-Mount` | Mount `boot.wim` ReadWrite only |
| `-Build` | Inject packages, drivers, scripts, updates |
| `-Save` | Unmount and **commit** changes |
| `-Discard` | Unmount and **drop** changes |
| `-Clean` | Clear project mounts (`-Force` = global DISM cleanup) |

### Media (use with `-Build`)

| Command | Does |
|---------|------|
| `-ISO` | Create ISO after build (commits first) |
| `-USB F:` | Create bootable USB (**requires `-Force`**, formats the drive) |

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `-WorkDirectory` | Project root | Script folder |
| `-Architecture` | `amd64`, `x86`, `arm64` | `amd64` |
| `-ScratchSpace` | 32 / 64 / 128 / 256 / 512 | `256` |
| `-Language` | OC language pack code | `en-us` |
| `-AddPackage` | One or more optional component names | default set |
| `-NoDefaultPackages` | Skip default package list | off |
| `-BootWimPath` | Custom `boot.wim` on `-Init` | ADK default |
| `-PCA2023` | UEFI CA 2023 boot (`/bootex`) | off |
| `-Force` | Overwrite ISO / format USB / global clean | off |

---

## 4. Use case: first-time project

**Goal:** Create a clean project and WinPE working tree.

```powershell
.\WinPE-Builder.ps1 -Init -WorkDirectory C:\WinPE-Projects\MyPE
```

**What happens:**

1. Creates `Add-Drivers`, `Add-Scripts`, `Add-Updates`, `WinPE-ISO`, `Logs`
2. Runs Microsoft `copype` -> `WinPE-Root`
3. Leaves the image **unmounted**
4. Prints where to add drivers, scripts, and updates

**Note:** You may see `Mounting` / `Unmounting` during `copype`. That is normal ADK staging, not `-Mount`.

---

## 5. Use case: add drivers, scripts, updates

**Goal:** Customize content before building.

```powershell
# After -Init
Copy-Item -Path D:\MyDrivers\* -Destination C:\WinPE-Projects\MyPE\Add-Drivers -Recurse
Copy-Item D:\MyTools\startnet.cmd C:\WinPE-Projects\MyPE\Add-Scripts\startnet.cmd

New-Item C:\WinPE-Projects\MyPE\Add-Scripts\System32 -ItemType Directory -Force
Copy-Item D:\MyTools\*.exe C:\WinPE-Projects\MyPE\Add-Scripts\System32\

Copy-Item D:\Updates\*.msu C:\WinPE-Projects\MyPE\Add-Updates\

.\WinPE-Builder.ps1 -Build -ISO -Force -WorkDirectory C:\WinPE-Projects\MyPE
```

**`startnet.cmd` tip:** keep `wpeinit`:

```cmd
@echo off
wpeinit
REM your commands here
```

---

## 6. Use case: inspect the image (-Mount)

```powershell
.\WinPE-Builder.ps1 -Mount -WorkDirectory C:\WinPE-Projects\MyPE

# Explore:
#   C:\WinPE-Projects\MyPE\WinPE-Root\mount
#   C:\WinPE-Projects\MyPE\WinPE-Root\mount\Windows\System32

.\WinPE-Builder.ps1 -Save -WorkDirectory C:\WinPE-Projects\MyPE
# or
.\WinPE-Builder.ps1 -Discard -WorkDirectory C:\WinPE-Projects\MyPE
```

| After mount | Command |
|-------------|---------|
| Keep edits | `-Save` |
| Drop edits | `-Discard` |

---

## 7. Use case: full build + ISO

```powershell
.\WinPE-Builder.ps1 -Init -WorkDirectory C:\WinPE-Projects\MyPE
# add files to Add-* folders
.\WinPE-Builder.ps1 -Build -ISO -Force -WorkDirectory C:\WinPE-Projects\MyPE
```

**What `-Build -ISO` does:**

1. Mounts `boot.wim`
2. Sets scratch space
3. Adds optional packages
4. Injects drivers from `Add-Drivers` (recursive)
5. Copies scripts from `Add-Scripts`
6. Applies updates from `Add-Updates`
7. Commits the image
8. Creates ISO under `WinPE-ISO\`

---

## 8. Use case: bootable USB

```powershell
# WARNING: formats the target partition
.\WinPE-Builder.ps1 -Build -USB F: -Force -WorkDirectory C:\WinPE-Projects\MyPE
```

Safety checks refuse system drive, boot/system disks, and non-USB bus types. Requires `-Force`.

```powershell
.\WinPE-Builder.ps1 -Build -ISO -USB F: -Force -WorkDirectory C:\WinPE-Projects\MyPE
```

---

## 9. Use case: custom boot.wim

```powershell
.\WinPE-Builder.ps1 -Init -WorkDirectory C:\WinPE-Projects\MyPE -BootWimPath D:\Images\my-boot.wim
.\WinPE-Builder.ps1 -Build -ISO -Force -WorkDirectory C:\WinPE-Projects\MyPE
```

---

## 10. Use case: custom background

1. Save image as `Add-Scripts\winpe.jpg` (about 800x600)
2. Run build:

```powershell
.\WinPE-Builder.ps1 -Build -ISO -Force -WorkDirectory C:\WinPE-Projects\MyPE
```

The script takes ownership of the protected `winpe.jpg` in the image, then replaces it.

---

## 11. Use case: only some packages

```powershell
.\WinPE-Builder.ps1 -Build -ISO -Force -WorkDirectory C:\WinPE-Projects\MyPE `
  -NoDefaultPackages `
  -AddPackage WinPE-WMI,WinPE-PowerShell,WinPE-Scripting
```

When `-AddPackage` is used, that list is what gets installed (use `-NoDefaultPackages` for a minimal explicit set).

---

## 12. Use case: PCA2023 / modern Secure Boot

```powershell
.\WinPE-Builder.ps1 -Build -ISO -PCA2023 -Force -WorkDirectory C:\WinPE-Projects\MyPE
.\WinPE-Builder.ps1 -Build -USB F: -PCA2023 -Force -WorkDirectory C:\WinPE-Projects\MyPE
```

Requires a recent ADK with MakeWinPEMedia `/bootex`.

---

## 13. Use case: recover from a bad mount

```powershell
.\WinPE-Builder.ps1 -Discard -WorkDirectory C:\WinPE-Projects\MyPE
.\WinPE-Builder.ps1 -Clean -Force -WorkDirectory C:\WinPE-Projects\MyPE
```

---

## 14. Rules and tips

**Do**

- Run as Administrator
- Use the same `-WorkDirectory` for the whole project
- Add content to `Add-*` before `-Build`
- Use `-Force` for USB

**Don't**

- Mix `-Discard` with `-Init` / `-Build` / `-Save`
- Mix `-Save` with `-ISO` / `-USB`
- Use `-ISO` or `-USB` without `-Build`
- Use `-USB` without `-Force`

**Logs**

```text
<WorkDirectory>\Logs\WinPEBuilder_yyyyMMdd_HHmmss.log
```

**Automation**

```powershell
$result = .\WinPE-Builder.ps1 -Build -ISO -Force -WorkDirectory C:\WinPE-Projects\MyPE
if ($result.Success) { $result.ISOPath }
```

---

## Cheat sheet

```powershell
.\WinPE-Builder.ps1 -Init -WorkDirectory C:\WinPE-Projects\MyPE
.\WinPE-Builder.ps1 -Mount -WorkDirectory C:\WinPE-Projects\MyPE
.\WinPE-Builder.ps1 -Save  -WorkDirectory C:\WinPE-Projects\MyPE
.\WinPE-Builder.ps1 -Build -ISO -Force -WorkDirectory C:\WinPE-Projects\MyPE
.\WinPE-Builder.ps1 -Build -USB F: -Force -WorkDirectory C:\WinPE-Projects\MyPE
.\WinPE-Builder.ps1 -Init -BootWimPath D:\custom\boot.wim -WorkDirectory C:\WinPE-Projects\MyPE
.\WinPE-Builder.ps1 -Discard -WorkDirectory C:\WinPE-Projects\MyPE
```
