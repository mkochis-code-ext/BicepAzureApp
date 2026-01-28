targetScope = 'subscription'

@description('Configuration for the project deployment')
param config object

// Resource Group Module
module resourceGroup '../modules/azurerm/resource_group/main.bicep' = {
  params: {
    name: config.resourceGroupName
    location: config.location
    tags: config.tags
  }
}

// Network Security Groups
module appServiceNsg '../modules/azurerm/network_security_group/main.bicep' = if (config.?network != null) {
  scope: az.resourceGroup(config.resourceGroupName)
  params: {
    name: 'nsg-${config.appServiceName}-appservice'
    location: config.location
    tags: config.tags
    securityRules: []
  }
  dependsOn: [
    resourceGroup
  ]
}

module appGatewayNsg '../modules/azurerm/network_security_group/main.bicep' = if (config.?network != null) {
  scope: az.resourceGroup(config.resourceGroupName)
  params: {
    name: 'nsg-${config.appServiceName}-appgateway'
    location: config.location
    tags: config.tags
    securityRules: [
      {
        name: 'AllowGatewayManager'
        protocol: 'Tcp'
        sourcePortRange: '*'
        destinationPortRange: '65200-65535'
        sourceAddressPrefix: 'GatewayManager'
        destinationAddressPrefix: '*'
        access: 'Allow'
        priority: 100
        direction: 'Inbound'
      }
      {
        name: 'AllowHTTP'
        protocol: 'Tcp'
        sourcePortRange: '*'
        destinationPortRange: '80'
        sourceAddressPrefix: 'Internet'
        destinationAddressPrefix: '*'
        access: 'Allow'
        priority: 110
        direction: 'Inbound'
      }
      {
        name: 'AllowHTTPS'
        protocol: 'Tcp'
        sourcePortRange: '*'
        destinationPortRange: '443'
        sourceAddressPrefix: 'Internet'
        destinationAddressPrefix: '*'
        access: 'Allow'
        priority: 120
        direction: 'Inbound'
      }
    ]
  }
  dependsOn: [
    resourceGroup
  ]
}

// Virtual Network
var hasNetwork = config.?network != null

module virtualNetwork '../modules/azurerm/virtual_network/main.bicep' = if (hasNetwork) {
  scope: az.resourceGroup(config.resourceGroupName)
  params: {
    name: 'vnet-${config.appServiceName}'
    location: config.location
    addressPrefix: config.?network.?vnetAddressPrefix ?? '10.0.0.0/16'
    tags: config.tags
    subnets: [
      {
        name: 'snet-appservice'
        addressPrefix: config.?network.?appServiceSubnetPrefix ?? '10.0.1.0/24'
        delegations: [
          {
            name: 'appServiceDelegation'
            properties: {
              serviceName: 'Microsoft.Web/serverFarms'
            }
          }
        ]
        networkSecurityGroupId: appServiceNsg.?outputs.?id ?? ''
      }
      {
        name: 'snet-appgateway'
        addressPrefix: config.?network.?appGatewaySubnetPrefix ?? '10.0.2.0/24'
        networkSecurityGroupId: appGatewayNsg.?outputs.?id ?? ''
      }
      {
        name: 'snet-privateendpoints'
        addressPrefix: config.?network.?privateEndpointSubnetPrefix ?? '10.0.3.0/24'
        privateEndpointNetworkPolicies: 'Disabled'
      }
    ]
  }
  dependsOn: [
    resourceGroup
  ]
}

// Private DNS Zone for App Service
module privateDnsZone '../modules/azurerm/private_dns_zone/main.bicep' = if (hasNetwork) {
  scope: az.resourceGroup(config.resourceGroupName)
  params: {
    name: 'privatelink.azurewebsites.net'
    virtualNetworkId: virtualNetwork.?outputs.?id ?? ''
    tags: config.tags
  }
  dependsOn: [
    resourceGroup
  ]
}

// App Service Module
module appService '../modules/azurerm/app_service/main.bicep' = {
  scope: az.resourceGroup(config.resourceGroupName)
  params: {
    name: config.appServiceName
    location: config.location
    sku: config.appServiceSku
    linuxFxVersion: config.linuxFxVersion
    tags: config.tags
    enableVnetIntegration: hasNetwork
    vnetIntegrationSubnetId: virtualNetwork.?outputs.?subnets[0].?id ?? ''
    allowedSubnetCidrs: hasNetwork ? [
      config.?network.?appGatewaySubnetPrefix ?? '10.0.2.0/24'
    ] : []
  }
  dependsOn: [
    resourceGroup
  ]
}

// Private Endpoint for App Service
module privateEndpoint '../modules/azurerm/private_endpoint/main.bicep' = if (hasNetwork) {
  scope: az.resourceGroup(config.resourceGroupName)
  params: {
    name: 'pe-${config.appServiceName}'
    location: config.location
    subnetId: virtualNetwork.?outputs.?subnets[2].?id ?? ''
    privateLinkServiceId: appService.outputs.webAppId
    groupIds: ['sites']
    privateDnsZoneId: privateDnsZone.?outputs.?id ?? ''
    tags: config.tags
  }
  dependsOn: [
    resourceGroup
  ]
}

// Application Gateway
module applicationGateway '../modules/azurerm/application_gateway/main.bicep' = if (hasNetwork) {
  scope: az.resourceGroup(config.resourceGroupName)
  params: {
    name: 'agw-${config.appServiceName}'
    location: config.location
    subnetId: virtualNetwork.?outputs.?subnets[1].?id ?? ''
    backendAddresses: [
      appService.outputs.webAppHostName
    ]
    tags: config.tags
  }
  dependsOn: [
    resourceGroup
  ]
}

@description('The name of the created resource group')
output resourceGroupName string = resourceGroup.outputs.name

@description('The resource ID of the created resource group')
output resourceGroupId string = resourceGroup.outputs.id

@description('The name of the App Service Plan')
output appServicePlanName string = appService.outputs.appServicePlanName

@description('The name of the Web App')
output webAppName string = appService.outputs.webAppName

@description('The URL of the Web App')
output webAppUrl string = appService.outputs.webAppUrl

@description('The Application Gateway public IP address')
output applicationGatewayPublicIp string = applicationGateway.?outputs.?publicIpAddress ?? ''

@description('The Virtual Network name')
output virtualNetworkName string = virtualNetwork.?outputs.?name ?? ''

@description('The Private DNS Zone name')
output privateDnsZoneName string = privateDnsZone.?outputs.?name ?? ''

@description('The Private Endpoint name')
output privateEndpointName string = privateEndpoint.?outputs.?name ?? ''
