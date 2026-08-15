<p align="center">
  <img src="_docs/assets/logo.jpg" alt="WinPE Builder logo" width="200" />
</p>

<h1 align="center">WinPE Builder 2.0</h1>

<p align="center">
  Build a fully customized <strong>Windows PE</strong> environment with a simple PowerShell workflow.
</p>

**WinPE Builder 2.0** automates creating a WinPE image with essential optional components, drivers, scripts, updates, and an ISO or USB — ideal for deployment, recovery, and troubleshooting media.

```text
Init project  →  Add drivers / scripts / updates / packages  →  Build ISO or USB
```

> **Version 2.0** — project-based workflow, `packages.pe` control, Secure Boot options (PCA 2011 / PCA 2023).

Looking for the original **version 1.1** batch-based tool? See the **[legacy branch](https://github.com/cmartinezone/WinPEBuilder/tree/legacy)**.

---

## ✨ Features

- ⚡ Build a custom WinPE ISO (or USB) in minutes  
- 📁 Project folders for drivers, scripts, updates, and logs  
- 📦 Default optional components included (PowerShell, DISM, BitLocker tools, and more)  
- 📝 Edit **`packages.pe`** to enable or disable components without editing the script  
- 🔌 Inject drivers with ease  
- 🧰 Copy your own scripts and tools into the image  
- 🖼️ Customize the WinPE background  
- 🔐 Optional modern Secure Boot signing (`-PCA2023`)  
- 🚀 Perfect for deployment, recovery, and automation  

---

## 📦 Included WinPE components (defaults)

These optional components are installed by default (dependency-safe order):

| Component | Purpose |
|-----------|---------|
| **WinPE-WMI** | WMI / management foundation |
| **WinPE-NetFx** | .NET Framework subset |
| **WinPE-Scripting** | Windows Script Host |
| **WinPE-PowerShell** | PowerShell in WinPE |
| **WinPE-DismCmdlets** | DISM PowerShell module |
| **WinPE-StorageWMI** | Storage PowerShell cmdlets |
| **WinPE-SecureBootCmdlets** | Secure Boot PowerShell cmdlets |
| **WinPE-HTA** | HTML Applications |
| **WinPE-FMAPI** | File Management API |
| **WinPE-SecureStartup** | BitLocker / TPM tools |
| **WinPE-EnhancedStorage** | Enhanced storage / BitLocker-related devices |

On **`-Init`**, a project file **`packages.pe`** is created with these defaults **enabled** and other ADK optional components listed as comments — uncomment to add more.

📚 Learn more:  
https://learn.microsoft.com/windows-hardware/manufacture/desktop/winpe-add-packages--optional-components-reference

---

## 🚀 Getting started

### 1️⃣ Install the Windows ADK

Download and install the latest **Windows Assessment and Deployment Kit (ADK)**.

https://learn.microsoft.com/windows-hardware/get-started/adk-install

### 2️⃣ Install the WinPE add-on

The **Windows PE add-on** is separate from the main ADK. Install it before using WinPE Builder.

https://learn.microsoft.com/windows-hardware/get-started/adk-install#other-adk-downloads

### 3️⃣ Download WinPE Builder

Download the latest release ZIP and extract it, or clone the repository.

https://github.com/cmartinezone/WinPEBuilder/releases

### 4️⃣ Run PowerShell as Administrator

Right-click **Windows PowerShell** → **Run as administrator**, then `cd` into the folder where you extracted the ZIP (the folder that contains `WinPE-Builder.ps1`).

```powershell
cd C:\path\to\extracted\WinPEBuilder
```

---

## 📂 Project structure

After extract (and after `-Init`), a typical layout looks like:

```text
WinPEBuilder\                 # folder from the ZIP (or your -WorkDirectory)
│
├── WinPE-Builder.ps1         # Main engine (run this)
├── packages.pe               # Optional components list (created on -Init if missing)
│
├── Add-Drivers\              # Drivers injected into the image on -Build
├── Add-Scripts\              # Scripts, wallpaper, tools (see layout below)
├── Add-Updates\              # .msu / .cab updates
│
├── WinPE-Root\               # Working WinPE tree (managed by Init/Build)
├── WinPE-ISO\                # Generated ISO files
├── WinPE-Logs\               # Run logs
│
└── _docs\                    # Simple guide, recipes, full reference
```

### `Add-Scripts` layout

| Path | Goes to |
|------|---------|
| `Add-Scripts\startnet.cmd` | Startup script (must keep `wpeinit`) |
| `Add-Scripts\winpe.jpg` | WinPE background |
| `Add-Scripts\System32\` | Image `Windows\System32` |
| `Add-Scripts\Root\` | Image root (`X:\`) |
| `Add-Scripts\Media\` | Boot media (`WinPE-Root\media`) |
| Other files in `Add-Scripts\` | Copied into `System32` (tools, scripts, etc.) |

---

## ▶️ Quick start (first ISO)

Always pass **`-WorkDirectory`** (where the project lives). Two common choices after downloading the ZIP:

### Option A — Use the extracted folder as the project

```powershell
cd C:\path\to\extracted\WinPEBuilder

# Create project layout in the current folder
.\WinPE-Builder.ps1 -Init -WorkDirectory .

# Optional customization (see below):
#   - Copy your drivers into Add-Drivers
#   - Edit Add-Scripts\startnet.cmd and packages.pe

# Build ISO
.\WinPE-Builder.ps1 -Build -ISO -Force -AddPackage packages.pe
```

💿 ISO output:

```text
.\WinPE-ISO\WinPE_amd64_yyyyMMdd_HHmm.iso
```

### Option B — Use another path as the project

```powershell
cd C:\path\to\extracted\WinPEBuilder

# Create the project at a path you choose (folders + base WinPE + packages.pe)
.\WinPE-Builder.ps1 -Init -WorkDirectory C:\MyWinPE-Project

# Optional: copy your drivers into that project's Add-Drivers folder,
# edit Add-Scripts and packages.pe there, then build:

.\WinPE-Builder.ps1 -Build -ISO -Force -AddPackage packages.pe
```

💿 ISO output (under your project folder):

```text
<WorkDirectory>\WinPE-ISO\WinPE_amd64_yyyyMMdd_HHmm.iso
```

> ⚠️ **Important:** Always run as **Administrator**.  
> Builds usually complete in a few minutes (depends on packages and drivers).

---

## ⚙️ Customization

All paths below are **inside your project** (`-WorkDirectory` — the ZIP folder if you used `.`).

### 🖼️ Change the background

Copy your wallpaper into the project as:

```text
Add-Scripts\winpe.jpg
```

Recommended size: **800 × 600**.

To use the default WinPE background again, remove that file.

### 📜 Run custom scripts at startup

Edit (or create) in the project:

```text
Add-Scripts\startnet.cmd
```

Keep `wpeinit` at the top, then launch your tools or scripts:

```cmd
@echo off
wpeinit
REM your commands here
```

### 🔌 Add drivers

Copy **your** driver packages (folders with `.inf` files) into:

```text
Add-Drivers
```

They are injected automatically on **`-Build`**.

### 🧰 Add scripts and tools

Copy **your** scripts, executables, or tools into:

```text
Add-Scripts
```

Use subfolders when you need a specific destination:

| Put files in | Destination in the image / media |
|--------------|-----------------------------------|
| `Add-Scripts\` (root of that folder) | `Windows\System32` |
| `Add-Scripts\System32\` | `Windows\System32` |
| `Add-Scripts\Root\` | Image root (`X:\`) |
| `Add-Scripts\Media\` | Boot media (`WinPE-Root\media`) |

### 📝 Control optional packages (`packages.pe`)

Created on **`-Init`** in the project folder.

```text
# Default Components   ← enabled (no #)
# Optional Components  ← uncomment a line to enable
```

Open `packages.pe` in any text editor, adjust the list, then build:

```powershell
.\WinPE-Builder.ps1 -Build -ISO -Force -AddPackage packages.pe
```

Missing packages are skipped with a warning; the build continues.

### 📥 Add Windows updates

Copy **your** `.msu` / `.cab` update files into:

```text
Add-Updates
```

### 💾 Use your own boot.wim

Only with **`-Init`**. Point `-BootWimPath` at **your** WinPE `boot.wim` file:

```powershell
.\WinPE-Builder.ps1 -Init -WorkDirectory . `
  -BootWimPath ".\path\to\your\boot.wim"
```

### 🔑 Create a USB stick

> ⚠️ **Warning:** `-USB` **formats** the target drive. Double-check the letter (`F:`, `E:`, …).  
> Wrong drive = total data loss. The script refuses the system disk and non-USB buses, but you still choose the letter.

**Recommended (safer for most people):** build an **ISO**, then write it to USB with a tool such as **[Rufus](https://rufus.ie/)**.

```powershell
# 1) Build ISO
.\WinPE-Builder.ps1 -Build -ISO -Force -AddPackage packages.pe

# 2) Open Rufus → select your USB stick → select the ISO under WinPE-ISO\ → Start
```

**Optional (ADK formats the stick directly):**

```powershell
.\WinPE-Builder.ps1 -Build -USB F: -Force -AddPackage packages.pe
```

Only use `-USB` when you are sure of the drive letter and can wipe that stick.

### 🔐 Secure Boot (PCA 2023)

Default media uses **PCA 2011** (widest compatibility).

```powershell
.\WinPE-Builder.ps1 -Build -ISO -PCA2023 -Force -AddPackage packages.pe
```

Use **`-PCA2023`** only when target PCs trust the Windows UEFI CA 2023.

---

## 📋 Common commands

| Goal | Command |
|------|---------|
| Init in current folder (ZIP extract) | `.\WinPE-Builder.ps1 -Init -WorkDirectory .` |
| Init at a custom path | `.\WinPE-Builder.ps1 -Init -WorkDirectory C:\MyWinPE-Project` |
| Resume project (new window) | `.\WinPE-Builder.ps1 -WorkDirectory C:\MyWinPE-Project` |
| Build ISO (recommended) | `.\WinPE-Builder.ps1 -Build -ISO -Force -AddPackage packages.pe` |
| Write USB via Rufus | Build ISO, then use [Rufus](https://rufus.ie/) (safer) |
| Build USB (formats drive) | `.\WinPE-Builder.ps1 -Build -USB F: -Force -AddPackage packages.pe` |
| Mount image | `.\WinPE-Builder.ps1 -Mount` |
| Save mount | `.\WinPE-Builder.ps1 -Save` |
| Discard mount | `.\WinPE-Builder.ps1 -Discard` |

Same PowerShell window keeps the project path after `-Init` or `-WorkDirectory`.

---

## 📚 Documentation

| Guide | When to use it |
|-------|----------------|
| [Simple guide](_docs/SIMPLE-GUIDE.md) | Full first-project walkthrough |
| [Common uses](_docs/COMMON-USES.md) | Short recipes |
| [Usage reference](_docs/USAGE.md) | Every switch and option |
| [Improvements backlog](IMPROVEMENTS.md) | Ideas we can improve next |

---

## ✅ Requirements

1. Windows 10 / 11 (or Windows Server)  
2. **Windows ADK** + **Windows PE add-on**  
3. PowerShell **as Administrator**  

If the ADK or WinPE add-on is missing, the script stops with a clear message and install link.

---

## ❤️ Support the project

If WinPE Builder saves you time, consider buying me a coffee ☕

**PayPal donation**

[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=5NWDHDEXV9582&source=url)

---

## ⭐ Star the project

If you find WinPE Builder useful, please consider giving the repository a ⭐ on GitHub.  
It helps others discover the project and motivates future improvements.

https://github.com/cmartinezone/WinPEBuilder

**Legacy (v1.1):** [github.com/cmartinezone/WinPEBuilder/tree/legacy](https://github.com/cmartinezone/WinPEBuilder/tree/legacy)

---

## ⚠️ Notes

- Run elevated.  
- Prefer **ISO + Rufus** for bootable USB; **`-USB` formats** the selected drive — verify the letter first.  
- **`-Init` rebuilds** `WinPE-Root` — do not re-Init a project you want to keep; resume with `-WorkDirectory` alone.  
- Stuck mount: `.\WinPE-Builder.ps1 -Discard` or `-Clean -Force`.  
