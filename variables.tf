variable "project" {
  type    = string
  default = "contoso"
}

variable "location" {
  type = object({
    name = string
    code = string
  })
  default = {
    name = "westeurope"
    code = "weu"
  }
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "tenant_id" {
  type = string
}

variable "subscription_id" {
  type = string
}

variable "app_virtual_network_address_space" {
  type    = string
  default = "192.168.0.0/24"
}

variable "svc_virtual_network_address_space" {
  type    = string
  default = "192.168.1.0/24"
}

variable "service_plan_sku_name" {
  type    = string
  default = "B1"
}

variable "key_vault_soft_delete_retention_days" {
  type    = number
  default = 7
}

variable "sql_server_administrator_login" {
  type     = string
  nullable = true
  default  = null
}

variable "dns_zone_id" {
  type = string
}

variable "web_app_repo_url" {
  type    = string
  default = "https://github.com/mdmsft/web-app-dotnet-ado-sql"
}
