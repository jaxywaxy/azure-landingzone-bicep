@minLength(3)
@maxLength(11)
param prefix string
param location string
param tags object = {}

// ---------------------------------------------------------------------------
// Platform-owned shared tooling. The platform RG was created by the
// resource-groups module but nothing deployed into it, so it came up empty -
// which also meant a subscription-scoped scan had one declared RG with no
// contents to attribute anything to.
//
// Everything here is deliberately near-zero cost: a user-assigned identity is
// free, and a standard Key Vault costs nothing at rest. The expensive parts of
// this landing zone (NAT gateway, private endpoints) stay in networking/apps.
// ---------------------------------------------------------------------------

// Key Vault names are 3-24 chars, globally unique.
// Layout: <prefix>-kvp-<6-char-hash>
//   prefix  max 11 (per param decorator)
//   '-kvp-' 5 chars ('p' = platform, distinguishing it from the apps vault)
//   hash    6 chars (uniqueString truncated, per-RG so it differs from apps)
// Max total: 11 + 5 + 6 = 22 chars, inside the 24-char ceiling.
var suffix = take(uniqueString(resourceGroup().id), 6)

// Platform automation identity - the identity platform tooling runs as
// (deployments, policy remediation). Declared without role assignments: this
// template does not grant it anything, so adding a grant is a deliberate,
// reviewable act rather than something that arrives with the landing zone.
resource platformIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${prefix}-id-platform'
  location: location
  tags: tags
}

// Platform secrets vault - separate from the apps vault so platform and
// workload secrets have different blast radii and different owners.
resource platformKeyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: '${prefix}-kvp-${suffix}'
  location: location
  tags: tags
  properties: {
    tenantId: tenant().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    // Purge protection is deliberately OFF. It cannot be turned off once on,
    // and it blocks purging a soft-deleted vault - which makes redeploying this
    // landing zone under the same name fail until the vault is recovered by
    // hand. This estate is torn down and rebuilt often; that trade is wrong here.
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      // Declared explicitly rather than omitted: when the last rule is removed
      // Azure collapses networkAcls to null, and an absent block compares
      // differently from an empty one.
      ipRules: []
      virtualNetworkRules: []
    }
  }
}

// Outputs
output platformIdentityId string = platformIdentity.id
output platformIdentityPrincipalId string = platformIdentity.properties.principalId
output platformIdentityClientId string = platformIdentity.properties.clientId
output platformKeyVaultId string = platformKeyVault.id
output platformKeyVaultName string = platformKeyVault.name
