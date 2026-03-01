param(
  [Parameter(Mandatory)][string]$HubsFolder,
  [string]$HubsFilter = "all",
  [bool]$CanaryMode = $false,
  [string]$CanaryHubCode = "AZS"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/SharedFunctions.ps1"

$bicep = BicepPath "biceps/Deploy_managed_identity_avm.bicep"
$hubFiles = Get-HubTemplates -HubsFolder $HubsFolder -HubsFilter $HubsFilter -CanaryMode:$CanaryMode -CanaryHubCode $CanaryHubCode

foreach ($f in $hubFiles) {
  $h = Read-YamlFile $f.FullName

  # UAMI lives in the configured RG (defaulting to hub RG in the YAML)
  $uamiRg = $h.uami.resourceGroup
  $uamiLocation = $h.resourceGroup.location

  Ensure-ResourceGroup -name $uamiRg -location $uamiLocation

  $dep = "uami-$($h.hubCode)-$($h.region)-$($h.resourceVersion)"

  # Pass parameters inline (avoids JSON parameter-file shape issues)
  Invoke-AzCli @(
    "deployment","group","create",
    "-g", $uamiRg,
    "-n", $dep,
    "-f", $bicep,
    "-p",
      "uamiName=$($h.uami.name)",
      "location=$uamiLocation"
  ) | Out-Null

  Write-Info "UAMI deployed: $($h.uami.name)"
}

Write-Info "UAMI deployment complete."