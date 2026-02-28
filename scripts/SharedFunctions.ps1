Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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

# Resolve the real az executable (Application), not any alias/function
$script:AzExe = (Get-Command az -CommandType Application -ErrorAction Stop |
  Select-Object -First 1 -ExpandProperty Source)

Write-Info "Using az executable: $script:AzExe"

function Invoke-AzCli {
  param(
    [Parameter(Mandatory)][string[]]$AzArgs
  )

  Write-Info ("az " + ($AzArgs -join " "))

  $out = & $script:AzExe @AzArgs 2>&1
  if ($LASTEXITCODE -ne 0) {
    throw ("az failed: az " + ($AzArgs -join " ") + "`n" + ($out | Out-String))
  }
  return $out
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

function Ensure-ResourceGroup {
  param(
    [Parameter(Mandatory)][string]$name,
    [Parameter(Mandatory)][string]$location
  )

  $exists = [bool]((Invoke-AzCli @("group","exists","-n",$name)) | ConvertFrom-Json)

  if (-not $exists) {
    Invoke-AzCli @("group","create","-n",$name,"-l",$location) | Out-Null
    Write-Info "Created RG: $name"
  }
  else {
    Write-Info "RG exists: $name"
  }
}