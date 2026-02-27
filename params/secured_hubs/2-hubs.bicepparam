using '../../biceps/Deploy_all_hubs.bicep'

param hubs = [
    {
    regionCode: 'AZS' // Name must match deployed site
    location: 'southcentralus'
    hubAddressPrefix: '10.144.255.0/24'
    // unused params below - these params are in the individual reg.sh param files
    fortiGateImageVersion: '7.2.7'
    scaleUnit: '2'
    fortiGateASN: '65054'
    
    }
    {
    regionCode: 'AZC' // Name must match deployed site
    location: 'centralus'
    hubAddressPrefix: '10.145.255.0/24'
    fortiGateImageVersion: '7.2.7'
    scaleUnit: '2'
    fortiGateASN: '65055'
    }
  ]
