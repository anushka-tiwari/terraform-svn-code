variable "environment_abbreviation" {
  type        = string
  description = "Abbreviated name of the environment to deploy (full name)"

}
variable "environment" {
  type        = string
  description = "The name of the environment to deploy (full name)"
}

variable "track" {
  type        = string
  description = "Track number"
}

variable "instance_type" {
  type        = string
  description = "Instance type to be used"
}

variable "ami" {
  type        = string
  description = "AMI ID for the svn instances"
}

variable "ebs_volume_size" {
  type        = number
  description = "Size of the EBS volume"
  default     = 30
}


#################################################### Test ##################################################
variable "prod_server_name_1" {
  description = "Production server name 1"
  type        = string
  # default = "svncc"
}

variable "prod_server_name_2" {
  description = "Production server name 2"
  type        = string
  # default = "svnrepos"

}

variable "prod_server_name_3" {
  description = "Production server name 3"
  type        = string
  # default = "svnzos"

}

variable "prod_server_name_4" {
  description = "Production server name 4"
  type        = string
  # default = "svnnlbt"

}

variable "prod_server_name_5" {
  description = "Production server name 5"
  type        = string
  # default = "svntesting"

}