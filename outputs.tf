output "update_kubectl" {
  description = "Command to use to set access to kubectl on local machine. This assumes [default] aws profile credentials are being used, otherwise append --profile <name_of_profile>."
  value       = "aws eks --region ${var.region} update-kubeconfig --name ${aws_eks_cluster.k8s.name}"
}

output "cluster_name" {
  value = aws_eks_cluster.k8s.name
}

output "environment_name" {
  value = var.environment_name
}

output "region" {
  value = var.region
}

output "pg_dbname" {
  value = aws_db_instance.postgres.db_name
}

output "pg_user" {
  value = aws_db_instance.postgres.username
}

output "pg_password" {
  value     = aws_db_instance.postgres.password
  sensitive = true
}

output "pg_address" {
  value = aws_db_instance.postgres.address
}

output "redis_host" {
  value = lookup(aws_elasticache_cluster.redis.cache_nodes[0], "address", "No redis created")
}

output "s3_bucket" {
  value = aws_s3_bucket.tfe-bucket.bucket
}