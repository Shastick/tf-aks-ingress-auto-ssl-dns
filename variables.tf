variable "env-name" {
  type = string
  description = "Environment name (such as 'dev' or 'prod')"
}

variable "env-domain-prefix" {
  type = string
  description = "Environment domain prefix (such as 'app' or 'dev')"
}

variable "dns-domain" {
  type = string
  description = "The domain/DNS Zone under which services will be made available. Should not include the prefixes s.a. 'dev' or 'prod'"
}

variable "azure-region" {
  type    = string
  default = "northcentralus"
}

variable resource-name-prefix {
  type = string
  description = "Prefix for the name of all resources that will be created"
}

variable aks-vm-type {
  type = string
  description = "VM ID for the agent pool used for AKS"
}

variable aks-pool-size {
  type = number
  description = "Number of nodes in the default AKS node pool"
}

variable "aks-acr-scope" {
  type = string
  description = "The Azure scope string for the Azure Container Registry from which the cluster will be allowed to pull."
}

variable "aks-namespaces" {
  type = list(string)
  description = "AKS namespaces to create for usage once the cluster is set up."
}

variable "aks-kubernetes-version" {
  type = string
  description = "Version of Kubernetes to install with AKS"
}

variable ext-dns-extra-domain-filters {
  type = list(string)
  description = "Additional domains to be passed to the external-dns domain-filters"
}

variable letsencrypt-email {
  type = string
}

variable "oauth2-allowed-email-domains" {
  type = list(string)
  description = "The email domains allowed to authenticate via the oauth2 proxy"
}

locals {
  pfx = var.resource-name-prefix
  cluster-name = "${local.pfx}-${var.env-name}"
  resource-group-name = "${local.pfx}-${var.env-name}"
  dnz-zone-resource-group = local.resource-group-name
  complete-dns-domain = "${var.env-domain-prefix}.${var.dns-domain}"
  ingress-cert-secret-name = "wildcard"
}
