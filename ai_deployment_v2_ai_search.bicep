// Based on:
// https://github.com/microsoft-foundry/foundry-samples/blob/main/infrastructure/infrastructure-setup-bicep/00-basic/main.bicep

param envPrefix string
param aiFoundryName string = envPrefix
param aiProjectName string = '${aiFoundryName}-proj'
param acrName string = '${envPrefix}acr'
param location string = resourceGroup().location

param llmModelDeploymentName string = '${envPrefix}-llm-deploy'
param embeddingModelDeploymentName string = '${envPrefix}-embed-deploy'

// Optional: Pass your User Object ID if testing queries in Azure Portal Playground
param userPrincipalId string = ''

// Unique storage and search resource names
param storageAccountName string = take('${envPrefix}st${uniqueString(resourceGroup().id)}', 24)
param searchServiceName string = take('${envPrefix}search${uniqueString(resourceGroup().id)}', 24)

/*
  Built-in Role Definition IDs
*/

// Storage
var storageBlobDataContributorRoleId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'

// Azure AI Search
var searchServiceContributorRoleId = '7ca78c08-252a-4471-8644-bb5ff32d4ba0'
var searchIndexDataContributorRoleId = '8ebe5a00-799e-43f5-93ac-243d3dce84a7'
var searchIndexDataReaderRoleId = '1407120a-92aa-4202-b7e9-c0e197c71c8f'

// Azure AI Services
var cognitiveServicesUserRoleId = 'a97b65f3-24c7-4388-baec-2e87135dc908'

/*
  1. Storage Account
*/
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
  }
}

/*
  2. Azure AI Search Service
*/
resource searchService 'Microsoft.Search/searchServices@2023-11-01' = {
  name: searchServiceName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'basic'
  }
  properties: {
    replicaCount: 1
    partitionCount: 1
    authOptions: {
      aadOrApiKey: {
        aadAuthFailureMode: 'http401WithBearerChallenge'
      }
    }
  }
}

/*
  3. Azure AI Foundry Instance
*/
resource aiFoundry 'Microsoft.CognitiveServices/accounts@2025-06-01' = {
  name: aiFoundryName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'S0'
  }
  kind: 'AIServices'
  properties: {
    allowProjectManagement: true
    customSubDomainName: aiFoundryName
    disableLocalAuth: false
  }
}

/*
  4. AI Project
*/
resource aiProject 'Microsoft.CognitiveServices/accounts/projects@2025-06-01' = {
  name: aiProjectName
  parent: aiFoundry
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {}
}

/*
  5. Role Assignments - AI Foundry Account Managed Identity
*/

// AI Foundry -> Storage Blob Data Contributor
resource foundryStorageBlobDataContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, aiFoundry.id, storageBlobDataContributorRoleId)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataContributorRoleId)
    principalId: aiFoundry.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// AI Foundry -> Search Service Contributor
resource foundrySearchServiceContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(searchService.id, aiFoundry.id, searchServiceContributorRoleId)
  scope: searchService
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', searchServiceContributorRoleId)
    principalId: aiFoundry.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// AI Foundry -> Search Index Data Contributor
resource foundrySearchIndexDataContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(searchService.id, aiFoundry.id, searchIndexDataContributorRoleId)
  scope: searchService
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', searchIndexDataContributorRoleId)
    principalId: aiFoundry.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// AI Foundry -> Search Index Data Reader
resource foundrySearchIndexDataReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(searchService.id, aiFoundry.id, searchIndexDataReaderRoleId)
  scope: searchService
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', searchIndexDataReaderRoleId)
    principalId: aiFoundry.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

/*
  6. Role Assignments - AI Project Managed Identity

  This is the important part for MCP 403 issues.
  Foundry agent / MCP access may use the project managed identity,
  not only the parent AI Foundry account identity.
*/

// AI Project -> Storage Blob Data Contributor
resource projectStorageBlobDataContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, aiProject.id, storageBlobDataContributorRoleId)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataContributorRoleId)
    principalId: aiProject.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// AI Project -> Search Service Contributor
resource projectSearchServiceContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(searchService.id, aiProject.id, searchServiceContributorRoleId)
  scope: searchService
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', searchServiceContributorRoleId)
    principalId: aiProject.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// AI Project -> Search Index Data Contributor
resource projectSearchIndexDataContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(searchService.id, aiProject.id, searchIndexDataContributorRoleId)
  scope: searchService
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', searchIndexDataContributorRoleId)
    principalId: aiProject.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

// AI Project -> Search Index Data Reader
resource projectSearchIndexDataReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(searchService.id, aiProject.id, searchIndexDataReaderRoleId)
  scope: searchService
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', searchIndexDataReaderRoleId)
    principalId: aiProject.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

/*
  7. Role Assignment - Azure AI Search Managed Identity

  This allows Azure AI Search to call the Azure AI Foundry / AI Services account
  when the knowledge base or agentic retrieval flow needs model access.
*/

resource searchCognitiveServicesUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aiFoundry.id, searchService.id, cognitiveServicesUserRoleId)
  scope: aiFoundry
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', cognitiveServicesUserRoleId)
    principalId: searchService.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

/*
  8. Optional User Assignments

  Useful when testing from Azure Portal / Foundry playground.
*/

resource userSearchServiceContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(userPrincipalId)) {
  name: guid(searchService.id, userPrincipalId, searchServiceContributorRoleId)
  scope: searchService
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', searchServiceContributorRoleId)
    principalId: userPrincipalId
    principalType: 'User'
  }
}

resource userSearchIndexDataContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(userPrincipalId)) {
  name: guid(searchService.id, userPrincipalId, searchIndexDataContributorRoleId)
  scope: searchService
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', searchIndexDataContributorRoleId)
    principalId: userPrincipalId
    principalType: 'User'
  }
}

resource userSearchIndexDataReader 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(userPrincipalId)) {
  name: guid(searchService.id, userPrincipalId, searchIndexDataReaderRoleId)
  scope: searchService
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', searchIndexDataReaderRoleId)
    principalId: userPrincipalId
    principalType: 'User'
  }
}

/*
  9. Connections to Azure AI Foundry
*/

// Storage Connection
resource storageConnection 'Microsoft.CognitiveServices/accounts/connections@2025-06-01' = {
  parent: aiFoundry
  name: '${aiFoundryName}-storage'
  properties: {
    category: 'AzureStorageAccount'
    target: storageAccount.properties.primaryEndpoints.blob
    authType: 'AAD'
    isSharedToAll: true
    metadata: {
      ResourceId: storageAccount.id
    }
  }
}

// AI Search Connection
resource searchConnection 'Microsoft.CognitiveServices/accounts/connections@2025-06-01' = {
  parent: aiFoundry
  name: '${aiFoundryName}-search'
  properties: {
    category: 'CognitiveSearch'
    target: 'https://${searchService.name}.search.windows.net'
    authType: 'AAD'
    isSharedToAll: true
    metadata: {
      ResourceId: searchService.id
    }
  }
}

/*
  10. Deployments - LLM + Embedding Model
*/

// Chat / Completion Model
resource llmModelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = {
  parent: aiFoundry
  name: llmModelDeploymentName
  sku: {
    capacity: 1
    name: 'GlobalStandard'
  }
  properties: {
    model: {
      name: 'gpt-5-mini'
      format: 'OpenAI'
      version: '2025-08-07'
    }
  }
}

// Vector Embedding Model
resource embeddingModelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = {
  parent: aiFoundry
  name: embeddingModelDeploymentName
  sku: {
    capacity: 10
    name: 'Standard'
  }
  properties: {
    model: {
      name: 'text-embedding-3-small'
      format: 'OpenAI'
      version: '1'
    }
  }
  dependsOn: [
    llmModelDeployment
  ]
}

/*
  11. Outputs
*/

output OPENAI_ENDPOINT string = 'https://${aiFoundry.properties.customSubDomainName}.services.ai.azure.com/openai/v1'
output OPENAI_API_KEY string = listKeys(aiFoundry.id, '2025-06-01').key1
output LLM_MODEL_DEPLOYMENT_NAME string = llmModelDeployment.name
output EMBEDDING_MODEL_DEPLOYMENT_NAME string = embeddingModelDeployment.name
output SEARCH_SERVICE_NAME string = searchService.name
output SEARCH_SERVICE_ENDPOINT string = 'https://${searchService.name}.search.windows.net'
output STORAGE_ACCOUNT_NAME string = storageAccount.name
output AI_FOUNDRY_NAME string = aiFoundry.name
output AI_PROJECT_NAME string = aiProject.name
output AI_FOUNDRY_PRINCIPAL_ID string = aiFoundry.identity.principalId
output AI_PROJECT_PRINCIPAL_ID string = aiProject.identity.principalId
output SEARCH_SERVICE_PRINCIPAL_ID string = searchService.identity.principalId
