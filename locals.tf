locals {
  # Generic Locals
  name           = "hub"
  context_prefix = "gitops-bridge"
  region         = var.region
  ecr_account    = var.ecr_account == "" ? data.aws_caller_identity.current.account_id : var.ecr_account
  # EKS Locals
  argocd_namespace = "argocd"
  cluster_version  = var.kubernetes_version
  tenant           = "control-plane"
  environment      = "dev"
  //Setings of the gitops repo
  gitops_addons_repo_name = "app-tooling-gitops-eks-addons"
  gitops_addons_org       = "ssh://${aws_iam_user_ssh_key.user_ssh_key.id}@git-codecommit.${var.codecommit_region}.amazonaws.com"
  gitops_addons_url       = "${local.gitops_addons_org}/${var.gitops_addons_repo}"
  gitops_addons_basepath  = var.gitops_addons_basepath
  gitops_addons_path      = var.gitops_addons_path
  gitops_addons_revision  = var.gitops_addons_revision
  //seting of Manifest configuration
  gitops_manifests_repo_name = "app-tooling-gitops-eks-addons"
  gitops_manifests_org       = "ssh://${aws_iam_user_ssh_key.user_ssh_key.id}@git-codecommit.${var.codecommit_region}.amazonaws.com"
  gitops_manifests_url       = "${local.gitops_manifests_org}/${var.gitops_manifests_repo}"
  gitops_manifests_basepath  = var.gitops_manifests_basepath
  gitops_manifests_path      = var.gitops_manifests_path
  gitops_manifests_revision  = var.gitops_manifests_revision

  aws_addons = {
    enable_cert_manager                          = try(var.addons.enable_cert_manager, false)
    enable_aws_efs_csi_driver                    = try(var.addons.enable_aws_efs_csi_driver, false)
    enable_aws_fsx_csi_driver                    = try(var.addons.enable_aws_fsx_csi_driver, false)
    enable_aws_cloudwatch_metrics                = try(var.addons.enable_aws_cloudwatch_metrics, false)
    enable_aws_privateca_issuer                  = try(var.addons.enable_aws_privateca_issuer, false)
    enable_cluster_autoscaler                    = try(var.addons.enable_cluster_autoscaler, false)
    enable_external_dns                          = try(var.addons.enable_external_dns, false)
    enable_external_secrets                      = try(var.addons.enable_external_secrets, false)
    enable_aws_load_balancer_controller          = try(var.addons.enable_aws_load_balancer_controller, false)
    enable_fargate_fluentbit                     = try(var.addons.enable_fargate_fluentbit, false)
    enable_aws_for_fluentbit                     = try(var.addons.enable_aws_for_fluentbit, false)
    enable_aws_node_termination_handler          = try(var.addons.enable_aws_node_termination_handler, false)
    enable_karpenter                             = try(var.addons.enable_karpenter, false)
    enable_velero                                = try(var.addons.enable_velero, false)
    enable_aws_gateway_api_controller            = try(var.addons.enable_aws_gateway_api_controller, false)
    enable_aws_ebs_csi_resources                 = try(var.addons.enable_aws_ebs_csi_resources, false)
    enable_aws_secrets_store_csi_driver_provider = try(var.addons.enable_aws_secrets_store_csi_driver_provider, false)
    enable_ack_apigatewayv2                      = try(var.addons.enable_ack_apigatewayv2, false)
    enable_ack_dynamodb                          = try(var.addons.enable_ack_dynamodb, false)
    enable_ack_s3                                = try(var.addons.enable_ack_s3, false)
    enable_ack_rds                               = try(var.addons.enable_ack_rds, false)
    enable_ack_prometheusservice                 = try(var.addons.enable_ack_prometheusservice, false)
    enable_ack_emrcontainers                     = try(var.addons.enable_ack_emrcontainers, false)
    enable_ack_sfn                               = try(var.addons.enable_ack_sfn, false)
    enable_ack_eventbridge                       = try(var.addons.enable_ack_eventbridge, false)
    enable_ack_acm                               = try(var.addons.enable_ack_acm, false)
    enable_ack_route53                           = try(var.addons.enable_ack_route53, false)
    enable_aws_argocd                            = try(var.addons.enable_aws_argocd, false)
  }
  oss_addons = {
    enable_argocd                          = try(var.addons.enable_argocd, false)
    enable_argo_rollouts                   = try(var.addons.enable_argo_rollouts, false)
    enable_argo_events                     = try(var.addons.enable_argo_events, false)
    enable_argo_workflows                  = try(var.addons.enable_argo_workflows, false)
    enable_cluster_proportional_autoscaler = try(var.addons.enable_cluster_proportional_autoscaler, false)
    enable_gatekeeper                      = try(var.addons.enable_gatekeeper, false)
    enable_gpu_operator                    = try(var.addons.enable_gpu_operator, false)
    enable_ingress_nginx                   = try(var.addons.enable_ingress_nginx, false)
    enable_kyverno                         = try(var.addons.enable_kyverno, false)
    enable_kube_prometheus_stack           = try(var.addons.enable_kube_prometheus_stack, false)
    enable_metrics_server                  = try(var.addons.enable_metrics_server, false)
    enable_prometheus_adapter              = try(var.addons.enable_prometheus_adapter, false)
    enable_secrets_store_csi_driver        = try(var.addons.enable_secrets_store_csi_driver, false)
    enable_vpa                             = try(var.addons.enable_vpa, false)
  }

  manifests = {
    enable_namespaces_bootstrap = try(var.manifests.enable_namespaces_bootstrap, false)
  }

  addons = merge(
    local.aws_addons,
    local.oss_addons,
    local.manifests,
    { kubernetes_version = local.cluster_version },
    { aws_cluster_name = module.eks.cluster_name },
    { tenant = local.tenant },
  )

  addons_metadata = merge(
    module.eks_blueprints_addons.gitops_metadata,
    {
      aws_cluster_name = module.eks.cluster_name
      aws_region       = local.region
      aws_account_id   = data.aws_caller_identity.current.account_id
      aws_vpc_id       = data.aws_vpc.vpc.id
      tenant           = local.tenant
    },
    {
      argocd_namespace              = local.argocd_namespace
      argocd_iam_role_arn           = module.argocd_irsa.iam_role_arn
      external_secrets_iam_role_arn = aws_iam_role.eso.arn
      # ack_acm_namespace             = "ack-system"
      # ack_acm_service_account       = "ack-acm-controller"
      # ack_route53_namespace             = "ack-system"
      # ack_route53_service_account       = "ack-route53-controller"
    },
    {
      addons_repo_url      = local.gitops_addons_url
      addons_repo_basepath = local.gitops_addons_basepath
      addons_repo_path     = local.gitops_addons_path
      addons_repo_revision = local.gitops_addons_revision
    },
    {
      manifests_repo_url      = local.gitops_manifests_url
      manifests_repo_basepath = local.gitops_manifests_basepath
      manifests_repo_path     = local.gitops_manifests_path
      manifests_repo_revision = local.gitops_manifests_revision
    },
    {
      addons_chart_repository = "${local.ecr_account}.dkr.ecr.${data.aws_region.current.id}.amazonaws.com"
    }
  )


  argocd_apps = {
    manifests = file("${path.module}/bootstrap/manifests.yaml")
    addons    = file("${path.module}/bootstrap/addons.yaml")
  }

  tags = {
    Blueprint  = local.name
    GithubRepo = "github.com/aws-ia/terraform-aws-eks-blueprints"
  }
}
