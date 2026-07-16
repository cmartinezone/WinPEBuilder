# WinPE Builder - Common Uses

Short recipes for the things you will do most often.  
Run **PowerShell as Administrator**.

Replace `C:\WinPE-Projects\MyPE` with your project folder.

---

## 1. Create a new project and build an ISO

```powershell
.\WinPE-Builder.ps1 -Init -WorkDirectory C:\WinPE-Projects\MyPE

# Optional: copy content into the project
#   Add-Drivers\   -> .inf driver packages (subfolders OK)
#   Add-Scripts\   -> startnet.cmd, winpe.jpg, tools
#   Add-Updates\   -> .msu / .cab

.\WinPE-Builder.ps1 -Build -ISO -Force -WorkDirectory C:\WinPE-Projects\MyPE
```

**Result:** ISO under `C:\WinPE-Projects\MyPE\WinPE-ISO\`

---

## 2. Add drivers, then rebuild

```powershell
# Copy drivers into the project
Copy-Item D:\MyDrivers\* C:\WinPE-Projects\MyPE\Add-Drivers -Recurse

.\WinPE-Builder.ps1 -Build -ISO -Force -WorkDirectory C:\WinPE-Projects\MyPE
```

Drivers are injected with `Add-WindowsDriver -Recurse` on **`-Build`**.

---

## 3. Change startup script or background

```powershell
# Startup (keep wpeinit)
# File: C:\WinPE-Projects\MyPE\Add-Scripts\startnet.cmd

# Background (about 800x600)
# File: C:\WinPE-Projects\MyPE\Add-Scripts\winpe.jpg

.\WinPE-Builder.ps1 -Build -ISO -Force -WorkDirectory C:\WinPE-Projects\MyPE
```

---

## 4. Inspect the image before building

```powershell
.\WinPE-Builder.ps1 -Mount -WorkDirectory C:\WinPE-Projects\MyPE

# Browse: C:\WinPE-Projects\MyPE\WinPE-Root\mount

# Keep manual edits
.\WinPE-Builder.ps1 -Save -WorkDirectory C:\WinPE-Projects\MyPE

# Or drop them
.\WinPE-Builder.ps1 -Discard -WorkDirectory C:\WinPE-Projects\MyPE
```

---

## 5. Create a bootable USB

```powershell
# WARNING: formats the USB partition
.\WinPE-Builder.ps1 -Build -USB F: -Force -WorkDirectory C:\WinPE-Projects\MyPE
```

Or ISO and USB together:

```powershell
.\WinPE-Builder.ps1 -Build -ISO -USB F: -Force -WorkDirectory C:\WinPE-Projects\MyPE
```

---

## 6. Use a custom boot.wim

```powershell
.\WinPE-Builder.ps1 -Init -WorkDirectory C:\WinPE-Projects\MyPE `
  -BootWimPath D:\Images\custom-boot.wim

.\WinPE-Builder.ps1 -Build -ISO -Force -WorkDirectory C:\WinPE-Projects\MyPE
```

---

## 7. Recover when something is stuck mounted

```powershell
.\WinPE-Builder.ps1 -Discard -WorkDirectory C:\WinPE-Projects\MyPE

# Stronger cleanup if DISM is still stuck
.\WinPE-Builder.ps1 -Clean -Force -WorkDirectory C:\WinPE-Projects\MyPE
```

---

## Command map

| You want to... | Run |
|----------------|-----|
| Start a project | `-Init` |
| Open image to look/edit | `-Mount` |
| Keep mount edits | `-Save` |
| Drop mount edits | `-Discard` |
| Apply Add-* content | `-Build` |
| Make ISO | `-Build -ISO -Force` |
| Make USB | `-Build -USB X: -Force` |
| Fix bad mount state | `-Discard` or `-Clean -Force` |

---

## Full guide

See [USAGE.md](USAGE.md) for every option and advanced cases.
