# Region
azure-region="northcentralus"

# Naming of resources being created as well as the environment name, if you intend to have eg 'dev', 'staging', etc
resource-name-prefix="<some-prefix>"
env-name="dev"

# DNS and environment name
dns-domain="<your domain>"
# The domain prefix is specified separately from the 'env-name' above,
# should you want to give it a different name
env-domain-prefix="dev"

# AKS
aks-kubernetes-version="1.22.6"
aks-vm-type="standard_d2_v2"
# Set a conservative value, bump up as needed
aks-pool-size=1
# Scope is a String in the form: "/subscriptions/<subscription_id>/resourceGroups/<rg_name>/providers/Microsoft.ContainerRegistry/registries/<registry_name>"
aks-acr-scope="<ACR SCOPE>"

# If needed, addition namespaces you want to be created
aks-namespaces=[]

# External DNS
# If additional domains need to be set for the external-dns filter
# Note that the main dns-domain is included by default.
ext-dns-extra-domain-filters=[]

# List of domains for which authentication via oauth2-proxy is enabled
oauth2-allowed-email-domains=[]

# The e-mail to be used for let's encrypt notifications
letsencrypt-email="<>"
