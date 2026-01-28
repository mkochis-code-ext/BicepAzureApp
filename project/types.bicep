@description('Configuration object for the project')
type ProjectConfig = {
  @description('Name of the resource group')
  resourceGroupName: string
  
  @description('Azure region for all resources')
  location: string
  
  @description('Base name for the app service')
  appServiceName: string
  
  @description('App Service Plan SKU configuration')
  appServiceSku: {
    name: string
    tier: string
    capacity: int
  }
  
  @description('Linux runtime stack version')
  linuxFxVersion: string
  
  @description('Network configuration for VNet integration and Application Gateway')
  network: {
    @description('Virtual network address prefix')
    vnetAddressPrefix: string?
    
    @description('App Service subnet address prefix')
    appServiceSubnetPrefix: string?
    
    @description('Application Gateway subnet address prefix')
    appGatewaySubnetPrefix: string?
    
    @description('Private Endpoint subnet address prefix')
    privateEndpointSubnetPrefix: string?
  }?
  
  @description('Resource tags')
  tags: object
}
