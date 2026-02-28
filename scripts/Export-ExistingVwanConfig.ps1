param([string]$OutputPath = "exports/vwan-inventory.json")

. "$PSScriptRoot/SharedFunctions.ps1"

Write-Info "Exporting VWAN inventory from current subscription..."
$vwanList = Az "network vwan list -o json" | ConvertFrom-Json
New-Item -ItemType Directory -Force -Path (Split-Path $OutputPath -Parent) | Out-Null
$vwanList | ConvertTo-Json -Depth 50 | Set-Content -Path $OutputPath -Encoding utf8
Write-Info "Saved: $OutputPath"