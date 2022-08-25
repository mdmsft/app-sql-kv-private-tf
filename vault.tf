locals {
  vault_secrets = [
    azurerm_key_vault_secret.sql_connection_string.resource_versionless_id,
    azurerm_key_vault_secret.application_insights_connection_string.resource_versionless_id
  ]
}

resource "azurerm_key_vault" "main" {
  name                       = substr("kv-${local.resource_suffix}", 0, 24)
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  enable_rbac_authorization  = true
  sku_name                   = "standard"
  tenant_id                  = var.tenant_id
  soft_delete_retention_days = var.key_vault_soft_delete_retention_days

  network_acls {
    bypass         = "AzureServices"
    default_action = "Allow"
  }
}

resource "azurerm_role_assignment" "key_vault_administrator" {
  role_definition_name = "Key Vault Administrator"
  scope                = azurerm_key_vault.main.id
  principal_id         = data.azurerm_client_config.main.object_id
}

resource "azurerm_key_vault_secret" "sql_connection_string" {
  name         = "sql-connection-string"
  key_vault_id = azurerm_key_vault.main.id
  value        = "Server=tcp:${azurerm_mssql_server.main.fully_qualified_domain_name},1433;Database=${azurerm_mssql_database.main.name};User ID=${random_string.sql_server_login.result}@${azurerm_mssql_server.main.name};Password=${random_password.sql_server_password.result};Trusted_Connection=False;Encrypt=True;"
  depends_on = [
    azurerm_role_assignment.key_vault_administrator
  ]
}

resource "azurerm_key_vault_secret" "application_insights_connection_string" {
  name         = "application-insights-connection-string"
  key_vault_id = azurerm_key_vault.main.id
  value        = azurerm_application_insights.main.connection_string
  depends_on = [
    azurerm_role_assignment.key_vault_administrator
  ]
}

resource "azurerm_role_assignment" "key_vault_secrets_user" {
  count                = length(local.vault_secrets)
  role_definition_name = "Key Vault Secrets User"
  scope                = local.vault_secrets[count.index]
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

module "vault_endpoint" {
  source                         = "./modules/endpoint"
  resource_group_name            = azurerm_resource_group.main.name
  resource_suffix                = "${local.resource_suffix}-kv"
  subnet_id                      = azurerm_subnet.svc.id
  private_connection_resource_id = azurerm_key_vault.main.id
  subresource_name               = "vault"
  private_dns_zone_id            = azurerm_private_dns_zone.main["vault"].id

  depends_on = [
    azurerm_key_vault.main
  ]
}
