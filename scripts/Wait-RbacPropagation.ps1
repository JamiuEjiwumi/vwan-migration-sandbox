param(
  [Parameter(Mandatory)][string]$HubsFolder,
  [string]$HubsFilter = "all",
  [bool]$CanaryMode = $false,
  [string]$CanaryHubCode = "AZS",
  [int]$TimeoutMinutes = 15,
  [int]$PollSeconds = 20,
  [string]$RoleName = "Contributor"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/SharedFunctions.ps1"

$sub = (Invoke-AzCli @("account","show","-o","json") | ConvertFrom-Json).id
if (-not $sub) { throw "Unable to determine subscription id from az account show" }

$scope = "/subscriptions/$sub"

$hubFiles = Get-HubTemplates -HubsFolder $HubsFolder -HubsFilter $HubsFilter -CanaryMode:$CanaryMode -CanaryHubCode $CanaryHubCode
$deadline = (Get-Date).AddMinutes($TimeoutMinutes)

foreach ($f in $hubFiles) {
  $h = Read-YamlFile $f.FullName
  $u = $h.uami

  $idObj = Invoke-AzCli @(
    "identity","show",
    "-g", $u.resourceGroup,
    "-n", $u.name,
    "-o", "json"
  ) | ConvertFrom-Json

  $principalId = $idObj.principalId
  if (-not $principalId) { throw "Cannot resolve principalId for $($u.name)" }

  Write-Info "Waiting for RBAC: $RoleName on $scope for UAMI $($u.name) (principalId=$principalId)"

  while ($true) {
    $ra = Invoke-AzCli @(
      "role","assignment","list",
      "--assignee", $principalId,
      "--role", $RoleName,
      "--scope", $scope,
      "-o", "json"
    ) | ConvertFrom-Json

    if ($ra -and $ra.Count -gt 0) { break }

    if ((Get-Date) -gt $deadline) {
      throw "Timed out waiting for RBAC propagation for $($u.name). Ensure the GitHub OIDC principal has Owner/User Access Admin to create role assignments."
    }

    Start-Sleep -Seconds $PollSeconds
  }

  Write-Info "RBAC propagated for $($u.name)"
}

Write-Info "RBAC propagation confirmed for all selected hubs."