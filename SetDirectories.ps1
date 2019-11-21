<# Author: Carlos Martinez Date: 11-20-2019
Create Pre-WinPE Directories
#>

#List of Directories 
$WorkDirectories = @("Add-Drivers", "Add-Scripts", "WinPE-ISO", "WinPE-Root")

# If Directories don't Exist create directories
$WorkDirectories | ForEach-Object { if (!(Test-Path $_)) { 
        New-Item -ItemType Directory -Path ".\$_"  -Force 
        Write-Output $_ | Out-File -FilePath ".\$_\info.txt" -Force
    } }

