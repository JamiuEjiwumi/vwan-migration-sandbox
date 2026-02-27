param(
    [Parameter(Mandatory = $true)]
    [string] $TemplatePath
)

# --- Hardening (optional but recommended)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Dot-source shared functions (MUST be *after* param, note the leading dot)
. "$PSScriptRoot/SharedFunctions.ps1"

# --- Basic validation
if (-not (Test-Path -LiteralPath $TemplatePath)) {
    throw "TemplatePath not found: $TemplatePath"
}

# --- Load and validate YAML
$v = Read-YamlFile -Path $TemplatePath
if ($v.kind -ne "vwan") {
    throw "Expected kind=vwan in $TemplatePath"
}

# --- Ensure RG exists
Ensure-ResourceGroup -Name $v.resourceGroup.name -Location $v.resourceGroup.location

# --- Resolve Bicep path
$bicep = BicepPath "biceps/Deploy_virtual_wan_avm.bicep"

# --- Build parameters
$params = @{
    virtualWans_global_vwan_name = $v.name
    location                     = $v.location
}

# --- Temp parameters file and deploy
$tmp = New-TemporaryFile
try {
    $params | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $tmp -Encoding utf8

    $dep = "vwan-$($v.name)-$($v.resourceVersion)"

    Az "deployment group create -g $($v.resourceGroup.name) -n $dep -f `"$bicep`" -p `"$tmp`"" | Out-Null
    Write-Info "VWAN deployed: $dep"
}
finally {
    if (Test-Path -LiteralPath $tmp) {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
    }
}
``
