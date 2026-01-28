@description('The name of the network security group')
param name string

@description('The Azure region where the NSG will be created')
param location string

@description('Security rules for the NSG')
param securityRules array = []

@description('Tags to apply to the NSG')
param tags object = {}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    securityRules: [for rule in securityRules: {
      name: rule.name
      properties: {
        protocol: rule.protocol
        sourcePortRange: rule.?sourcePortRange ?? '*'
        destinationPortRange: rule.?destinationPortRange ?? '*'
        sourceAddressPrefix: rule.?sourceAddressPrefix ?? '*'
        destinationAddressPrefix: rule.?destinationAddressPrefix ?? '*'
        access: rule.access
        priority: rule.priority
        direction: rule.direction
        description: rule.?description ?? ''
      }
    }]
  }
}

@description('The name of the created NSG')
output name string = networkSecurityGroup.name

@description('The resource ID of the created NSG')
output id string = networkSecurityGroup.id
