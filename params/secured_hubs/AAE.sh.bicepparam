using '../../biceps/Deploy_secure_hub.bicep'

// REGION PARAM
param regionCode = 'AAE'


// PARENT HUB PARAMS
param hubAddressPrefix = '10.159.255.0/24'
param location = 'uaenorth'


// NVA PARAMS
param fortiGateImageVersion = '7.4.8'
param scaleUnit = '2'
param fortiGateASN = '65255'


// OPTIONAL NVA PARAMS
  // LEAVE AS '' IF UNUSED
param fortiManagerIP = ''
param fortiManagerSerial = ''
