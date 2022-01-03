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
    random     = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }
  }
}

# kubernetes_manifest and kubectl_manifest needs a single manifest:
# here we extract individual manifests.
# Possibly overkill, but this serves as an example.
data "kubectl_file_documents" "ping_app_manifests" {
  content = templatefile("${path.module}/ping-ingress-app.yaml", {
    namespace        = var.example-namespace
    secret_name      = var.cert-secret-name
    ping_test_domain = "ping.${var.ingress-parent-domain}"
  })
}

resource "kubectl_manifest" "ping_app" {
  count     = 3
  yaml_body = element(data.kubectl_file_documents.ping_app_manifests.documents, count.index)
}

# Basic Auth example app

# Define a hashed password:
resource "random_password" "password" {
  length = 30
}

resource "htpasswd_password" "hash" {
  password = random_password.password.result
  salt     = "AnAwesomeSalt"
}

# Store them in a secret
# Secret for updating the DNS zone
resource "kubernetes_secret" "basic_auth_creds" {
  metadata {
    name      = "basic-auth-creds"
    namespace = var.example-namespace
  }

  data = {
    # bcrypt would be optimal but does not seem to be support for basic auth with nginx
    # (See https://stackoverflow.com/questions/31833583/nginx-gives-an-internal-server-error-500-after-i-have-configured-basic-auth)
    # Falling back to sha512: if we believe https://iceburn.medium.com/how-handle-htpasswd-in-nginx-d6ca28def2e4
    # it's not too bad.
    "auth" = <<-EOF
              test-user:${htpasswd_password.hash.sha512}
             EOF
  }

}

# Store the password to file for demo usage
resource "local_file" "basic-password" {
  content  = "test-user:${random_password.password.result}"
  filename = "${path.module}/basic-password.txt"
}

data "kubectl_file_documents" "basic_auth_app_manifests" {
  content = templatefile("${path.module}/basic-auth-ingress-app.yaml", {
    namespace              = var.example-namespace
    secret_name            = var.cert-secret-name
    basic_auth_test_domain = "basic-auth.${var.ingress-parent-domain}"
  })
}

resource "kubectl_manifest" "basic_auth_app" {
  count     = 3
  yaml_body = element(data.kubectl_file_documents.basic_auth_app_manifests.documents, count.index)
}

data "kubectl_file_documents" "aad_auth_test" {
  content = templatefile("${path.module}/aad-auth-ingress-app.yaml", {
    namespace            = var.example-namespace
    auth_redirect_domain = var.oauth2-redirect-domain
    secret_name          = var.cert-secret-name
    auth_test_domain     = "aad-test.${var.ingress-parent-domain}"
  })
}

resource "kubectl_manifest" "aad_auth_test" {
  count     = 3
  yaml_body = element(data.kubectl_file_documents.aad_auth_test.documents, count.index)
}
