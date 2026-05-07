# modules/logging/main.bicep
cat > modules/logging/main.bicep << 'EOF'
param prefix string
param location string
param resourceGroupName string
param tags object = {}

// Log Analytics Workspace
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: '${prefix}-law'
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

// Outputs
output lawId string = logAnalyticsWorkspace.id
output lawName string = logAnalyticsWorkspace.name
EOF
