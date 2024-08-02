## Generic Pod Identity Role
resource "aws_iam_role" "eso" {
  name = "eso"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
      Effect = "Allow"
      Principal = {
        Service = [
          "pods.eks.amazonaws.com"
        ]
      }
    }]
  })
}
################################################################################
# ESO Secrets Access
################################################################################
# ESO Pod Identity
resource "aws_eks_pod_identity_association" "eso" {
  cluster_name    = "hub"
  namespace       = "external-secrets"
  service_account = "external-secrets-sa"
  role_arn        = aws_iam_role.eso.arn

  depends_on = [module.eks]
}

data "aws_iam_policy_document" "eso" {
  statement {
    effect    = "Allow"
    actions   = ["secretsmanager:ListSecrets"]
    resources = ["*"]
  }

  statement {
    actions   = ["ssm:DescribeParameters"]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    "secretsmanager:ListSecretVersionIds"]
    resources = [
      "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:${local.name}/*",
    ]
  }
  statement {
    effect = "Allow"
    actions = [
    "kms:Decrypt", ]
    resources = [
      "arn:aws:kms:${var.region}:${data.aws_caller_identity.current.account_id}:key/*",
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "ssm:GetParameter",
    "ssm:GetParameters", ]
    resources = [
      "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/${local.name}/*",
    ]
  }
}

## Create the IAM policy with the document created above
resource "aws_iam_policy" "eso" {
  name   = "${module.eks.cluster_name}-eso"
  policy = data.aws_iam_policy_document.eso.json
}

resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.eso.name
  policy_arn = aws_iam_policy.eso.arn
}

################################################################################
# ArgoCD ECR Access
################################################################################
# resource "aws_iam_role" "argo_cd" {
#   name = "argo-cd-pod-identity"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Action = [
#         "sts:AssumeRole",
#         "sts:TagSession"
#       ]
#       Effect = "Allow"
#       Principal = {
#         Service = [
# 					"pods.eks.amazonaws.com"
# 				]
#       }
#     }]
#   })
# }

# resource "aws_eks_pod_identity_association" "argocd_app_controller" {
#   cluster_name    = module.eks.cluster_name
#   namespace       = "argocd"
#   service_account = "argocd-application-controller"
#   role_arn        = aws_iam_role.argo_cd.arn
# }

# resource "aws_eks_pod_identity_association" "argocd_api_server" {
#   cluster_name    = module.eks.cluster_name
#   namespace       = "argocd"
#   service_account = "argocd-server"
#   role_arn        = aws_iam_role.argo_cd.arn
# }

# data "aws_iam_policy_document" "argo_cd" {
#   statement {
#     effect    = "Allow"
#     resources = ["*"]
#     actions   = [
#       "sts:AssumeRole"
#     ]
#   }

#   statement {
#     effect    = "Allow"
#     resources = ["*"]
#     actions   = ["ecr:*"]
#   }
# }

# resource "aws_iam_policy" "argo_cd" {
#   name        = "${module.eks.cluster_name}-argocd"
#   description = "IAM Policy for ArgoCD"
#   policy      = data.aws_iam_policy_document.argo_cd.json
# }

# resource "aws_iam_role_policy_attachment" "argo_cd" {
#   role       = aws_iam_role.argo_cd.name
#   policy_arn = aws_iam_policy.argo_cd.arn
# }

################################################################################
# ACK Pod Identity
################################################################################
# resource "aws_iam_policy" "ack_acm" {
#   count       = local.addons.enable_ack_acm ? 1 : 0
#   name        = "ack-acm-${data.aws_region.current.name}"
#   policy      = data.aws_iam_policy_document.ack_acm_policy[0].json
# }

# resource "aws_iam_role_policy_attachment" "attach_acm" {
#   count = local.addons.enable_ack_acm ? 1 : 0
#   role       = aws_iam_role.ack_acm_role[0].name
#   policy_arn = aws_iam_policy.ack_acm_policy[0].arn
# }

# resource "aws_eks_pod_identity_association" "iam_ack_role_association" {
#   count = local.addons.enable_ack_acm ? 1 : 0
#   cluster_name    = module.eks.cluster_name
#   namespace       = "ack-system"
#   service_account = "ack-acm-controller"
#   role_arn        = aws_iam_role.ack_acm_role[0].arn

#   depends_on = [ module.eks ]
# }

# resource "aws_eks_pod_identity_association" "iam_ack_role_association_route53" {
#   count = local.addons.enable_ack_acm ? 1 : 0
#   cluster_name    = module.eks.cluster_name
#   namespace       = "ack-system"
#   service_account = "ack-route53-controller"
#   role_arn        = aws_iam_role.ack_acm_role[0].arn

#   depends_on = [ module.eks ]
# }