locals {
  private_dns_zones = {
    vault    = "privatelink.vaultcore.azure.net"
    database = "privatelink.database.windows.net"
  }
  dns_zone_name                = reverse(split("/", var.dns_zone_id))[0]
  dns_zone_resource_group_name = split("/", var.dns_zone_id)[4]
}

resource "azurerm_private_dns_zone" "main" {
  for_each            = local.private_dns_zones
  name                = each.value
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "main" {
  for_each              = local.private_dns_zones
  name                  = azurerm_resource_group.main.name
  private_dns_zone_name = each.value
  resource_group_name   = azurerm_resource_group.main.name
  virtual_network_id    = azurerm_virtual_network.app.id

  depends_on = [
    azurerm_private_dns_zone.main
  ]
}

data "azurerm_dns_zone" "main" {
  name                = local.dns_zone_name
  resource_group_name = local.dns_zone_resource_group_name
}

resource "azurerm_dns_cname_record" "main" {
  name                = var.project
  zone_name           = data.azurerm_dns_zone.main.name
  resource_group_name = data.azurerm_dns_zone.main.resource_group_name
  ttl                 = 300
  record              = azurerm_windows_web_app.main.default_hostname
}

resource "azurerm_dns_txt_record" "main" {
  name                = "asuid.${azurerm_dns_cname_record.main.name}"
  zone_name           = data.azurerm_dns_zone.main.name
  resource_group_name = data.azurerm_dns_zone.main.resource_group_name
  ttl                 = 300

  record {
    value = azurerm_windows_web_app.main.custom_domain_verification_id
  }
}

resource "azurerm_app_service_custom_hostname_binding" "main" {
  hostname            = trim(azurerm_dns_cname_record.main.fqdn, ".")
  app_service_name    = azurerm_windows_web_app.main.name
  resource_group_name = azurerm_resource_group.main.name

  depends_on = [
    azurerm_dns_txt_record.main
  ]

  lifecycle {
    ignore_changes = [
      ssl_state,
      thumbprint
    ]
  }
}

resource "azurerm_app_service_managed_certificate" "main" {
  custom_hostname_binding_id = azurerm_app_service_custom_hostname_binding.main.id
}

resource "azurerm_app_service_certificate_binding" "main" {
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.main.id
  certificate_id      = azurerm_app_service_managed_certificate.main.id
  ssl_state           = "SniEnabled"
}
