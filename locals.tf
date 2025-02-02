data "aws_region" "current" {}
locals {
  region             = data.aws_region.current.name
  availability-zones = ["${local.region}a", "${local.region}b", "${local.region}c"]
  project            = "svn"
  region-alias       = "euc1"

  environment-mapping = {
    cab            = 0
    build          = 1
    test           = 2
    formation      = 6
    acceptance     = 7
    pre-production = 8
    production     = 9
  }
  account-mapping = {
    cab            = "hexaware-cab"
    build          = "byld"
    test           = "test"
    formation      = "form"
    acceptance     = "accp"
    pre-production = "ppro"
    production     = "prod"
  }

  this_servername_prefix = format("%s%s%s%s", "awx", local.environment-mapping[var.environment], local.project, var.track)
  resource_name_prefix   = format("%s%s%s%s%s", local.project, "-", local.region-alias, "-", var.environment_abbreviation)
  domain_name            = "${local.account-mapping[var.environment]}.awscloud.private"
  prod_dns               = format("%s%s%s%s%s", var.environment_abbreviation, ".", var.environment_abbreviation, ".", "awscloud.private")
  prod_server_names = [
    var.prod_server_name_1,
    var.prod_server_name_2,
    var.prod_server_name_3,
    var.prod_server_name_4,
    var.prod_server_name_5
  ]
  lb_name_prefix  = format("%s%s%s%s%s", local.region-alias, "-", var.environment_abbreviation, "-", "lb")
  asg_name_prefix = format("%s%s%s%s%s", local.region-alias, "-", var.environment_abbreviation, "-", "asg")


}
