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

// Storage account names are 3-24 chars, lowercase alphanumeric, globally unique.
// Layout: <prefix-no-hyphens><st><purposeCode><6-char-hash>
//   prefix       max 11 (per param decorator)
//   'st'         2 chars (convention marker)
//   purposeCode  1 char  ('g' general, 'l' logging)
//   hash         6 chars (uniqueString truncated; sufficient collision resistance per RG)
// Max total: 11 + 2 + 1 + 6 = 20 chars. Well inside the 24-char ceiling.
var purposeCode = storagePurpose == 'logging' ? 'l' : 'g'
var storageAccountName = toLower('${replace(prefix, '-', '')}st${purposeCode}${take(uniqueString(resourceGroup().id), 6)}')

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
