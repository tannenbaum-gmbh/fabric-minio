targetScope = 'resourceGroup'

@description('Azure region for all resources.')
param location string = resourceGroup().location

@description('Name of the Log Analytics workspace used by the Container Apps environment.')
param logAnalyticsWorkspaceName string = 'log-${uniqueString(resourceGroup().id)}'

@description('Name of the Azure Container Apps managed environment.')
param containerAppsEnvironmentName string = 'cae-${uniqueString(resourceGroup().id)}'

@description('Name of the MinIO Azure Container App.')
param containerAppName string = 'minio-${uniqueString(resourceGroup().id)}'

@description('MinIO container image to deploy for test workloads.')
param minioImage string = 'quay.io/minio/minio:latest'

@secure()
@description('Access key ID that MinIO exposes to clients.')
param minioRootUser string

@secure()
@description('Secret access key that MinIO exposes to clients.')
param minioRootPassword string

@description('CPU allocation for the MinIO container, expressed as a string so it can be converted to the numeric value expected by the AVM module.')
param minioCpu string = '0.5'

@description('Memory allocation for the MinIO container.')
param minioMemory string = '1Gi'

@description('Optional tags applied to all deployed resources.')
param tags object = {}

module logAnalyticsWorkspace 'br/public:avm/res/operational-insights/workspace:0.16.0' = {
  name: 'deploy-log-analytics-workspace'
  params: {
    name: logAnalyticsWorkspaceName
    location: location
    features: {
      disableLocalAuth: false
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    tags: tags
    enableTelemetry: false
  }
}

resource logAnalyticsWorkspaceResource 'Microsoft.OperationalInsights/workspaces@2025-07-01' existing = {
  name: logAnalyticsWorkspaceName
}

module managedEnvironment 'br/public:avm/res/app/managed-environment:0.14.0' = {
  name: 'deploy-container-apps-environment'
  params: {
    name: containerAppsEnvironmentName
    location: location
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsWorkspaceResourceId: logAnalyticsWorkspaceResource.id
    }
    publicNetworkAccess: 'Enabled'
    zoneRedundant: false
    tags: tags
    enableTelemetry: false
  }
  dependsOn: [
    logAnalyticsWorkspace
  ]
}

resource managedEnvironmentResource 'Microsoft.App/managedEnvironments@2025-10-02-preview' existing = {
  name: containerAppsEnvironmentName
  dependsOn: [
    managedEnvironment
  ]
}

module containerApp 'br/public:avm/res/app/container-app:0.23.0' = {
  name: 'deploy-minio-container-app'
  params: {
    name: containerAppName
    location: location
    environmentResourceId: managedEnvironmentResource.id
    ingressAllowInsecure: false
    ingressTargetPort: 9000
    ingressTransport: 'auto'
    scaleSettings: {
      minReplicas: 1
      maxReplicas: 1
    }
    traffic: [
      {
        latestRevision: true
        weight: 100
      }
    ]
    secrets: [
      {
        name: 'minio-root-user'
        value: minioRootUser
      }
      {
        name: 'minio-root-password'
        value: minioRootPassword
      }
    ]
    containers: [
      {
        name: 'minio'
        image: minioImage
        args: [
          'server'
          '/data'
          '--console-address'
          ':9001'
        ]
        env: [
          {
            name: 'MINIO_ROOT_USER'
            secretRef: 'minio-root-user'
          }
          {
            name: 'MINIO_ROOT_PASSWORD'
            secretRef: 'minio-root-password'
          }
        ]
        resources: {
          cpu: json(minioCpu)
          memory: minioMemory
        }
      }
    ]
    tags: tags
    enableTelemetry: false
  }
  dependsOn: [
    managedEnvironment
  ]
}

resource containerAppResource 'Microsoft.App/containerApps@2026-01-01' existing = {
  name: containerAppName
  dependsOn: [
    containerApp
  ]
}

output fabricShortcutServiceUrl string = 'https://${containerAppResource.properties.configuration.ingress.fqdn}'
output fabricShortcutHost string = containerAppResource.properties.configuration.ingress.fqdn
output containerAppResourceId string = containerAppResource.id
output containerAppsEnvironmentDefaultDomain string = managedEnvironmentResource.properties.defaultDomain
output logAnalyticsWorkspaceResourceId string = logAnalyticsWorkspaceResource.id
