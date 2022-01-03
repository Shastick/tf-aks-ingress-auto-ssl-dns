variable "dns-manager-principal-id" {
  type = string
}

variable "dns-manager-secret" {
  type = string
}

variable "txt-owner-id" {
  type = string
}

variable "az-dns-resource-group" {
  type = string
}

variable "az-tenant-id" {
  type = string
}

variable "az-subscription-id" {
  type = string
}

variable "az-dns-zone-principal-id" {
  type = string
}

variable "az-dns-zone-principal-secret" {
  type = string
}

variable "domain-filters" {
  type = list(string)
  description = "Only expose these domains via external-DNS"
}
