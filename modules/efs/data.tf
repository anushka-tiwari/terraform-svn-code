
data "aws_caller_identity" "current" {}

############################################### Fetch VPC List ###############################################

data "aws_vpc" "vpc" {

  tags = {
    Name = "prov-mainvpc-primary-vpc"
  }
}

############################################### Fetch Public Subnets List ###############################################

data "aws_subnets" "subnet" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
  filter {
    name   = "tag:Name"
    values = ["subnet-App-*"]
  }
}
