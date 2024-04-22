/*
  Deploy vnet with subnets and NSGs
*/

@description('This is the base name for each Azure resource name (6-8 chars)')
param baseName string

@description('The resource group location')
param location string = resourceGroup().location

param developmentEnvironment bool

// variables
var vnetName = 'vnet-${baseName}'
var ddosPlanName = 'ddos-${baseName}'

var vnetAddressPrefix = '10.0.0.0/16'
var appGatewaySubnetPrefix = '10.0.1.0/24'
var appServicesSubnetPrefix = '10.0.0.0/24'
var privateEndpointsSubnetPrefix = '10.0.2.0/27'
var agentsSubnetPrefix = '10.0.2.32/27'
var bastionSubnetPrefix = '10.0.2.64/26'
var jumpboxSubnetPrefix = '10.0.2.128/28'
var trainingSubnetPrefix = '10.0.3.0/24'
var scoringSubnetPrefix = '10.0.4.0/24'
var azureFirewallSubnetPrefix = '10.1.1.0/26'

var enableDdosProtection = !developmentEnvironment

// ---- Networking resources ----

var rtDeploymentAppGWName = 'udr-appGatewaySubnet-deployment'
var rtDeploymentAppServicesName = 'udr-appServicesSubnet-deployment'
var rtDeploymentJumpboxName = 'udr-jumpboxSubnet-deployment'
var rtDeploymentPEName = 'udr-privateEndpointsSubnet-deployment'
var rtDeploymentTrainingName = 'udr-snet-training-deployment'
var rtDeploymentAgentsName = 'udr-snet-agents-deployment'
var rtDeploymentScoringName = 'udr-snet-scoring-deployment'


// Route Tables
var rtAppGWName = 'udr-appGatewaySubnet'
var rtAppServicesName = 'udr-appServicesSubnet'
var rtJumpboxName = 'udr-jumpboxSubnet'
var rtPEName = 'udr-privateEndpointsSubnet'
var rtTrainingName = 'udr-snet-training'
var rtAgentsName = 'udr-snet-agents'
var rtScoringName = 'udr-snet-scoring'

var fwPrivateIP = '10.1.1.4'

module rtAppGW 'br/public:avm/res/network/route-table:0.2.1' = {
  name: rtDeploymentAppGWName
  params: {
    name: rtAppGWName
    location: location
    routes: [
      {
        name: 'ib-frontend-app-aoaizt'
        properties: {
          addressPrefix: '10.1.2.0/27'
          nextHopIpAddress: fwPrivateIP
          nextHopType: 'VirtualAppliance'
        }
      }
    ]
  }
}

module rtAppServices 'br/public:avm/res/network/route-table:0.2.1' = {
  name: rtDeploymentAppServicesName
  params: {
    name: rtAppServicesName
    location: location
    routes: [
      {
        name: 'default'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopIpAddress: fwPrivateIP
          nextHopType: 'VirtualAppliance'
        }
      }
    ]
  }
}

module rtJumpbox 'br/public:avm/res/network/route-table:0.2.1' = {
  name: rtDeploymentJumpboxName
  params: {
    name: rtJumpboxName
    location: location
    routes: [
      {
        name: 'default'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopIpAddress: fwPrivateIP
          nextHopType: 'VirtualAppliance'
        }
      }
    ]
  }
}

module rtPE 'br/public:avm/res/network/route-table:0.2.1' = {
  name: rtDeploymentPEName
  params: {
    name: rtPEName
    location: location
    routes: [
      {
        name: 'default'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopIpAddress: fwPrivateIP
          nextHopType: 'VirtualAppliance'
        }
      }
    ]
  }
}

module rtTraining 'br/public:avm/res/network/route-table:0.2.1' = {
  name: rtDeploymentTrainingName
  params: {
    name: rtTrainingName
    location: location
    routes: [
      {
        name: 'default'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopIpAddress: fwPrivateIP
          nextHopType: 'VirtualAppliance'
        }
      }
    ]
  }
}

module rtAgents 'br/public:avm/res/network/route-table:0.2.1' = {
  name: rtDeploymentAgentsName
  params: {
    name: rtAgentsName
    location: location
    routes: [
      {
        name: 'default'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopIpAddress: fwPrivateIP
          nextHopType: 'VirtualAppliance'
        }
      }
    ]
  }
}


module rtScoring 'br/public:avm/res/network/route-table:0.2.1' = {
  name: rtDeploymentScoringName
  params: {
    name: rtScoringName
    location: location
    routes: [
      {
        name: 'default'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopIpAddress: fwPrivateIP
          nextHopType: 'VirtualAppliance'
        }
      }
    ]
  }
}

// DDoS Protection Plan
resource ddosProtectionPlan 'Microsoft.Network/ddosProtectionPlans@2022-11-01' = if (enableDdosProtection) {
  name: ddosPlanName
  location: location
  properties: {}
}

// Virtual network and subnets
resource vnet 'Microsoft.Network/virtualNetworks@2022-11-01' = {
  name: vnetName
  location: location
  properties: {
    enableDdosProtection: enableDdosProtection
    ddosProtectionPlan: enableDdosProtection ? { id: ddosProtectionPlan.id } : null
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        //App services plan subnet
        name: 'snet-appServicePlan'
        properties: {
          addressPrefix: appServicesSubnetPrefix
          networkSecurityGroup: {
            id: appServiceSubnetNsg.id
          }
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
          routeTable: {
            id: rtAppServices.outputs.resourceId
          }
        }
      }
      {
        // App Gateway subnet
        name: 'snet-appGateway'
        properties: {
          addressPrefix: appGatewaySubnetPrefix
          networkSecurityGroup: {
            id: appGatewaySubnetNsg.id
          }
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          routeTable: {
            id: rtAppGW.outputs.resourceId
          }
        }
      }
      {
        // Private endpoints subnet
        name: 'snet-privateEndpoints'
        properties: {
          addressPrefix: privateEndpointsSubnetPrefix
          networkSecurityGroup: {
            id: privateEndpointsSubnetNsg.id
          }
          routeTable: {
            id: rtPE.outputs.resourceId
          }
        }
      }
      {
        // Build agents subnet
        name: 'snet-agents'
        properties: {
          addressPrefix: agentsSubnetPrefix
          networkSecurityGroup: {
            id: agentsSubnetNsg.id
          }
          routeTable: {
            id: rtAgents.outputs.resourceId
          }
        }
      }
      {
        // Azure Bastion subnet
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: bastionSubnetPrefix
          networkSecurityGroup: {
            id: bastionSubnetNsg.id
          }
        }
      }
      {
        // Jump box VMs subnet
        name: 'snet-jumpbox'
        properties: {
          addressPrefix: jumpboxSubnetPrefix
          networkSecurityGroup: {
            id: jumpboxSubnetNsg.id
          }
          routeTable: {
            id: rtJumpbox.outputs.resourceId
          }
        }
      }
      {
        // Training subnet
        name: 'snet-training'
        properties: {
          addressPrefix: trainingSubnetPrefix
          networkSecurityGroup: {
            id: trainingSubnetNsg.id
          }
          routeTable: {
            id: rtTraining.outputs.resourceId
          }
        }
      }
      {
        // Scoring subnet
        name: 'snet-scoring'
        properties: {
          addressPrefix: scoringSubnetPrefix
          networkSecurityGroup: {
            id: scoringSubnetNsg.id
          }
          routeTable: {
            id: rtScoring.outputs.resourceId
          }
        }
      }
    ]
  }

  resource appGatewaySubnet 'subnets' existing = {
    name: 'snet-appGateway'
  }

  resource appServiceSubnet 'subnets' existing = {
    name: 'snet-appServicePlan'
  }

  resource privateEnpointsSubnet 'subnets' existing = {
    name: 'snet-privateEndpoints'
  }

  resource agentsSubnet 'subnets' existing = {
    name: 'snet-agents'
  }

  resource azureBastionSubnet 'subnets' existing = {
    name: 'AzureBastionSubnet'
  }

  resource jumpBoxSubnet 'subnets' existing = {
    name: 'snet-jumpbox'
  }

  resource trainingSubnet 'subnets' existing = {
    name: 'snet-training'
  }

  resource scoringSubnet 'subnets' existing = {
    name: 'snet-scoring'
  }
}

// App Gateway subnet NSG
resource appGatewaySubnetNsg 'Microsoft.Network/networkSecurityGroups@2022-11-01' = {
  name: 'nsg-appGatewaySubnet'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AppGw.In.Allow.ControlPlane'
        properties: {
          description: 'Allow inbound Control Plane (https://docs.microsoft.com/azure/application-gateway/configuration-infrastructure#network-security-groups)'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '65200-65535'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'AppGw.In.Allow443.Internet'
        properties: {
          description: 'Allow ALL inbound web traffic on port 443'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: appGatewaySubnetPrefix
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
    ]
  }
}

// App Service subnet NSG
resource appServiceSubnetNsg 'Microsoft.Network/networkSecurityGroups@2022-11-01' = {
  name: 'nsg-appServicesSubnet'
  location: location
  properties: {
    securityRules: [
      {
        name: 'DenyVnetInBound'
        properties: {
          description: 'Deny inbound traffic from other subnets to the appServices subnet. Note: adjust rules as needed after adding resources to the subnet.'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Deny'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'AppPlan.Out.Allow.PrivateEndpoints'
        properties: {
          description: 'Allow outbound traffic from the app service subnet to the private endpoints subnet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: appServicesSubnetPrefix
          destinationAddressPrefix: privateEndpointsSubnetPrefix
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
      {
        name: 'AppPlan.Out.Allow.HTTPsInternet'
        properties: {
          description: 'Allow outbound traffic from the app service subnet to the Internet over HTTPs.'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: appServicesSubnetPrefix
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 500
          direction: 'Outbound'
        }
      }
      {
        name: 'DenyAllOutBound'
        properties: {
          description: 'Deny outbound traffic from the app services (vnet integration) subnet. Note: adjust rules as needed after adding resources to the subnet'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: appServicesSubnetPrefix
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Outbound'
        }
      }
    ]
  }
}

// Private endpoints subnet NSG
resource privateEndpointsSubnetNsg 'Microsoft.Network/networkSecurityGroups@2022-11-01' = {
  name: 'nsg-privateEndpointsSubnet'
  location: location
  properties: {
    securityRules: [
      {
        name: 'PrivateEndpoints.In.Allow.AppGateway'
        properties: {
          description: 'Allow inbound from the Application Gateway Subnet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: appServicesSubnetPrefix
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'PrivateEndpoints.In.Allow.Jumpbox'
        properties: {
          description: 'Allow inbound from the jumpbox Subnet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: jumpboxSubnetPrefix
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'PrivateEndpoints.In.Allow.AppServicesPlan'
        properties: {
          description: 'Allow inbound from the App Services Plan Integration subnet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: appServicesSubnetPrefix
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      {
        name: 'PrivateEndpoints.In.Allow.AzureFirewall'
        properties: {
          description: 'Allow inbound from the AzureFirewallSubnet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: azureFirewallSubnetPrefix
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 130
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyVnetInBound'
        properties: {
          description: 'Deny inbound traffic from other subnets to the appServices subnet. Note: adjust rules as needed after adding resources to the subnet.'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Deny'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllOutBound'
        properties: {
          description: 'Deny outbound traffic from the private endpoints subnet'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: privateEndpointsSubnetPrefix
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Outbound'
        }
      }
    ]
  }
}

// Build agents subnet NSG
resource agentsSubnetNsg 'Microsoft.Network/networkSecurityGroups@2022-11-01' = {
  name: 'nsg-agentsSubnet'
  location: location
  properties: {
    securityRules: [
      {
        name: 'DenyVnetInBound'
        properties: {
          description: 'Deny inbound traffic from other subnets to the agents subnet. Note: adjust rules as needed after adding resources to the subnet.'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Deny'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllOutBound'
        properties: {
          description: 'Deny outbound traffic from the build agents subnet. Note: adjust rules as needed after adding resources to the subnet'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: appGatewaySubnetPrefix
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Outbound'
        }
      }
    ]
  }
}

// Training subnet NSG
resource trainingSubnetNsg 'Microsoft.Network/networkSecurityGroups@2022-11-01' = {
  name: 'nsg-trainingSubnet'
  location: location
  properties: {
    securityRules: [
      {
        name: 'DenyVnetInBound'
        properties: {
          description: 'Deny inbound traffic from other subnets to the training subnet. Note: adjust rules as needed after adding resources to the subnet.'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Deny'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllOutBound'
        properties: {
          description: 'Deny outbound traffic from the training subnet. Note: adjust rules as needed after adding resources to the subnet'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: trainingSubnetPrefix
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Outbound'
        }
      }
    ]
  }
}

// Scoring subnet NSG
resource scoringSubnetNsg 'Microsoft.Network/networkSecurityGroups@2022-11-01' = {
  name: 'nsg-scoringSubnet'
  location: location
  properties: {
    securityRules: [
      {
        name: 'DenyVnetInBound'
        properties: {
          description: 'Deny inbound traffic from other subnets to the scoring subnet. Note: adjust rules as needed after adding resources to the subnet.'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Deny'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllOutBound'
        properties: {
          description: 'Deny outbound traffic from the scoring subnet. Note: adjust rules as needed after adding resources to the subnet'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: scoringSubnetPrefix
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Outbound'
        }
      }
    ]
  }
}

// Bastion host subnet NSG
// https://learn.microsoft.com/azure/bastion/bastion-nsg
// https://github.com/Azure/azure-quickstart-templates/blob/master/quickstarts/microsoft.network/azure-bastion-nsg/main.bicep
resource bastionSubnetNsg 'Microsoft.Network/networkSecurityGroups@2022-11-01' = {
  name: 'nsg-bastionSubnet'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Bastion.In.Allow.Https'
        properties: {
          description: 'Allow inbound Https traffic from the from the Internet to the Bastion Host'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'Internet'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'Bastion.In.Allow.GatewayManager'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'GatewayManager'
          destinationPortRanges: [
            '443'
            '4443'
          ]
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'Bastion.In.Allow.LoadBalancer'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      {
        name: 'Bastion.In.Allow.BastionHostCommunication'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 130
          direction: 'Inbound'
        }
      }      
      {
        name: 'DenyAllInBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Inbound'
        }
      }
      
      {
        name: 'Bastion.Out.Allow.SshRdp'
        properties: {
          description: 'Allow outbound RDP and SSH from the Bastion Host subnet to elsewhere in the vnet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRanges: [
            '22'
            '3389'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
      {
        name: 'Bastion.Out.Allow.AzureMonitor'
        properties: {
          description: 'Allow outbound traffic from the Bastion Host subnet to Azure Monitor'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: bastionSubnetPrefix
          destinationAddressPrefix: 'AzureMonitor'
          access: 'Allow'
          priority: 110
          direction: 'Outbound'
        }
      }
      {
        name: 'Bastion.Out.Allow.AzureCloudCommunication'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '443'
          destinationAddressPrefix: 'AzureCloud'
          access: 'Allow'
          priority: 120
          direction: 'Outbound'
        }
      }
      {
        name: 'Bastion.Out.Allow.BastionHostCommunication'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 130
          direction: 'Outbound'
        }
      }
      {
        name: 'Bastion.Out.Allow.GetSessionInformation'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          destinationPortRanges: [
            '80'
            '443'
          ]
          access: 'Allow'
          priority: 140
          direction: 'Outbound'
        }
      }      
      {
        name: 'DenyAllOutBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Outbound'
        }
      }
    ]
  }
}

// Jump box subnet NSG 
resource jumpboxSubnetNsg 'Microsoft.Network/networkSecurityGroups@2022-11-01' = {
  name: 'nsg-jumpboxSubnet'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Jumpbox.In.Allow.SshRdp'
        properties: {
          description: 'Allow inbound RDP and SSH from the Bastion Host subnet'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: bastionSubnetPrefix
          destinationPortRanges: [
            '22'
            '3389'
          ]
          destinationAddressPrefix: jumpboxSubnetPrefix
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyVnetInBound'
        properties: {
          description: 'Deny inbound traffic from other subnets to the scoring subnet. Note: adjust rules as needed after adding resources to the subnet.'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Deny'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'Jumpbox.Out.Allow.PrivateEndpoints'
        properties: {
          description: 'Allow outbound traffic from the jumpbox subnet to the Private Endpoints subnet.'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: jumpboxSubnetPrefix
          destinationAddressPrefix: privateEndpointsSubnetPrefix
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
      {
        name: 'Jumpbox.Out.Allow.HTTPInternet'
        properties: {
          description: 'Allow outbound traffic from the jumpbox subnet to the Internet over HTTP.'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: jumpboxSubnetPrefix
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 490
          direction: 'Outbound'
        }
      }
      {
        name: 'Jumpbox.Out.Allow.HTTPsInternet'
        properties: {
          description: 'Allow outbound traffic from the jumpbox subnet to the Internet over HTTPs.'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: jumpboxSubnetPrefix
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 500
          direction: 'Outbound'
        }
      }
      {
        name: 'DenyAllOutBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: jumpboxSubnetPrefix
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Outbound'
        }
      }
    ]
  }
}

@description('The name of the vnet.')
output vnetNName string = vnet.name

@description('The name of the app service plan subnet.')
output appServicesSubnetName string = vnet::appServiceSubnet.name

@description('The name of the app gatewaysubnet.')
output appGatewaySubnetName string = vnet::appGatewaySubnet.name

@description('The name of the private endpoints subnet.')
output privateEndpointsSubnetName string = vnet::privateEnpointsSubnet.name

@description('The name of the private endpoints subnet.')
output bastionSubnetName string = vnet::azureBastionSubnet.name

@description('The name of the private endpoints subnet.')
output jumpboxSubnetName string = vnet::jumpBoxSubnet.name

@description('The name of the private endpoints subnet.')
output scoringSubnetName string = vnet::trainingSubnet.name

@description('The name of the private endpoints subnet.')
output trainingSubnetName string = vnet::scoringSubnet.name
