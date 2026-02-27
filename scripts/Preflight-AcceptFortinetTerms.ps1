. "$PSScriptRoot/SharedFunctions.ps1"

param(
  [Parameter(Mandatory)][string]$HubsFolder,
  [string]$HubsFilter = "all",
  [bool]$CanaryMode = $false,
  [string]$CanaryHubCode = "AZS"
)

$hubFiles = Get-HubTemplates -HubsFolder $HubsFolder -HubsFilter $HubsFilter -CanaryMode:$CanaryMode -CanaryHubCode $CanaryHubCode

foreach ($f in $hubFiles) {
  $h = Read-YamlFile $f.FullName

  $publisher = $h.nva.publisher
  $offer     = $h.nva.offer
  $plan      = $h.nva.plan
  $version   = $h.nva.version

  if (-not $publisher -or -not $offer -or -not $plan) {
    throw "$($f.Name): Missing nva.publisher/offer/plan"
  }

  # Try VM image URN acceptance (common for FortiGate VM images)
  if ($version) {
    $urn = "$publisher:$offer:$plan:$version"
    Write-Info "$($f.Name): attempting vm image terms accept for URN: $urn"
    try {
      Az "vm image terms accept --urn $urn" | Out-Null
      continue
    } catch {
      Write-Warn "$($f.Name): vm image terms accept failed; will try marketplace agreement accept instead."
    }
  }

  # Fallback: marketplace agreement (common for managed applications)
  Write-Info "$($f.Name): attempting marketplace agreement accept: $publisher / $offer / $plan"
  Az "marketplace agreement accept --publisher $publisher --offer $offer --plan $plan" | Out-Null
}

Write-Info "Preflight terms acceptance complete."
