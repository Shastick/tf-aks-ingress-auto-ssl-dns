output "dns-manager-principal-id" {
  depends_on   = [azuread_service_principal_password.dns-manager]

  value = azuread_service_principal.dns-manager.application_id
}

output "dns-manager-secret" {
  depends_on   = [azuread_service_principal_password.dns-manager]
  value = azuread_service_principal_password.dns-manager.value
}
