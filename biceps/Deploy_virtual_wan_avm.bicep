param virtualWans_global_vwan_name string = 'vwan-test-deploy'
param location string = 'southcentralus'


module virtualWan 'br/public:avm/res/network/virtual-wan:0.4.0' = {
  params: {
    // Required parameters
    name: virtualWans_global_vwan_name
    location: location
    type: 'Standard'
    allowBranchToBranchTraffic: true
  }
}