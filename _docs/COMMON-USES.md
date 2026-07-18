<p align="center">
  <img src="assets/logo.jpg" alt="WinPE Builder logo" width="180" />
</p>

# WinPE Builder 2.0 — Common Uses

> **Short recipes only.**  
> First project walkthrough → [SIMPLE-GUIDE.md](SIMPLE-GUIDE.md) · All options → [USAGE.md](USAGE.md) · Overview → [README](../README.md)

Run **PowerShell as Administrator**. After `-Init -WorkDirectory ...`, the same window usually needs no path again.

---

## Index

| I want to… | Jump |
|------------|------|
| [Add drivers and rebuild](#1-add-drivers-and-rebuild) | |
| [Change startnet or wallpaper](#2-change-startnet-or-wallpaper) | |
| [Edit packages (packages.pe)](#3-edit-packages-packagespe) | |
| [Mount / Save / Discard](#4-mount--save--discard) | |
| [Make a USB stick](#5-make-a-usb-stick) | |
| [Use my own boot.wim](#6-use-my-own-bootwim) | |
| [Fix a stuck mount](#7-fix-a-stuck-mount) | |
| [Language / time zone / one-off packages](#8-language--time-zone--one-off-packages) | |
| [PCA2023 media](#9-pca2023-media) | |
| [Resume an existing project](#10-resume-an-existing-project) | |

---

## 1. Add drivers and rebuild

Copy **your** drivers into `Add-Drivers` (folders with `.inf` files), then:

```powershell
.\WinPE-Builder.ps1 -Build -ISO -Force -AddPackage packages.pe
```

Prefer packages with `.inf` + `.cat` + `.sys` (not setup.exe alone).

---

## 2. Change startnet or wallpaper

| File | Notes |
|------|--------|
| `Add-Scripts\startnet.cmd` | Keep `wpeinit` |
| `Add-Scripts\winpe.jpg` | About 800×600 — copy **your** wallpaper here |

```powershell
.\WinPE-Builder.ps1 -Build -ISO -Force -AddPackage packages.pe
```

---

## 3. Edit packages (`packages.pe`)

Created on `-Init`. Uncomment optional OCs; comment out defaults you do not want.

Open `packages.pe` in any text editor, then:

```powershell
.\WinPE-Builder.ps1 -Build -ISO -Force -AddPackage packages.pe
```

| Tip | Detail |
|-----|--------|
| File is the set | When you pass `packages.pe`, only **uncommented** lines install (built-in defaults are not re-merged) |
| Missing cab | Logged as a warning; build continues |

Full rules → [USAGE — packages.pe](USAGE.md#packagespe-project-package-list).

---

## 4. Mount / Save / Discard

```powershell
.\WinPE-Builder.ps1 -Mount
# edit ...\WinPE-Root\mount
.\WinPE-Builder.ps1 -Save
# or
.\WinPE-Builder.ps1 -Discard
```

---

## 5. Make a USB stick

> Formats the USB drive.

```powershell
.\WinPE-Builder.ps1 -Build -USB F: -Force -AddPackage packages.pe
.\WinPE-Builder.ps1 -Build -ISO -USB F: -Force -AddPackage packages.pe
```

---

## 6. Use my own boot.wim

**Only with `-Init`.** Replaces the ADK `boot.wim` after copype. Point at **your** WinPE boot.wim:

```powershell
.\WinPE-Builder.ps1 -Init -WorkDirectory . `
  -Architecture amd64 `
  -BootWimPath ".\path\to\your\boot.wim"

.\WinPE-Builder.ps1 -Build -ISO -Force -AddPackage packages.pe
```

- Path must exist; image should be a **WinPE** boot.wim (not `install.wim`).  
- Mount/build use **index 1**.  
- On re-Init, pass `-BootWimPath` again if you still want that base image.  

Details → [USAGE — Custom boot.wim](USAGE.md#custom-bootwim--bootwimpath).

---

## 7. Fix a stuck mount

```powershell
.\WinPE-Builder.ps1 -Discard
.\WinPE-Builder.ps1 -Clean -Force
```

---

## 8. Language / time zone / one-off packages

```powershell
# Built-in defaults + extra OC names (no packages.pe file)
.\WinPE-Builder.ps1 -Build -ISO -Force -AddPackage WinPE-WDS-Tools,WinPE-Dot3Svc

# Locale
.\WinPE-Builder.ps1 -Build -ISO -Force `
  -Language de-de -TimeZone 'W. Europe Standard Time' `
  -AddPackage packages.pe

# Minimal set without built-in defaults
.\WinPE-Builder.ps1 -Build -ISO -Force `
  -NoDefaultPackages -AddPackage WinPE-WMI,WinPE-NetFx,WinPE-Scripting,WinPE-PowerShell
```

Time zone names: `tzutil /l`

---

## 9. PCA2023 media

```powershell
.\WinPE-Builder.ps1 -Build -ISO -PCA2023 -Force -AddPackage packages.pe
.\WinPE-Builder.ps1 -Build -USB F: -PCA2023 -Force -AddPackage packages.pe
```

Default (no switch) = PCA 2011 (max compatibility).  
When to use 2023: [USAGE — Secure Boot](USAGE.md#secure-boot--pca2023).

---

## 10. Resume an existing project

New shell — **do not** `-Init` again:

```powershell
.\WinPE-Builder.ps1 -WorkDirectory C:\MyWinPE-Project
.\WinPE-Builder.ps1 -Build -ISO -Force -AddPackage packages.pe
```

Or from the ZIP extract folder used as the project:

```powershell
cd C:\path\to\extracted\WinPEBuilder
.\WinPE-Builder.ps1 -WorkDirectory .
.\WinPE-Builder.ps1 -Build -ISO -Force -AddPackage packages.pe
```

---

## Command map

| Goal | Run |
|------|-----|
| New project (this folder) | `-Init -WorkDirectory .` |
| New project (custom path) | `-Init -WorkDirectory C:\...` |
| Custom base WIM | `-Init … -BootWimPath ".\path\to\your\boot.wim"` |
| Resume | `-WorkDirectory .` or `-WorkDirectory C:\...` |
| Packages file | Edit `packages.pe` then `-AddPackage packages.pe` |
| Mount / save / drop | `-Mount` · `-Save` · `-Discard` |
| ISO | `-Build -ISO -Force -AddPackage packages.pe` |
| ISO + PCA2023 | `-Build -ISO -PCA2023 -Force -AddPackage packages.pe` |
| USB | `-Build -USB X: -Force -AddPackage packages.pe` |
| Stuck | `-Discard` or `-Clean -Force` |
