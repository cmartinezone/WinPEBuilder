# 🚀 WinPEBuilder

Build a fully customized **Windows PE** environment in just a few clicks.

WinPEBuilder automates the creation of a Windows PE image with all the essential components already included, making it easy to build deployment, recovery, and troubleshooting media.

---

## ✨ Features

- ⚡ Build a custom WinPE ISO in minutes
- 📦 Automatically includes common WinPE optional components
- 🔧 Inject drivers with ease
- 📜 Copy your own PowerShell scripts and tools
- 🎨 Customize the WinPE background
- 💿 Perfect for deployment, recovery, and automation

---

# 📦 Included WinPE Components

The following optional components are automatically added:

- HTA
- WMI
- StorageWMI
- Scripting
- .NET Framework
- PowerShell
- DISM Cmdlets
- FMAPI
- Secure Boot Cmdlets
- Enhanced Storage
- Secure Startup (BitLocker Support)

📖 Learn more:

https://learn.microsoft.com/windows-hardware/manufacture/desktop/winpe-add-packages--optional-components-reference

---

# 🚀 Getting Started

## 1. Install the Windows ADK

Download and install the latest **Windows Assessment and Deployment Kit (ADK)**.

https://learn.microsoft.com/windows-hardware/get-started/adk-install

---

## 2. Install the WinPE Add-on

The **Windows PE Add-on** is distributed separately from the ADK.

Make sure it is installed before using WinPEBuilder.

https://learn.microsoft.com/windows-hardware/get-started/adk-install#other-adk-downloads

---

## 3. Download WinPEBuilder

Download the latest release and extract the ZIP file.

https://github.com/cmartinezone/WinPEBuilder/releases

---

# 📁 Project Structure

```text
WinPEBuilder
│
├── Add-Drivers      # Drivers injected into the WinPE image
├── Add-Scripts      # Files copied to %SystemRoot%\System32
├── WinPE-ISO        # Generated WinPE_X64.iso
└── WinPE-Root       # Temporary WinPE mount directory
````

---

# ⚙️ Customization

## 🎨 Change the Background

Replace:

```text
Add-Scripts\winpe.jpg
```

Recommended size:

```text
800 × 600
```

To restore the default WinPE background, simply delete:

```text
Add-Scripts\winpe.jpg
```

---

## 📜 Run Custom Scripts

Edit:

```text
Add-Scripts\startnet.cmd
```

to launch your own applications, PowerShell scripts, or automation when WinPE starts.

---

## 🚗 Add Drivers

Copy all drivers into:

```text
Add-Drivers
```

They will automatically be injected during the build process.

---

## 📂 Add Scripts & Tools

Place any scripts, executables, or supporting files inside:

```text
Add-Scripts
```

Everything in this folder will be copied to:

```text
%SystemRoot%\System32
```

---

# ▶️ Build the ISO

Run:

```text
WinPEBuilder.bat
```

> **Important:** Run as **Administrator**.

The build usually completes in **2–5 minutes**.

Your finished ISO will be located at:

```text
WinPE-ISO\WinPE_X64.iso
```

---

# ❤️ Support the Project

If WinPEBuilder saves you time, consider buying me a coffee ☕.

**PayPal Donation**

[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=5NWDHDEXV9582&source=url)

---

## ⭐ Star the Project

If you find WinPEBuilder useful, please consider giving the repository a ⭐ on GitHub.
It helps others discover the project and motivates future improvements.

```
```
