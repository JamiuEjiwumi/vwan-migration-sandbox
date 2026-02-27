using '../../biceps/Deploy_secure_hub.bicep'

// REGION PARAM
param regionCode = 'AZA'


// PARENT HUB PARAMS
param hubAddressPrefix = '10.244.255.0/24'
param location = 'australiaeast'


// NVA PARAMS
param fortiGateImageVersion = '7.4.8'
param scaleUnit = '2'
param fortiGateASN = '65352'


// OPTIONAL NVA PARAMS
  // LEAVE AS '' IF UNUSED
param fortiManagerIP = ''
param fortiManagerSerial = ''
