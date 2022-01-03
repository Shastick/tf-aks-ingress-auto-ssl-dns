# Information you get when creating a service principal
# The appId
export ARM_CLIENT_ID="<APP _ID>"
# Subscription Id
export ARM_SUBSCRIPTION_ID="<SUB ID>"
# Tenant ID
export ARM_TENANT_ID="<TENANT_ID>"
# Password for the service principal
export ARM_CLIENT_SECRET="<SECRET>"

# The storage account used to store the terraform state
# Account key for the terraform state storage
export ARM_ACCESS_KEY="<Storage_account_access_key>"

# Ensure that KUBE_CONFIG_FILE and KUBE_CONFIG_FILES environment variables are NOT set,
# as they will interfere with the cluster build (the kubernetes terraform module is influenced by these)
unset KUBE_CONFIG_FILE
unset KUBE_CONFIG_FILES