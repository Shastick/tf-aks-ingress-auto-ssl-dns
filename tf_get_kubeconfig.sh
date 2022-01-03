#!/usr/bin/env bash

# Exit if any command fails or variables are undefined
set -euo

# Make the relevant credentials available
# shellcheck disable=SC1090
source "tf_env.sh"

# Start with a reconfiguration of the backend (in case the env changed since last run)
terraform init -reconfigure -backend-config="tf-backend.tfvars"

export TF_CLI_ARGS="-var-file=my-variables.tfvars"

# Regenerate the local kubeconfig so you can interact with the kubernetes cluster,
# if you don't have it available locally.

echo "Getting the local kubeconfig ..."
terraform apply -target=local_file.kubeconfig
