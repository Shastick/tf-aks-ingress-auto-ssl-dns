#!/usr/bin/env bash

# Exit if any command fails or variables are undefined
set -euo

# Main script to setup an environment.
# You'll note that we need several different calls to TF,
# as the interplay between TF and k8s is not trivial, and prevents a single call to terraform

# DEPENDENCIES:
# This assumes that:
#  - A blob store for TF's state is available and has been parametrized
#    in tf-backend.tfvars
#  - You have a relevant tf_env.sh file with the correct credentials ready to be sourced

# Make the relevant credentials available
# shellcheck disable=SC1090
source "tf_env.sh"

# Install dependencies & validate .tf files
echo "Initialising and validating..."
# Start with a reconfiguration of the backend (in case the env changed since last run)
terraform init -reconfigure -backend-config="tf-backend.tfvars"

# Init stuff in case it's not been done before
terraform init
terraform validate

export TF_CLI_ARGS="-var-file=my-variables.tfvars"

# Apply DNS
echo "Applying DNS ..."
# Calling apply directly on it: if changes are detected when e.g. the aks module is applied,
# required changes are not applied.
terraform apply -target=module.dns-zone

# Apply the AKS cluster.
# This _should_ apply transitive deps such as DNS but does not always seem to
echo "Applying AKS cluster ..."
terraform apply -target=module.aks-cluster

echo "Getting the local kubeconfig ..."
terraform apply -target=local_file.kubeconfig

echo "Applying Helm charts"
# Apply the helm charts for various things the k8s config depend on
# Setting KUBE_CONFIG_PATH as there seem to be bugs SOMETIMES to get the k8s config...
# See https://itnext.io/terraform-dont-use-kubernetes-provider-with-your-cluster-resource-d8ec5319d14a
export KUBE_CONFIG_PATH=./kubeconfig
terraform apply -target=module.helm-charts

echo "Applying final kubernetes config"
# Finally, apply the final kubernetes things
terraform apply -target=module.k8s-config
terraform apply -target=module.k8s-examples
