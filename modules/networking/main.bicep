@minLength(3)
@maxLength(11)
param prefix string
param location string
param tags object = {}

// ---------------------------------------------------------------------------
// Platform-owned network fabric: NSGs, route table, NAT gateway, VNets, subnets,
// peering. In a CAF/ALZ the platform team owns all of this EXCEPT the NSG
// securityRules, which are typically app-team owned (the drift agent classifies
// a securityRules change as workload even though the NSG resource is platform).
// ---------------------------------------------------------------------------

// Public IP for the NAT gateway (platform egress)
resource natPublicIp 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: '${prefix}-pip-nat'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    idleTimeoutInMinutes: 4
  }
}

// NAT gateway - outbound SNAT for the apps subnets (platform egress control)
resource natGateway 'Microsoft.Network/natGateways@2023-04-01' = {
  name: '${prefix}-natgw-apps'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    idleTimeoutInMinutes: 4
    publicIpAddresses: [
      {
        id: natPublicIp.id
      }
    ]
  }
}

// Route table for the apps subnets (platform-owned routing)
resource appsRouteTable 'Microsoft.Network/routeTables@2023-04-01' = {
  name: '${prefix}-rt-apps'
  location: location
  tags: tags
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'to-hub'
        properties: {
          addressPrefix: '10.0.0.0/16'
          nextHopType: 'VnetLocal'
        }
      }
    ]
  }
}

// NSG - web tier (platform resource; rules are app-owned)
resource nsgWeb 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: '${prefix}-nsg-web'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Allow-HTTPS-Inbound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '10.1.1.0/24'
        }
      }
      {
        name: 'Allow-HTTP-Inbound'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '10.1.1.0/24'
        }
      }
    ]
  }
}

// NSG - app tier
resource nsgApp 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: '${prefix}-nsg-app'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Allow-Web-To-App'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '8080'
          sourceAddressPrefix: '10.1.1.0/24'
          destinationAddressPrefix: '10.1.2.0/24'
        }
      }
    ]
  }
}

// NSG - data tier
resource nsgData 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: '${prefix}-nsg-data'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'Allow-App-To-Sql'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '1433'
          sourceAddressPrefix: '10.1.2.0/24'
          destinationAddressPrefix: '10.1.3.0/24'
        }
      }
      {
        name: 'Deny-All-Inbound'
        properties: {
          priority: 4096
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

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

// Apps Virtual Network - subnets associate the platform NSGs / route table /
// NAT gateway defined above.
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
          networkSecurityGroup: {
            id: nsgWeb.id
          }
          routeTable: {
            id: appsRouteTable.id
          }
          natGateway: {
            id: natGateway.id
          }
        }
      }
      {
        name: 'snet-app'
        properties: {
          addressPrefix: '10.1.2.0/24'
          networkSecurityGroup: {
            id: nsgApp.id
          }
          routeTable: {
            id: appsRouteTable.id
          }
          natGateway: {
            id: natGateway.id
          }
        }
      }
      {
        name: 'snet-data'
        properties: {
          addressPrefix: '10.1.3.0/24'
          networkSecurityGroup: {
            id: nsgData.id
          }
          routeTable: {
            id: appsRouteTable.id
          }
        }
      }
      {
        name: 'snet-privateendpoints'
        properties: {
          addressPrefix: '10.1.4.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
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
output peSubnetId string = '${appsVnet.id}/subnets/snet-privateendpoints'
output dataSubnetId string = '${appsVnet.id}/subnets/snet-data'
