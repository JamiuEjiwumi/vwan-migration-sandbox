param(
  [Parameter(Mandatory)][string]$HubsFolder,
  [string]$HubsFilter = "all",
  [bool]$CanaryMode = $false,
  [string]$CanaryHubCode = "AZS",

  [string]$RoleName = "Contributor",
  [ValidateSet("subscription")]
  [string]$Scope = "subscription"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/SharedFunctions.ps1"

# Subscription scope
$subId = (Invoke-AzCli @("account","show","-o","json") | ConvertFrom-Json).id
if (-not $subId) { throw "Unable to determine subscription id from az account show" }

$scopeStr = "/subscriptions/$subId"

$hubFiles = Get-HubTemplates -HubsFolder $HubsFolder -HubsFilter $HubsFilter -CanaryMode:$CanaryMode -CanaryHubCode $CanaryHubCode

foreach ($f in $hubFiles) {
  $h = Read-YamlFile $f.FullName
  $u = $h.uami

  if (-not $u -or -not $u.name -or -not $u.resourceGroup) {
    throw "Missing uami.name or uami.resourceGroup in hub template: $($f.FullName)"
  }

  $idObj = Invoke-AzCli @(
    "identity","show",
    "-g", $u.resourceGroup,
    "-n", $u.name,
    "-o", "json"
  ) | ConvertFrom-Json

  $principalId = $idObj.principalId
  if (-not $principalId) { throw "UAMI principalId not found for $($u.name)" }

  # Check existing assignment
  $existing = Invoke-AzCli @(
    "role","assignment","list",
    "--assignee", $principalId,
    "--role", $RoleName,
    "--scope", $scopeStr,
    "-o", "json"
  ) | ConvertFrom-Json

  if ($existing -and $existing.Count -gt 0) {
    Write-Info "RBAC exists: $RoleName for $($u.name) at $scopeStr"
    continue
  }

  # Create assignment
  Invoke-AzCli @(
    "role","assignment","create",
    "--assignee-object-id", $principalId,
    "--assignee-principal-type", "ServicePrincipal",
    "--role", $RoleName,
    "--scope", $scopeStr,
    "-o", "none"
  ) | Out-Null

  Write-Info "RBAC assigned: $RoleName for $($u.name) at $scopeStr"
}

Write-Info "RBAC deployment complete."