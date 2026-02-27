param hubName string
param connectionName string = ''
param vnet1Name string
param vnet1RG string
param vnetSubscriptionId string = ''

resource hub 'Microsoft.Network/virtualHubs@2023-09-01' existing = {
  name: hubName
}

var vnetScope = empty(vnetSubscriptionId) ? resourceGroup(vnet1RG) : resourceGroup(vnetSubscriptionId, vnet1RG)

resource vnet1 'Microsoft.Network/virtualNetworks@2020-05-01' existing = {
  name: vnet1Name
  scope: vnetScope
}

resource vnetConn 'Microsoft.Network/virtualHubs/hubVirtualNetworkConnections@2023-09-01' = {
  name: empty(connectionName) ? '${vnet1Name}-2-${hubName}' : connectionName
  parent: hub
  properties: {
    remoteVirtualNetwork: {
      id: vnet1.id
    }
    allowHubToRemoteVnetTransit: true
    allowRemoteVnetToUseHubVnetGateways: true
    enableInternetSecurity: true
  }
}
