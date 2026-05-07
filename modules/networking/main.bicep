# modules/networking/main.bicep
cat > modules/networking/main.bicep << 'EOF'
param prefix string
param location string
param resourceGroupName string
param tags object = {}

// Hub Virtual Network
resource hubVnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: '${prefix}-vnet-hub'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
      {
        name: 'snet-shared-services'
        properties: {
          addressPrefix: '10.0.10.0/24'
        }
      }
    ]
  }
}

// Apps Virtual Network
resource appsVnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: '${prefix}-vnet-apps'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.1.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'snet-web'
        properties: {
          addressPrefix: '10.1.1.0/24'
        }
      }
      {
        name: 'snet-app'
        properties: {
          addressPrefix: '10.1.2.0/24'
        }
      }
      {
        name: 'snet-data'
        properties: {
          addressPrefix: '10.1.3.0/24'
        }
      }
    ]
  }
}

// VNet Peering - Hub to Apps
resource hubToAppsPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-04-01' = {
  parent: hubVnet
  name: 'hub-to-apps'
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: false
    remoteVirtualNetwork: {
      id: appsVnet.id
    }
  }
}

// VNet Peering - Apps to Hub
resource appsToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-04-01' = {
  parent: appsVnet
  name: 'apps-to-hub'
  properties: {
    allowForwardedTraffic: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: hubVnet.id
    }
  }
}

// Outputs
output hubVnetId string = hubVnet.id
output hubVnetName string = hubVnet.name
output appsVnetId string = appsVnet.id
output appsVnetName string = appsVnet.name
EOF
