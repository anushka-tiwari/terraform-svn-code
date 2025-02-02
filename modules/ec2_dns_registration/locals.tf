data "aws_region" "current" {}

locals {
  region             = data.aws_region.current.name
  availability-zones = ["${local.region}a", "${local.region}b", "${local.region}c"]
  project            = "svn"
  region-alias       = "euc1"



  account-mapping = {
    cab            = "hexaware-cab"
    build          = "byld"
    test           = "test"
    formation      = "form"
    acceptance     = "accp"
    pre-production = "ppro"
    production     = "prod"
  }

  domain_name = "${local.account-mapping[var.environment]}.awscloud.private"

}
