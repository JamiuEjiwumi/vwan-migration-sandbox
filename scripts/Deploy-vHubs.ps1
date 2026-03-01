param(
  [Parameter(Mandatory)][string]$HubsFolder,
  [string]$HubsFilter = "all",
  [bool]$CanaryMode = $false,
  [string]$CanaryHubCode = "AZS",
  [string]$VwanTemplatePath = "resourceTemplates/vwan/vwan-global.yaml"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/SharedFunctions.ps1"

$vwan = Read-YamlFile $VwanTemplatePath
if ($vwan.kind -ne "vwan") { throw "Expected kind=vwan in $VwanTemplatePath" }

# Resolve VWAN ID (must exist first)
$vwanObj = Invoke-AzCli @(
  "network","vwan","show",
  "-g", $vwan.resourceGroup.name,
  "-n", $vwan.name,
  "-o", "json"
) | ConvertFrom-Json

$vwanId = $vwanObj.id
if (-not $vwanId) { throw "Unable to resolve VWAN id for $($vwan.name)" }

$bicep = BicepPath "modules/hub.bicep"
$hubFiles = Get-HubTemplates -HubsFolder $HubsFolder -HubsFilter $HubsFilter -CanaryMode:$CanaryMode -CanaryHubCode $CanaryHubCode

foreach ($f in $hubFiles) {
  $h = Read-YamlFile $f.FullName

  Ensure-ResourceGroup -name $h.resourceGroup.name -location $h.resourceGroup.location

  $dep = "hub-$($h.hubCode)-$($h.region)-$($h.resourceVersion)"

  # Pass parameters inline as key=value (simplest + avoids JSON parameter file shape issues)
  Invoke-AzCli @(
    "deployment","group","create",
    "-g", $h.resourceGroup.name,
    "-n", $dep,
    "-f", $bicep,
    "-p",
      "location=$($h.resourceGroup.location)",
      "virtualWanID=$vwanId",
      "hubName=$($h.name)",
      "addressPrefix=$($h.hubAddressPrefix)"
  ) | Out-Null

  Write-Info "Hub deployed: $($h.name)"
}

Write-Info "Base hub deployment complete."