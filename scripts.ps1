#Requires -Version 5
$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

# from the PowerShell prompt, import these functions using: . .\scripts.ps1

function Build {
    & (Resolve-Path (Join-Path $PSScriptRoot 'ps1/build.ps1')).Path
}

function Format {
    & (Resolve-Path (Join-Path $PSScriptRoot 'ps1/format/format.ps1')).Path
}

function Run {
    & (Resolve-Path (Join-Path $PSScriptRoot 'ps1/run.ps1')).Path
}

function Clean {
    & (Resolve-Path (Join-Path $PSScriptRoot 'ps1/clean.ps1')).Path
}

function Web {
    & (Resolve-Path (Join-Path $PSScriptRoot 'ps1/web.ps1')).Path
}

function RunWeb {
    & (Resolve-Path (Join-Path $PSScriptRoot 'ps1/runweb.ps1')).Path
}
