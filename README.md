# WinPE Builder

One PowerShell script to create customized WinPE media (ISO/USB).

**Needs:** Windows ADK + WinPE add-on, **Administrator** PowerShell

## Quick start

```powershell
.\WinPE-Builder.ps1 -Init -WorkDirectory C:\WinPE-Projects\MyPE
# add drivers/scripts/updates under Add-*
.\WinPE-Builder.ps1 -Build -ISO -Force -WorkDirectory C:\WinPE-Projects\MyPE
```

| Switch | Does |
|--------|------|
| `-Init` | Folders + copype (**not left mounted**) |
| `-Mount` | Mount boot.wim only |
| `-Build` | Packages / drivers / scripts / updates |
| `-Save` | Unmount + commit |
| `-Discard` | Unmount + discard |
| `-ISO` / `-USB` | Media (with `-Build`) |

## Documentation

- **[docs/COMMON-USES.md](docs/COMMON-USES.md)** - most common recipes
- **[docs/USAGE.md](docs/USAGE.md)** - full use cases and options

**Build uses native PowerShell DISM:** `Mount-WindowsImage`, `Add-WindowsPackage`, `Add-WindowsDriver`.  
**ADK scripts only for:** `copype`, `MakeWinPEMedia`.
