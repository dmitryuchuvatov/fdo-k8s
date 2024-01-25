# TFE FDO - Kubernetes on AWS


# Prerequisites
* Install [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

* AWS account

* Install [Kubectl](https://kubernetes.io/docs/tasks/tools/)

* Install [Helm](https://helm.sh/docs/intro/install/)

* TFE FDO license

# How To

## Clone repository

```
git clone https://github.com/dmitryuchuvatov/tfe-fdo-eks.git
```

## Change folder

```
cd tfe-fdo-eks
```

## Rename the file called `terraform.tfvars-sample` to `terraform.tfvars` and replace the values with your own.
The current content is below:

```
region           = "eu-west-1"     # AWS region to deploy in
environment_name = "eks-fdo"       # Name of the environment, used in naming of resources
vpc_cidr         = "10.200.0.0/16" # The IP range for the VPC in CIDR format
rds_name         = "fdo"           # Name of PostgreSQL database
rds_username     = "postgres"      # Username for PostgreSQL database
rds_password     = "Password1#"    # Password used for the PostgreSQL database                                                                                                                 
```

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

After ~ 10 minutes, you should see the folowing output:

```
Apply complete! Resources: 27 added, 0 changed, 0 destroyed.
```

When it's done, the AWS Infrastructure is ready for deployment of TFE.

## Switch to `tfe` folder

```
cd tfe/
```

## Rename the file called `terraform.tfvars-sample` to `terraform.tfvars` and replace the values with your own.
The current content is below:

```
region                  = "eu-west-1"                      # AWS region to deploy in
cert_email              = "dmitry.uchuvatov@hashicorp.com" # The email address used to register the certificate
route53_zone            = "tf-support.hashicorpdemo.com"   # The domain of your hosted zone in Route 53
route53_subdomain       = "eks-fdo"                        # The subomain of the URL
tfe_encryption_password = "Password1#"                     # TFE encryption password
replica_count           = "1"                              # Number of Pods/replicas
tfe_release             = "v202312-1"                      # Which release version of TFE to install
tfe_license             = "02MV4UU43..."                   # Value from the License file                                                                                                            
```

## Terraform initialize

```
terraform init
```

## Terraform apply

```
terraform apply
```

When prompted, type **yes** and hit **Enter** to start installing TFE.

After some time, you should see the similar result:

```
Apply complete! Resources: 8 added, 0 changed, 0 destroyed.

Outputs:

tfe_url = "https://eks-fdo.tf-support.hashicorpdemo.com"
```

## Next steps

[Provision your first administrative user](https://developer.hashicorp.com/terraform/enterprise/flexible-deployments/install/initial-admin-user) and start using Terraform Enterprise.

