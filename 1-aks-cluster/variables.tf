variable "kubernetes-version" {
  type = string
}

variable "node-count" {
  default = "2"
}

variable "vm-size" {
  type = string
}

variable "cluster-name" {
  type = string
}

variable "resource-group-name" {
  type = string
}

variable "location" {
  type = string
}

variable "env-name" {
  type = string
}

variable "acr-scope" {
  type = string
  description = "The Azure scope string for the Azure Container Registry from which the cluster will be allowed to pull."
}

variable "resource-name-prefix" {
  type = string
  description = "A string to be opportunistically prepended in front of created resources."
}
