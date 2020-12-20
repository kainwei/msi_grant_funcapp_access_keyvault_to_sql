locals {
  tags = {
    "terraform managed"   = "true"
    "terraform workspace" = terraform.workspace
  }
}

resource "azurerm_resource_group" "funcapp-msi" {
  name     = "funcapp-msi-rg"
  location = "australiaeast"
  tags     = local.tags
}

resource "azurerm_storage_account" "storage_account" {
  name                      = substr(format("%ssa", lower(replace("${azurerm_resource_group.funcapp-msi.name}${lookup(var.function_app_spec, "name", "function-app")}", "/[[:^alnum:]]/", ""))), 0, 24)
  resource_group_name       = azurerm_resource_group.funcapp-msi.name
  location                  = azurerm_resource_group.funcapp-msi.location
  account_tier              = lookup(var.storage_account_spec, "account_tier", "Standard")
  account_replication_type  = lookup(var.storage_account_spec, "account_replication_type", "LRS")
  enable_https_traffic_only = lookup(var.storage_account_spec, "enable_https_traffic_only", false)
  tags                      = local.tags
}

resource "azurerm_app_service_plan" "plan" {
  name                = "${azurerm_resource_group.funcapp-msi.name}-${lookup(var.function_app_spec, "name", "function-app")}-plan"
  location            = azurerm_resource_group.funcapp-msi.location
  resource_group_name = azurerm_resource_group.funcapp-msi.name
  kind                = lookup(var.service_plan_spec, "kind", "FunctionApp")
  tags                = local.tags

  sku {
    tier     = lookup(var.service_plan_spec, "tier", "Dynamic")
    size     = lookup(var.service_plan_spec, "size", "Y1")
    capacity = lookup(var.service_plan_spec, "capacity", 0)
  }
}

resource "azurerm_function_app" "funcapp-msi-app" {
  name = "my-funcapp-msi-app"
  location                  = azurerm_resource_group.funcapp-msi.location
  resource_group_name       = azurerm_resource_group.funcapp-msi.name
  app_service_plan_id       = azurerm_app_service_plan.plan.id
  storage_connection_string = azurerm_storage_account.storage_account.primary_connection_string

  connection_string {
    name  = "SqlAzureDbConnectionString"
    type  = "SQLAzure"
    value = "xxx.xxx.xxx"
  }

  version = "~1"

  app_settings = {
    TEST_KEYVAULT_URL = azurerm_key_vault.msi-keyvault.vault_uri
  }

  identity {
    type = "SystemAssigned"
  }

}

resource "azurerm_key_vault" "msi-keyvault" {
  name = "msi-test-vault"
  location = azurerm_resource_group.funcapp-msi.location
  resource_group_name = azurerm_resource_group.funcapp-msi.name

  tenant_id = var.tenant_id
  sku_name = "standard"
}

resource "azurerm_key_vault_secret" "msi-kv-sec" {
  name      = "secret-sauce"
  value     = "szechuan"
  key_vault_id = azurerm_key_vault.msi-keyvault.id
}

resource "azurerm_key_vault_access_policy" "msi-test-to-keyvault-test" {

  tenant_id = azurerm_key_vault.msi-keyvault.tenant_id
  object_id = lookup(azurerm_function_app.funcapp-msi-app.identity[0],"principal_id")

  key_permissions = [
    "get",
  ]

  secret_permissions = [
    "get",
  ]
  key_vault_id = azurerm_key_vault.msi-keyvault.id
}

provider "azurerm" {
  version = "=2.0.0"
  features {}
}