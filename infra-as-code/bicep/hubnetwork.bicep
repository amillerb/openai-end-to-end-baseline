var vnetDeploymentName = 'vnet-hub-deployment'
var vnetName = 'vnet-hub'
var privateEndpointsSubnetName = 'snet-sharedPrivateEndpoints'
var location = 'EastUS'


module hubvnet 'br/public:network/virtual-network:1.1.3' = {
  name: vnetDeploymentName
  params: {
    name: vnetName
    location: location
    addressPrefixes: [
      '10.1.0.0/16'
    ]
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        addressPrefix: '10.1.1.0/26'
      }
      {
        name: privateEndpointsSubnetName
        addressPrefix: '10.1.2.0/24'
      }
    ]
  }
}
output vnetId string = hubvnet.outputs.resourceId

// NSGs
