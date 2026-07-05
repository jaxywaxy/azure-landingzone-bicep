// Spoke VNet + spoke->hub peering (platform-owned fabric in the workload sub).
param location string
param tags object
param spokeVnetName string
param hubVnetId string

resource spokeVnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: spokeVnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.2.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'snet-workload'
        properties: {
          addressPrefix: '10.2.1.0/24'
        }
      }
      {
        name: 'snet-privateendpoints'
        properties: {
          addressPrefix: '10.2.2.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

resource spokeToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-04-01' = {
  parent: spokeVnet
  name: 'spoke-to-hub'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: hubVnetId
    }
  }
}

output spokeVnetId string = spokeVnet.id
