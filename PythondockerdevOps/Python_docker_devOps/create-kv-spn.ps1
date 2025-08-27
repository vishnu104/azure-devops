
##Let us create a script for creating a service connection
# -------------------------------
# Variables - customize these
# -------------------------------
$spName = "sp-kv-access"
$kvName = "hub-keyvault-104"
$rgName = "hub-rg"
$role = "Key Vault Secrets Officer"  # or "Key Vault Secrets User" for read-only

# -------------------------------
# Create Service Principal
# -------------------------------
$sp = az ad sp create-for-rbac --name $spName --skip-assignment | ConvertFrom-Json
$spAppId = $sp.appId
$tenantId = $sp.tenant

Write-Host "`nService Principal created:"
Write-Host "AppId (Client ID): $spAppId"
Write-Host "Tenant ID: $tenantId"
$subsName = az account list --query "[].{Name:name, Id:id}" -o table

# -------------------------------
# Create a client secret
# -------------------------------
$secret = az ad sp credential reset --id $spAppId --years 1 | ConvertFrom-Json
$clientSecret = $secret.password
Write-Host "`nClient secret generated: $clientSecret"

# -------------------------------
# Get Key Vault resource ID
# -------------------------------
$kvId = az keyvault show -g $rgName -n $kvName --query id -o tsv
Write-Host "`nKey Vault Resource ID: $kvId"

# -------------------------------
# Assign Key Vault role to SPN
# -------------------------------
# Get SP object ID
$spObjectId = az ad sp show --id $spAppId --query id -o tsv

az role assignment create `
  --assignee-object-id $spObjectId `
  --assignee-principal-type ServicePrincipal `
  --role $role `
  --scope $kvId

Write-Host "`nRole assignment complete. SPN can now access Key Vault secrets."

# -------------------------------
# Output info for DevOps service connection
# -------------------------------
Write-Host "`nUse the following details to create a manual service connection in Azure DevOps:"
Write-Host "Subscription ID: $(az account show --query id -o tsv)"
Write-Host "Tenant ID: $tenantId"
Write-Host "Client ID (AppId): $spAppId"
Write-Host "Client Secret: $clientSecret"
Write-Host "Service Principal Name: $spName"
Write-Host "Subscription Name: $subsName"