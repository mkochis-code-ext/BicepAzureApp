@description('The name of the virtual network')
param name string

@description('The Azure region where the virtual network will be created')
param location string

@description('The address prefix for the virtual network')
param addressPrefix string

@description('Array of subnets to create')
param subnets array

@description('Tags to apply to the virtual network')
param tags object = {}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
        delegations: subnet.?delegations ?? []
        networkSecurityGroup: subnet.?networkSecurityGroupId != null ? {
          id: subnet.networkSecurityGroupId
        } : null
        privateEndpointNetworkPolicies: subnet.?privateEndpointNetworkPolicies ?? 'Disabled'
        privateLinkServiceNetworkPolicies: subnet.?privateLinkServiceNetworkPolicies ?? 'Enabled'
      }
    }]
  }
}

@description('The name of the created virtual network')
output name string = virtualNetwork.name

@description('The resource ID of the created virtual network')
output id string = virtualNetwork.id

@description('The subnet resource IDs')
output subnetIds array = [for i in range(0, length(subnets)): virtualNetwork.properties.subnets[i].id]

@description('The subnet details')
output subnets array = [for i in range(0, length(subnets)): {
  name: virtualNetwork.properties.subnets[i].name
  id: virtualNetwork.properties.subnets[i].id
  addressPrefix: virtualNetwork.properties.subnets[i].properties.addressPrefix
}]
