# Out Of The Box, Batteries Included Terraform AKS setup

Are you building things and seeking to host them on AKS? 
Do you have several common needs such as basic authentication, AAD integration or let's encrypt integration?
Do you want to manage the whole enchilada with Terraform?

If so, this repo can be a good place for you to begin from.

## Spec

This repo is a sample Terraform managed configuration for Azure that sets up and configures:

 - An Azure DNS Zone (of your choice)
 - An AKS Cluster with:
   - `nginx` installed as the ingress
   - Automated DNS updates upon ingress creation for subdomains of the aforementioned zone
   - Automated wildcard certificate creation and renewal with let's encrypt
   - [oauth2-proxy](https://github.com/oauth2-proxy/oauth2-proxy) to provide integration with supported authentication providers
   - Access to a pre-existing ACR (Azure Container Registry)
 - Some authentication examples:
   - Basic (username + password)
   - AAD integration

For details, please see the relevant Terraform modules, which contain a faire amount of comments.

### Dependencies

- An Azure Subscription with proper credentials
- An Admin account on said Subscription if you intend to do a simple integration with AAD
- An Azure blob store for storing the Terraform state (if you so wish)
- An existing Azure Container Registry to deploy your containers from
- A DNS domain for which Azure is the authority

## Howto

1. Set the relevant subscription credentials in [tf_env.sh](tf_env.sh)
2. Assuming you want to store your terraform state in an Azure Blob store, you'll need to create a storage account and set the credentials in [tf-backend.tfvars](tf-backend.tfvars)
3. [variables.tf](variables.tf) contains the variables you'll most likely want to define to your specific case, 
which you can conveniently do in [my-variables.tfvars](my-variables.tfvars). 
4. run [tf_apply_all.sh](tf_apply_all.sh) to apply the Terraform manifests.
5. run [tf_get_kubeconfig.sh](tf_get_kubeconfig.sh) to generate the `kubeconfig` file to interact with the AKS cluster.
6. Try out `ping.<your-configured-domain-zone>` or the other variants



## About

Last year (2021) I ran into frustrations with kubernetes on Azure (AKS) when I was trying to host some API endpoints relatively seriously. 
That is, with proper SSL, authentication and having everything _as code_ to easily replicate the setup where needed.

For all the parts I required, there were numerous examples, albeit not all of them specified provided with _terraform_.

This repo is both a template for me to re-use later, and for anyone to use if they like.

## Caveat emptor

Terraform and kubernetes don't play that well together: 
it works but actually requires running terraform in multiple steps, as no plan to deploy kubernetes resources can be prepared against a non-existing cluster.
Terraform is good enough to set up some basic things in kubernetes, but you'll probably want another solution if you are deploying often.

Also, some kubernetes resources are templated with the terraform templating language.

Furthermore, this may not work _out of the box_ as it is the result of a few iterations: please get in touch if you have any questions.

## Sources

This sample includes inspiration from the following sources:
 - https://github.com/hashicorp/terraform-provider-kubernetes/tree/main/_examples/aks
 - https://www.thorsten-hans.com/external-dns-azure-kubernetes-service-azure-dns/
 - https://www.mytechramblings.com/posts/automate-azure-ad-app-registration-using-terraform/
 - https://itnext.io/terraform-dont-use-kubernetes-provider-with-your-cluster-resource-d8ec5319d14a

## Kubeconfig
If you need the kubeconfig that terraform relies on to create AKS resources, you can generate it locally with:
```
./tf_get_kubeconfig.sh
```

Note that you can also get a personal kubeconfig via the `az` CLI with `az aks`.

## AAD Integration

Note that the application created by terraform will need some administrator's approval in the Azure Portal.
