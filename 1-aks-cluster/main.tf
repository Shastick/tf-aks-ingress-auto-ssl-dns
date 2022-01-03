terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.48"
    }
  }
}

resource "azurerm_kubernetes_cluster" "cluster" {
  name                = "${var.resource-name-prefix}-${var.env-name}"
  location            = var.location
  resource_group_name = var.resource-group-name
  dns_prefix          = "${var.resource-name-prefix}-${var.env-name}"
  kubernetes_version  = var.kubernetes-version

  default_node_pool {
    name       = "default"
    node_count = var.node-count
    vm_size    = var.vm-size
  }

  identity {
    type = "SystemAssigned"
  }
}

# Allow the AKS cluster to pull from our central docker registry
resource "azurerm_role_assignment" "acr_pull_access" {
  # The ACR is managed via TF in a separate module (cf infra)
  # Interesting question: how to share it to both dev and prod?
  # (the ACR is managed via TF but through a non-related module)
  # Get this via the "JSON View" of the overview.
  scope                = var.acr-scope
  role_definition_name = "AcrPull"
  # Taken from https://stackoverflow.com/a/71049680
  # Question is: does/will this work with different types of agent pools?
  principal_id         = azurerm_kubernetes_cluster.cluster.kubelet_identity[0].object_id
}
