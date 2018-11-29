variable "cluster_name" {
  default = "lovelace"
}

variable "vpc_cidr" {
  default     = "10.1.0.0/16"
  description = "The CIDR of the VPC created for this cluster"
}

variable "availability_zones" {
  default     = ["us-west-2a","us-west-2b"]
  description = "The availability zones to run the cluster in"
}

variable "k8s_version" {
  default = "1.10"
  description = "The version of Kubernetes to use"
}
