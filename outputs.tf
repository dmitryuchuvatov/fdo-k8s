output "update_kubectl" {
  description = "Command to use to set access to kubectl on local machine. This assumes [default] aws profile credentials are being used, otherwise append --profile <name_of_profile>."
  value       = "aws eks --region ${var.region} update-kubeconfig --name ${aws_eks_cluster.k8s.name}"
}