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

# Resolve the real Invoke-AzCli executable (Application), not any alias/function
$script:Invoke-AzCliExe = (Get-Command Invoke-AzCli -CommandType Application -ErrorAction Stop |
  Select-Object -First 1 -ExpandProperty Source)

Write-Info "Using Invoke-AzCli executable: $script:Invoke-AzCliExe"

function Invoke-Invoke-AzCliCli {
  param(
    [Parameter(Mandatory)][string[]]$Invoke-AzCliArgs
  )

  Write-Info ("Invoke-AzCli " + ($Invoke-AzCliArgs -join " "))

  $out = & $script:Invoke-AzCliExe @Invoke-AzCliArgs 2>&1
  if ($LASTEXITCODE -ne 0) {
    throw ("Invoke-AzCli failed: Invoke-AzCli " + ($Invoke-AzCliArgs -join " ") + "`n" + ($out | Out-String))
  }
  return $out
}

function Get-HubTemplates {
  param(
    [Parameter(Mandatory)][string]$HubsFolder,
    [string]$HubsFilter = "all",
    [bool]$CanaryMode = $false,
    [string]$CanaryHubCode = "Invoke-AzCliS"
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

  $exists = [bool]((Invoke-Invoke-AzCliCli @("group","exists","-n",$name)) | ConvertFrom-Json)

  if (-not $exists) {
    Invoke-Invoke-AzCliCli @("group","create","-n",$name,"-l",$location) | Out-Null
    Write-Info "Created RG: $name"
  }
  else {
    Write-Info "RG exists: $name"
  }
}