################################################################################
# ArgoCD EKS Access
################################################################################
module "argocd_irsa" {
  #checkov:skip=CKV_TF_1:We are using version control for those modules
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.20"

  role_name_prefix           = "argocd-hub-"
  assume_role_condition_test = "StringLike"
  role_policy_arns = {
    ArgoCD_EKS_Policy = aws_iam_policy.irsa_policy.arn
  }
  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["${local.argocd_namespace}:argocd-*"]
    }
  }

  tags = local.tags
}

resource "aws_iam_policy" "irsa_policy" {
  name        = "${module.eks.cluster_name}-argocd-irsa"
  description = "IAM Policy for ArgoCD Hub"
  policy      = data.aws_iam_policy_document.irsa_policy.json
  tags        = local.tags
}

data "aws_iam_policy_document" "irsa_policy" {
  statement {
    effect    = "Allow"
    resources = ["*"]
    actions = [
      "sts:AssumeRole"
    ]
  }
}

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = local.argocd_namespace
  }
  depends_on = [module.eks_blueprints_addons]
}

//user for argocd credentials
resource "aws_iam_user" "codecommit_user" {
  name = "${local.name}-gitops-bridge"
  path = "/"
}

resource "tls_private_key" "gitops" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_iam_user_ssh_key" "user_ssh_key" {
  username   = aws_iam_user.codecommit_user.name
  encoding   = "SSH"
  public_key = tls_private_key.gitops.public_key_openssh
}

data "aws_iam_policy_document" "gitops_access" {
  statement {
    sid = ""
    actions = [
      "codecommit:GitPull",
      "codecommit:GitPush"
    ]
    effect = "Allow"
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "gitops_access" {
  name   = "${local.name}-gitops-bridge"
  path   = "/"
  policy = data.aws_iam_policy_document.gitops_access.json
}

resource "aws_iam_user_policy_attachment" "gitops_access" {
  user       = aws_iam_user.codecommit_user.name
  policy_arn = aws_iam_policy.gitops_access.arn
}

################################################################################
# ArgoCD Secret for github access
################################################################################
resource "kubernetes_secret" "git_secrets" {
  for_each = {
    git-addons = {
      type                  = "git"
      url                   = local.gitops_addons_url
      sshPrivateKey         = tls_private_key.gitops.private_key_pem
      insecureIgnoreHostKey = "true"
    }
    argocd-ecr-credentials = {
      type      = "helm"
      url       = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.id}.amazonaws.com"
      name      = "ecr-charts"
      enableOCI = true
      username  = "AWS"
      password  = data.aws_ecr_authorization_token.token.password
    }
    argocd-public-ecr = {
      type      = "helm"
      url       = "public.ecr.aws"
      name      = "aws-public-ecr"
      enableOCI = true
    }
  }
  metadata {
    name      = each.key
    namespace = local.argocd_namespace
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }
  data = each.value

  depends_on = [kubernetes_namespace.argocd]
}


################################################################################
# GitOps Bridge: Bootstrap
################################################################################
module "gitops_bridge_bootstrap" {
  source = "gitops-bridge-dev/gitops-bridge/helm"
  version = "0.1.0"
  cluster = {
    cluster_name = module.eks.cluster_name
    environment  = local.environment
    metadata     = local.addons_metadata
    addons       = local.addons
  }

  apps = local.argocd_apps
  argocd = {
    namespace        = local.argocd_namespace
    chart_version    = "7.3.11"
    timeout          = 600
    create_namespace = false
    set = [
      {
        name  = "server.service.type"
        value = "LoadBalancer"
      }
    ]
  }
  depends_on = [kubernetes_secret.git_secrets]
}