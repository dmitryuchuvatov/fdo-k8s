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

Establish a connection with the Kubernetes cluster by running the command from the previous output.

You should see the similar message:

```
Added new context arn:aws:eks:eu-west-1:323533494701:cluster/demo-fdo-k8s-cluster to /Users/dmitryuchuvatov/.kube/config
```

Create a custom namespace

```
kubectl create namespace terraform-enterprise
```

Create image pull secret

Create an image pull secret in the namespace from previous step to fetch the *terraform-enterprise* container from the registry appropriate to your installation:

```
kubectl create secret docker-registry terraform-enterprise --docker-server=terraform-enterprise-beta.terraform.io --docker-username=hc-support-tfe-beta --docker-password=3gdnBJlYWMvOgnnL0GnEMrff2t5dBmLR4OuMt+Niph+ACRDyGuJE  -n terraform-enterprise
```

Add the Hashicorp helm registry and render a local template of the Terraform Enterprise chart:



```
helm repo add hashicorp https://helm.releases.hashicorp.com
```
Once the helm repo is added, render the terraform-enterprise chart via:



```
helm template terraform-enterprise hashicorp/terraform-enterprise
```

Install terraform-enterprise via helm pointing to the **values.yaml** file. **Make sure to edit the file before running this command!** 

More information [here](https://developer.hashicorp.com/terraform/enterprise/flexible-deployments-beta/install/kubernetes#optional-configurations)

```
helm install terraform-enterprise hashicorp/terraform-enterprise -f values.yaml -n terraform-enterprise
```

It should return the similar output:

```
NAME: terraform-enterprise
LAST DEPLOYED: Tue Sep  5 10:30:26 2023
NAMESPACE: terraform-enterprise
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

Wait ~3 minutes and run the following command to check the status of the installation.

```
kubectl get pods -n terraform-enterprise
```

In the output, the **STATUS** should be in *Running* state and the ***READY** section should show *1/1*. e.g:

```
NAME                                    READY   STATUS    RESTARTS   AGE
terraform-enterprise-6446dd8857-lg5h8   1/1     Running   0          2m34s
```

Run the following command and copy the value from **EXTERNAL-IP** section:

```
kubectl get services -n terraform-enterprise

NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP                                                               PORT(S)         AGE
terraform-enterprise   LoadBalancer   172.20.218.45   a1b29588a386a4ed1a96f03ef653a412-1431959226.eu-west-1.elb.amazonaws.com   443:31688/TCP   2m51s
```

Now, navigate to AWS Console -> Route 53 -> choose the hosted zone -> Create record -> specify the same record name as in **values.yaml**, select *CNAME* as **Record type**, paste the External IP into Value field -> Create records:

![Screenshot 2023-09-05 at 10 33 56](https://github.com/dmitryuchuvatov/fdo-k8s/assets/119931089/302a76e7-651f-4604-a975-1867be73933a)

You should be able to reach TFE FDO instance with FQDN:

![Screenshot 2023-09-05 at 11 00 03](https://github.com/dmitryuchuvatov/fdo-k8s/assets/119931089/3711c353-f93d-4bdb-bdf2-86cd5cff8046)


## Obtain initial user token and create the initial user account

To obtain the token to create an admin user, you can exec into the container. E.g:

```
kubectl exec -it <POD-NAME> -n terraform-enterprise -- bash -c "/usr/local/bin/retrieve-iact"
```

Save the token (without the **%** from the end) and append it to the TFE URL. E.g:

```
https://<TFE_HOSTNAME>/admin/account/new?token=<TOKEN>
```

![Screenshot 2023-09-05 at 11 02 29](https://github.com/dmitryuchuvatov/fdo-k8s/assets/119931089/eb93e700-1ae8-4b87-9ed0-a44e4844903e)

Proceed with creating an initial account and once it’s done, TFE FDO Beta is ready to use.

![Screenshot 2023-09-05 at 11 02 42](https://github.com/dmitryuchuvatov/fdo-k8s/assets/119931089/7944c4ec-651f-430c-b2cf-dd1a3a6003ba)

