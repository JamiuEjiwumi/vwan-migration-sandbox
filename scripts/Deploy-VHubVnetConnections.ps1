param(
  [Parameter(Mandatory)][string]$ConnectionsFolder,
  [string]$HubsFilter = "all",
  [bool]$CanaryMode = $false,
  [string]$CanaryHubCode = "AZS"
)

. "$PSScriptRoot/SharedFunctions.ps1"

Assert-Path $ConnectionsFolder
$bicep = BicepPath "biceps/move-vnet-2-vwan.bicep"

$files = Get-ChildItem -Path $ConnectionsFolder -Filter "*.yaml" -File | Sort-Object Name
if ($files.Count -eq 0) { throw "No vnetConnections YAML found in $ConnectionsFolder" }

foreach ($f in $files) {
  $cfg = Read-YamlFile $f.FullName
  if ($cfg.kind -ne "vnetConnections") { throw "$($f.Name): kind must be vnetConnections" }

  if ($CanaryMode -and $cfg.hubCode -ne $CanaryHubCode) { continue }
  if ($HubsFilter -ne "all" -and $cfg.hubCode -ne $HubsFilter) { continue }

  foreach ($c in $cfg.connections) {
    if (-not $c.subscriptionId) { throw "$($f.Name): connection entry missing subscriptionId" }
    if (-not $c.resourceGroup)  { throw "$($f.Name): connection entry missing resourceGroup" }
    if (-not $c.vnetName)       { throw "$($f.Name): connection entry missing vnetName" }

    $params = @{
      hubName            = $cfg.hubName
      connectionName     = $c.name
      vnet1Name          = $c.vnetName
      vnet1RG            = $c.resourceGroup
      vnetSubscriptionId = $c.subscriptionId
    }

    $tmp = New-TemporaryFile
    $params | ConvertTo-Json -Depth 10 | Set-Content $tmp -Encoding utf8

    $dep = "vnetconn-$($cfg.hubCode)-$($c.vnetName)-$($cfg.resourceVersion)"
    # Hub is a resource-group scoped resource; deploy into the hub RG
    Az "deployment group create -g $($cfg.hubResourceGroup) -n $dep -f `"$bicep`" -p `"$tmp`"" | Out-Null

    Write-Info "Connected VNet $($c.vnetName) (sub $($c.subscriptionId)) to hub $($cfg.hubName)"
  }
}

Write-Info "VNet connection deployment complete."
