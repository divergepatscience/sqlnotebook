#Requires -Version 5
$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

$root = (Resolve-Path (Join-Path $PSScriptRoot '../')).Path

Write-Output ""
$timestamp = [System.DateTime]::Now.ToString()
Write-Output ("### " + $timestamp + " ").PadRight(80, '#')

Write-Output "--- src/electron ---------------------------------------------------------------"
Push-Location (Join-Path $root 'src/electron')
try {
    & yarn -s install
    if ($LastExitCode -ne 0) {
        throw "'yarn install' failed in src/electron"
    }
} finally {
    Pop-Location
}

Write-Output "--- src/gui --------------------------------------------------------------------"
Push-Location (Join-Path $root 'src/gui')
try {
    & yarn -s install
    if ($LastExitCode -ne 0) {
        throw "'yarn install' failed in src/gui"
    }

    & yarn -s build
    if ($LastExitCode -ne 0) {
        throw "'yarn build' failed in src/electron"
    }

    if (Test-Path ../electron/content) {
        rm -Recurse -Force ../electron/content
    }
    mkdir ../electron/content | Out-Null
    cp -Recurse -Force build/* ../electron/content/
} finally {
    Pop-Location
}

Write-Output "--- src/cli --------------------------------------------------------------------"
Push-Location (Join-Path $root 'src/cli')
try {
    & dotnet build --verbosity q
    if ($LastExitCode -ne 0) {
        throw "'dotnet build' failed in src/cli"
    }
} finally {
    Pop-Location
}

$timestamp = [System.DateTime]::Now.ToString()
Write-Output ("### " + $timestamp + " ").PadRight(80, '#')
Write-Output ""
