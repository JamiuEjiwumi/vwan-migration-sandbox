param(
  [Parameter(Mandatory)][string]$HubsFolder,
  [string]$HubsFilter = "all",
  [bool]$CanaryMode = $false,
  [string]$CanaryHubCode = "AZS",
  [string]$OutFolder = "artifacts/nva-map"
)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot/SharedFunctions.ps1"

New-Item -ItemType Directory -Force -Path $OutFolder | Out-Null

# Get current subscription id from Azure CLI context (set by azure/login)
$subId = (az account show --query id -o tsv)
if (-not $subId) { throw "No Azure subscription in context. Ensure azure/login ran successfully." }

$hubFiles = Get-HubTemplates -HubsFolder $HubsFolder -HubsFilter $HubsFilter -CanaryMode:$CanaryMode -CanaryHubCode $CanaryHubCode
if (-not $hubFiles -or $hubFiles.Count -eq 0) { throw "No hub templates found to process." }

foreach ($hf in $hubFiles) {
  $hub = Read-YamlFile $hf.FullName

  $origRg   = $hub.resourceGroup.name
  $nameLike = $hub.hubCode   # AZS / AZC / etc. used to match NVA name

  Write-Host "=== Discover NVA for hubCode=$nameLike in RG=$origRg ==="

  # List managed apps in hub RG
  $maListJson = az resource list `
      --subscription $subId `
      --resource-group $origRg `
      --resource-type "Microsoft.Solutions/applications" `
      --query "[].id" -o json

  $maIds = $maListJson | ConvertFrom-Json
  if (-not $maIds -or $maIds.Count -eq 0) {
      throw "No Managed Application found in hub RG '$origRg' (hubCode=$nameLike)."
  }

  $selectedManagedAppId = $null
  $managedRgName        = $null
  $matchedNvaId         = $null
  $matchedNvaName       = $null

  foreach ($maId in $maIds) {
    # Read managedResourceGroupId
    $maJson = az rest --method get --uri ("https://management.azure.com{0}?api-version=2021-07-01" -f $maId)
    $maObj  = $maJson | ConvertFrom-Json

    $mrgId = $maObj.properties.managedResourceGroupId
    if (-not $mrgId) { continue }

    $mrgName = ($mrgId -split '/')[ -1 ]

    # List NVAs in managed RG (API version aligns with Cory’s working script)
    $nvaJson = az rest --method get `
      --uri ("https://management.azure.com/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Network/networkVirtualAppliances?api-version=2025-05-01" -f $subId, $mrgName)

    $nvaObj = $nvaJson | ConvertFrom-Json
    $match  = $nvaObj.value | Where-Object { $_.name -like "*$nameLike*" } | Select-Object -First 1

    if ($match) {
      $selectedManagedAppId = $maId
      $managedRgName        = $mrgName
      $matchedNvaName       = $match.name
      $matchedNvaId         = $match.id
      break
    }
  }

  if (-not $selectedManagedAppId) {
    throw "No Managed App in hub RG '$origRg' has an NVA name containing '$nameLike' in its managed RG."
  }

  $out = [ordered]@{
    hubCode          = $hub.hubCode
    hubName          = $hub.name
    hubResourceGroup = $origRg
    managedAppId     = $selectedManagedAppId
    managedRgName    = $managedRgName
    nvaName          = $matchedNvaName
    nvaId            = $matchedNvaId
    discoveredAtUtc  = (Get-Date).ToUniversalTime().ToString("o")
  }

  $outPath = Join-Path $OutFolder "$($hub.hubCode).json"
  ($out | ConvertTo-Json -Depth 10) | Out-File -FilePath $outPath -Encoding utf8

  Write-Host "Selected Managed App: $selectedManagedAppId"
  Write-Host "Managed Resource Group: $managedRgName"
  Write-Host "Matched NVA: $matchedNvaName"
  Write-Host "Wrote: $outPath"
}