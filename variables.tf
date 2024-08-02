variable "vpc_cidr" {
  description = "VPC CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "codecommit_region" {
  description = "codecommit regions"
  default     = "eu-west-2"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.30"
}

variable "ecr_account" {
  description = "The Ecr Account for the ECR"
  type = string
  default = ""
}

variable "addons" {
  description = "Kubernetes addons"
  type        = any
  default = {
    enable_aws_load_balancer_controller = true
    enable_aws_argocd                   = true
    enable_external_secrets             = true
    enable_metrics_server               = true
    enable_aws_cloudwatch_metrics       = true
  }
}

variable "manifests" {
  description = "Kubernetes manifests"
  type        = any
  default = {
    enable_namespaces_bootstrap = false
  }
}

# Addons Git
variable "gitops_addons_repo" {
  description = "Git repository contains for addons"
  type        = string
  default     = "v1/repos/gitops-bridge-addons"
}
variable "gitops_addons_revision" {
  description = "Git repository revision/branch/ref for addons"
  type        = string
  default     = "HEAD"
}
variable "gitops_addons_basepath" {
  description = "Git repository base path for addons"
  type        = string
  default     = ""
}
variable "gitops_addons_path" {
  description = "Git repository path for addons"
  type        = string
  default     = "bootstrap"
}
