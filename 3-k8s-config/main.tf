terraform {
  required_providers {
    htpasswd   = {
      source  = "loafoe/htpasswd"
      version = "1.0.1"
    }
    azurerm    = {
      source  = "hashicorp/azurerm"
      version = "2.48"
    }
    kubectl    = {
      source  = "gavinbunney/kubectl"
      version = "1.13.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.3"
    }
    random     = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }
  }
}

data "azuread_client_config" "current" {}

resource "random_uuid" "auth-permission" {}

# IMPORTANT NOTE: before this app can be used to authenticate,
# an admin needs to accept it via the Azure Portal in the Azure Active Directory's app settings.
resource "azuread_application" "oauth2-auth" {
  display_name = "oauth2-proxy-auth-${var.env-name}"
  owners       = [data.azuread_client_config.current.object_id]

  web {
    homepage_url  = "https://${local.oauth2-proxy-domain}"
    logout_url    = "https://${local.oauth2-proxy-domain}/logout"
    redirect_uris = ["https://${local.oauth2-proxy-domain}/oauth2/callback"]
  }

  api {
    # Note the application needs "User.Read" permission and to have the admin consent,
    # which may not be a thing that is doable via terraform
    oauth2_permission_scope {
      admin_consent_description  = "Let the app access the user profile in order to authenticate."
      admin_consent_display_name = "Authentication"
      enabled                    = true
      id                         = random_uuid.auth-permission.result
      type                       = "User"
      user_consent_description   = "Let the app access the user profile in order to authenticate."
      user_consent_display_name  = "Authentication"
      value                      = "user_impersonation"
    }
  }

}

resource "azuread_service_principal" "oauth2-auth" {
  application_id               = azuread_application.oauth2-auth.application_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal_password" "oauth2-auth" {
  service_principal_id = azuread_service_principal.oauth2-auth.object_id
}

resource "random_string" "cookie-seed" {
  length  = 16
  special = false
}

resource "kubernetes_namespace" "oauth2_proxy" {
  metadata {
    name = var.oauth2-proxy-namespace
  }
}

resource "kubernetes_secret" "oauth2-auth_creds" {
  metadata {
    name      = "oauth2-proxy-auth-creds"
    namespace = kubernetes_namespace.oauth2_proxy.metadata[0].name
  }

  data = {
    api_client_secret = azuread_service_principal_password.oauth2-auth.value
    api_cookie_secret = random_string.cookie-seed.result
  }

}

# Secret for updating the DNS zone
resource "kubernetes_secret" "azure_dns_creds" {
  metadata {
    name      = "azure-dns-creds"
    # TODO parameter
    namespace = "cert-manager"
  }

  data = {
    password = var.dns-manager-secret
  }

}

data "kubectl_file_documents" "cluster-issuer" {
  content = templatefile("${path.module}/templates/cluster-issuer.yaml.tftpl", {
    letsencrypt_email            = var.letsencrypt-email
    azure_service_principal_id   = var.dns-manager-principal-id
    azure_client_secret_key_name = "azure-dns-creds"
    azure_subscription_id        = var.azure-subscription-id
    azure_tenant_id              = var.azure-tenant-id
    azure_resource_group_name    = var.azure-resource-group-name
    azure_zone_name              = var.azure-zone-name
  })
}

resource "kubectl_manifest" "cluster-issuer" {
  yaml_body = data.kubectl_file_documents.cluster-issuer.content
}

# This file is added to git so it is available to terraform
# at terraform apply time, even if it should be overridden first from the relevant template
# Having the file allows us to use kubectl_manifest's for_each field
# which complains if it can't know how many manifests are available at apply time.
data "kubectl_file_documents" "oauth2-proxy" {
  content = templatefile("${path.module}/templates/oauth2-proxy.yaml.tftpl", {
    namespace            = var.oauth2-proxy-namespace
    azure_tenant_id      = var.azure-tenant-id
    api_client_id        = azuread_service_principal.oauth2-auth.application_id
    email_domains        = var.oauth2-allowed-email-domains
    cookie_domain        = var.ingress-parent-domain
    whitelist_domains    = [".${var.ingress-parent-domain}"]
    internal_auth_domain = "auth.${var.ingress-parent-domain}"
  })
}

resource "kubectl_manifest" "oauth2-proxy" {
  # Hardcoding the count of manifests we find in the generated kubectl_file_documents oauth2-proxy file,
  # we need it otherwise terraform can't determine how many resources it will need to apply.
  count     = 3
  yaml_body = element(data.kubectl_file_documents.oauth2-proxy.documents, count.index)
}

data "kubectl_file_documents" "extra-certificates" {
  for_each = toset(var.extra-namespaces)
  content  = templatefile("${path.module}/templates/certificate.yaml.tftpl", {
    namespace   = each.key
    secret_name = var.ingress-cert-secret-name
    common_name = "*.${var.ingress-parent-domain}"
    # TODO only include namespace relevant domains here?
    # Alternatively, cert-manager might be able to request non-wildcard certs?
    dns_names   = [
      var.ingress-parent-domain,
      "*.${var.ingress-parent-domain}"
    ]
  })
}

resource "kubernetes_namespace" "extra-namespaces" {
  for_each = toset(var.extra-namespaces)
  metadata {
    name = each.key
  }
}

resource "kubernetes_manifest" "certificates" {
  depends_on = [kubernetes_namespace.extra-namespaces]
  for_each   = toset(var.extra-namespaces)
  manifest   = yamldecode(data.kubectl_file_documents.extra-certificates[each.key].content)
}
