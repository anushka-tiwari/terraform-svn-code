#version=1.0.0-SNAPSHOT

module "alb" {
  source = "./modules/alb"

  sg-name                  = "${local.resource_name_prefix}-alb-sg-${var.track}"
  sg-name-tag              = "${local.resource_name_prefix}-sg-${var.track}"
  sg-accountname           = "${local.resource_name_prefix}-sg-accname-${var.track}"
  name-prefix              = "${local.resource_name_prefix}-ec2-sg-${var.track}"
  lb-name                  = "${local.resource_name_prefix}-lb-${var.track}"
  listener_rule_priority   = 1
  instance-type            = var.instance_type
  environment              = var.environment
  environment_abbreviation = var.environment_abbreviation
  track                    = var.track
  image_id                 = var.ami
  ebs-volume-size          = var.ebs_volume_size
  asg-name                 = "${local.resource_name_prefix}-asg-${var.track}"
  ec2-role                 = aws_iam_instance_profile.ec2-iam-role.name
  dns_name                 = "${local.project}-${var.environment_abbreviation}.${local.domain_name}"
  ssm-secret-key           = "${local.project}-${var.environment_abbreviation}-secret-pair-${var.track}"
  key-name                 = "${local.project}-generated-key-pair${var.track}"
  kms_key_id               = aws_kms_key.ebs-efs.arn
  prod_server_name_1       = var.prod_server_name_1
  prod_server_name_2       = var.prod_server_name_2
  prod_server_name_3       = var.prod_server_name_3
  prod_server_name_4       = var.prod_server_name_4
  prod_server_name_5       = var.prod_server_name_5



  prod_urls     = [for name in local.prod_server_names : "${name}-${local.prod_dns}"]
  lb_name       = [for name in local.prod_server_names : "${name}-${local.lb_name_prefix}"]
  asg_prod_name = [for name in local.prod_server_names : "${name}-${local.asg_name_prefix}"]


  depends_on = [
    aws_iam_role_policy_attachment.ec2_policies_attachment,
    aws_iam_instance_profile.ec2-iam-role,
  ]
}
