@minLength(3)
@maxLength(11)
param prefix string
param location string
param tags object = {}

@allowed([
  'general'
  'logging'
])
param storagePurpose string = 'general'

var storageAccountName = toLower('${replace(prefix, '-', '')}st${storagePurpose}${uniqueString(resourceGroup().id)}')

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
