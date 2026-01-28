@description('The base name for the app service resources')
param name string

@description('The Azure region where resources will be created')
param location string

@description('The SKU for the App Service Plan')
param sku object = {
  name: 'S1'
  tier: 'Standard'
  capacity: 1
}

@description('The runtime stack for the web app')
param linuxFxVersion string = 'NODE|20-lts'

@description('Enable VNet integration')
param enableVnetIntegration bool = false

@description('The subnet ID for VNet integration')
param vnetIntegrationSubnetId string = ''

@description('Subnet CIDR ranges allowed to access the app (e.g., Application Gateway subnet)')
param allowedSubnetCidrs array = []

@description('Tags to apply to the resources')
param tags object = {}

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: 'asp-${name}'
  location: location
  tags: tags
  sku: sku
  kind: 'linux'
  properties: {
    reserved: true
  }
}

// Web App
resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: 'app-${name}'
  location: location
  tags: tags
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    vnetRouteAllEnabled: enableVnetIntegration
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      minTlsVersion: '1.2'
      ftpsState: 'Disabled'
      http20Enabled: true
      alwaysOn: true
      ipSecurityRestrictions: [for (cidr, i) in allowedSubnetCidrs: {
        ipAddress: cidr
        action: 'Allow'
        priority: 100 + i
        name: 'AllowAppGatewaySubnet${i}'
        description: 'Allow traffic from Application Gateway subnet'
      }]
      scmIpSecurityRestrictionsUseMain: true
    }
  }
}

// VNet Integration
resource vnetConnection 'Microsoft.Web/sites/virtualNetworkConnections@2023-12-01' = if (enableVnetIntegration && !empty(vnetIntegrationSubnetId)) {
  parent: webApp
  name: 'vnetIntegration'
  properties: {
    vnetResourceId: vnetIntegrationSubnetId
    isSwift: true
  }
}

@description('The name of the App Service Plan')
output appServicePlanName string = appServicePlan.name

@description('The resource ID of the App Service Plan')
output appServicePlanId string = appServicePlan.id

@description('The name of the Web App')
output webAppName string = webApp.name

@description('The resource ID of the Web App')
output webAppId string = webApp.id

@description('The default hostname of the Web App')
output webAppHostName string = webApp.properties.defaultHostName

@description('The default URL of the Web App')
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
