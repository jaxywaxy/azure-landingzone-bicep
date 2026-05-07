# envs/dev/main.bicep
cat > envs/dev/main.bicep << 'EOF'
param prefix string
param location string
param tags object

// Module: Resource Groups
module resourceGroups 'modules/resource-groups/main.bicep' = {
  name: 'resourceGroups-${uniqueString(subscription().id)}'
  scope: subscription()
  params: {
    prefix: prefix
    location: location
    tags: tags
  }
}

// Module: Networking
module networking 'modules/networking/main.bicep' = {
  name: 'networking-${uniqueString(subscription().id)}'
  scope: resourceGroup(resourceGroups.outputs.networkingRgName)
  params: {
    prefix: prefix
    location: location
    resourceGroupName: resourceGroups.outputs.networkingRgName
    tags: tags
  }
}

// Module: Logging
module logging 'modules/logging/main.bicep' = {
  name: 'logging-${uniqueString(subscription().id)}'
  scope: resourceGroup(resourceGroups.outputs.loggingRgName)
  params: {
    prefix: prefix
    location: location
    resourceGroupName: resourceGroups.outputs.loggingRgName
    tags: tags
  }
}

// Module: Storage Account - Logging
module storageLogs 'modules/storage/main.bicep' = {
  name: 'storage-logs-${uniqueString(subscription().id)}'
  scope: resourceGroup(resourceGroups.outputs.loggingRgName)
  params: {
    prefix: prefix
    location: location
    resourceGroupName: resourceGroups.outputs.loggingRgName
    tags: tags
    storagePurpose: 'logging'
  }
}

// Outputs
output resourceGroupsOutput object = {
  platform: resourceGroups.outputs.platformRgName
  networking: resourceGroups.outputs.networkingRgName
  apps: resourceGroups.outputs.appsRgName
  logging: resourceGroups.outputs.loggingRgName
}

output networkingOutput object = {
  hubVnetId: networking.outputs.hubVnetId
  appsVnetId: networking.outputs.appsVnetId
}

output loggingOutput object = {
  lawId: logging.outputs.lawId
}
EOF
