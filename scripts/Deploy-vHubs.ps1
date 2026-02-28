. "$PSScriptRoot/SharedFunctions.ps1"

param(
  [Parameter(Mandatory)][string]$HubsFolder,
  [string]$HubsFilter = "all",
  [bool]$CanaryMode = $false,
  [string]$CanaryHubCode = "Invoke-AzCliS",
  [string]$VwanTemplatePath = "resourceTemplates/vwan/vwan-global.yaml"
)

$vwan = Read-YamlFile $VwanTemplatePath
if ($vwan.kind -ne "vwan") { throw "Expected kind=vwan in $VwanTemplatePath" }

# Resolve VWAN ID (must exist first)
$vwanObj = Invoke-AzCli "network vwan show -g $($vwan.resourceGroup.name) -n $($vwan.name) -o json" | ConvertFrom-Json
$vwanId = $vwanObj.id
if (-not $vwanId) { throw "Unable to resolve VWAN id for $($vwan.name)" }

$bicep = BicepPath "modules/hub.bicep"
$hubFiles = Get-HubTemplates -HubsFolder $HubsFolder -HubsFilter $HubsFilter -CanaryMode:$CanaryMode -CanaryHubCode $CanaryHubCode

foreach ($f in $hubFiles) {
  $h = Read-YamlFile $f.FullName

  Ensure-ResourceGroup $h.resourceGroup.name $h.resourceGroup.location

  $params = @{
    location     = $h.resourceGroup.location
    virtualWanID = $vwanId
    hubName      = $h.name
    addressPrefix= $h.hubAddressPrefix
  }

  $tmp = New-TemporaryFile
  $params | ConvertTo-Json -Depth 10 | Set-Content $tmp -Encoding utf8

  $dep = "hub-$($h.hubCode)-$($h.region)-$($h.resourceVersion)"
  Invoke-AzCli "deployment group create -g $($h.resourceGroup.name) -n $dep -f `"$bicep`" -p `"$tmp`"" | Out-Null

  Write-Info "Hub deployed: $($h.name)"
}

Write-Info "Base hub deployment complete."
