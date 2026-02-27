# Octave VWAN Migration Pipeline

## Overview
This pipeline orchestrates the redeployment of the Global Virtual WAN backbone from the existing Hexagon Azure tenant into the new Octave Azure tenant using the existing working Bicep infrastructure.

The goal of this repository is not to author new infrastructure, but to:
- Recreate the VWAN backbone in Octave
- Deploy virtual hubs
- Attach Fortinet NVAs
- Apply routing intent
- Reconnect VNets (spokes)

All deployments are executed using:
- Existing Bicep templates
- Regional .bicepparam files
- YAML deployment intent
- PowerShell orchestration scripts
- GitHub Actions (OIDC login)

## Deployment Order of Operations
The pipeline enforces the following deployment sequence:
1. Deploy Virtual WAN
2. Deploy base virtual hubs
3. Create User Assigned Managed Identity (UAMI) per hub
4. Assign Contributor RBAC to UAMI at subscription scope
5. Deploy Fortinet NVA (managed application) into hub
6. Apply Routing Intent (depends on NVA)
7. Connect VNets to hubs (hubVirtualNetworkConnections)

## Required GitHub Environment
Create:
octave-prod
via:
Repo → Settings → Environments

## Required GitHub Secrets
AZURE_CLIENT_ID
AZURE_TENANT_ID
AZURE_SUBSCRIPTION_ID
FORTIMANAGER_IP
FORTIMANAGER_SERIAL
FORTIGATE_ADMIN_PASSWORD

## Required Azure Permissions
The GitHub OIDC Service Principal must have:
Contributor
User Access Administrator
at:
Subscription Scope

## Running the Pipeline
Navigate to:
Actions → Octave VWAN Migration

Run with:
environment: octave-prod
canary_mode: true
canary_hub_code: AZS
hubs_filter: AZS
connect_vnets: false

This deploys a single canary hub.

## Full Deployment
After successful canary:
canary_mode: false
hubs_filter: all
connect_vnets: false

Reconnect VNets only after NVA deployment is stable.

## Notes
- Marketplace terms must be accepted in Octave tenant before NVA deployment.
- RBAC propagation delay may impact managed application deployment.
- VNets may reside in separate subscriptions and require additional permissions.
