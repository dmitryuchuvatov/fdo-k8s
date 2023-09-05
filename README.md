# fdo-k8s

# Terraform Enterprise Flexible Deployment Options - Kubernetes


# Prerequisites
Install Terraform as per [official documentation](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

AWS account

Install Kubectl [official documentation](https://kubernetes.io/docs/tasks/tools/)

Install Helm [official documentation](https://helm.sh/docs/intro/install/)

TFE FDO license

# How To

## Clone repository

```
git clone https://github.com/dmitryuchuvatov/fdo-k8s.git
```

## Change folder

```
cd fdo-k8s
```

## Open *terraform.tfvars* and change the values per your requirements

## Set AWS credentials

```
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
export AWS_SESSION_TOKEN=
```

## Terraform init
```
terraform init
```

## Terraform apply

```
terraform apply
```

When prompted, type **yes** and hit **Enter** to start provisioning AWS infrastructure.

You should see the similar result:

```
Apply complete! Resources: 24 added, 0 changed, 0 destroyed.

Outputs:

update_kubectl = "aws eks --region eu-west-1 update-kubeconfig --name demo-fdo-k8s-cluster"
```

## Installing TFE FDO Beta




