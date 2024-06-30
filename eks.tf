module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.14.0"

  vpc_id                                   = var.vpc_id
  subnet_ids                               = var.subnet_ids
  cluster_name                             = var.cluster_name
  access_entries                           = var.access_entries
  cluster_version                          = var.cluster_version
  enable_irsa                              = true
  enable_cluster_creator_admin_permissions = true
  cluster_endpoint_public_access           = false
  authentication_mode                      = var.authentication_mode
  cloudwatch_log_group_retention_in_days   = var.cloudwatch_log_group_retention_in_days
  cluster_addons = {
    coredns = {
      most_recent = true
      configuration_values = jsonencode({
        tolerations = [
          # Allow CoreDNS to run on the same nodes as the Karpenter controller
          # for use during cluster creation when Karpenter nodes do not yet exist
          {
            key    = "karpenter.sh/controller"
            value  = "true"
            effect = "NoSchedule"
          }
        ]
      })
    }
    eks-pod-identity-agent = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }
  cluster_security_group_additional_rules = {
    ingress_from_same_vpc = {
      description = "HTTPS to EKS Endpoint API from same VPC"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      cidr_blocks = [
        var.cluster_additional_cidr_blocks
      ]
    }
  }
  enable_efa_support = false
  eks_managed_node_groups = {
    karpenter = {
      ami_type       = var.managed_nodes_ami_type
      name           = "eks-control-plane"
      instance_types = var.managed_nodes_instance_types

      min_size     = var.managed_nodes_min_size
      max_size     = var.managed_nodes_max_size
      desired_size = var.managed_nodes_desired_size

      create_launch_template = true                                 # false will use the default launch template
      launch_template_os     = var.managed_nodes_launch_template_os # amazonlinux2eks or bottlerocket

      labels = {
        # Used to ensure Karpenter runs on nodes that it does not manage
        "karpenter.sh/controller" = "true"
      }

      taints = var.managed_nodes_taints
    }
  }

  tags = merge(var.tags,
    {
      "karpenter.sh/discovery" = "${var.cluster_name}"
  })
}
