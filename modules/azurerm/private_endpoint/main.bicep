@description('The name of the private endpoint')
param name string

@description('The Azure region where the private endpoint will be created')
param location string

@description('The subnet ID for the private endpoint')
param subnetId string

@description('The resource ID of the service to connect to')
param privateLinkServiceId string

@description('The group IDs for the private endpoint (e.g., sites for App Service)')
param groupIds array

@description('The private DNS zone ID for DNS integration')
param privateDnsZoneId string

@description('Tags to apply to the private endpoint')
param tags object = {}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: name
        properties: {
          privateLinkServiceId: privateLinkServiceId
          groupIds: groupIds
        }
      }
    ]
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

@description('The name of the private endpoint')
output name string = privateEndpoint.name

@description('The resource ID of the private endpoint')
output id string = privateEndpoint.id

@description('The private IP address')
output privateIpAddress string = privateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]
