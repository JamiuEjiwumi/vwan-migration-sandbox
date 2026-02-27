using '../../biceps/Deploy_secure_hub.bicep'

// REGION PARAM
param regionCode = 'ASA'


// PARENT HUB PARAMS
param hubAddressPrefix = '10.158.255.0/24'
param location = 'southafricanorth'


// NVA PARAMS
param fortiGateImageVersion = '7.4.8'
param scaleUnit = '2'
param fortiGateASN = '65254'


// OPTIONAL NVA PARAMS
  // LEAVE AS '' IF UNUSED
param fortiManagerIP = ''
param fortiManagerSerial = ''
