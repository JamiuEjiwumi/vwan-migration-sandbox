// AAE missing
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
    {
    regionCode: 'AZB' // Name must match deployed site
    location: 'brazilsouth'
    hubAddressPrefix: '10.146.255.0/24'
    fortiGateImageVersion: '7.2.7'
    scaleUnit: '2'
    fortiGateASN: '65056'
    }
    {
    regionCode: 'AZE' // Name must match deployed site
    location: 'westeurope'
    hubAddressPrefix: '10.156.250.0/24'
    fortiGateImageVersion: '7.2.7'
    scaleUnit: '2'
    fortiGateASN: '65252'
    }
    {
    regionCode: 'ASU' // Name must match deployed site
    location: 'uksouth'
    hubAddressPrefix: '10.157.250.0/24'
    fortiGateImageVersion: '7.2.7'
    scaleUnit: '2'
    fortiGateASN: '65253'
    }
    {
    regionCode: 'ASA' // Name must match deployed site
    location: 'southafricanorth'
    hubAddressPrefix: '10.158.255.0/24'
    fortiGateImageVersion: '7.2.7'
    scaleUnit: '2'
    fortiGateASN: '65254'
    }
    {
    regionCode: 'AZI' // Name must match deployed site
    location: 'southindia'
    hubAddressPrefix: '10.160.255.0/24'
    fortiGateImageVersion: '7.2.7'
    scaleUnit: '2'
    fortiGateASN: '65453'
    }
    {
    regionCode: 'ACI' // Name must match deployed site
    location: 'centralindia'
    hubAddressPrefix: '10.161.255.0/24'
    fortiGateImageVersion: '7.2.7'
    scaleUnit: '2'
    fortiGateASN: '65454'
    }
    {
    regionCode: 'AZA' // Name must match deployed site
    location: 'australiaeast'
    hubAddressPrefix: '10.244.255.0/24'
    fortiGateImageVersion: '7.2.7'
    scaleUnit: '2'
    fortiGateASN: '65352'
    }
    {
    regionCode: 'ASE' // Name must match deployed site
    location: 'southeastasia'
    hubAddressPrefix: '10.245.255.0/24'
    fortiGateImageVersion: '7.2.7'
    scaleUnit: '2'
    fortiGateASN: '65353'
    }



































]
