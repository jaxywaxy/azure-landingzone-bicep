targetScope = 'subscription'

@minLength(3)
@maxLength(11)
param prefix string
param location string
param tags object

var platformRgName = '${prefix}-rg-platform'
var networkingRgName = '${prefix}-rg-networking'
var appsRgName = '${prefix}-rg-apps'
var loggingRgName = '${prefix}-rg-logging'

module resourceGroups '../../modules/resource-groups/main.bicep' = {
  name: 'resourceGroups-${uniqueString(subscription().id)}'
  scope: subscription()
  params: {
    prefix: prefix
    location: location
    tags: tags
  }
}

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
