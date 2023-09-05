region           = "eu-west-1"     # AWS region to deploy in
environment_name = "demo-fdo-k8s"  # Name of the environment, used in naming of resources
vpc_cidr         = "10.200.0.0/16" # The IP range for the VPC in CIDR format
rds_name         = "fdo"           # Name of PostgreSQL database
rds_username     = "postgres"      # Username for PostgreSQL database
rds_password     = "Password1#"    # Password used for the PostgreSQL database