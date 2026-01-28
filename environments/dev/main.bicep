targetScope = 'subscription'

// Import project orchestration
module project '../../project/main.bicep' = {
  params: {
    config: {
      resourceGroupName: 'rg-myapp-dev'
      location: 'canadacentral'
      appServiceName: 'myapp-dev-${uniqueString(subscription().subscriptionId)}'
      appServiceSku: {
        name: 'S1'
        tier: 'Standard'
        capacity: 1
      }
      linuxFxVersion: 'NODE|20-lts'
      network: {
        vnetAddressPrefix: '10.0.0.0/16'
        appServiceSubnetPrefix: '10.0.1.0/24'
        appGatewaySubnetPrefix: '10.0.2.0/24'
        privateEndpointSubnetPrefix: '10.0.3.0/24'
      }
      tags: {
        Environment: 'Development'
        ManagedBy: 'Bicep'
        Project: 'MyApp'
      }
    }
  }
}

@description('The name of the created resource group')
output resourceGroupName string = project.outputs.resourceGroupName

@description('The name of the App Service Plan')
output appServicePlanName string = project.outputs.appServicePlanName

@description('The name of the Web App')
output webAppName string = project.outputs.webAppName

@description('The direct URL of the Web App (blocked from public access)')
output webAppUrl string = project.outputs.webAppUrl

@description('The Application Gateway public IP (use this to access the app)')
output applicationGatewayPublicIp string = project.outputs.applicationGatewayPublicIp

@description('The Virtual Network name')
output virtualNetworkName string = project.outputs.virtualNetworkName

@description('The Private DNS Zone name')
output privateDnsZoneName string = project.outputs.privateDnsZoneName

@description('The Private Endpoint name')
output privateEndpointName string = project.outputs.privateEndpointName
