. "$PSScriptRoot/SharedFunctions.ps1"

param(
  [Parameter(Mandatory)][string]$HubsFolder,
  [string]$HubsFilter = "all",
  [bool]$CanaryMode = $false,
  [string]$CanaryHubCode = "Invoke-AzCliS",
  [string]$RoleName = "Contributor",
  [ValidateSet("subscription")]
  [string]$Scope = "subscription"
)

$sub = (Invoke-AzCli "account show -o json" | ConvertFrom-Json).id
$scope = "/subscriptions/$sub"

$hubFiles = Get-HubTemplates -HubsFolder $HubsFolder -HubsFilter $HubsFilter -CanaryMode:$CanaryMode -CanaryHubCode $CanaryHubCode

foreach ($f in $hubFiles) {
  $h = Read-YamlFile $f.FullName
  $u = $h.uami

  $idObj = Invoke-AzCli "identity show -g $($u.resourceGroup) -n $($u.name) -o json" | ConvertFrom-Json
  $principalId = $idObj.principalId
  if (-not $principalId) { throw "Cannot resolve principalId for $($u.name)" }

  $existing = Invoke-AzCli "role assignment list --assignee $principalId --role `"$RoleName`" --scope $scope -o json" | ConvertFrom-Json
  if ($existing.Count -gt 0) {
    Write-Info "RBAC exists: $RoleName for $($u.name)"
    continue
  }

  Invoke-AzCli "role assignment create --assignee-object-id $principalId --assignee-principal-type ServicePrincipal --role `"$RoleName`" --scope $scope" | Out-Null
  Write-Info "RBAC assigned: $RoleName for $($u.name)"
}

Write-Info "RBAC assignment complete."
