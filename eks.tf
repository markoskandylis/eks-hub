module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.5"

  cluster_name                   = local.name
  cluster_version                = local.cluster_version
  cluster_endpoint_public_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets


  # vpc_id                   = data.aws_vpc.vpc.id
  # subnet_ids               = data.aws_subnets.intra_subnets_worker.ids
  # control_plane_subnet_ids = data.aws_subnets.intra_subnets_controler.ids

  cluster_security_group_additional_rules = {
    cluster_internal_ingress = {
      description = "Access EKS from VPC."
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      cidr_blocks = [var.vpc_cidr]
    }
  }

  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    platform = {
      instance_types = ["m5.large"]
      ami_type       = "BOTTLEROCKET_x86_64"
      min_size       = 3
      max_size       = 3
      desired_size   = 3
    }
  }
  # EKS Addons
  cluster_addons = {
    coredns    = {}
    kube-proxy = {}
    eks-pod-identity-agent = {
      most_recent    = true
      before_compute = true
    }
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_driver_irsa.iam_role_arn
    }
    eks-pod-identity-agent = {
      most_recent    = true
      before_compute = true
    }
    vpc-cni = {
      # Specify the VPC CNI addon should be deployed before compute to ensure
      # the addon is configured before data plane compute resources are created
      # See README for further details
      before_compute = true
      most_recent    = true # To ensure access to the latest settings provided
      configuration_values = jsonencode({
        env = {
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
  }
  tags = {}
  depends_on = [ module.vpc ]
}

module "ebs_csi_driver_irsa" {
  #checkov:skip=CKV_TF_1:We are using version control for those modules
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.20"

  role_name_prefix = "${local.name}-ebs-csi-driver-"

  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = local.tags
}

################################################################################
# Supporting Resources
################################################################################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = local.tags
}

# Creating parameter for argocd hub role for the spoke clusters to read
resource "aws_ssm_parameter" "argocd_hub_role" {
  name  = "/hub/argocd-hub-role"
  type  = "String"
  value = module.argocd_irsa.iam_role_arn
}

resource "aws_ssm_parameter" "argocd_ssh_user" {
  name  = "/hub/ssh-user"
  type  = "String"
  value = aws_iam_user_ssh_key.user_ssh_key.id
}