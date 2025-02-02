variable "function_name" {
  description = "The name of the Lambda function."
  type        = string
}

variable "domain_name" {
  description = "The domain name"
  type        = string
}

variable "environment" {
  type        = string
  description = "The name of the environment to deploy (full name)"
}
variable "track" {
  type        = string
  description = "The name of the instance"
}
variable "kms_key_id" {
  type        = string
  description = "KMS key for encrypting DyanmoDB"
}