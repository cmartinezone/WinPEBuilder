#Requires -Version 5.1
# Simple smoke tests — no module required

$root = Resolve-Path (Join-Path $PSScriptRoot '..')

Describe 'WinPE Builder layout' {
    It 'has the main script' {
        Test-Path (Join-Path $root 'WinPE-Builder.ps1') | Should Be $true
    }

    It 'has convention folders' {
        foreach ($n in @('Add-Drivers','Add-Scripts','Add-Updates','WinPE-ISO','WinPE-Root')) {
            Test-Path (Join-Path $root $n) | Should Be $true
        }
    }

    It 'script parses' {
        $errors = $null
        $null = [System.Management.Automation.Language.Parser]::ParseFile(
            (Join-Path $root 'WinPE-Builder.ps1'), [ref]$null, [ref]$errors)
        @($errors).Count | Should Be 0
    }
}
