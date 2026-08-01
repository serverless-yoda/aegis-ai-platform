param envPrefix string
param aiFoundryName string = envPrefix
param aiProjectName string = '${aiFoundryName}-proj'
param location string = resourceGroup().location

param llmModelDeploymentName string = '${envPrefix}-llm-deploy'
param embeddingModelDeploymentName string = '${envPrefix}-embed-deploy'

param storageAccountName string = take('${envPrefix}st${uniqueString(resourceGroup().id)}', 24)

/*
  Built-in Role Definition IDs
*/

var storageBlobDataContributorRoleId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'

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
  2. Azure AI Foundry Account
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
  3. AI Project

  Explicitly depends on aiFoundry to avoid parent update conflicts.
*/

resource aiProject 'Microsoft.CognitiveServices/accounts/projects@2025-06-01' = {
  name: aiProjectName
  parent: aiFoundry
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {}

  dependsOn: [
    aiFoundry
  ]
}

/*
  4. AI Foundry -> Storage Blob Data Contributor
*/

resource foundryStorageBlobDataContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, aiFoundry.id, storageBlobDataContributorRoleId)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      storageBlobDataContributorRoleId
    )
    principalId: aiFoundry.identity.principalId
    principalType: 'ServicePrincipal'
  }

  dependsOn: [
    aiFoundry
    storageAccount
  ]
}

/*
  5. AI Project -> Storage Blob Data Contributor
*/

resource projectStorageBlobDataContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, aiProject.id, storageBlobDataContributorRoleId)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      storageBlobDataContributorRoleId
    )
    principalId: aiProject.identity.principalId
    principalType: 'ServicePrincipal'
  }

  dependsOn: [
    aiProject
    storageAccount
  ]
}

/*
  6. Storage Connection

  This is also a child resource under the AI Foundry account.
  Deploy it after the AI Project and role assignments.
*/

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

  dependsOn: [
    foundryStorageBlobDataContributor
    projectStorageBlobDataContributor
  ]
}

/*
  7. GPT-5 Mini Deployment

  Deploy after storage connection so the parent account is not being updated
  by multiple child operations at the same time.
*/

resource llmModelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = {
  parent: aiFoundry
  name: llmModelDeploymentName
  sku: {
    name: 'GlobalStandard'
    capacity: 1
  }
  properties: {
    model: {
      name: 'gpt-5-mini'
      format: 'OpenAI'
      version: '2025-08-07'
    }
  }

  dependsOn: [
    storageConnection
  ]
}

/*
  8. Embedding Deployment

  Deploy after LLM deployment to avoid concurrent deployment operations
  on the same AI Foundry parent resource.
*/

resource embeddingModelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = {
  parent: aiFoundry
  name: embeddingModelDeploymentName
  sku: {
    name: 'Standard'
    capacity: 10
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
  9. Outputs
*/

output OPENAI_ENDPOINT string = 'https://${aiFoundry.properties.customSubDomainName}.services.ai.azure.com/openai/v1'
output OPENAI_API_KEY string = listKeys(aiFoundry.id, '2025-06-01').key1

output LLM_MODEL_DEPLOYMENT_NAME string = llmModelDeployment.name
output EMBEDDING_MODEL_DEPLOYMENT_NAME string = embeddingModelDeployment.name

output STORAGE_ACCOUNT_NAME string = storageAccount.name
output AI_FOUNDRY_NAME string = aiFoundry.name
output AI_PROJECT_NAME string = aiProject.name

output AI_FOUNDRY_PRINCIPAL_ID string = aiFoundry.identity.principalId
output AI_PROJECT_PRINCIPAL_ID string = aiProject.identity.principalId
