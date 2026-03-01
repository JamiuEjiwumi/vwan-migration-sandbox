param(
  [Parameter(Mandatory)][string]$HubCode,
  [Parameter(Mandatory)][string]$HubName,
  [Parameter(Mandatory)][string]$HubResourceGroup,
  [Parameter(Mandatory)][string]$HubRegion,
  [Parameter(Mandatory)][string]$OutFile
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/SharedFunctions.ps1"

$doc = @{
  kind = "vnetConnections"
  hubCode = $HubCode
  hubName = $HubName
  hubResourceGroup = $HubResourceGroup
  hubRegion = $HubRegion
  defaults = @{
    routeTable = "default"
    propagateTo = @("default")
  }
  connections = @()
  deploymentScript = "Deploy-VHubVnetConnections.ps1"
  deploymentPriority = 700
  resourceVersion = (Get-Date -Format "yyyyMMdd")
}

New-Item -ItemType Directory -Force -Path (Split-Path $OutFile -Parent) | Out-Null
($doc | ConvertTo-Yaml) | Set-Content -Path $OutFile -Encoding utf8
Write-Info "Generated empty hub-centric vnetConnections YAML: $OutFile"