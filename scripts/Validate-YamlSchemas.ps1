param(
  [Parameter(Mandatory)]
  [string]$TemplatesRoot
)

. "$PSScriptRoot/SharedFunctions.ps1"

Write-Info "Validating YAML templates under: $TemplatesRoot"

function Assert-Has($obj, $path) {
  $parts = $path.Split('.')
  $cur = $obj
  foreach ($p in $parts) {
    if ($null -eq $cur.$p) { throw "Missing required field '$path'" }
    $cur = $cur.$p
  }
}

# VWAN
$vwanPath = Join-Path $TemplatesRoot "vwan/vwan-global.yaml"
$vwan = Read-YamlFile $vwanPath
Assert-Has $vwan "kind"
if ($vwan.kind -ne "vwan") { throw "vwan-global.yaml kind must be 'vwan'" }
Assert-Has $vwan "name"
Assert-Has $vwan "location"
Assert-Has $vwan "resourceGroup.name"
Assert-Has $vwan "resourceGroup.location"
Assert-Has $vwan "deploymentScript"
Assert-Has $vwan "deploymentPriority"
Assert-Has $vwan "resourceVersion"

# Hubs
$hubFolder = Join-Path $TemplatesRoot "hubs"
$hubFiles = Get-ChildItem $hubFolder -Filter "vhub-*.yaml" -File
if ($hubFiles.Count -eq 0) { throw "No hub YAML files found in $hubFolder" }

foreach ($f in $hubFiles) {
  $h = Read-YamlFile $f.FullName
  if ($h.kind -ne "vhub") { throw "$($f.Name): kind must be 'vhub'" }
  foreach ($req in @("hubCode","region","name","resourceGroup.name","resourceGroup.location","vwan.name","vwan.resourceGroup","hubAddressPrefix","scaleUnit","deploymentScript","deploymentPriority","resourceVersion")) {
    Assert-Has $h $req
  }
  if ($h.hubAddressPrefix -notmatch "^\d+\.\d+\.\d+\.\d+\/24$") {
    Write-Warn "$($f.Name): hubAddressPrefix is not /24. Ensure your Deploy_secure_hub.bicep assumptions still hold."
  }
  if ($h.uami -and $h.uami.roleAssignments) {
    # ok
  } else {
    Write-Warn "$($f.Name): uami.roleAssignments missing (expected one per hub)."
  }
}

# VNet Connections
$vcFolder = Join-Path $TemplatesRoot "vnetConnections"
$vcFiles = Get-ChildItem $vcFolder -Filter "*.yaml" -File -ErrorAction SilentlyContinue
foreach ($f in $vcFiles) {
  $c = Read-YamlFile $f.FullName
  if ($c.kind -ne "vnetConnections") { throw "$($f.Name): kind must be 'vnetConnections'" }
  foreach ($req in @("hubCode","hubName","hubResourceGroup","hubRegion","deploymentScript","deploymentPriority","resourceVersion")) {
    Assert-Has $c $req
  }
}

# Routing Intent
$riPath = Join-Path $TemplatesRoot "routingIntent/routingIntent-global.yaml"
if (Test-Path $riPath) {
  $ri = Read-YamlFile $riPath
  if ($ri.kind -ne "routingIntent") { throw "routingIntent-global.yaml kind must be 'routingIntent'" }
  foreach ($req in @("name","intent.internetTraffic.enabled","intent.privateTraffic.enabled","deploymentScript","deploymentPriority","resourceVersion")) {
    Assert-Has $ri $req
  }
} else {
  Write-Warn "routingIntent-global.yaml not found at $riPath (ok if you haven't added it yet)."
}

Write-Info "YAML validation completed successfully."