resource "azurerm_user_assigned_identity" "app" {
  name                = "id-${local.resource_suffix}-app"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
}

resource "azurerm_service_plan" "main" {
  name                = "plan-${local.resource_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Windows"
  sku_name            = var.service_plan_sku_name
}

resource "azurerm_windows_web_app" "main" {
  name                            = "app-${local.resource_suffix}"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  service_plan_id                 = azurerm_service_plan.main.id
  https_only                      = true
  key_vault_reference_identity_id = azurerm_user_assigned_identity.app.id
  virtual_network_subnet_id       = azurerm_subnet.app.id

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app.id]
  }

  connection_string {
    name  = "Database"
    type  = "SQLAzure"
    value = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.sql_connection_string.versionless_id})"
  }

  app_settings = {
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.application_insights_connection_string.versionless_id})"
  }

  site_config {
    application_stack {
      current_stack  = "dotnet"
      dotnet_version = "v6.0"
    }

    minimum_tls_version    = "1.2"
    health_check_path      = "/healthz"
    http2_enabled          = true
    use_32_bit_worker      = false
    vnet_route_all_enabled = true
  }

  logs {
    detailed_error_messages = true
    failed_request_tracing  = true

    application_logs {
      file_system_level = "Verbose"
    }

    http_logs {
      file_system {
        retention_in_days = 0
        retention_in_mb   = 100
      }
    }
  }

  depends_on = [
    azurerm_role_assignment.key_vault_secrets_user
  ]
}

resource "azurerm_app_service_source_control" "main" {
  app_id                 = azurerm_windows_web_app.main.id
  branch                 = "main"
  repo_url               = var.web_app_repo_url
  use_manual_integration = true
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-${local.resource_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "main" {
  name                = "appi-${local.resource_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"
}
