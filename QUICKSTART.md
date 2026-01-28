# Quick Start Guide

## First Time Setup

1. **Install Prerequisites**
   ```bash
   # Install Azure CLI (if not installed)
   # Visit: https://docs.microsoft.com/cli/azure/install-azure-cli
   
   # Install Bicep CLI
   az bicep install
   
   # Upgrade Bicep to latest
   az bicep upgrade
   ```

2. **Login to Azure**
   ```bash
   az login
   az account list --output table
   az account set --subscription "<your-subscription-id>"
   ```

## Deploy Development Environment

```bash
# Navigate to dev environment
cd environments/dev

# Validate (always do this first!)
az deployment sub validate --location canadacentral --template-file main.bicep

# Preview (shows new Private DNS and Private Endpoint resources)
az deployment sub what-if --location canadacentral --template-file main.bicep --name myapp-dev

# Deploy
az deployment sub create --location canadacentral --template-file main.bicep --name myapp-dev-deployment

# Watch deployment progress
az deployment sub show --name myapp-dev-deployment --query properties.provisioningState
```

## View Resources

```bash
# List resource groups
az group list --query "[?tags.Environment=='Development'].name" -o table

# Get deployment outputs
az deployment sub show --name myapp-dev-deployment --query properties.outputs

# Get Web App URL
az deployment sub show --name myapp-dev-deployment --query properties.outputs.webAppUrl.value -o tsv
```

## Clean Up

```bash
# Delete resource group (will delete all resources)
az group delete --name rg-myapp-dev --yes --no-wait
```

## Common Customizations

### Change Location
Edit [environments/dev/main.bicep](environments/dev/main.bicep):
```bicep
location: 'westus2'  // or any Azure region
```

### Change App Service Plan Size
```bicep
appServiceSku: {
  name: 'S1'       // B1, B2, B3, S1, S2, S3, P1V2, P2V2, P3V2
  tier: 'Standard' // Basic, Standard, Premium, PremiumV2
  capacity: 1      // Number of instances
}
```

### Change Runtime
```bicep
linuxFxVersion: 'PYTHON|3.11'  // NODE|20-lts, DOTNET|8.0, JAVA|17, PHP|8.2
```

## Troubleshooting

### View Deployment Errors
```bash
az deployment sub show --name myapp-dev-deployment --query properties.error
```

### Validate Before Deploy
```bash
az deployment sub validate --location eastus --template-file main.bicep
```

### Check Bicep Version
```bash
az bicep version
```
