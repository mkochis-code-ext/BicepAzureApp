@description('The name of the private DNS zone')
param name string

@description('The virtual network ID to link to')
param virtualNetworkId string

@description('Tags to apply to the private DNS zone')
param tags object = {}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: name
  location: 'global'
  tags: tags
}

resource privateDnsZoneVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: '${name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetworkId
    }
  }
}

@description('The name of the private DNS zone')
output name string = privateDnsZone.name

@description('The resource ID of the private DNS zone')
output id string = privateDnsZone.id
