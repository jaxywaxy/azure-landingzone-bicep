@minLength(3)
@maxLength(11)
param prefix string
param location string
param tags object = {}

@description('Resource ID of the subnet to place private endpoints in (from networking module).')
param privateEndpointSubnetId string

// ---------------------------------------------------------------------------
// Workload-owned resources (app team). The drift agent classifies all of these
// as 'workload' - including the private endpoints, which are the app's private
// connection to its PaaS resources even though they are Microsoft.Network types.
// ---------------------------------------------------------------------------

var suffix = take(uniqueString(resourceGroup().id), 6)

// NOTE: App Service (plan + web app) was intentionally omitted - App Service Plan
// creation is throttled at the subscription level in this test subscription. The
// workload owner class is still well represented by Key Vault, Cosmos, storage,
// and the private endpoints below.

// Key Vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: '${prefix}-kv-${suffix}'
  location: location
  tags: tags
  properties: {
    tenantId: tenant().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
  }
}

// Cosmos DB (serverless, SQL API)
resource cosmos 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' = {
  name: '${toLower(prefix)}-cosmos-${suffix}'
  location: location
  tags: tags
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    capabilities: [
      {
        name: 'EnableServerless'
      }
    ]
    publicNetworkAccess: 'Disabled'
    disableKeyBasedMetadataWriteAccess: false
  }
}

resource cosmosDb 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2024-05-15' = {
  parent: cosmos
  name: 'appdb'
  properties: {
    resource: {
      id: 'appdb'
    }
  }
}

resource cosmosContainer 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2024-05-15' = {
  parent: cosmosDb
  name: 'items'
  properties: {
    resource: {
      id: 'items'
      partitionKey: {
        paths: [
          '/id'
        ]
        kind: 'Hash'
      }
    }
  }
}

// Private endpoint - Key Vault (workload-owned network resource)
resource kvPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: '${prefix}-pe-kv'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'kv-connection'
        properties: {
          privateLinkServiceId: keyVault.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]
  }
}

// Private endpoint - Cosmos DB
resource cosmosPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
  name: '${prefix}-pe-cosmos'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'cosmos-connection'
        properties: {
          privateLinkServiceId: cosmos.id
          groupIds: [
            'Sql'
          ]
        }
      }
    ]
  }
}

// Outputs
output keyVaultName string = keyVault.name
output cosmosName string = cosmos.name
