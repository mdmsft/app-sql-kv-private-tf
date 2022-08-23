
resource "random_string" "sql_server_login" {
  length  = 8
  special = false
  numeric = false
}

resource "random_password" "sql_server_password" {
  length = 64
}

resource "azurerm_mssql_server" "main" {
  name                          = "sql-${local.resource_suffix}"
  resource_group_name           = azurerm_resource_group.main.name
  location                      = azurerm_resource_group.main.location
  version                       = "12.0"
  administrator_login           = random_string.sql_server_login.result
  administrator_login_password  = random_password.sql_server_password.result
  public_network_access_enabled = false
}

resource "azurerm_mssql_database" "main" {
  name        = "sqldb-${local.resource_suffix}"
  server_id   = azurerm_mssql_server.main.id
  sample_name = "AdventureWorksLT"
  sku_name    = "Basic"
}

module "database_endpoint" {
  source                         = "./modules/endpoint"
  resource_group_name            = azurerm_resource_group.main.name
  resource_suffix                = "${local.resource_suffix}-sql"
  subnet_id                      = azurerm_subnet.svc.id
  private_connection_resource_id = azurerm_mssql_server.main.id
  subresource_name               = "sqlServer"
  private_dns_zone_id            = azurerm_private_dns_zone.main["database"].id

  depends_on = [
    azurerm_mssql_server.main
  ]
}
