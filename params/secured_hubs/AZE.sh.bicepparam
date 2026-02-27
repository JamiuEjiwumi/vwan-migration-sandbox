using '../../biceps/Deploy_secure_hub.bicep'

// REGION PARAM
param regionCode = 'AZE'


// PARENT HUB PARAMS
param hubAddressPrefix = '10.156.250.0/24'
param location = 'westeurope'


// NVA PARAMS
param fortiGateImageVersion = '7.4.8'
param scaleUnit = '4'
param fortiGateASN = '65252'


// OPTIONAL NVA PARAMS
  // LEAVE AS '' IF UNUSED
param fortiManagerIP = ''
param fortiManagerSerial = ''
