targetScope = 'subscription'

@minLength(3)
@maxLength(11)
param prefix string
param location string
param tags object = {}

// Platform Resource Group
resource platformRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${prefix}-rg-platform'
  location: location
  tags: tags
}

// Networking Resource Group
resource networkingRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${prefix}-rg-networking'
  location: location
  tags: tags
}

// Apps Resource Group
resource appsRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${prefix}-rg-apps'
  location: location
  tags: tags
}

// Logging Resource Group
resource loggingRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: '${prefix}-rg-logging'
  location: location
  tags: tags
}

// Outputs (kept for downstream consumers; parent template now derives names directly from prefix)
output platformRgName string = platformRg.name
output platformRgId string = platformRg.id
output networkingRgName string = networkingRg.name
output networkingRgId string = networkingRg.id
output appsRgName string = appsRg.name
output appsRgId string = appsRg.id
output loggingRgName string = loggingRg.name
output loggingRgId string = loggingRg.id
