module "lambda" {
  source = "./modules/ec2_dns_registration"

  domain_name   = local.domain_name
  function_name = "${local.this_servername_prefix}-DNS-registration-${var.track}"
  environment   = var.environment
  track         = var.track
  kms_key_id    = aws_kms_key.ebs-efs.arn

}