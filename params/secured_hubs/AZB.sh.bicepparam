using '../../biceps/Deploy_secure_hub.bicep'

// REGION PARAM
param regionCode = 'AZB'


// PARENT HUB PARAMS
param hubAddressPrefix = '10.146.255.0/24'
param location = 'brazilsouth'


// NVA PARAMS
param fortiGateImageVersion = '7.4.8'
param scaleUnit = '4'
param fortiGateASN = '65056'


// OPTIONAL NVA PARAMS
  // LEAVE AS '' IF UNUSED
param fortiManagerIP = ''
param fortiManagerSerial = ''
