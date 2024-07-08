module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.16.3" #ensure to update this to the latest/desired version

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  enable_external_dns = var.enable_external_dns
  external_dns = {
    name          = "external-dns"
    chart_version = var.external_dns_chart_version
    repository    = "https://kubernetes-sigs.github.io/external-dns/"
    namespace     = "external-dns"

    set = [
      {
        name  = "revisionHistoryLimit"
        value = 1
      },
      {
        name  = "extraArgs[0]"
        value = "--aws-prefer-cname"
      },
      {
        name  = "extraArgs[1]"
        value = "--txt-prefix=${var.external_dns_txt_prefix}"
      },
      {
        name  = "extraArgs[2]"
        value = "--txt-owner-id=${var.external_dns_txt_owner_id}"
      },
      {
        name  = "extraArgs[3]"
        value = "--domain-filter=${var.external_dns_domain_filter}"
      }
    ]
  }

  external_dns_route53_zone_arns = ["arn:aws:route53:::hostedzone/${var.external_dns_hosted_zone_id}"]

  enable_aws_load_balancer_controller = var.enable_aws_load_balancer_controller
  aws_load_balancer_controller = {
    chart_version = var.aws_load_balancer_controller_chart_version
  }

  enable_metrics_server = var.enable_metrics_server

  enable_cert_manager   = var.enable_cert_manager
  cert_manager = {
    chart_version = var.cert_manager_chart_version
    set = [
      {
        name  = "revisionHistoryLimit"
        value = 1
      },

      {
        name  = "crds.enable"
        value = "true"
      }
    ]
  }


  enable_external_secrets = var.enable_external_secrets
  external_secrets = {
    chart_version = "0.9.20"
    namespace     = "external-secrets"

    set = [
      {
        name  = "revisionHistoryLimit"
        value = 1
      },

      {
        name  = "webhook.serviceAccount.name"
        value = var.eso_service_account_name
      },
      {
        name  = "webhook.serviceAccount.annotations[0].eks.amazonaws.com~1role-arn"
        value = module.eso_iam_role.iam_role_arn
      }
    ]
  }


  tags = var.tags
}