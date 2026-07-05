// Hub->spoke peering, deployed into the hub's networking RG (cross-subscription).
param hubVnetName string
param spokeVnetId string

resource hubVnet 'Microsoft.Network/virtualNetworks@2023-04-01' existing = {
  name: hubVnetName
}

resource hubToSpoke 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-04-01' = {
  parent: hubVnet
  name: 'hub-to-spoke-drifttest'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: spokeVnetId
    }
  }
}
