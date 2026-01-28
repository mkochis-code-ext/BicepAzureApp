@description('The name of the application gateway')
param name string

@description('The Azure region where the application gateway will be created')
param location string

@description('The subnet ID for the application gateway')
param subnetId string

@description('The backend address pool - array of FQDNs or IP addresses')
param backendAddresses array

@description('SKU configuration for the application gateway')
param sku object = {
  name: 'Standard_v2'
  tier: 'Standard_v2'
}

@description('Autoscale configuration')
param autoscaleConfiguration object = {
  minCapacity: 1
  maxCapacity: 2
}

@description('Tags to apply to the application gateway')
param tags object = {}

// Public IP for Application Gateway
resource publicIp 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: 'pip-${name}'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource applicationGateway 'Microsoft.Network/applicationGateways@2023-11-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    sku: {
      name: sku.name
      tier: sku.tier
    }
    autoscaleConfiguration: {
      minCapacity: autoscaleConfiguration.minCapacity
      maxCapacity: autoscaleConfiguration.maxCapacity
    }
    gatewayIPConfigurations: [
      {
        name: 'gatewayIpConfig'
        properties: {
          subnet: {
            id: subnetId
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'frontendIpConfig'
        properties: {
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'httpPort'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'backendPool'
        properties: {
          backendAddresses: [for address in backendAddresses: {
            fqdn: address
          }]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'backendHttpSettings'
        properties: {
          port: 443
          protocol: 'Https'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: true
          requestTimeout: 30
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', name, 'healthProbe')
          }
        }
      }
    ]
    httpListeners: [
      {
        name: 'httpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', name, 'frontendIpConfig')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', name, 'httpPort')
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'routingRule'
        properties: {
          ruleType: 'Basic'
          priority: 100
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', name, 'httpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', name, 'backendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', name, 'backendHttpSettings')
          }
        }
      }
    ]
    probes: [
      {
        name: 'healthProbe'
        properties: {
          protocol: 'Https'
          path: '/'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: true
          minServers: 0
          match: {
            statusCodes: [
              '200-399'
            ]
          }
        }
      }
    ]
  }
}

@description('The name of the application gateway')
output name string = applicationGateway.name

@description('The resource ID of the application gateway')
output id string = applicationGateway.id

@description('The public IP address of the application gateway')
output publicIpAddress string = publicIp.properties.ipAddress

@description('The public IP resource ID')
output publicIpId string = publicIp.id
