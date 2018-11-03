#Requires -Version 5
$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

# Beautifies all source code.

function FormatCsFiles {
    $srcDir = $PSScriptRoot
    $uncrustifyExe = (Resolve-Path (Join-Path $srcDir '..\ext\uncrustify\uncrustify.exe')).Path
    $uncrustifyCfg = (Resolve-Path (Join-Path $srcDir '..\build\format\uncrustify.cfg')).Path

    $csFiles = Get-ChildItem $srcDir -Recurse |
    Where-Object { $_.Extension -eq '.cs' -and $_.FullName -inotmatch '\\bin\\' -and $_.FullName -inotmatch '\\obj\\' } |
    Select-Object -ExpandProperty FullName

    foreach ($csFile in $csFiles) {
        Write-Output $csFile
        & $uncrustifyExe -q --replace --no-backup -c $uncrustifyCfg $csFile
    }
}

function FormatPs1Files {
    $srcDir = $PSScriptRoot
    $beautifierPsd1 = (Resolve-Path (Join-Path $srcDir '..\ext\PowerShell-Beautifier\PowerShell-Beautifier.psd1')).Path
    Import-Module $beautifierPsd1

    $ps1Files = Get-ChildItem $srcDir -Recurse |
    Where-Object { $_.Extension -eq '.ps1' } |
    Select-Object -ExpandProperty FullName

    foreach ($ps1File in $ps1Files) {
        Write-Output $ps1File
        Edit-DTWBeautifyScript $ps1File -NewLine LF -IndentType FourSpaces
    }
}

Set-ExecutionPolicy Bypass -Scope Process
FormatCsFiles
FormatPs1Files
