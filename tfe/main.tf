# Fetching the data from State file and authorizing to EKS clusrer

data "terraform_remote_state" "infra" {
  backend = "local"

  config = {
    path = "${path.module}/../terraform.tfstate"
  }
}

data "aws_eks_cluster" "k8s" {
  name = data.terraform_remote_state.infra.outputs.cluster_name
}

data "aws_eks_cluster_auth" "k8s" {
  name = data.terraform_remote_state.infra.outputs.cluster_name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.k8s.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.k8s.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.k8s.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.k8s.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.k8s.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.k8s.token
  }
}

locals {
  namespace = "terraform-enterprise"
}

# SSL certificates

resource "tls_private_key" "cert_private_key" {
  algorithm = "RSA"
}

resource "acme_registration" "registration" {
  account_key_pem = tls_private_key.cert_private_key.private_key_pem
  email_address   = var.cert_email
}

resource "acme_certificate" "certificate" {
  account_key_pem = acme_registration.registration.account_key_pem
  common_name     = "${var.route53_subdomain}.${var.route53_zone}"

  dns_challenge {
    provider = "route53"

    config = {
      AWS_HOSTED_ZONE_ID = data.aws_route53_zone.selected.zone_id
    }
  }
}

resource "aws_acm_certificate" "cert" {
  certificate_body  = acme_certificate.certificate.certificate_pem
  private_key       = acme_certificate.certificate.private_key_pem
  certificate_chain = acme_certificate.certificate.issuer_pem
}

# Preparing K8s namespace and secret

resource "kubernetes_namespace" "terraform-enterprise" {
  metadata {
    name = local.namespace
  }
}

resource "kubernetes_secret" "example" {
  metadata {
    name      = local.namespace
    namespace = local.namespace
  }

  data = {
    ".dockerconfigjson" = <<DOCKER
{
  "auths": {
    "images.releases.hashicorp.com": {
      "auth": "${base64encode("terraform:${var.tfe_license}")}"
    }
  }
}
DOCKER
  }

  type = "kubernetes.io/dockerconfigjson"
}

# Populating data into Helm chart

resource "helm_release" "tfe" {
  name       = local.namespace
  repository = "helm.releases.hashicorp.com"
  chart      = "hashicorp/terraform-enterprise"
  namespace  = local.namespace

  values = [
    templatefile("${path.module}/values.yaml", {
      replica_count = var.replica_count
      cert_data     = "${base64encode(acme_certificate.certificate.certificate_pem)}"
      key_data      = "${base64encode(nonsensitive(acme_certificate.certificate.private_key_pem))}"
      ca_cert_data  = "${base64encode(acme_certificate.certificate.issuer_pem)}"
      tfe_release   = var.tfe_release
      fqdn          = "${var.route53_subdomain}.${var.route53_zone}"
      pg_address    = data.terraform_remote_state.infra.outputs.pg_address
      pg_dbname     = data.terraform_remote_state.infra.outputs.pg_dbname
      pg_user       = data.terraform_remote_state.infra.outputs.pg_user
      pg_password   = data.terraform_remote_state.infra.outputs.pg_password
      s3_bucket     = data.terraform_remote_state.infra.outputs.s3_bucket
      region        = data.terraform_remote_state.infra.outputs.region
      redis_host    = data.terraform_remote_state.infra.outputs.redis_host
      enc_password  = var.tfe_encryption_password
      tfe_license   = var.tfe_license
    })
  ]
  depends_on = [
    kubernetes_secret.example, kubernetes_namespace.terraform-enterprise
  ]
}

# Pointing DNS to a newly created LB
data "kubernetes_service" "example" {
  metadata {
    name      = local.namespace
    namespace = local.namespace
  }
  depends_on = [helm_release.tfe]
}

data "aws_route53_zone" "selected" {
  name         = var.route53_zone
  private_zone = false
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "${var.route53_subdomain}.${var.route53_zone}"
  type    = "CNAME"
  ttl     = "300"
  records = [data.kubernetes_service.example.status.0.load_balancer.0.ingress.0.hostname]

  depends_on = [helm_release.tfe]
}