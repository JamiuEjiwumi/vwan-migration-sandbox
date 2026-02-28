param(
  [Parameter(Mandatory)][string]$HubsFolder,
  [string]$HubsFilter = "all",
  [bool]$CanaryMode = $false,
  [string]$CanaryHubCode = "AZS",
  [Parameter(Mandatory)][string]$FortiManagerIP,
  [Parameter(Mandatory)][string]$FortiManagerSerial,
  [string]$AdminPassword = ""
)

. "$PSScriptRoot/SharedFunctions.ps1"

# Enforce FortiGate admin password (do not allow hardcoded defaults)
if ([string]::IsNullOrWhiteSpace($AdminPassword)) {
  if ($env:FORTIGATE_ADMIN_PASSWORD) { $AdminPassword = $env:FORTIGATE_ADMIN_PASSWORD }
}
if ([string]::IsNullOrWhiteSpace($AdminPassword)) {
  throw "AdminPassword is required. Pass -AdminPassword or set env var FORTIGATE_ADMIN_PASSWORD."
}

$bicep = BicepPath "biceps/Deploy_secure_hub.bicep"
$hubFiles = Get-HubTemplates -HubsFolder $HubsFolder -HubsFilter $HubsFilter -CanaryMode:$CanaryMode -CanaryHubCode $CanaryHubCode

foreach ($f in $hubFiles) {
  $h = Read-YamlFile $f.FullName

  # Deploy into the hub resource group scope so the existing hub reference resolves correctly.
  $rg = $h.resourceGroup.name

  $params = @{
    regionCode            = $h.hubCode
    location              = $h.region
    hubName               = $h.name
    uamiName              = $h.uami.name
    hubAddressPrefix      = $h.hubAddressPrefix
    scaleUnit             = $h.scaleUnit
    fortiGateASN          = $h.nva.fortiGateASN
    fortiGateImageVersion = $h.nva.fortiGateImageVersion
    fortiManagerIP        = $FortiManagerIP
    fortiManagerSerial    = $FortiManagerSerial
    adminPassword       = $AdminPassword
  }

  # Remove null/empty keys so Bicep defaults apply
  $params.GetEnumerator() | Where-Object { $null -eq $_.Value -or $_.Value -eq "" } | ForEach-Object { $params.Remove($_.Key) }

  $tmp = New-TemporaryFile
  $params | ConvertTo-Json -Depth 20 | Set-Content $tmp -Encoding utf8

  $dep = "securehub-$($h.hubCode)-$($h.region)-$($h.resourceVersion)"
  Az "deployment group create -g $rg -n $dep -f `"$bicep`" -p `"$tmp`"" | Out-Null

  Write-Info "Secure hub deployed for: $($h.name)"
}

Write-Info "NVA (managed app) deployment complete."
