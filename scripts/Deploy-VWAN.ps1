param(
    [Parameter(Mandatory = $true)]
    [string] $TemplatePath
)

# Fail fast and catch issues early
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Dot-source shared helpers (note the leading dot)
. "$PSScriptRoot/SharedFunctions.ps1"

# Basic validation
if (-not (Test-Path -LiteralPath $TemplatePath)) {
    throw "TemplatePath not found: $TemplatePath"
}

# Load and validate YAML
$v = Read-YamlFile -Path $TemplatePath
if ($v.kind -ne "vwan") {
    throw "Expected kind=vwan in $TemplatePath"
}

# Ensure RG exists
Ensure-ResourceGroup -Name $v.resourceGroup.name -Location $v.resourceGroup.location

# Resolve Bicep path
$bicep = BicepPath "biceps/Deploy_virtual_wan_avm.bicep"

# Build parameters
$params = @{
    virtualWans_global_vwan_name = $v.name
    location                     = $v.location
}

# Write params to a temp file
$tmp = New-TemporaryFile
try {
    $params | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $tmp -Encoding utf8

    $dep = "vwan-$($v.name)-$($v.resourceVersion)"

    # Use helper to invoke az
    Az "deployment group create -g $($v.resourceGroup.name) -n $dep -f `"$bicep`" -p `"$tmp`"" | Out-Null

    Write-Info "VWAN deployed: $dep"
}
finally {
    # Clean up temp file
    if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
}
