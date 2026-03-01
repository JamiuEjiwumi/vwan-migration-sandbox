param(
  [Parameter(Mandatory)][string]$HubsFolder,
  [string]$HubsFilter = "all",
  [bool]$CanaryMode = $false,
  [string]$CanaryHubCode = "AZS"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/SharedFunctions.ps1"

Write-Info "RoutingIntent is created by Deploy_secure_hub.bicep. This script validates it exists per hub."

$hubFiles = Get-HubTemplates -HubsFolder $HubsFolder -HubsFilter $HubsFilter -CanaryMode:$CanaryMode -CanaryHubCode $CanaryHubCode

foreach ($f in $hubFiles) {
  $h = Read-YamlFile $f.FullName

  $ri = Invoke-AzCli @(
    "resource","list",
    "-g", $h.resourceGroup.name,
    "--resource-type", "Microsoft.Network/virtualHubs/routingIntent",
    "-o", "json"
  ) | ConvertFrom-Json

  if ($null -eq $ri -or $ri.Count -eq 0) {
    throw "No RoutingIntent found for hub $($h.name) in RG $($h.resourceGroup.name)"
  }

  Write-Info "RoutingIntent OK: $($h.name)"
}

Write-Info "RoutingIntent validation complete."