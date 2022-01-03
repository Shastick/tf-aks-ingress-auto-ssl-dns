variable "env-name" {
  type = string
  description = "Environment name (such as 'dev' or 'prod')"
}

variable "dns-domain" {
  type = string
  description = "The domain/DNS Zone under which services will be made available. Should already include the prefixes s.a. 'dev' or 'prod'"
}

variable "resource-group-name" {
  type = string
}

variable "location" {
  type = string
}
