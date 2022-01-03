terraform {
  required_providers {
    htpasswd   = {
      source  = "loafoe/htpasswd"
      version = "1.0.1"
    }
    kubectl    = {
      source  = "gavinbunney/kubectl"
      version = "1.13.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.3"
    }
    azurerm    = {
      source  = "hashicorp/azurerm"
      version = "2.48"
    }
    helm       = {
      source  = "hashicorp/helm"
      version = ">= 2.1.0"
    }
  }
  backend "azurerm" {}
}

data "azurerm_kubernetes_cluster" "default" {
  depends_on          = [module.aks-cluster] # refresh cluster state before reading
  name                = local.cluster-name
  resource_group_name = local.resource-group-name
}

resource "local_file" "kubeconfig" {
  depends_on = [data.azurerm_kubernetes_cluster.default]
  content    = data.azurerm_kubernetes_cluster.default.kube_config_raw
  filename   = "${path.module}/kubeconfig"
}

data "azurerm_client_config" "current" {}

provider htpasswd {}

provider "kubectl" {
  host                   = data.azurerm_kubernetes_cluster.default.kube_config.0.host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.default.kube_config.0.client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.default.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.default.kube_config.0.cluster_ca_certificate)
  load_config_file       = false
}

provider "kubernetes" {
  host                   = data.azurerm_kubernetes_cluster.default.kube_config.0.host
  client_certificate     = base64decode(data.azurerm_kubernetes_cluster.default.kube_config.0.client_certificate)
  client_key             = base64decode(data.azurerm_kubernetes_cluster.default.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.default.kube_config.0.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = data.azurerm_kubernetes_cluster.default.kube_config.0.host
    client_certificate     = base64decode(data.azurerm_kubernetes_cluster.default.kube_config.0.client_certificate)
    client_key             = base64decode(data.azurerm_kubernetes_cluster.default.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(data.azurerm_kubernetes_cluster.default.kube_config.0.cluster_ca_certificate)
  }
}

provider "azurerm" {
  features {}
}

module "dns-zone" {
  source              = "0-dns-zone"
  resource-group-name = local.dnz-zone-resource-group
  location            = var.azure-region
  env-name            = var.env-name
  dns-domain          = local.complete-dns-domain
}

module "aks-cluster" {
  depends_on           = [module.dns-zone]
  source               = "1-aks-cluster"
  kubernetes-version   = var.aks-kubernetes-version
  cluster-name         = local.cluster-name
  resource-group-name  = local.resource-group-name
  location             = var.azure-region
  vm-size              = var.aks-vm-type
  node-count           = var.aks-pool-size
  env-name             = var.env-name
  acr-scope            = var.aks-acr-scope
  resource-name-prefix = var.resource-name-prefix
}

module "helm-charts" {
  depends_on                   = [module.aks-cluster]
  source                       = "2-helm-charts"
  dns-manager-principal-id     = module.dns-zone.dns-manager-principal-id
  dns-manager-secret           = module.dns-zone.dns-manager-secret
  az-dns-resource-group        = local.dnz-zone-resource-group
  az-dns-zone-principal-id     = module.dns-zone.dns-manager-principal-id
  az-dns-zone-principal-secret = module.dns-zone.dns-manager-secret
  az-subscription-id           = data.azurerm_client_config.current.subscription_id
  az-tenant-id                 = data.azurerm_client_config.current.tenant_id
  domain-filters               = concat(var.ext-dns-extra-domain-filters, [local.complete-dns-domain])
  txt-owner-id                 = local.cluster-name
}

module "k8s-config" {
  depends_on                = [module.aks-cluster]
  source                    = "3-k8s-config"
  env-name                  = var.env-name
  cluster-name              = local.cluster-name
  dns-manager-principal-id  = module.dns-zone.dns-manager-principal-id
  dns-manager-secret        = module.dns-zone.dns-manager-secret
  azure-resource-group-name = local.resource-group-name
  azure-subscription-id     = data.azurerm_client_config.current.subscription_id
  azure-tenant-id           = data.azurerm_client_config.current.tenant_id
  azure-zone-name           = local.complete-dns-domain
  letsencrypt-email         = var.letsencrypt-email

  ingress-parent-domain    = local.complete-dns-domain
  ingress-cert-secret-name = local.ingress-cert-secret-name

  oauth2-proxy-namespace       = "oauth2-proxy"
  oauth2-allowed-email-domains = var.oauth2-allowed-email-domains

  extra-namespaces = concat(var.aks-namespaces, ["examples"])
}

module "k8s-examples" {
  depends_on             = [module.k8s-config]
  source                 = "4-k8s-examples"
  example-namespace      = "examples"
  ingress-parent-domain  = local.complete-dns-domain
  oauth2-redirect-domain = "auth.${local.complete-dns-domain}"
  cert-secret-name       = local.ingress-cert-secret-name
}

module "k8s-ssf" {
  depends_on    = [module.k8s-config]
  source        = "./k8s-ssf"
  env-name = var.env-name
  blob-resource-group = local.resource-group-name
  blob-region = var.azure-region

  k8s-namespace = "ssf-demo"
}
