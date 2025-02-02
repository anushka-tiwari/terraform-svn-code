

variable "creation_token" {
  description = "A unique name for the EFS file system."
}

variable "performance_mode" {
  description = "The performance mode of the file system. Accepted values: generalPurpose, maxIO."
  default     = "generalPurpose"
}

variable "throughput_mode" {
  description = "The throughput mode of the file system. Accepted values: bursting, provisioned."
  default     = "elastic"
}

variable "encrypted" {
  description = "Specifies whether the file system is encrypted. Default is true."
  default     = true
}

variable "sg-name" {
  description = "Name of the Security group Name"
  type        = string
}

variable "environment" {
  type        = string
  description = "The name of the environment to deploy (full name)"
}
variable "environment_abbreviation" {
  type        = string
  description = "Abbreviated name of the environment to deploy (full name)"

}
variable "kms_key_id" {
  type        = string
  description = "KMS key for efs encryption"
}

variable "track" {
  type        = string
  description = "track no of the instance"
}


#################################################### Test ##################################################
variable "prod_server_name_1" {
  description = "Production server name 1"
  type        = string
  default     = "svncc"
}

variable "prod_server_name_2" {
  description = "Production server name 2"
  type        = string
  default     = "svnzos"

}

variable "prod_server_name_3" {
  description = "Production server name 3"
  type        = string
  default     = "svnrepos"

}

variable "prod_server_name_4" {
  description = "Production server name 4"
  type        = string
  default     = "svnnlbt"

}

variable "prod_server_name_5" {
  description = "Production server name 5"
  type        = string
  default     = "svntesting"

}