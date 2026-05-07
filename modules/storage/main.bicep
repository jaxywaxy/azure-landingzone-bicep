# modules/storage/main.bicep
cat > modules/storage/main.bicep << 'EOF'
param prefix string
param location string
param resourceGroupName string
param tags object = {}
param storagePurpose string = 'general' // 'general' or 'logging'

var storageAccountName = '${replace(prefix, '-', '')}st${storagePurpose}'

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
  }
}

// Outputs
output storageId string = storageAccount.id
output storageName string = storageAccount.name
output primaryBlobEndpoint string = storageAccount.properties.primaryEndpoints.blob
EOF
