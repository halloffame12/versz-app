$ErrorActionPreference = 'Stop'

Set-Location (Split-Path -Parent $PSScriptRoot)

Write-Host 'Starting stable Flutter debug session on emulator-5554...' -ForegroundColor Cyan
Write-Host 'Using --no-dds to avoid VM service disposed disconnects on some emulator setups.' -ForegroundColor DarkGray

flutter run -d emulator-5554 --debug --no-dds
