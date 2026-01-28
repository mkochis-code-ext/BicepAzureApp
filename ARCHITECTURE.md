# Network Architecture

## 🌐 Overview

This deployment creates a secure, production-ready network architecture for hosting web applications with Application Gateway as the public-facing endpoint.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                         Internet                            │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ HTTP/HTTPS (Port 80/443)
                         ▼
┌─────────────────────────────────────────────────────────────┐
│            Application Gateway (Public IP)                  │
│                                                             │
│  - Standard_v2 SKU                                          │
│  - Public IP Address                                        │
│  - Health Probe: HTTPS / (30s interval)                     │
│  - Autoscale: 1-3 instances                                 │
│                                                             │
│  Subnet: 10.0.2.0/24 (snet-appgateway)                      │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ DNS Query: app-xyz.azurewebsites.net
                         ▼
┌─────────────────────────────────────────────────────────────┐
│           Private DNS Zone                                  │
│           privatelink.azurewebsites.net                     │
│                                                             │
│  Returns: 10.0.3.x (Private Endpoint IP)                    │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ Backend HTTPS to Private IP
                         │
┌────────────────────────▼────────────────────────────────────┐
│                    Virtual Network                          │
│                   (vnet-myapp-dev)                          │
│                    10.0.0.0/16                              │
│                                                             │
│  ┌────────────────────────────────────────────────────┐     │
│  │  Private Endpoint Subnet (snet-privateendpoints)   │     │
│  │  10.0.3.0/24                                       │     │
│  │                                                    │     │
│  │  ┌─────────────────────────────────────────┐       │     │
│  │  │   Private Endpoint                      │       │     │
│  │  │   IP: 10.0.3.x                          │       │     │
│  │  │   ↓ Private Link Connection             │       │     │
│  │  └─────────────────────────────────────────┘       │     │
│  └────────────────────────────────────────────────────┘     │
│                          ↓                                  │
│  ┌────────────────────────────────────────────────────┐     │
│  │  App Service Subnet (snet-appservice)              │     │
│  │  10.0.1.0/24                                       │     │
│  │                                                    │     │
│  │  ┌─────────────────────────────────────────┐       │     │
│  │  │       App Service / Web App             │       │     │
│  │  │                                         │       │     │
│  │  │  - VNet Integration Enabled             │       │     │
│  │  │  - Private Endpoint Enabled             │       │     │
│  │  │  - IP Restrictions (Defense in Depth)   │       │     │
│  │  │  - HTTPS Only (TLS 1.2+)                │       │     │
│  │  │  - Node.js 20 LTS Runtime               │       │     │
│  │  │  - Standard S1 Plan                     │       │     │
│  │  └─────────────────────────────────────────┘       │     │
│  │                                                    │     │
│  │  Delegation: Microsoft.Web/serverFarms             │     │
│  └────────────────────────────────────────────────────┘     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Network Flow

### Inbound Traffic (User → Application)
1. **User Request** → Public IP of Application Gateway
2. **Application Gateway** → Performs SSL/TLS termination, health checks
3. **DNS Resolution** → Queries `app-xyz.azurewebsites.net`
4. **Private DNS Zone** → Returns private IP (10.0.3.x) from Private Endpoint
5. **Backend Connection** → Application Gateway connects to Private Endpoint via private IP
6. **Private Link** → Traffic flows through Azure backbone to App Service
7. **App Service** → Processes request, returns response
8. **Response** → Flows back through Private Endpoint → Application Gateway → User

**Key Benefit**: Traffic never leaves Azure's network backbone between Application Gateway and App Service.

### Outbound Traffic (Application → Internet)
- **App Service** → Uses VNet Integration for outbound connectivity
- **Traffic** → Routes through Virtual Network
- **Destination** → Can reach Azure services, Internet, or on-premises networks

## Security Features

### Network Security Groups (NSGs)

#### Application Gateway NSG (nsg-myapp-dev-appgateway)
| Rule Name              | Priority | Direction | Protocol | Port      | Source          | Destination |
|------------------------|----------|-----------|----------|-----------|-----------------|-------------|
| AllowGatewayManager    | 100      | Inbound   | TCP      | 65200-65535 | GatewayManager| *           |
| AllowHTTP              | 110      | Inbound   | TCP      | 80        | Internet        | *           |
| AllowHTTPS             | 120      | Inbound   | TCP      | 443       | Internet        | *           |

#### App Service NSG (nsg-myapp-dev-appservice)
- No custom rules (allows delegated subnet traffic)
- Subnet delegation to Microsoft.Web/serverFarms

### App Service Security
- ✅ **Private Endpoint**: Enabled (10.0.3.0/24 subnet)
- ✅ **Private DNS**: Automatic resolution via privatelink.azurewebsites.net
- ✅ **IP Restrictions**: Only allows Application Gateway subnet (defense in depth)
- ✅ **HTTPS Only**: Enforced
- ✅ **TLS Version**: 1.2+ required
- ✅ **FTPS**: Disabled
- ✅ **Always On**: Enabled
- ✅ **HTTP/2**: Enabled

### Private Link Security
- **Network Isolation**: Traffic stays on Azure backbone
- **No Public Exposure**: App Service only accessible via Private Endpoint
- **DNS Integration**: Automatic with Private DNS Zone
- **Private IP**: Dynamically assigned from dedicated subnet

### Application Gateway Features
- **Health Probes**: Automatically removes unhealthy backends
- **Connection Draining**: Graceful shutdown of connections
- **Autoscaling**: Scales between 1-3 instances based on load
- **SSL/TLS Offloading**: Handles encryption/decryption

## IP Address Allocation

| Resource                  | Subnet/IP Range    | Purpose                           |
|---------------------------|--------------------|---------------------------------|
| Virtual Network           | 10.0.0.0/16        | Overall address space           |
| App Service Subnet        | 10.0.1.0/24        | VNet integration (254 IPs)      |
| Application Gateway Subnet| 10.0.2.0/24        | Gateway instances (254 IPs)     |
| Private Endpoint Subnet   | 10.0.3.0/24        | Private Endpoints (254 IPs)     |

## Customization Options

### Change Network Address Space
Edit [environments/dev/main.bicep](environments/dev/main.bicep):
```bicep
network: {
  vnetAddressPrefix: '10.1.0.0/16'           // Change VNet CIDR
  appServiceSubnetPrefix: '10.1.1.0/24'      // Change App Service subnet
  appGatewaySubnetPrefix: '10.1.2.0/24'      // Change App Gateway subnet
  privateEndpointSubnetPrefix: '10.1.3.0/24' // Change Private Endpoint subnet
}
```

### Disable Network (Simple Deployment)
Remove or comment out the `network` configuration:
```bicep
// network: {
//   vnetAddressPrefix: '10.0.0.0/16'
//   ...
// }
```
This will deploy a simple App Service without VNet integration.

### Add Additional Subnets
Edit [project/main.bicep](project/main.bicep) and add to the `subnets` array in the VirtualNetwork module.

## Deployment Notes

### Prerequisites
- Standard S1 or higher App Service Plan (VNet integration requires Standard+)
- Application Gateway subnet must be dedicated (no other resources)
- App Service subnet requires delegation to `Microsoft.Web/serverFarms`

### Deployment Time
- **Initial deployment**: ~15-20 minutes
- **Application Gateway**: ~10-12 minutes (longest component)
- **VNet & Subnets**: ~2-3 minutes
- **App Service**: ~3-5 minutes

### Cost Considerations
- **Application Gateway Standard_v2**: ~$0.36/hour + data processing
- **App Service S1**: ~$0.10/hour
- **VNet**: No charge for VNet itself
- **Public IP**: ~$0.005/hour

**Estimated monthly cost**: ~$350-400 USD (with autoscaling)

## Testing the Deployment

### Get the Public IP
```bash
az deployment sub show --name myapp-dev --query properties.outputs.applicationGatewayPublicIp.value -o tsv
```

### Test Connectivity
```bash
# Get the public IP
PUBLIC_IP=$(az deployment sub show --name myapp-dev --query properties.outputs.applicationGatewayPublicIp.value -o tsv)

# Test HTTP endpoint
curl http://$PUBLIC_IP

# Check if App Service is blocked from direct access
APP_URL=$(az deployment sub show --name myapp-dev --query properties.outputs.webAppUrl.value -o tsv)
curl $APP_URL  # Should fail or return 403 Forbidden
```

## Troubleshooting

### Application Gateway Health Probe Failing
```bash
# Check backend health
az network application-gateway show-backend-health \
  --resource-group rg-myapp-dev \
  --name agw-myapp-dev-<unique-id>
```

### App Service Not Accessible
- Verify VNet integration is enabled
- Check NSG rules aren't blocking traffic
- Ensure App Service is running: `az webapp show --name <app-name> --resource-group rg-myapp-dev`

### View Network Topology
```bash
# List all resources in the VNet
az network vnet show \
  --resource-group rg-myapp-dev \
  --name vnet-myapp-dev-<unique-id> \
  --query "subnets[].{Name:name, AddressPrefix:addressPrefix, Delegation:delegations[0].properties.serviceName}"
```

## Future Enhancements

Potential additions to this architecture:
- **WAF (Web Application Firewall)**: Upgrade to WAF_v2 SKU
- **Private Endpoints**: For storage, databases, etc.
- **Azure Firewall**: For advanced egress filtering
- **VPN Gateway**: Connect to on-premises networks
- **Azure Front Door**: Global load balancing and CDN
- **DDoS Protection**: Standard tier for DDoS mitigation
