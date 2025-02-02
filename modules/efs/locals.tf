data "aws_region" "current" {}
locals {
  region             = data.aws_region.current.name
  availability-zones = ["${local.region}a", "${local.region}b", "${local.region}c"]
  project            = "svn"
  region-alias       = "euc1"

  resource_name_prefix = format("%s%s%s%s%s", local.project, "-", local.region-alias, "-", var.environment_abbreviation)
  prod_server_names = [
    var.prod_server_name_1,
    var.prod_server_name_2,
    var.prod_server_name_3,
    var.prod_server_name_4,
    var.prod_server_name_5
  ]
  this_servername_prefix = local.project
  server_names           = var.environment_abbreviation == "prod" ? local.prod_server_names : [local.this_servername_prefix]

}
