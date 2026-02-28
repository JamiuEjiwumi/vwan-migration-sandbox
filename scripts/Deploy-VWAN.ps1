param(
  [Parameter(Mandatory)]
  [string]$TemplatePath
)

. "$PSScriptRoot/SharedFunctions.ps1"

$v = Read-YamlFile $TemplatePath
if ($v.kind -ne "vwan") { throw "Expected kind=vwan in $TemplatePath" }

Ensure-ResourceGroup -name $v.resourceGroup.name -location $v.resourceGroup.location

$bicep = BicepPath "biceps/Deploy_virtual_wan_avm.bicep"

$params = @{
  virtualWans_global_vwan_name = $v.name
  location                    = $v.location
}

$tmp = New-TemporaryFile
$params | ConvertTo-Json -Depth 10 | Set-Content $tmp -Encoding utf8

$dep = "vwan-$($v.name)-$($v.resourceVersion)"

Invoke-Invoke-AzCliCli @(
  "deployment","group","create",
  "-g", $v.resourceGroup.name,
  "-n", $dep,
  "-f", $bicep,
  "-p", $tmp
) | Out-Null

Write-Info "VWAN deployed: $dep"
