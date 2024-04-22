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

param azfwIP string
param location string
param fwPrivateIP string

module rtAppGW 'br/public:avm/res/network/route-table:0.2.1' = {
  name: rtDeploymentAppGWName
  params: {
    name: rtAppGWName
    location: location
    routes: [
      {
        name: 'PrivateEndpointsSubnet'
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
