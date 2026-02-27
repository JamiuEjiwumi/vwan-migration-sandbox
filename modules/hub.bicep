// API version updated 2/24/26
// HUB PARAMs
@description('Location where all resources will be created.')
param location string

@description('ID of existing virtual wan resource')
param virtualWanID string

@description('Name of the Virtual Hub. A virtual hub is created inside a virtual wan.')
param hubName string

@description('The hub address prefix. This address prefix will be used as the address prefix for the hub vnet')
param addressPrefix string

// CREATE HUB
resource hub 'Microsoft.Network/virtualHubs@2025-01-01' = {
  name: hubName
  location: location
  properties: {
    addressPrefix: addressPrefix
    allowBranchToBranchTraffic: true
    hubRoutingPreference: 'ASPath'
    virtualWan: {
      id: virtualWanID
    }
  }
}

output hubID string = hub.id
