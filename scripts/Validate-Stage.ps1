. "$PSScriptRoot/SharedFunctions.ps1"

param(
  [Parameter(Mandatory)]
  [ValidateSet("vwan","hubs","uami","rbac","nva","routing_intent","vnet_connections")]
  [string]$Stage,

  [string]$TemplatesRoot = "resourceTemplates",
  [string]$HubsFolder = "resourceTemplates/hubs",
  [string]$ConnectionsFolder = "resourceTemplates/vnetConnections",

  [string]$HubsFilter = "all",
  [bool]$CanaryMode = $false,
  [string]$CanaryHubCode = "Invoke-AzCliS"
)

switch ($Stage) {
  "vwan" {
    $vwan = Read-YamlFile (Join-Path $TemplatesRoot "vwan/vwan-global.yaml")
    $res = Invoke-AzCli "network vwan show -g $($vwan.resourceGroup.name) -n $($vwan.name) -o json" | ConvertFrom-Json
    if ($res.provisioningState -ne "Succeeded") { throw "VWAN not Succeeded: $($res.provisioningState)" }
    Write-Info "VWAN OK: $($vwan.name)"
  }

  "hubs" {
    $hubFiles = Get-HubTemplates -HubsFolder $HubsFolder -HubsFilter $HubsFilter -CanaryMode:$CanaryMode -CanaryHubCode $CanaryHubCode
    foreach ($f in $hubFiles) {
      $h = Read-YamlFile $f.FullName
      $hub = Invoke-AzCli "network vhub show -g $($h.resourceGroup.name) -n $($h.name) -o json" | ConvertFrom-Json
      if ($hub.provisioningState -ne "Succeeded") { throw "Hub $($h.name) not Succeeded: $($hub.provisioningState)" }
      Write-Info "Hub OK: $($h.name)"
    }
  }

  "uami" {
    $hubFiles = Get-HubTemplates -HubsFolder $HubsFolder -HubsFilter $HubsFilter -CanaryMode:$CanaryMode -CanaryHubCode $CanaryHubCode
    foreach ($f in $hubFiles) {
      $h = Read-YamlFile $f.FullName
      $u = $h.uami
      $idObj = Invoke-AzCli "identity show -g $($u.resourceGroup) -n $($u.name) -o json" | ConvertFrom-Json
      if (-not $idObj.principalId) { throw "UAMI missing principalId: $($u.name)" }
      Write-Info "UAMI OK: $($u.name)"
    }
  }

  "rbac" {
    $sub = (Invoke-AzCli "account show -o json" | ConvertFrom-Json).id
    $scope = "/subscriptions/$sub"
    $hubFiles = Get-HubTemplates -HubsFolder $HubsFolder -HubsFilter $HubsFilter -CanaryMode:$CanaryMode -CanaryHubCode $CanaryHubCode
    foreach ($f in $hubFiles) {
      $h = Read-YamlFile $f.FullName
      $u = $h.uami
      $idObj = Invoke-AzCli "identity show -g $($u.resourceGroup) -n $($u.name) -o json" | ConvertFrom-Json
      $principalId = $idObj.principalId
      $ra = Invoke-AzCli "role assignment list --assignee $principalId --role `"Contributor`" --scope $scope -o json" | ConvertFrom-Json
      if ($ra.Count -eq 0) { throw "RBAC missing Contributor for $($u.name) at $scope" }
      Write-Info "RBAC OK: $($u.name)"
    }
  }

  "nva" {
    # validate managed app exists in hub RG
    $hubFiles = Get-HubTemplates -HubsFolder $HubsFolder -HubsFilter $HubsFilter -CanaryMode:$CanaryMode -CanaryHubCode $CanaryHubCode
    foreach ($f in $hubFiles) {
      $h = Read-YamlFile $f.FullName
      $apps = Invoke-AzCli "resource list -g $($h.resourceGroup.name) --resource-type Microsoft.Solutions/applications -o json" | ConvertFrom-Json
      if ($apps.Count -eq 0) { throw "No NVA managed app found in $($h.resourceGroup.name) for $($h.name)" }
      Write-Info "NVA OK for hub: $($h.name)"
    }
  }

  "routing_intent" {
    $hubFiles = Get-HubTemplates -HubsFolder $HubsFolder -HubsFilter $HubsFilter -CanaryMode:$CanaryMode -CanaryHubCode $CanaryHubCode
    foreach ($f in $hubFiles) {
      $h = Read-YamlFile $f.FullName
      # routing intent is child resource; list by type
      $ri = Invoke-AzCli "resource list -g $($h.resourceGroup.name) --resource-type Microsoft.Network/virtualHubs/routingIntent -o json" | ConvertFrom-Json
      if ($ri.Count -eq 0) { throw "No RoutingIntent found in RG $($h.resourceGroup.name) for $($h.name)" }
      Write-Info "RoutingIntent OK: $($h.name)"
    }
  }

  "vnet_connections" {
    Write-Info "VNet connection validation depends on naming in move-vnet-2-vwan.bicep. Add checks once connection names are standardised."
  }
}