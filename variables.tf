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
    enable_aws_efs_csi_driver           = false
    enable_aws_ebs_csi_resources        = true
    enable_cert_manager                 = true
    enable_ack_acm                      = false
    enable_ack_route53                  = false
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


variable "codecommit_region" {
  default = "eu-west-2"
}
# Addons Git
variable "addons_repo_name" {
  default = "eks-addons"
}
variable "gitops_addons_repo" {
  description = "Git repository contains for addons"
  type        = string
  default     = "v1/repos/app-tooling-gitops-eks-addons"
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
  default     = "bootstrap/control-plane/addons"
}

//manifests configuration
variable "manifests_repo_name" {
  default = "eks-addons"
}
variable "gitops_manifests_repo" {
  description = "Git repository contains for addons"
  type        = string
  default     = "v1/repos/app-tooling-gitops-eks-addons"
}
variable "gitops_manifests_revision" {
  description = "Git repository revision/branch/ref for addons"
  type        = string
  default     = "HEAD"
}
variable "gitops_manifests_basepath" {
  description = "Git repository base path for addons"
  type        = string
  default     = ""
}
variable "gitops_manifests_path" {
  description = "Git repository path for addons"
  type        = string
  default     = "bootstrap/control-plane/manifests"
}
