Set-StrictMode -Version Latest

# Ensure YAML cmdlets exist
if (-not (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue)) {
  try { Import-Module powershell-yaml -ErrorAction Stop } catch { }
}
$ErrorActionPreference = 'Stop'

# Ensure YAML cmdlets are available
if (-not (Get-Command ConvertFrom-Yaml -ErrorAction SilentlyContinue)) {
  try {
    Import-Module powershell-yaml -ErrorAction Stop
  } catch {
    throw "Missing 'powershell-yaml' module. Install with: Install-Module powershell-yaml -Scope CurrentUser -Force"
  }
}

function Write-Info($msg) { Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Write-Warn($msg) { Write-Host "[WARN] $msg" -ForegroundColor Yellow }

function Assert-Path($Path) {
  if (-not (Test-Path $Path)) { throw "Path not found: $Path" }
}

function Read-YamlFile([string]$Path) {
  Assert-Path $Path
  (Get-Content -Raw $Path) | ConvertFrom-Yaml
}

function RepoRoot { (Resolve-Path (Join-Path $PSScriptRoot "..")).Path }

function BicepPath([string]$rel) {
  $p = Join-Path (RepoRoot) $rel
  Assert-Path $p
  $p
}

function Az([string]$args) {
  Write-Info "az $args"
  $out = & az $args 2>&1
  if ($LASTEXITCODE -ne 0) { throw "az failed: $args`n$out" }
  $out
}

function Get-HubTemplates {
  param(
    [Parameter(Mandatory)][string]$HubsFolder,
    [string]$HubsFilter = "all",
    [bool]$CanaryMode = $false,
    [string]$CanaryHubCode = "AZS"
  )
  Assert-Path $HubsFolder
  $files = Get-ChildItem $HubsFolder -Filter "vhub-*.yaml" -File | Sort-Object Name
  if ($files.Count -eq 0) { throw "No hub templates found in $HubsFolder" }

  if ($CanaryMode) {
    $files = $files | Where-Object { $_.Name -match "vhub-$CanaryHubCode-" }
    if ($files.Count -eq 0) { throw "Canary: no hub file for $CanaryHubCode" }
    return $files
  }

  if ($HubsFilter -and $HubsFilter -ne "all") {
    $files = $files | Where-Object { $_.Name -match "vhub-$HubsFilter-" }
    if ($files.Count -eq 0) { throw "No hub files match filter '$HubsFilter'" }
  }

  return $files
}

function Ensure-ResourceGroup([string]$name, [string]$location) {
  $exists = (Az "group exists -n $name" | ConvertFrom-Json)
  if (-not $exists) {
    Az "group create -n $name -l $location" | Out-Null
    Write-Info "Created RG: $name"
  } else {
    Write-Info "RG exists: $name"
  }
}