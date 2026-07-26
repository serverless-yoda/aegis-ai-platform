// https://github.com/microsoft-foundry/foundry-samples/blob/main/infrastructure/infrastructure-setup-bicep/00-basic/main.bicep

param envPrefix string
param aiFoundryName string = envPrefix
param aiProjectName string = '${aiFoundryName}-proj'
param acrName string = '${envPrefix}acr'
param location string = resourceGroup().location
param llmModelDeploymentName string = '${envPrefix}-llm-deploy'

// Storage account name (lowercase alphanumeric only, max 24 chars)
param storageAccountName string = take('${envPrefix}st${uniqueString(resourceGroup().id)}', 24)

/*
  Cheapest Local Storage: Standard HDD/SSD + Locally Redundant Storage (LRS)
*/
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS' // Cheapest local redundancy option
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
  }
}

/*
  An AI Foundry resource is a variant of a CognitiveServices/account resource type
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
    // required to work in AI Foundry
    allowProjectManagement: true

    // Defines developer API endpoint subdomain
    customSubDomainName: aiFoundryName

    disableLocalAuth: false
  }
}

/*
  RBAC: Grant AI Foundry Managed Identity "Storage Blob Data Contributor" on the Storage Account
*/
var storageBlobDataContributorRoleId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'

resource storageRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, aiFoundry.id, storageBlobDataContributorRoleId)
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataContributorRoleId)
    principalId: aiFoundry.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

/*
  Connect the Storage Account to Azure AI Foundry
*/
resource storageConnection 'Microsoft.CognitiveServices/accounts/connections@2025-06-01' = {
  parent: aiFoundry
  name: '${aiFoundryName}-storage'
  properties: {
    category: 'AzureStorageAccount'
    // Target fixed to use the Blob endpoint URI instead of Resource ID
    target: storageAccount.properties.primaryEndpoints.blob
    authType: 'AAD'
    isSharedToAll: true
    metadata: {
      ResourceId: storageAccount.id
    }
  }
}

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
  Deploying models to use in playground, agents and other tools.
*/

// https://ai.azure.com/catalog/models/gpt-4.1-mini
resource llmModelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01'= {
  parent: aiFoundry
  name: llmModelDeploymentName
  sku : {
    capacity: 1
    name: 'GlobalStandard'
  }
  properties: {
    model:{
      name: 'gpt-5-mini'
      format: 'OpenAI'
      version: '2025-08-07'
    }
  }
}

output OPENAI_ENDPOINT string = 'https://${aiFoundry.properties.customSubDomainName}.services.ai.azure.com/openai/v1'
output OPENAI_API_KEY string = listKeys(aiFoundry.id, '2025-06-01').key1
output LLM_MODEL_DEPLOYMENT_NAME string = llmModelDeployment.name
output STORAGE_ACCOUNT_NAME string = storageAccount.name
