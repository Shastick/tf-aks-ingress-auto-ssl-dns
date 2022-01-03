variable "example-namespace" {
  type = string
  description = "The namespace to be running the examples in"
}

variable "ingress-parent-domain" {
  type = string
  description = "Parent domain to be used for example apps."
}

variable "oauth2-redirect-domain" {
  type = string
  description = "The domain in charge of doing oauth2 authentication with nginx"
}

variable "cert-secret-name" {
  type = string
  description = "Name of the secret holding the SSL certificate for ingress(e)s"
  default = "wildcard"
}
