// REGION PARAM
@description('3-4 digit code to represent region - used to generate other names')
param regionCode string


// HUB PARAMS
@description('Location where all resources will be created.')
param location string

@description('Name of the Virtual Hub. A virtual hub is created inside a virtual wan.')
param hubName string = '${regionCode}-${location}-vHub'

@description('Name of the Virtual Hub. A virtual hub is created inside a virtual wan.')
param uamiName string = '${regionCode}-${location}-UAMI'

@description('The hub address prefix. This address prefix will be used as the address prefix for the hub vnet')
param hubAddressPrefix string


// NVA PARAMS
@description('Name of NVA Application Resource in Azure')
param NvaName string = '${regionCode}-vHub-NVA'

@description('Will be used as prefix for NVA name - not Azure resource name')
param fortiGateNamePrefix string = regionCode

@description('Firmware version for fortigates - Recommend 7.2.6')
@allowed([
  '7.4.8'
  '7.4.10'
//  '7.4.2'
])
param fortiGateImageVersion string = '7.4.8'

@description('The scale unit size to deploy')
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

@description('BGP ASN to be used on FortiGates')
param fortiGateASN string

@description('Generates router addresses based on supplied /24 in hubAddressPrefix')
param hubRouter1 string = replace(hubAddressPrefix, '0/24', '68')
param hubRouter2 string = replace(hubAddressPrefix, '0/24', '69')

@description('Virtual WAN Hub Router IPs - always .68 and .69 in hub address space')
param hubRouters array = [hubRouter1, hubRouter2]

@description('FortiManager IP or DNS name to connect to on port TCP/541')
param fortiManagerIP string

@description('FortiManager serial number to add the deployed FortiGate into the FortiManager')
param fortiManagerSerial string

// OPTIONAL OVERRIDES
@description('Admin username for FortiGates (optional override)')
param adminUsername string = 'IManager'

@description('Admin password for FortiGates (override via GitHub Secret)')
@secure()
param adminPassword string
// 'CdPYV!PwW9FW7%hRt!'


// IMPORT EXISTING HUB
resource hub 'Microsoft.Network/virtualHubs@2025-01-01' existing = {
  name: hubName
}

// DEPLOY NVA TO HUB
module nva '../modules/nva.bicep' = {
  name: '${regionCode}-Deploy'
  params: {
    location: location
    fortiGateASN: fortiGateASN
    fortiGateImageVersion: fortiGateImageVersion
    fortiGateNamePrefix: fortiGateNamePrefix
    fortiManagerIP: fortiManagerIP
    fortiManagerSerial: fortiManagerSerial
    adminUsername: adminUsername
    adminPassword: adminPassword
    hubID: hub.id
    hubRouters: hubRouters
    NvaName: NvaName
    scaleUnit: scaleUnit
    uamiName: uamiName
    regionCode: regionCode
  }
}

// resource defaultRouteTable 'Microsoft.Network/virtualHubs/hubRouteTables@2024-07-01' = {
//   parent: hub
//   name: 'defaultRouteTable'
//   properties: {
//     routes: [
//       {
//         name: '_policy_Internet'
//         destinationType: 'CIDR'
//         destinations: [
//           '0.0.0.0/0'
//         ]
//         nextHopType: 'ResourceId'
//         nextHop: nva.outputs.nvaID
        
//       }
//       {
//         name: '_policy_PrivateTraffic'
//         destinationType: 'CIDR'
//         destinations: [
//           '10.0.0.0/8'
//           '172.16.0.0/12'
//           '192.168.0.0/16'
//         ]
//         nextHopType: 'ResourceId'
//         nextHop: nva.outputs.nvaID
//       }
//     ]
//     labels: [
//       'default'
//     ]
//   }
// }

resource RoutingIntent 'Microsoft.Network/virtualHubs/routingIntent@2024-07-01' = {
  parent: hub
  name: 'hubRoutingIntent'
  properties: {
    routingPolicies: [
      {
        name: 'Internet'
        destinations: [
          'Internet'
        ]
        nextHop: nva.outputs.nvaName
      }
      {
        name: 'PrivateTraffic'
        destinations: [
          'PrivateTraffic'
        ]
        nextHop: nva.outputs.nvaName
      }
    ]
  }
}
