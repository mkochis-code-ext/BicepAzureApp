# Azure Infrastructure with Bicep

> **Disclaimer:** This repository is provided purely as a demonstration of these workflows. You are free to use, modify, and adapt the code as you see fit; however, it is offered as-is with no warranty or support of any kind. Use it at your own risk. This is not production-ready code — it should be reviewed, understood, and rewritten to suit your own environment before any real-world use.

This repository contains Bicep templates for managing Azure infrastructure using a Terraform-inspired folder structure.

## 📁 Folder Structure

```
BicepAzureApp/
├── environments/
│   └── dev/
│       ├── main.bicep                # Environment-specific configuration
│       ├── parameters.bicepparam     # Environment parameters
│       └── parameters.bicepparam.example   # Example configuration
├── project/
│   ├── main.bicep                    # Project-level orchestration
│   └── types.bicep                   # Type definitions
└── modules/
    └── azurerm/
        ├── resource_group/           # Resource Group module
        │   └── main.bicep
        ├── app_service/              # App Service module
        │   └── main.bicep
        ├── virtual_network/          # Virtual Network module
        │   └── main.bicep
        ├── network_security_group/   # NSG module
        │   └── main.bicep
        ├── application_gateway/      # Application Gateway module
        │   └── main.bicep
        ├── private_dns_zone/         # Private DNS Zone module
        │   └── main.bicep
        └── private_endpoint/         # Private Endpoint module
            └── main.bicep
```

## 🏗️ Architecture

This setup deploys a secure, production-ready web application infrastructure:

### Resources Deployed
- **Resource Group** - Container for all resources
- **Virtual Network** (10.0.0.0/16) with subnets:
  - App Service subnet (10.0.1.0/24) with delegation
  - Application Gateway subnet (10.0.2.0/24)
  - Private Endpoint subnet (10.0.3.0/24)
- **Private DNS Zone** - `privatelink.azurewebsites.net` for name resolution
- **Network Security Groups** - Controlling traffic to subnets
- **App Service Plan** - Standard S1 tier (required for VNet integration)
- **Web App** - Node.js 20 LTS runtime, HTTPS-only, private access via Private Endpoint
- **Private Endpoint** - Provides private IP for App Service
- **Application Gateway** - Public-facing entry point with health probes

### Network Flow
```
Internet
   │
   ▼ HTTP/HTTPS
Application Gateway (Public IP)
   │ DNS Query
   ▼
Private DNS Zone (returns 10.0.3.x)
   │
   ▼ Backend: HTTPS to Private IP
Private Endpoint (10.0.3.x)
   │ Private Link
   ▼
App Service (Private - No public access)
```

**Security Features:**
- App Service accessible only via Private Endpoint
- VNet integration for outbound connectivity
- Private DNS for automatic name resolution within VNet
- IP restrictions as defense-in-depth
- Application Gateway provides WAF capabilities (when using WAF_v2 SKU)
- HTTPS enforcement with TLS 1.2+

## Prerequisites

- [Azure CLI](https://docs.microsoft.com/cli/azure/install-azure-cli)
- [Bicep CLI](https://docs.microsoft.com/azure/azure-resource-manager/bicep/install)

## 🚀 Deployment

### Prerequisites Setup
```bash
# Login to Azure
az login

# Set your subscription
az account set --subscription <subscription-id>

# Verify subscription
az account show
```

### Deploy Development Environment

⚠️ **Note**: This deployment includes Application Gateway and will take ~15-20 minutes.

```bash
# Navigate to dev environment
cd environments/dev

# Preview changes before deployment (recommended)
az deployment sub what-if --location canadacentral --template-file main.bicep

# Validate deployment
az deployment sub validate --location canadacentral --template-file main.bicep

# Deploy to Azure
az deployment sub create --location canadacentral --template-file main.bicep --name myapp-dev

# Deploy with parameter file (if using custom parameters)
az deployment sub create --location canadacentral --template-file main.bicep --parameters parameters.bicepparam --name myapp-dev
```

### View Deployment Outputs
```bash
# Get all outputs
az deployment sub show --name myapp-dev --query properties.outputs

# Get Application Gateway Public IP (use this to access your app)
az deployment sub show --name myapp-dev --query properties.outputs.applicationGatewayPublicIp.value -o tsv

# Get Web App URL (direct access is blocked)
az deployment sub show --name myapp-dev --query properties.outputs.webAppUrl.value -o tsv
```

### Test Your Deployment
```bash
# Get the public IP
PUBLIC_IP=$(az deployment sub show --name myapp-dev --query properties.outputs.applicationGatewayPublicIp.value -o tsv)

# Access via Application Gateway
curl http://$PUBLIC_IP
```

## 🛠️ Development

### Build and Lint
```bash
# Build a specific Bicep file
az bicep build --file environments/dev/main.bicep

# Lint for errors and warnings
az bicep lint --file environments/dev/main.bicep

# Format Bicep files (requires Bicep CLI v0.4+)
az bicep format --file environments/dev/main.bicep
```

### Working with Modules

All reusable modules are in `modules/azurerm/`. Each module:
- Has a `main.bicep` file with the resource definitions
- Includes parameter descriptions and outputs
- Can be reused across different environments

To add a new module:
1. Create a folder in `modules/azurerm/<module-name>/`
2. Add `main.bicep` with your resource definitions
3. Reference it in `project/main.bicep`

### Adding New Environments

To create a new environment (e.g., staging, prod):
1. Copy `environments/dev/` to `environments/<env-name>/`
2. Update `main.bicep` with environment-specific values:
   - Change `resourceGroupName`
   - Adjust `appServiceSku` as needed
   - Modify `network` configuration if needed
   - Update `tags`
3. Deploy using the same commands from the new directory

## 📚 Documentation

- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Detailed network architecture and security
- **[QUICKSTART.md](QUICKSTART.md)** - Quick reference guide
- **[README.md](README.md)** - This file

## 🔧 Customization

### Disable Network (Simple Deployment)
To deploy without VNet integration and Application Gateway, remove the `network` configuration from [environments/dev/main.bicep](environments/dev/main.bicep):
```bicep
config: {
  resourceGroupName: 'rg-myapp-dev'
  location: 'canadacentral'
  appServiceName: 'myapp-dev-${uniqueString(subscription().subscriptionId)}'
  appServiceSku: {
    name: 'B1'      // Can use Basic tier without networking
    tier: 'Basic'
    capacity: 1
  }
  // Remove or comment out network configuration
  // network: { ... }
  tags: { ... }
}
```

### Modify App Service SKU
Edit [environments/dev/main.bicep](environments/dev/main.bicep):
```bicep
appServiceSku: {
  name: 'S1'      // B1, B2, B3, S1, S2, S3, P1V2, P2V2, P3V2
  tier: 'Standard' // Basic, Standard, Premium, PremiumV2
  capacity: 1     // Number of instances
}
```
⚠️ **VNet integration requires Standard S1 or higher**

### Change Network Address Space
```bicep
network: {
  vnetAddressPrefix: '10.1.0.0/16'          // Change VNet CIDR
  appServiceSubnetPrefix: '10.1.1.0/24'     // App Service subnet
  appGatewaySubnetPrefix: '10.1.2.0/24'     // Application Gateway subnet
}
```

### Change Runtime Stack
Modify the `linuxFxVersion` parameter:
```bicep
linuxFxVersion: 'NODE|20-lts'  // Examples: PYTHON|3.11, DOTNET|8.0, JAVA|17
```
