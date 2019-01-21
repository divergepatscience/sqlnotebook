#Requires -Version 5
$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

$root = (Resolve-Path (Join-Path $PSScriptRoot '../')).Path

Invoke-Command -ArgumentList (Join-Path $root 'src/electron') -ScriptBlock {
    Set-Location $args[0]
    & yarn start
}

Write-Output ""
