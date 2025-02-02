module "efs" {
  source = "./modules/efs"


  environment              = var.environment
  environment_abbreviation = var.environment_abbreviation
  sg-name                  = "${local.resource_name_prefix}-efs-sg-${var.track}"
  creation_token           = "${local.resource_name_prefix}-efs-token-${var.track}"
  kms_key_id               = aws_kms_key.ebs-efs.arn
  track                    = var.track

}
