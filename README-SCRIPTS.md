# Migration Orchestration Scripts

These scripts automate the redeployment of VWAN infrastructure into the Octave tenant.

Infrastructure logic resides in:
/biceps

Scripts orchestrate deployment only.

## Script Responsibilities
Deploy-VWAN.ps1 - Deploy Virtual WAN backbone
Deploy-vHubs.ps1 - Deploy base Virtual Hubs
Deploy-UAMI.ps1 - Create Managed Identity per hub
Deploy-RBAC.ps1 - Assign Contributor role to UAMI
Wait-RbacPropagation.ps1 - Ensure RBAC propagation before NVA
Deploy-NVA.ps1 - Deploy Fortinet managed application
Deploy-RoutingIntent.ps1 - Apply hub routing intent
Deploy-VHubVnetConnections.ps1 - Connect VNets to hubs
Validate-YamlSchemas.ps1 - Validate YAML deployment templates
Validate-Stage.ps1 - Post-deployment verification
Preflight-AcceptFortinetTerms.ps1 - Accept Fortinet marketplace terms

## Local Testing Requirements
winget install Microsoft.PowerShell
Install-Module powershell-yaml -Scope CurrentUser -Force
Install-Module Az -Scope CurrentUser -Force

Login:
az login --tenant <OCTAVE_TENANT_ID>
az account set --subscription <SUB_ID>

## Canary Deployment Test
pwsh -File scripts/Deploy-VWAN.ps1 -TemplatePath resourceTemplates/vwan/vwan-global.yaml

pwsh -File scripts/Deploy-vHubs.ps1 -HubsFolder resourceTemplates/hubs -HubsFilter AZS -CanaryMode $true -CanaryHubCode AZS

pwsh -File scripts/Deploy-UAMI.ps1 -HubsFolder resourceTemplates/hubs -HubsFilter AZS -CanaryMode $true -CanaryHubCode AZS

pwsh -File scripts/Deploy-RBAC.ps1 -HubsFolder resourceTemplates/hubs -HubsFilter AZS -CanaryMode $true -CanaryHubCode AZS

pwsh -File scripts/Deploy-NVA.ps1 -HubsFolder resourceTemplates/hubs -HubsFilter AZS -CanaryMode $true -CanaryHubCode AZS -FortiManagerIP $env:FORTIMANAGER_IP -FortiManagerSerial $env:FORTIMANAGER_SERIAL

## Known Risks
- RBAC assignment propagation delay
- Marketplace agreement requirements
- Cross-subscription VNet connections
- Tenant-specific object IDs
- Resource provider registration differences
