#Requires -Version 5
$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

function Format-Ps1Files {
    $dir = $PSScriptRoot
    Import-Module (Resolve-Path (Join-Path $dir '..\..\ext\PowerShell-Beautifier\PowerShell-Beautifier.psd1')).Path

    $srcDir = (Resolve-Path (Join-Path $dir '..')).Path
    $ps1Files = Get-ChildItem $srcDir -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Extension -eq '.ps1' } | Select-Object -ExpandProperty FullName

    foreach ($ps1File in $ps1Files) {
        Write-Output $ps1File
        Edit-DTWBeautifyScript $ps1File -NewLine LF -IndentType FourSpaces
    }
}

function Format-CsFiles {
    $dir = $PSScriptRoot
    $uncrustifyExe = (Resolve-Path (Join-Path $dir '..\..\ext\uncrustify\uncrustify.exe')).Path
    $uncrustifyCfg = (Resolve-Path (Join-Path $dir 'uncrustify.cfg')).Path

    $srcDir = (Resolve-Path (Join-Path $dir '..\..\src\cli')).Path
    if (-not (Test-Path $srcDir)) {
        throw "Does not exist: $srcDir"
    }

    $csFiles = Get-ChildItem $srcDir -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Extension -eq '.cs' -and $_.FullName -inotmatch '\\bin\\' -and $_.FullName -inotmatch '\\obj\\' } | Select-Object -ExpandProperty FullName

    foreach ($csFile in $csFiles) {
        Write-Output $csFile
        & $uncrustifyExe -q --replace --no-backup -c $uncrustifyCfg $csFile
    }
}

function Format-JsFiles {
    Push-Location (Join-Path $PSScriptRoot '..\..\src\gui')
    try {
        & yarn -s install
        & yarn -s run format
    } finally {
        Pop-Location
    }

    $jsFiles = Get-ChildItem (Join-Path $PSScriptRoot '..\..\src\gui\src') -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Extension -eq '.ts' -or $_.Extension -eq '.tsx' -or $_.Extension -eq '.js' } | Select-Object -ExpandProperty FullName
    $jsFiles += (Join-Path $PSScriptRoot '..\..\src\electron\main.js')
    $header = Get-Content (Join-Path $PSScriptRoot 'header.txt')
    foreach ($jsFile in $jsFiles) {
        $oldContent = Get-Content $jsFile
        $needsHeader = $false;
        for ($i = 0; $i -lt $header.Count; $i++) {
            if ($oldContent[$i] -ne $header[$i]) {
                $needsHeader = $true;
            }
        }
        if ($needsHeader) {
            $newContent = @()
            $newContent += $header
            $newContent += $oldContent
            [System.IO.File]::WriteAllText($jsFile,$newContent -join "`n")
            Write-Output "Added license header to $jsFile"
        }
    }
}

Set-ExecutionPolicy Bypass -Scope Process
Format-Ps1Files
Format-CsFiles
Format-JsFiles
