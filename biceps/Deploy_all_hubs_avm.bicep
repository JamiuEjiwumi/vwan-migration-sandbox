// HUB PARAMS
@description('Name of existing virtual wan resource')
param vWanName string = 'vwan-test-deploy'

@description('Resource Group of existing virtual wan resource')
param vWanRG string = 'test-vwan-deployment'

@description('List of all hubs and parameters')
param hubs array

// IMPORT EXISTING VWAN
resource vWan 'Microsoft.Network/virtualWans@2025-01-01' existing = {
  name: vWanName
  scope: resourceGroup(vWanRG)
}

module virtualHub 'br/public:avm/res/network/virtual-hub:0.4.3' = [ for vhub in hubs: {
  params: {
    addressPrefix: vhub.hubAddressPrefix
    name: '${vhub.location}-vHub-Deployment'
    virtualWanResourceId: vWan.id
    allowBranchToBranchTraffic: true
    hubRoutingPreference: 'ASPath'
    location: vhub.location
  }
}
]
