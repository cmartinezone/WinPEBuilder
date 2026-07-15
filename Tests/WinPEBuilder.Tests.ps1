#Requires -Modules Pester

<#
.SYNOPSIS
    Pester tests for WinPEBuilder.

.DESCRIPTION
    Basic smoke tests to validate the WinPEBuilder project structure
    and key files are present before a build.

    Run with:
        Invoke-Pester .\Tests\WinPEBuilder.Tests.ps1 -Output Detailed
#>

Describe 'WinPEBuilder - Project Structure' {

    $projectRoot = Resolve-Path "$PSScriptRoot\.."

    Context 'Required files exist' {

        It 'WinPEBuilder.bat is present' {
            "$projectRoot\WinPEBuilder.bat" | Should -Exist
        }

        It 'Add-Drivers folder is present' {
            "$projectRoot\Add-Drivers" | Should -Exist
        }

        It 'Add-Scripts folder is present' {
            "$projectRoot\Add-Scripts" | Should -Exist
        }

        It 'Add-Updates folder is present' {
            "$projectRoot\Add-Updates" | Should -Exist
        }

        It 'WinPE-ISO folder is present' {
            "$projectRoot\WinPE-ISO" | Should -Exist
        }

        It 'WinPE-Root folder is present' {
            "$projectRoot\WinPE-Root" | Should -Exist
        }

        It 'README.md is present' {
            "$projectRoot\README.md" | Should -Exist
        }
    }

    Context 'Add-Scripts contents' {

        It 'startnet.cmd is present' {
            "$projectRoot\Add-Scripts\startnet.cmd" | Should -Exist
        }
    }
}
