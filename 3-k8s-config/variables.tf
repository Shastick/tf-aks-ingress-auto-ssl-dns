variable env-name {
  type = string
}

variable "cluster-name" {
  type = string
}

# Dns updates stuff
variable "dns-manager-principal-id" {
  type = string
}
variable "dns-manager-secret" {
  type = string
}
variable "letsencrypt-email" {
  type = string
}
variable "azure-subscription-id" {
  type = string
}
variable "azure-tenant-id" {
  type = string
}
variable "azure-resource-group-name" {
  type = string
}
variable "azure-zone-name" {
  type = string
}

# Ingress stuff
variable "ingress-parent-domain" {
  type = string
  description = "The domain under which web services & apps are made available"
}

variable "ingress-cert-secret-name" {
  type = string
  description = "Name of the secret where the certificate signed by letsencrypt will be stored, in each extra namespace"
}

# Oauth2 Proxy stuff
variable "oauth2-proxy-namespace" {
  type = string
}

variable "oauth2-proxy-ingress-subdomain" {
  type = string
  description = "The subdomain under which the oauth proxy is made available"
  default = "auth"
}

variable "oauth2-allowed-email-domains" {
  type = list(string)
  description = "The email domains allowed to authenticate via the oauth2 proxy"
}

variable "extra-namespaces" {
  description = "Additional namespaces (besides the required ones) to be created."
  type = list(string)
}

locals {
  oauth2-proxy-domain = "${var.oauth2-proxy-ingress-subdomain}.${var.ingress-parent-domain}"
}
