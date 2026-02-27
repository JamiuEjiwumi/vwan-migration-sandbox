// NVA PARAMS
@description('Location where all resources will be created.')
param location string

@description('ID of existing virtual wan hub resource')
param hubID string

@description('ID of existing UAMI resource')
param uamiName string

@description('Name of NVA Application Resource in Azure')
param NvaName string


// HARDCODED USERNAME AND PASSWORD FOR INITIAL DEPLOYMENT - OPEN TO OPTIONS HERE
@description('Admin username of FortiGates')
param adminUsername string = 'IManager'

@description('Admin password of FortiGates (override via GitHub Secret)')
@secure()
param adminPassword string = 'CdPYV!PwW9FW7%hRt!'

@description('fortiGateNamePrefix is the name used as the hostname prefix on the fortigates - use a 3 digit code')
param fortiGateNamePrefix string

@description('NVA Fortigate licensing')
param vwandeploymentSKU string = 'ngfw-byol'

@description('Firmware version for fortigates - Recommend 7.2.6')
@allowed([
  '7.4.8'
  '7.4.10'
])
param fortiGateImageVersion string

@description('LICENSE SIZE - The scale unit size to deploy - 2 or 4')
@allowed([
  '2'
  '4'
  // '10'
  // '20'
  // '30'
  // '40'
  // '60'
  // '80'
])
param scaleUnit string

@description('BGP ASN to be used on FortiGates - must be unique')
param fortiGateASN string

@description('Virtual WAN Hub Router IPs - always .68 and .69 in hub address space')
param hubRouters array

@description('Virtual WAN Hub ASN - always 65515')
param hubASN string = '65515'

@description('FortiManager IP or DNS name to connect to on port TCP/541')
param fortiManagerIP string

@description('FortiManager serial number to add the deployed FortiGate into the FortiManager')
param fortiManagerSerial string

@description('Plan name associated with managed application plan')
param planName string = 'fortigate-managedvwan'

param product string = 'fortigate_vwan_nva'
param publisher string = 'fortinet'
param version string = '7.4.800250826'
param regionCode string

@description('Deployment type as defined by the selected managed applicaiton plan. i.e. ngfw or SDWAN')
param vwandeploymentType string = 'ngfw'


// CREATE MANAGED RESOURCE GROUP FOR NVA MANAGED APPLICATION
// param managedIdentity object = {}
param managedResourceGroupId string = ''
var randomManagedResourceGroupId = (empty(managedResourceGroupId) ? '${subscription().id}/resourceGroups/${take('${resourceGroup().name}-NVA-${uniqueString(resourceGroup().id)}${uniqueString(NvaName)}', 90)}' : managedResourceGroupId)
// var randomManagedResourceGroupId = (empty(managedResourceGroupId) ? '${subscription().id}/resourceGroups/${resourceGroup().name}-NVA-Managed-App' : managedResourceGroupId)

resource uami 'Microsoft.ManagedIdentity/userAssignedIdentities@2025-01-31-preview' existing = {
  name: uamiName
}
// will need to create UAMI and assign contrib to sub before continuing
// CREATE NVA IN HUB
resource Nva 'Microsoft.Solutions/applications@2021-07-01' = {
  location: location
  kind: 'MarketPlace'
  name: NvaName
  plan: {
    name: planName
    product: product
    publisher: publisher
    version: version
  }
  // identity: (empty(managedIdentity) ? null : managedIdentity) // This will need to be the UAMI.id
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: { 
      '${uami.id}': {}
    }
  }
  properties: {
    managedResourceGroupId: randomManagedResourceGroupId
    parameters: {
      adminUsername: {
        value: adminUsername
      }
      adminPassword: {
        value: adminPassword
      }
      fortiGateNamePrefix: {
        value: fortiGateNamePrefix
      }
      vwandeploymentSKU: {
        value: vwandeploymentSKU
      }
      managedApplicationPlan: {
        value: planName
      }
      vwandeploymentType: {
        value: vwandeploymentType
      }
      fortiGateImageVersion: {
        value: fortiGateImageVersion
      }
      hubId: {
        value: hubID
      }
      fortiGateASN: {
        value: fortiGateASN
      }
      tags: {
        value: null
      }
      scaleUnit: {
        value: scaleUnit
      }
      additionalNicCheck: {
        value: false
      }
      hubRouters: {
        value: hubRouters
      }
      hubASN: {
        value: hubASN
      }
      location: {
        value: location
      }
      fortiManagerIP: {
        value: fortiManagerIP
      }
      fortiManagerSerial: {
        value: fortiManagerSerial
      }
      internetInboundCheck: {
        value: false
      }
      nvaAdditionalCustomData: {
        value: ''
      }
      slbpiprg: {
        value: ''
      }
      slbpipname: {
        value: 'defaultslbpip'
      }
      slbPIpNewOrExisting: {
        value: 'none'
      }
      slbpublicIpDns: {
        value: ''
      }
      slbpublicIpSku: {
        value: 'Standard'
      }
    }
    jitAccessPolicy: null
  }
}

output nvaID string = Nva.id
output nvaName string = Nva.name
