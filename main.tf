# VPC
resource "aws_vpc" "tfe" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "${var.environment_name}-vpc"
  }
}

# Public Subnet #1
resource "aws_subnet" "tfe_public1" {
  vpc_id                  = aws_vpc.tfe.id
  cidr_block              = cidrsubnet(local.subnet, 8, 1)
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment_name}-subnet-public1"
  }
}

# Public Subnet #2
resource "aws_subnet" "tfe_public2" {
  vpc_id                  = aws_vpc.tfe.id
  cidr_block              = cidrsubnet(local.subnet, 8, 2)
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment_name}-subnet-public2"
  }
}

# Private Subnet #1
resource "aws_subnet" "tfe_private1" {
  vpc_id            = aws_vpc.tfe.id
  cidr_block        = cidrsubnet(local.subnet, 8, 11)
  availability_zone = "${var.region}a"

  tags = {
    Name = "${var.environment_name}-subnet-private1"
  }
}

# Private Subnet #2
resource "aws_subnet" "tfe_private2" {
  vpc_id            = aws_vpc.tfe.id
  cidr_block        = cidrsubnet(local.subnet, 8, 12)
  availability_zone = "${var.region}b"

  tags = {
    Name = "${var.environment_name}-subnet-private2"
  }
}

# IGW (Internet Gateway)
resource "aws_internet_gateway" "tfe_igw" {
  vpc_id = aws_vpc.tfe.id

  tags = {
    Name = "${var.environment_name}-igw"
  }
}

# Link IGW with Route Table
resource "aws_default_route_table" "tfe" {
  default_route_table_id = aws_vpc.tfe.default_route_table_id

  route {
    cidr_block = local.all_ips
    gateway_id = aws_internet_gateway.tfe_igw.id
  }

  tags = {
    Name = "${var.environment_name}-rtb"
  }
}

# Security Group
resource "aws_security_group" "tfe_sg" {
  name   = "${var.environment_name}-sg"
  vpc_id = aws_vpc.tfe.id

  tags = {
    Name = "${var.environment_name}-sg"
  }
}

resource "aws_security_group_rule" "allow_https_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.tfe_sg.id

  from_port   = var.https_port
  to_port     = var.https_port
  protocol    = local.tcp_protocol
  cidr_blocks = [local.all_ips]
}

resource "aws_security_group_rule" "allow_postgresql_inbound_vpc" {
  type              = "ingress"
  security_group_id = aws_security_group.tfe_sg.id

  from_port   = var.postgresql_port
  to_port     = var.postgresql_port
  protocol    = local.tcp_protocol
  cidr_blocks = [local.all_ips]
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.tfe_sg.id

  from_port   = local.any_port
  to_port     = local.any_port
  protocol    = local.any_protocol
  cidr_blocks = [local.all_ips]
}

# PostgreSQL database
resource "aws_db_instance" "postgres" {
  identifier                  = "${var.environment_name}-rds"
  db_name                     = var.rds_name
  allocated_storage           = 50
  engine                      = "postgres"
  engine_version              = "14.9"
  instance_class              = "db.m5d.xlarge"
  username                    = var.rds_username
  password                    = var.rds_password
  parameter_group_name        = "default.postgres14"
  skip_final_snapshot         = true
  publicly_accessible         = false
  multi_az                    = false
  vpc_security_group_ids      = [aws_security_group.tfe_sg.id]
  db_subnet_group_name        = aws_db_subnet_group.subnet_group.name
  allow_major_version_upgrade = true

  tags = {
    Name = "${var.environment_name}-rds"
  }
}

resource "aws_db_subnet_group" "subnet_group" {
  name       = "${var.environment_name}-subnet-group"
  subnet_ids = [aws_subnet.tfe_private1.id, aws_subnet.tfe_private2.id]

  tags = {
    Name = "${var.environment_name}-subnet-group"
  }
}

# S3 bucket
resource "aws_s3_bucket" "tfe-bucket" {
  bucket = "${var.environment_name}-s3"

  tags = {
    Name = "${var.environment_name}-s3"
  }
}

# IAM Roles and Policies

resource "aws_iam_role" "k8s-cluster" {
  name = "${var.environment_name}-cluster"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "k8s-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.k8s-cluster.name
}

resource "aws_iam_role_policy_attachment" "k8s-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.k8s-cluster.name
}

resource "aws_iam_role" "k8s-node" {
  name = "${var.environment_name}-node"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "k8s-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.k8s-node.name
}

resource "aws_iam_role_policy_attachment" "k8s-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.k8s-node.name
}

resource "aws_iam_role_policy_attachment" "k8s-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.k8s-node.name
}

resource "aws_iam_role_policy_attachment" "k8s-AmazonS3FullAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.k8s-node.name
}

# EKS

resource "aws_eks_cluster" "k8s" {
  name     = "${var.environment_name}-cluster"
  version  = "1.27"
  role_arn = aws_iam_role.k8s-cluster.arn

  vpc_config {
    subnet_ids = [aws_subnet.tfe_public1.id, aws_subnet.tfe_public2.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.k8s-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.k8s-AmazonEKSVPCResourceController,
  ]
}

resource "aws_eks_node_group" "k8s" {
  cluster_name    = aws_eks_cluster.k8s.name
  node_group_name = "${var.environment_name}-node"
  node_role_arn   = aws_iam_role.k8s-node.arn
  subnet_ids      = [aws_subnet.tfe_public1.id, aws_subnet.tfe_public2.id]
  instance_types  = ["c5.2xlarge"]

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.k8s-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.k8s-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.k8s-AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.k8s-AmazonS3FullAccess,
  ]
}