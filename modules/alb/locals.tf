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

  resource_name_prefix = format("%s%s%s%s%s", local.project, "-", local.region-alias, "-", var.environment_abbreviation)
  prod_dns             = format("%s%s%s%s%s", var.environment_abbreviation, ".", var.environment_abbreviation, ".", "awscloud.private")
  # Create a list from individual server name variables
  prod_server_names = [
    var.prod_server_name_1,
    var.prod_server_name_2,
    var.prod_server_name_3,
    var.prod_server_name_4,
    var.prod_server_name_5
  ]
  this_servername_prefix = [format("%s%s%s%s", "awx", local.environment-mapping[var.environment], local.project, var.track)]
  server_names           = var.environment_abbreviation == "prod" ? local.prod_server_names : [local.this_servername_prefix[0]]
  console_name_prefix    = "${local.resource_name_prefix}-ec2"
  server_configs = [for server in local.prod_server_names : {
    hostname = server
  }]


}

