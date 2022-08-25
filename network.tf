resource "azurerm_virtual_network" "app" {
  name                = "vnet-${local.resource_suffix}-app"
  address_space       = [var.app_virtual_network_address_space]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "app" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.app.name
  address_prefixes     = [var.app_virtual_network_address_space]

  delegation {
    name = "default"

    service_delegation {
      name    = "Microsoft.Web/serverFarms"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_virtual_network" "svc" {
  name                = "vnet-${local.resource_suffix}-svc"
  address_space       = [var.svc_virtual_network_address_space]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "svc" {
  name                                      = "default"
  resource_group_name                       = azurerm_resource_group.main.name
  virtual_network_name                      = azurerm_virtual_network.svc.name
  address_prefixes                          = [var.svc_virtual_network_address_space]
  private_endpoint_network_policies_enabled = false
}

resource "azurerm_virtual_network_peering" "app" {
  name                         = "peer-${azurerm_virtual_network.svc.name}"
  resource_group_name          = azurerm_resource_group.main.name
  virtual_network_name         = azurerm_virtual_network.app.name
  remote_virtual_network_id    = azurerm_virtual_network.svc.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "svc" {
  name                         = "peer-${azurerm_virtual_network.app.name}"
  resource_group_name          = azurerm_resource_group.main.name
  virtual_network_name         = azurerm_virtual_network.svc.name
  remote_virtual_network_id    = azurerm_virtual_network.app.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}
