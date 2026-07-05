// =============================================================================
// Spoke connectivity for the drift-test workload subscription (CAF vending)
// =============================================================================
// Deployed BY THE PLATFORM TEAM into the workload subscription:
//   az deployment sub create --subscription <workload-sub> \
//     --location australiaeast --template-file envs/spoke-drifttest/main.bicep \
//     --parameters envs/spoke-drifttest/parameters.json
//
// Creates the spoke network fabric (RG + VNet) in the workload subscription and
// peers it BOTH ways with the hub VNet in the platform subscription:
//   - spoke -> hub peering lives here (workload sub)
//   - hub -> spoke peering is deployed cross-subscription into the hub's
//     networking RG (the deploying identity needs rights in both subs)
//
// Everything in this template is PLATFORM-OWNED (VNets/peering), so drift on it
// routes to the platform team even though it lives in the workload subscription.
targetScope = 'subscription'

param location string = 'australiaeast'
param tags object = {
  environment: 'test'
  owner: 'platform'
  project: 'landingzone'
  service: 'connectivity'
  managedby: 'bicep'
}

@description('Hub subscription ID (platform/connectivity).')
param hubSubscriptionId string

@description('Resource group holding the hub VNet.')
param hubNetworkingRg string

@description('Hub VNet name to peer with.')
param hubVnetName string

var spokeRgName = 'rg-spoke-drifttest'
var spokeVnetName = 'vnet-spoke-drifttest'

resource spokeRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: spokeRgName
  location: location
  tags: tags
}

// Spoke VNet + spoke->hub peering (in the workload subscription)
module spokeNetwork 'spoke-network.bicep' = {
  name: 'spoke-network-${uniqueString(subscription().id)}'
  scope: resourceGroup(spokeRgName)
  dependsOn: [
    spokeRg
  ]
  params: {
    location: location
    tags: tags
    spokeVnetName: spokeVnetName
    hubVnetId: resourceId(hubSubscriptionId, hubNetworkingRg, 'Microsoft.Network/virtualNetworks', hubVnetName)
  }
}

// Hub->spoke peering, deployed cross-subscription into the hub's networking RG
module hubPeering 'hub-peering.bicep' = {
  name: 'hub-to-spoke-peering-${uniqueString(subscription().id)}'
  scope: resourceGroup(hubSubscriptionId, hubNetworkingRg)
  params: {
    hubVnetName: hubVnetName
    spokeVnetId: spokeNetwork.outputs.spokeVnetId
  }
}

output spokeVnetId string = spokeNetwork.outputs.spokeVnetId
