using '../../biceps/Deploy_secure_hub.bicep'

// REGION PARAM
param regionCode = 'ACI'


// PARENT HUB PARAMS
param hubAddressPrefix = '10.161.255.0/24'
param location = 'centralindia'


// NVA PARAMS
param fortiGateImageVersion = '7.4.8'
param scaleUnit = '2'
param fortiGateASN = '65454'


// OPTIONAL NVA PARAMS
  // LEAVE AS '' IF UNUSED
param fortiManagerIP = ''
param fortiManagerSerial = ''
