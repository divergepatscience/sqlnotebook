# from the PowerShell prompt:
# . .\scripts.ps1

function Build {
    & (Resolve-Path (Join-Path $PSScriptRoot 'scripts/build.ps1')).Path
}

function Format {
    & (Resolve-Path (Join-Path $PSScriptRoot 'scripts/format/format.ps1')).Path
}

function Run {
    & (Resolve-Path (Join-Path $PSScriptRoot 'scripts/run.ps1')).Path
}

function Clean {
    & (Resolve-Path (Join-Path $PSScriptRoot 'scripts/clean.ps1')).Path
}
