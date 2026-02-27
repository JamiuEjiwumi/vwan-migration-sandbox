using '../../biceps/Deploy_secure_hub.bicep'

// REGION PARAM
param regionCode = 'ASU'


// PARENT HUB PARAMS
param hubAddressPrefix = '10.157.250.0/24'
param location = 'uksouth'


// NVA PARAMS
param fortiGateImageVersion = '7.4.8'
param scaleUnit = '2'
param fortiGateASN = '65253'


// OPTIONAL NVA PARAMS
  // LEAVE AS '' IF UNUSED
param fortiManagerIP = ''
param fortiManagerSerial = ''
