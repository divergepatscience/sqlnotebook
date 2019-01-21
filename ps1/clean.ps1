#Requires -Version 5
$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

$root = (Resolve-Path (Join-Path $PSScriptRoot '../')).Path

$relativePaths = @(
    'src/cli/bin',
    'src/cli/obj',
    'src/electron/content',
    'src/electron/node_modules',
    'src/gui/build',
    'src/gui/node_modules',
    'web-build',
    'web-temp'
)

foreach ($relativePath in $relativePaths) {
    $absolutePath = (Join-Path $root $relativePath)
    Write-Output $absolutePath
    if (Test-Path $absolutePath) {
        rm -Force -Recurse $absolutePath
    }
}

Write-Output ""
