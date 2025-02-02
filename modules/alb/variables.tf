
############################## Load Balancer ##################################################

variable "lb-name" {
  type        = string
  description = "Name of the load balancer"
}

############################## Target Group ##################################################

variable "sg-name" {
  type        = string
  description = "Name of the Security group attached to load balancer"
}

variable "sg-name-tag" {
  type        = string
  description = "Security group tag name"
}

variable "sg-accountname" {
  type        = string
  description = "Security group account name"
}

variable "ec2-role" {
  type        = string
  description = "Name of the instances Iam role"
}

################################## Autoscaling group ###############################################

variable "asg-name" {
  type        = string
  description = "Name of the autoscaling group"

}

############################# Launch Config ###################################################


variable "name-prefix" {
  type        = string
  description = "name of the security group used for launch template"
}

variable "instance-type" {
  type        = string
  description = "Instance type of the ec2"
}

variable "image_id" {
  type        = string
  description = "ami id value"
}

variable "ebs-volume-size" {
  type        = number
  description = "size of the EBS volume"
}

############################# Listener rules ###################################################

variable "listener_rule_priority" {
  type        = number
  description = "Listener priority rule"
}

#######################################################################################################

variable "dns_name" {
  type        = string
  description = "The DNS name you want to associate with the ALB"
}

variable "environment" {
  type        = string
  description = "The name of the environment to deploy (full name)"
}
variable "environment_abbreviation" {
  type        = string
  description = "Abbreviated name of the environment to deploy (full name)"
}


variable "track" {
  type        = string
  description = "track no of the instance"
}


######################################## private dns name options ##############################

variable "hostname_type" {
  description = "The type of hostname for the instance"
  type        = string
  default     = "resource-name"
}

variable "enable_resource_name_dns_aaaa_record" {
  description = "Indicates whether to respond to DNS queries for instance hostnames with DNS AAAA records"
  type        = bool
  default     = false
}

variable "enable_resource_name_dns_a_record" {
  description = "Indicates whether to respond to DNS queries for instance hostnames with DNS A records"
  type        = bool
  default     = true
}

############################################# Key Pair ##########################################################

variable "ssm-secret-key" {
  type        = string
  description = "secret name to retrieve the key-pair generated"
}

variable "key-name" {
  type        = string
  description = "name of the key generated"
}

###################################################################################################

variable "kms_key_id" {
  type        = string
  description = "KMS key ID for encrypting ebs volume"
}

######################################## PROD env. Detail ##################################################

variable "prod_urls" {
  description = "URLs for the production servers"
  type        = list(string)
}

variable "lb_name" {
  description = "Load Balancer name for the production servers"
  type        = list(string)
}

variable "asg_prod_name" {
  description = "Auto-scaling name for the production servers"
  type        = list(string)
}

#################################################### Test ##################################################
variable "prod_server_name_1" {
  description = "Production server name 1"
  type        = string
}

variable "prod_server_name_2" {
  description = "Production server name 2"
  type        = string

}

variable "prod_server_name_3" {
  description = "Production server name 3"
  type        = string

}

variable "prod_server_name_4" {
  description = "Production server name 4"
  type        = string

}

variable "prod_server_name_5" {
  description = "Production server name 5"
  type        = string

}