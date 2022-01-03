
terraform {
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = ">= 2.0.3"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.1.0"
    }
  }
}

resource helm_release nginx_ingress {
  name       = "nginx-ingress-controller"
  namespace        = "ingress-nginx"
  create_namespace = true
  chart      = "nginx-ingress-controller"
  repository = "https://charts.bitnami.com/bitnami"
  version = "9.1.9"

  values = [
    file("${path.module}/nginx-ingress-values.yaml")
  ]
}

# k8s secret with the creds having the rights to manage the DNS zone
resource "kubernetes_secret" "azuredns" {
  depends_on = [helm_release.nginx_ingress]
  metadata {
    name = "secret-azuredns-config"
    namespace = "ingress-nginx"
  }

  data = {
    principal_id = var.dns-manager-principal-id
    password = var.dns-manager-secret
  }

  type = "kubernetes.io/basic-auth"
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true
  chart            = "cert-manager"
  repository       = "https://charts.jetstack.io"
  version          = "v1.5.3"
  values = [
    file("${path.module}/cert-manager-values.yaml")
  ]
}

resource "helm_release" "external_dns" {
  name = "external-dns"
  namespace = "external-dns"
  create_namespace = true
  chart = "external-dns"
  repository = "https://charts.bitnami.com/bitnami"
  version = "6.1.8"

  set {
    name  = "txtOwnerId"
    value = var.txt-owner-id
  }
  set {
    name = "provider"
    value = "azure"
  }
  set {
    name = "azure.resourceGroup"
    value = var.az-dns-resource-group
  }
  set {
    name = "azure.tenantId"
    value = var.az-tenant-id
  }
  set {
    name = "azure.subscriptionId"
    value = var.az-subscription-id
  }
  set {
    name = "azure.aadClientId"
    value = var.az-dns-zone-principal-id
  }
  set {
    name = "azure.aadClientSecret"
    value = var.az-dns-zone-principal-secret
  }
  set {
    name = "azure.cloud"
    value = "AzurePublicCloud"
  }
  set {
    name = "policy"
    value = "sync"
  }
  set {
    name = "domainFilters"
    # Encode a helm array for --set ...
    value = "{${join(",", var.domain-filters)}}"
  }
}
