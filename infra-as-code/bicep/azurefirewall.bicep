// Azure Firewall 
var azfwName = 'azfw-hub'
var azfwPolicyName = 'azfw-hub-policy'
param location string
var appGWRuleName = 'azfw-ip-group-app-gwsnet'
var appRulesName = 'snet-appGateway-to-frontend-app-aoaizt'
var azfwPIPName = 'azfw-pip'


var jumpboxRulesName = 'jumpbox-aoaizt-to-Internet'


// Deployment Names
var ipGroupAppGWSnetDeploymentName = 'ipgr-snet-appGateway-deployment'
var ipGroupInboundFESnetDeploymentName = 'ipgr-ib-frontend-app-aoaizt-deployment'
var ipGroupOutboundFESnetDeploymentName = 'ipgr-ob-frontend-app-aoaizt-deployment'
var ipGroupJumpBoxDeploymentName = 'ipgr-snet-jumpbox-deployment'
var azfwPolicyDeploymentName = 'azfw-hub-policy-deployment'
var azfwPIPDeploymentName = 'azfw-pip-deployment'
var azfwDeploymentName = 'azfw-hub-deployment'

// Name of the IP Groups
var ipGroupAppGWSnetName = 'ipgr-snet-appGateway'
var ipGroupInboundFESnetName = 'ipgr-ib-frontend-app-aoaizt'
var ipGroupOutboundFESnetName = 'ipgr-ob-frontend-app-aoaizt'
var ipGroupJumpBoxName = 'ipgr-snet-jumpbox'

// Rule Collections
var appRuleCollectionGroupName = 'apprule-cg-app-aoaizt'
var jumpboxRuleCollectionGroupName = 'apprule-cg-jumpbox-aoaizt'
var jumpboxOBRuleCollectionName = 'ob-app-rc-jumpbox'

//var netRuleCollectionName = 'netrule-cg-app-aoaizt'
var appOBRuleName = 'frontend-app-aoaizt-to-Internet'
var appIBRuleCollectionName = 'ib-net-appaoaizt'
var appOBRuleCollectionName = 'ob-app-rc-appaoaizt'

param logAnalyticsWorkspaceName string



// LA Workspace reference

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: logAnalyticsWorkspaceName
}

// IP Groups
module ipGroupAppGWSnet 'br/public:avm/res/network/ip-group:0.1.0' = {
  name: ipGroupAppGWSnetDeploymentName
  params: {
    name: ipGroupAppGWSnetName
    ipAddresses: [ '10.0.1.0/24']
    location: location
  }
}

module ipGroupInboundFESnet 'br/public:avm/res/network/ip-group:0.1.0' = {
  name: ipGroupInboundFESnetDeploymentName
  params: {
    name: ipGroupInboundFESnetName
    ipAddresses: ['10.0.2.14/32']
    location: location
  }
}

module ipGroupOutboundFESnet 'br/public:avm/res/network/ip-group:0.1.0' = {
  name: ipGroupOutboundFESnetDeploymentName
  params: {
    name: ipGroupOutboundFESnetName
    ipAddresses: ['10.0.0.0/24']
    location: location
  }
}

module ipGroupJumpBox 'br/public:avm/res/network/ip-group:0.1.0' = {
  name: ipGroupJumpBoxDeploymentName
  params: {
    name: ipGroupJumpBoxName
    ipAddresses: ['10.0.2.128/28']
    location: location
  }
}

// Firewall Policy
module firewallPolicy 'br/public:avm/res/network/firewall-policy:0.1.2' = {
  name: azfwPolicyDeploymentName
  params: {
    name: azfwPolicyName
    location: location
    ruleCollectionGroups: [
      {
        name: appRuleCollectionGroupName
        priority: 300
        ruleCollections: [
          {
            action: {
              type: 'Allow'
            }
            name: appIBRuleCollectionName
            priority: 100
            ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
            rules: [
              {
                terminateTLS: true
                destinationAddresses: []
                targetFqdns: [
                  'app-aoaiztwk.azurewebsites.net'
                  'app-aoaiztwk.scm.azurewebsites.net'
                ]
                destinationIpGroups: []
                protocols: [
                  {
                    protocolType: 'Https'
                    port: 443
                  }
                ]
                name: appRulesName
                ruleType: 'ApplicationRule'
                sourceAddresses: []
                sourceIpGroups: [ipGroupAppGWSnet.outputs.resourceId]
              }
            ]
          }
          {
            action: {
              type: 'Allow'
            }
            name: appOBRuleCollectionName
            priority: 110
            ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
            rules: [
              {
                terminateTLS: true
                destinationAddresses: []
                targetFqdns: [
                  'dc.services.visualstudio.com'
                  'mcr.microsoft.com'
                ]
                destinationIpGroups: []
                protocols: [
                  {
                    protocolType: 'Https'
                    port: 443
                  }
                ]
                name: appOBRuleName
                ruleType: 'ApplicationRule'
                sourceAddresses: []
                sourceIpGroups: [ipGroupOutboundFESnet.outputs.resourceId]
              }
            ]
          }
        ]
      }
      {
        name: jumpboxRuleCollectionGroupName
        priority: 310
        ruleCollections: [
          {
            action: {
              type: 'Deny'
            }
            name: jumpboxOBRuleCollectionName
            priority: 110
            ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
            rules: [
              {
                terminateTLS: true
                webCategories: [
                  'AlcoholAndTobacco'
                  'ChildAbuseImages'
                  'CriminalActivity'
                  'DatingAndPersonals'
                  'Gambling'
                  'Hacking'
                  'HateAndIntolerance'
                  'IllegalDrug'
                  'IllegalSoftware'
                  'LingerieAndSwimsuits'
                  'Marijuana'
                  'Nudity'
                  'PornographyAndSexuallyExplicit'
                  'SelfHarm'
                  'SexEducation'
                  'Tasteless'
                  'Violence'
                  'Weapons'
                  'Entertainment'
                  'AdvertisementsAndPopUps'
                  'Chat'
                  'Cults'
                  'Games'
                  'InstantMessaging'
                  'Shopping'
                  'SocialNetworking'
                  'RestaurantsAndDining'
                  'Travel'
                  'Religion'
                  'Sports'
                  'Transportation'
                  'PoliticsAndLaw'
                  'RealEstate'
                  'LeisureAndRecreation'
                  'NatureAndConservation'
                  'Arts'
                  'FashionAndBeauty'
                  'ProfessionalNetworking'
                  'NonProfitsAndNgos'
                  'News'
                  'JobSearch'
                  'HealthAndMedicine'
                  'Finance'
              ]
                targetFqdns: []
                destinationIpGroups: []
                protocols: [
                  {
                    protocolType: 'Https'
                    port: 443
                  }
                  {
                    protocolType: 'Http'
                    port: 80
                  }
                ]
                name: jumpboxRulesName
                ruleType: 'ApplicationRule'
                sourceAddresses: []
                sourceIpGroups: [ipGroupJumpBox.outputs.resourceId]
              }
            ]
          }
        ]
      }
    ]
    threatIntelMode: 'Alert'
    tier: 'Premium'
    mode: 'Alert'
    defaultWorkspaceId: logAnalyticsWorkspace.id
   }
  }


// Public IP
module azfwPIP 'br/public:avm/res/network/public-ip-address:0.3.1' = {
  name: azfwPIPDeploymentName
  params: {
    name: azfwPIPName
    location: location
    skuName: 'Standard'
    skuTier: 'Regional'
    zones: [
      1
      2
      3
    ]
  }
}

output azfwPIPAddress string = azfwPIP.outputs.ipAddress

// Azure Firewall
module azureFirewall 'br/public:avm/res/network/azure-firewall:0.2.0' = {
    name: azfwDeploymentName
    params: {
      name: azfwName
      azureSkuTier: 'Premium'
      location: location
      publicIPResourceID: azfwPIP.outputs.resourceId
      firewallPolicyId: firewallPolicy.outputs.resourceId
      virtualNetworkResourceId: resourceId('Microsoft.Network/virtualNetworks', 'vnet-hub')
      diagnosticSettings: [
        {
          name: 'azfw-diagnosticSettings'
          workspaceResourceId: logAnalyticsWorkspace.id
          metricCategories: [
            {
              category: 'AllMetrics'
            }
          ]
          logCategoriesAndGroups:[
            {
              categoryGroup: 'allLogs'
            }
          ]
        }
      ]
    }
    dependsOn:[
      firewallPolicy
    ]
  }

output fwPrivateIP string = azureFirewall.outputs.privateIp
