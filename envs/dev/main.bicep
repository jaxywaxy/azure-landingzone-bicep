targetScope = 'subscription'

@minLength(3)
@maxLength(11)
param prefix string
param location string
param tags object

// RG names computed here so module `scope:` expressions are calculable
// at the start of deployment (BCP120 — outputs from other modules can't
// be used in scope assignments).
var platformRgName = '${prefix}-rg-platform'
var networkingRgName = '${prefix}-rg-networking'
var appsRgName = '${prefix}-rg-apps'
var loggingRgName = '${prefix}-rg-logging'

// Module: Resource Groups
module resourceGroups '../../modules/resource-groups/main.bicep' = {
  name: 'resourceGroups-${uniqueString(subscription().id)}'
  scope: subscription()
  params: {
    prefix: prefix
    location: location
    tags: tags
  }
}

// Module: Networking (platform-owned fabric)
module networking '../../modules/networking/main.bicep' = {
  name: 'networking-${uniqueString(subscription().id)}'
  scope: resourceGroup(networkingRgName)
  dependsOn: [
    resourceGroups
  ]
  params: {
    prefix: prefix
    location: location
    tags: tags
  }
}

// Module: Logging
module logging '../../modules/logging/main.bicep' = {
  name: 'logging-${uniqueString(subscription().id)}'
  scope: resourceGroup(loggingRgName)
  dependsOn: [
    resourceGroups
  ]
  params: {
    prefix: prefix
    location: location
    tags: tags
  }
}

// Module: Storage Account - Logging
module storageLogs '../../modules/storage/main.bicep' = {
  name: 'storage-logs-${uniqueString(subscription().id)}'
  scope: resourceGroup(loggingRgName)
  dependsOn: [
    resourceGroups
  ]
  params: {
    prefix: prefix
    location: location
    tags: tags
    storagePurpose: 'logging'
  }
}

// Module: Apps (workload-owned - App Service, Key Vault, Cosmos, private endpoints)
module apps '../../modules/apps/main.bicep' = {
  name: 'apps-${uniqueString(subscription().id)}'
  scope: resourceGroup(appsRgName)
  dependsOn: [
    resourceGroups
  ]
  params: {
    prefix: prefix
    location: location
    tags: tags
    privateEndpointSubnetId: networking.outputs.peSubnetId
  }
}

// Module: Storage Account - Apps (workload general-purpose)
module storageApps '../../modules/storage/main.bicep' = {
  name: 'storage-apps-${uniqueString(subscription().id)}'
  scope: resourceGroup(appsRgName)
  dependsOn: [
    resourceGroups
  ]
  params: {
    prefix: prefix
    location: location
    tags: tags
    storagePurpose: 'general'
  }
}

// Outputs
output resourceGroupsOutput object = {
  platform: platformRgName
  networking: networkingRgName
  apps: appsRgName
  logging: loggingRgName
}

output networkingOutput object = {
  hubVnetId: networking.outputs.hubVnetId
  appsVnetId: networking.outputs.appsVnetId
}

output loggingOutput object = {
  lawId: logging.outputs.lawId
}

output appsOutput object = {
  keyVault: apps.outputs.keyVaultName
  cosmos: apps.outputs.cosmosName
}
