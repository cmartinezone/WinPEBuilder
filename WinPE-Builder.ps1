<#
.SYNOPSIS
    Build customized WinPE media (ISO/USB).

.DESCRIPTION
    -Init    Folders + copype (not left mounted)
    -Mount   Mount boot.wim only
    -Build   Packages, drivers, scripts, updates
    -Save / -Discard / -Clean
    -ISO / -USB (with -Build)

.EXAMPLE
    .\WinPE-Builder.ps1 -Init -WorkDirectory C:\WinPE-Projects\MyPE
    .\WinPE-Builder.ps1 -Mount -WorkDirectory C:\WinPE-Projects\MyPE
    .\WinPE-Builder.ps1 -Build -ISO -Force -WorkDirectory C:\WinPE-Projects\MyPE
#>

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [string]$WorkDirectory,
    [ValidateSet('amd64', 'x86', 'arm64')][string]$Architecture = 'amd64',
    [switch]$Init,
    [switch]$Mount,
    [switch]$Build,
    [string[]]$AddPackage,
    [switch]$ISO,
    [ValidateScript({
        if ([string]::IsNullOrWhiteSpace($_)) { return $true }
        if ($_ -notmatch '^[A-Za-z]:$') { throw 'USB must look like F:' }
        $true
    })][string]$USB,
    [switch]$PCA2023,
    [switch]$Clean,
    [ValidateSet(32, 64, 128, 256, 512)][int]$ScratchSpace = 256,
    [Alias('CustomBootWimPath')][string]$BootWimPath,
    [switch]$Save,
    [switch]$Discard,
    [switch]$Force,
    [switch]$NoDefaultPackages,
    [ValidatePattern('^[a-z]{2}-[A-Za-z]{2}$')][string]$Language = 'en-us'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module Dism -ErrorAction Stop

$script:Started = Get-Date
if ([string]::IsNullOrWhiteSpace($WorkDirectory)) {
    $WorkDirectory = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
}
$WorkDirectory = [IO.Path]::GetFullPath($WorkDirectory).TrimEnd('\')

# Project layout
$DirDrivers = Join-Path $WorkDirectory 'Add-Drivers'
$DirScripts = Join-Path $WorkDirectory 'Add-Scripts'
$DirUpdates = Join-Path $WorkDirectory 'Add-Updates'
$DirIso     = Join-Path $WorkDirectory 'WinPE-ISO'
$DirPeRoot  = Join-Path $WorkDirectory 'WinPE-Root'
$DirMount   = Join-Path $DirPeRoot 'mount'
$DirMedia   = Join-Path $DirPeRoot 'media'
$DirLogs    = Join-Path $WorkDirectory 'Logs'
$FileBootWim = Join-Path $DirPeRoot 'media\sources\boot.wim'

if (-not (Test-Path $DirLogs)) { New-Item -ItemType Directory -Path $DirLogs -Force | Out-Null }
$script:LogFile = Join-Path $DirLogs ("WinPEBuilder_{0:yyyyMMdd_HHmmss}.log" -f (Get-Date))

$DefaultPackages = @(
    'WinPE-WMI', 'WinPE-StorageWMI', 'WinPE-NetFx', 'WinPE-Scripting',
    'WinPE-PowerShell', 'WinPE-DismCmdlets', 'WinPE-HTA', 'WinPE-FMAPI',
    'WinPE-SecureBootCmdlets', 'WinPE-EnhancedStorage', 'WinPE-SecureStartup'
)

# --- console feedback (keep the user oriented) ---

function Write-Log {
    param([string]$Message, [ValidateSet('Info','Ok','Warn','Error','Step')][string]$Level = 'Info')
    $tag = @{ Info='INFO'; Ok='OK'; Warn='WARN'; Error='ERROR'; Step='STEP' }[$Level]
    $line = '[{0}] [{1}] {2}' -f (Get-Date -Format 'HH:mm:ss'), $tag, $Message
    Write-Host $line -ForegroundColor (@{ Info='Cyan'; Ok='Green'; Warn='Yellow'; Error='Red'; Step='White' }[$Level])
    Add-Content -Path $script:LogFile -Value $line -Encoding UTF8
}

function Write-Banner {
    param([string]$Action)
    Write-Host ''
    Write-Host '========================================' -ForegroundColor DarkGray
    Write-Host ' WinPE Builder' -ForegroundColor White
    Write-Host " Action : $Action" -ForegroundColor Cyan
    Write-Host " Folder : $WorkDirectory" -ForegroundColor Cyan
    Write-Host " Arch   : $Architecture" -ForegroundColor Cyan
    Write-Host " Log    : $script:LogFile" -ForegroundColor DarkGray
    Write-Host '========================================' -ForegroundColor DarkGray
    Write-Host ''
}

function Write-Phase {
    param([string]$Title, [string]$Hint = '')
    Write-Host ''
    Write-Host ">> $Title" -ForegroundColor Yellow
    if ($Hint) { Write-Host "   $Hint" -ForegroundColor DarkGray }
}

function Write-Done {
    param([string]$Summary)
    Write-Host ''
    Write-Host "DONE: $Summary" -ForegroundColor Green
    Write-Host ''
}

function Get-AdkInfo {
    $kits = $null
    foreach ($k in @(
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows Kits\Installed Roots',
        'HKLM:\SOFTWARE\Microsoft\Windows Kits\Installed Roots'
    )) {
        if (Test-Path $k) {
            $kits = (Get-ItemProperty $k -EA SilentlyContinue).KitsRoot10
            if ($kits) { break }
        }
    }
    if (-not $kits) { $kits = 'C:\Program Files (x86)\Windows Kits\10' }
    $adk = Join-Path $kits 'Assessment and Deployment Kit'
    $pe  = Join-Path $adk 'Windows Preinstallation Environment'
    [pscustomobject]@{
        EnvBat    = Join-Path $adk 'Deployment Tools\DandISetEnv.bat'
        Copype    = Join-Path $pe 'copype.cmd'
        MakeMedia = Join-Path $pe 'MakeWinPEMedia.cmd'
        OcRoot    = Join-Path $pe "$Architecture\WinPE_OCs"
        PeArch    = Join-Path $pe $Architecture
    }
}

function Test-AdkReady {
    param($Adk, [switch]$RequireWim)
    $missing = @($Adk.EnvBat, $Adk.Copype, $Adk.MakeMedia, $Adk.OcRoot, $Adk.PeArch) |
        Where-Object { -not (Test-Path $_) }
    if ($missing) { throw "ADK missing:`n  $($missing -join "`n  ")" }
    if ($RequireWim -and -not (Test-Path $FileBootWim)) {
        throw "boot.wim not found. Run -Init first: $FileBootWim"
    }
}

function Invoke-AdkCommand {
    # copype / MakeWinPEMedia need DandISetEnv in the same cmd session.
    # Progress lines (e.g. "0% complete") often go to stderr - must not treat as PS errors.
    param([string]$Tool, [string]$Arguments, [string]$EnvBat, [string]$Name, [string]$WaitHint = '')
    $cmd = 'call "{0}" && call "{1}" {2}' -f $EnvBat, $Tool, $Arguments
    Write-Log "Running $Name ..." -Level Step
    if ($WaitHint) { Write-Host "   $WaitHint" -ForegroundColor DarkYellow }
    Write-Host "   (tool output below - please wait)" -ForegroundColor DarkGray

    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $exitCode = 0
    try {
        # Append exit marker so we still know success after the pipeline
        $wrapped = '{0} & call echo __WPB_EXIT__%ERRORLEVEL%' -f $cmd
        cmd.exe /c $wrapped 2>&1 | ForEach-Object {
            $text = if ($_ -is [System.Management.Automation.ErrorRecord]) {
                $_.ToString()
            } else {
                "$_"
            }
            if (-not $text) { return }
            if ($text -match '^__WPB_EXIT__(\d+)\s*$') {
                $exitCode = [int]$Matches[1]
                return
            }
            Write-Host "   | $text" -ForegroundColor DarkGray
            Add-Content -Path $script:LogFile -Value "  $text" -Encoding UTF8
        }
    }
    finally {
        $ErrorActionPreference = $prevEap
    }

    if ($exitCode -ne 0) {
        throw "$Name failed (exit $exitCode). See log: $script:LogFile"
    }
    Write-Log "$Name finished." -Level Ok
}

function Get-ActiveMounts {
    $root = [IO.Path]::GetFullPath($DirPeRoot).TrimEnd('\')
    @(Get-WindowsImage -Mounted -EA SilentlyContinue) | Where-Object {
        [IO.Path]::GetFullPath($_.Path).TrimEnd('\').StartsWith($root, [StringComparison]::OrdinalIgnoreCase)
    }
}

function Dismount-ProjectImage {
    param([switch]$Save)
    foreach ($m in (Get-ActiveMounts)) {
        if ($Save) { Dismount-WindowsImage -Path $m.Path -Save -EA Stop | Out-Null }
        else       { Dismount-WindowsImage -Path $m.Path -Discard -EA SilentlyContinue | Out-Null }
    }
}

function Clear-ProjectMount {
    param([switch]$Global)
    Write-Log 'Clearing mounts...' -Level Step
    Dismount-ProjectImage
    if ($Global) { Clear-WindowsCorruptMountPoint -EA SilentlyContinue }
    if (Test-Path $DirMount) {
        Get-ChildItem $DirMount -Force -EA SilentlyContinue | Remove-Item -Recurse -Force -EA SilentlyContinue
    }
    Write-Log 'Mounts cleared.' -Level Ok
}

function New-ProjectFolders {
    foreach ($d in @($DirDrivers, $DirScripts, $DirUpdates, $DirIso, $DirLogs)) {
        if (-not (Test-Path $d)) {
            New-Item -ItemType Directory -Path $d -Force | Out-Null
            Write-Log "Created $d" -Level Info
        }
    }
}

function New-WinPeTree {
    # -Init: layout + copype; never leave mounted
    param($Adk)
    Write-Phase '1/2 Create folders' 'Add-Drivers, Add-Scripts, Add-Updates, WinPE-ISO, Logs'
    New-ProjectFolders
    Test-AdkReady -Adk $Adk

    Write-Phase '2/2 Stage WinPE tree (copype)' 'Copies ADK boot files into WinPE-Root.'
    if (Test-Path $DirPeRoot) {
        Write-Log 'Removing old WinPE-Root...' -Level Warn
        Dismount-ProjectImage
        Remove-Item $DirPeRoot -Recurse -Force
    }

    # Note: copype itself mounts/unmounts boot.wim briefly to copy boot files.
    # That is ADK behavior, not our -Mount. When it ends, nothing stays mounted.
    Invoke-AdkCommand -Tool $Adk.Copype -Arguments ("{0} `"{1}`"" -f $Architecture, $DirPeRoot) `
        -EnvBat $Adk.EnvBat -Name 'copype' `
        -WaitHint '1-3 min. You may see Mounting/Unmounting from copype - that is normal ADK staging.'

    # Safety net only if copype crashed mid-mount
    if (Get-ActiveMounts) {
        Write-Log 'Cleaning leftover mount from failed/partial copype...' -Level Warn
        Dismount-ProjectImage
    }

    if ($BootWimPath) {
        if (-not (Test-Path $BootWimPath)) { throw "Custom boot.wim not found: $BootWimPath" }
        Copy-Item $BootWimPath $FileBootWim -Force
        Write-Log 'Custom boot.wim applied.' -Level Ok
    }
    if (-not (Test-Path $FileBootWim)) { throw "copype done but boot.wim missing: $FileBootWim" }
    if (Get-ActiveMounts) { throw 'Unexpected mount still open. Run -Discard.' }

    Write-Done "WinPE tree ready at $DirPeRoot"
    Write-Host ''
    Write-Host 'Add your custom content here (before -Build):' -ForegroundColor Cyan
    Write-Host "  Drivers : $DirDrivers" -ForegroundColor White
    Write-Host "  Scripts : $DirScripts" -ForegroundColor White
    Write-Host "            (startnet.cmd, winpe.jpg, unattend.xml, tools...)" -ForegroundColor DarkGray
    Write-Host "  Updates : $DirUpdates" -ForegroundColor White
    Write-Host "            (.msu / .cab packages)" -ForegroundColor DarkGray
    Write-Host ''
}

function Mount-BootImage {
    # -Mount only
    Test-AdkReady -Adk (Get-AdkInfo) -RequireWim
    $open = @(Get-ActiveMounts)
    if ($open.Count -gt 0) {
        Write-Log "Already mounted: $($open[0].Path)" -Level Info
        return [IO.Path]::GetFullPath($open[0].Path).TrimEnd('\')
    }
    if (-not (Test-Path $DirMount)) { New-Item -ItemType Directory -Path $DirMount -Force | Out-Null }
    Write-Phase 'Mount boot.wim' "ReadWrite -> $DirMount"
    Mount-WindowsImage -ImagePath $FileBootWim -Index 1 -Path $DirMount -EA Stop | Out-Null
    $path = [IO.Path]::GetFullPath($DirMount).TrimEnd('\')
    Write-Done "Mounted at $path"
    return $path
}

function Add-OptionalPackages {
    param([string]$MountPath, [string]$OcRoot)
    $list = if ($AddPackage) { @($AddPackage) } elseif (-not $NoDefaultPackages) { $DefaultPackages } else { @() }
    if ($list.Count -eq 0) { return 0 }

    Write-Log "Adding $($list.Count) package(s)..." -Level Step
    $n = 0
    foreach ($name in $list) {
        $cab = Join-Path $OcRoot "$name.cab"
        if (-not (Test-Path $cab)) {
            $hit = Get-ChildItem $OcRoot -Filter "$name.cab" -EA SilentlyContinue | Select-Object -First 1
            if (-not $hit) { throw "Package not found: $name" }
            $cab = $hit.FullName
        }
        Write-Log "  $name" -Level Info
        Add-WindowsPackage -Path $MountPath -PackagePath $cab -EA Stop | Out-Null
        $langCab = Join-Path $OcRoot "$Language\${name}_${Language}.cab"
        if (Test-Path $langCab) {
            Add-WindowsPackage -Path $MountPath -PackagePath $langCab -EA Stop | Out-Null
        }
        $n++
    }
    Write-Log "Packages: $n" -Level Ok
    return $n
}

function Add-ProjectDrivers {
    param([string]$MountPath)
    if (-not (Test-Path $DirDrivers)) { return 0 }
    $infs = @(Get-ChildItem $DirDrivers -Recurse -Filter '*.inf' -EA SilentlyContinue)
    if ($infs.Count -eq 0) { return 0 }
    Write-Log "Adding drivers ($($infs.Count))..." -Level Step
    Add-WindowsDriver -Path $MountPath -Driver $DirDrivers -Recurse -EA Stop | Out-Null
    Write-Log "Drivers: $($infs.Count)" -Level Ok
    return $infs.Count
}

function Copy-ProjectScripts {
    param([string]$MountPath)
    if (-not (Test-Path $DirScripts)) { return }
    Write-Log 'Copying scripts...' -Level Step
    $sys32 = Join-Path $MountPath 'Windows\System32'

    $s32 = Join-Path $DirScripts 'System32'
    if (Test-Path $s32) { Copy-Item (Join-Path $s32 '*') $sys32 -Recurse -Force }
    $root = Join-Path $DirScripts 'Root'
    if (Test-Path $root) { Copy-Item (Join-Path $root '*') $MountPath -Recurse -Force }
    $media = Join-Path $DirScripts 'Media'
    if (Test-Path $media) { Copy-Item (Join-Path $media '*') $DirMedia -Recurse -Force }

    foreach ($n in @('Startnet.cmd', 'startnet.cmd')) {
        $src = Join-Path $DirScripts $n
        if (Test-Path $src) {
            Copy-Item $src (Join-Path $sys32 'Startnet.cmd') -Force
            break
        }
    }

    $bg = Join-Path $DirScripts 'winpe.jpg'
    if (Test-Path $bg) {
        $dest = Join-Path $sys32 'winpe.jpg'
        if (Test-Path $dest) {
            Start-Process takeown.exe -ArgumentList @('/f', $dest, '/a') -Wait -NoNewWindow | Out-Null
            Start-Process icacls.exe -ArgumentList @($dest, '/grant', 'Administrators:F') -Wait -NoNewWindow | Out-Null
        }
        Copy-Item $bg $dest -Force
    }

    $ua = Join-Path $DirScripts 'unattend.xml'
    if (Test-Path $ua) { Copy-Item $ua (Join-Path $DirMedia 'unattend.xml') -Force }
}

function Add-ProjectUpdates {
    param([string]$MountPath)
    if (-not (Test-Path $DirUpdates)) { return 0 }
    $files = @(Get-ChildItem $DirUpdates -Recurse -Include '*.msu', '*.cab' -EA SilentlyContinue)
    if ($files.Count -eq 0) { return 0 }

    Write-Log "Adding updates ($($files.Count))..." -Level Step
    foreach ($f in $files) {
        Write-Log "  $($f.Name)" -Level Info
        Add-WindowsPackage -Path $MountPath -PackagePath $f.FullName -EA Stop | Out-Null
    }
    Write-Log 'Component cleanup...' -Level Info
    Repair-WindowsImage -Path $MountPath -StartComponentCleanup -ResetBase -EA Stop | Out-Null
    Write-Log "Updates: $($files.Count)" -Level Ok
    return $files.Count
}

function Set-ImageScratchSpace {
    # No PS cmdlet for this setting
    param([string]$MountPath, [int]$SizeMB)
    Write-Log "Scratch space: $SizeMB MB" -Level Info
    $p = Start-Process dism.exe -ArgumentList @("/Image:$MountPath", "/Set-ScratchSpace:$SizeMB") -Wait -PassThru -NoNewWindow
    if ($p.ExitCode -ne 0) { throw "Set-ScratchSpace failed ($($p.ExitCode))" }
}

function New-WinPeIso {
    param($Adk)
    if (-not (Test-Path $DirIso)) { New-Item -ItemType Directory -Path $DirIso -Force | Out-Null }
    $iso = Join-Path $DirIso ("WinPE_{0}_{1:yyyyMMdd_HHmm}.iso" -f $Architecture, (Get-Date))
    if ((Test-Path $iso) -and -not $Force) { throw "ISO exists. Use -Force: $iso" }
    $args = '/ISO'
    if ($Force) { $args += ' /f' }
    $args += ' "{0}" "{1}"' -f $DirPeRoot, $iso
    if ($PCA2023) {
        if ((Get-Content $Adk.MakeMedia -Raw) -notmatch 'bootex') { throw 'ADK has no /bootex support.' }
        $args += ' /bootex'
    }
    Write-Phase 'Create ISO' $iso
    Invoke-AdkCommand -Tool $Adk.MakeMedia -Arguments $args -EnvBat $Adk.EnvBat -Name 'MakeWinPEMedia ISO' `
        -WaitHint 'Building ISO - can take a few minutes.'
    Write-Done "ISO ready: $iso"
    return $iso
}

function New-WinPeUsb {
    param($Adk)
    $letter = $USB.Substring(0, 1).ToUpper()
    $sys = if ($env:SystemDrive) { $env:SystemDrive.Substring(0, 1).ToUpper() } else { 'C' }
    if ($letter -eq $sys) { throw "Refused: system drive $letter`:" }

    $part = Get-Partition -DriveLetter $letter -EA SilentlyContinue
    if (-not $part) { throw "Drive not found: $letter`:" }
    $disk = Get-Disk -Number $part.DiskNumber -EA Stop
    if ($disk.IsBoot -or $disk.IsSystem) { throw "Refused: boot/system disk $($disk.Number)" }
    if ($disk.BusType -ne 'USB') { throw "Refused: bus is $($disk.BusType), not USB" }

    Write-Phase 'Create USB' ("Drive {0}:  Disk {1}  {2:N1} GB  (WILL FORMAT)" -f $letter, $disk.Number, ($disk.Size / 1GB))
    $args = '/UFD /f "{0}" {1}:' -f $DirPeRoot, $letter
    if ($PCA2023) { $args += ' /bootex' }
    Invoke-AdkCommand -Tool $Adk.MakeMedia -Arguments $args -EnvBat $Adk.EnvBat -Name 'MakeWinPEMedia USB' `
        -WaitHint 'Formatting USB and copying boot files...'
    Write-Done "USB ready: ${letter}:"
    return "${letter}:"
}

function New-BuildResult {
    param(
        [bool]$Ok, [string]$Action, [string]$Err = $null,
        [string]$Iso = $null, [string]$Usb = $null, [bool]$Mounted = $false,
        [int]$Pkgs = 0, [int]$Drvs = 0, [int]$Upds = 0
    )
    [pscustomobject]@{
        Success = $Ok; Action = $Action; WorkDirectory = $WorkDirectory
        Architecture = $Architecture; BootWim = $FileBootWim; MountPath = $DirMount
        IsMounted = $Mounted; ISOPath = $Iso; USBDrive = $Usb
        PackagesAdded = $Pkgs; DriversAdded = $Drvs; UpdatesAdded = $Upds
        LogPath = $script:LogFile; Started = $script:Started; Finished = Get-Date; Error = $Err
    }
}

# --- switch checks ---
if ($Discard -and ($Build -or $Save -or $Init)) { throw '-Discard cannot mix with -Build/-Save/-Init' }
if ($Save -and ($ISO -or $USB)) { throw '-Save cannot mix with -ISO/-USB' }
if ($ISO -and -not $Build) { throw '-ISO requires -Build' }
if ($USB -and -not $Build) { throw '-USB requires -Build' }
if ($USB -and -not $Force) { throw '-USB requires -Force' }

if (-not ($Init -or $Mount -or $Build -or $Save -or $Discard -or $Clean)) {
    Write-Banner 'Help'
    Write-Host 'Pick one action:' -ForegroundColor White
    Write-Host '  -Init              Create folders + copype tree (not mounted)'
    Write-Host '  -Mount             Mount boot.wim for manual edits'
    Write-Host '  -Build             Add packages/drivers/scripts/updates'
    Write-Host '  -Save              Unmount and keep changes'
    Write-Host '  -Discard           Unmount and drop changes'
    Write-Host '  -Build -ISO -Force Create ISO'
    Write-Host '  -Build -USB F: -Force  Create USB (formats drive)'
    Write-Host ''
    Write-Host "Example: .\WinPE-Builder.ps1 -Init -WorkDirectory '$WorkDirectory'" -ForegroundColor Cyan
    Write-Host ''
    return New-BuildResult -Ok $false -Action 'None' -Err 'No action'
}

# Resolve display action for the banner
$actionName = if ($Init -and -not $Mount -and -not $Build) { 'Init' }
    elseif ($Mount -and -not $Build) { 'Mount' }
    elseif ($Build -and $ISO) { 'Build + ISO' }
    elseif ($Build -and $USB) { 'Build + USB' }
    elseif ($Build) { 'Build' }
    elseif ($Save) { 'Save' }
    elseif ($Discard) { 'Discard' }
    elseif ($Clean) { 'Clean' }
    else { 'Run' }

Write-Banner $actionName

$adk = Get-AdkInfo
$isoPath = $null
$usbPath = $null
$pkgN = 0; $drvN = 0; $updN = 0

try {
    if ($Clean -and -not $Mount -and -not $Build) {
        Write-Phase 'Clean mounts' $(if ($Force) { 'Including global DISM cleanup' } else { 'Project mounts only' })
        Clear-ProjectMount -Global:$Force
        Write-Done 'Mounts cleaned'
        return New-BuildResult -Ok $true -Action 'Clean'
    }

    if ($Discard) {
        Write-Phase 'Discard mount' 'Drops uncommitted changes'
        Clear-ProjectMount
        Write-Done 'Changes discarded; not mounted'
        return New-BuildResult -Ok $true -Action 'Discard'
    }

    if ($Init) {
        New-WinPeTree -Adk $adk
        if (-not $Mount -and -not $Build) {
            return New-BuildResult -Ok $true -Action 'Init' -Mounted $false
        }
    }

    if ($Save -and -not $Build -and -not $Mount) {
        if (-not (Get-ActiveMounts)) { throw 'Nothing mounted. Run -Mount or -Build first.' }
        Write-Phase 'Save image' 'Unmount and keep changes'
        Dismount-ProjectImage -Save
        Write-Done 'Image saved and unmounted'
        return New-BuildResult -Ok $true -Action 'Save' -Mounted $false
    }

    if ($Mount -and -not $Build) {
        if ($Clean) { Clear-ProjectMount }
        $null = Mount-BootImage
        Write-Host "Edit files in: $DirMount" -ForegroundColor Cyan
        Write-Host "Then: -Save (keep) or -Discard (drop)" -ForegroundColor DarkGray
        Write-Host ''
        return New-BuildResult -Ok $true -Action 'Mount' -Mounted $true
    }

    if ($Build) {
        if ($Clean) { Clear-ProjectMount }
        Write-Phase 'Build customization' 'Packages, drivers, scripts, updates'
        $mountPath = Mount-BootImage
        Set-ImageScratchSpace -MountPath $mountPath -SizeMB $ScratchSpace
        $pkgN = Add-OptionalPackages -MountPath $mountPath -OcRoot $adk.OcRoot
        $drvN = Add-ProjectDrivers -MountPath $mountPath
        Copy-ProjectScripts -MountPath $mountPath
        $updN = Add-ProjectUpdates -MountPath $mountPath
        Write-Log "Build summary: packages=$pkgN drivers=$drvN updates=$updN" -Level Info

        if ($ISO -or $USB -or $Save) {
            Write-Phase 'Commit image' 'Saving changes into boot.wim'
            Dismount-WindowsImage -Path $mountPath -Save -EA Stop | Out-Null
            Write-Log 'Image committed.' -Level Ok
        }

        if ($ISO) { $isoPath = New-WinPeIso -Adk $adk }
        if ($USB) { $usbPath = New-WinPeUsb -Adk $adk }

        if (-not ($ISO -or $USB -or $Save)) {
            Write-Done 'Build applied; image still mounted (use -Save when ready)'
        }
        else {
            if ($isoPath) { Write-Host "ISO: $isoPath" -ForegroundColor Green }
            if ($usbPath) { Write-Host "USB: $usbPath" -ForegroundColor Green }
            Write-Done 'Build finished'
        }
    }

    $isMounted = [bool](Get-ActiveMounts)
    return New-BuildResult -Ok $true -Action 'Build' -Iso $isoPath -Usb $usbPath -Mounted $isMounted `
        -Pkgs $pkgN -Drvs $drvN -Upds $updN
}
catch {
    Write-Host ''
    Write-Host 'FAILED' -ForegroundColor Red
    Write-Log $_.Exception.Message -Level Error
    if ($_.ScriptStackTrace) { Write-Log $_.ScriptStackTrace -Level Error }
    $isMounted = $false
    try { $isMounted = [bool](Get-ActiveMounts) } catch {}
    Write-Host ''
    Write-Host "Log: $script:LogFile" -ForegroundColor Yellow
    if ($isMounted) {
        Write-Host "Image may still be mounted. Run -Discard if needed." -ForegroundColor Yellow
    }
    Write-Host ''
    return New-BuildResult -Ok $false -Action 'Failed' -Err $_.Exception.Message -Mounted $isMounted
}
