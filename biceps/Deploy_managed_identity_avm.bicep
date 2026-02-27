// Creates a UAMI in the current resource group scope and assigns Contributor at subscription scope.
// Uses AVM modules.

param uamiName string
param location string

module userAssignedIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.5.0' = {
  params: {
    name: uamiName
    location: location
    isolationScope: 'Regional'
  }
}

module roleAssignment 'br/public:avm/res/authorization/role-assignment/sub-scope:0.1.0' = {
  scope: subscription()
  params: {
    principalId: userAssignedIdentity.outputs.principalId
    roleDefinitionIdOrName: 'Contributor'
    principalType: 'ServicePrincipal'
  }
}

output principalId string = userAssignedIdentity.outputs.principalId
