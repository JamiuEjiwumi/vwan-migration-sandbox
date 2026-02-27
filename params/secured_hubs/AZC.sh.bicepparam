using '../../biceps/Deploy_secure_hub.bicep'

// REGION PARAM
param regionCode = 'AZC'


// PARENT HUB PARAMS
param hubAddressPrefix = '10.145.255.0/24'
param location = 'centralus'


// NVA PARAMS
param fortiGateImageVersion = '7.4.8'
param scaleUnit = '2'
param fortiGateASN = '65055'


// OPTIONAL NVA PARAMS
  // LEAVE AS '' IF UNUSED
param fortiManagerIP = ''
param fortiManagerSerial = ''


