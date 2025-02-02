
data "aws_caller_identity" "current" {}

############################################### Fetch VPC List ###############################################

data "aws_vpc" "vpc" {

  tags = {
    Name = "prov-mainvpc-primary-vpc"
  }
}

############################################### Fetch Public Subnets List ###############################################

data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }
  filter {
    name   = "tag:Name"
    values = ["subnet-App-*"]
  }
}

############################################ Importing ACM Certificate ##################################################

# Data source to fetch the ACM certificate based on domain name
data "aws_acm_certificate" "ssl_certificate" {

  domain      = "*.pvgroup.intranet"
  key_types   = ["RSA_2048"]
  statuses    = ["ISSUED"]
  most_recent = true
}

######################################### Default Security Group ##############################################################

data "aws_security_group" "default_sg" {
  name = "prov-LinuxEC2SecurityGroup"
}