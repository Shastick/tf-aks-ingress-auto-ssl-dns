terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.48"
    }
  }
}

data "azuread_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = var.resource-group-name
  location = var.location
}

resource "azuread_application" "dns-manager" {
  display_name = "${var.env-name}-dns-zone-manager"
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "dns-manager" {
  application_id               = azuread_application.dns-manager.application_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal_password" "dns-manager" {
  service_principal_id = azuread_service_principal.dns-manager.object_id
}

resource "azurerm_dns_zone" "dns-zone" {
  name                = var.dns-domain
  resource_group_name = azurerm_resource_group.rg.name
}

# DNS manager SP gets contributor rights on the dns zone
resource "azurerm_role_assignment" "dns-assignment" {
  scope                = azurerm_dns_zone.dns-zone.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.dns-manager.id
}
