#Requires -Version 5
$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

$root = (Resolve-Path (Join-Path $PSScriptRoot '../')).Path
Push-Location (Join-Path $root 'web-build')
try {
    & npx local-web-server
} finally {
    Pop-Location
}
