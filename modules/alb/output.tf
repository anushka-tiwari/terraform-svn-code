output "tg-arn" {
  # value = aws_lb_target_group.alb-tg.arn
  value = [for i in range(var.environment_abbreviation == "prod" ? 5 : 1) : aws_lb_target_group.alb-tg[i].arn]
}

output "my_id" {
  value = data.aws_vpc.vpc.id
}

output "cidr_block" {
  value = data.aws_vpc.vpc.cidr_block_associations[0].cidr_block
}

output "listener_arn" {
  # value = aws_lb_listener.lb-listener.arn
  value = [for i in range(var.environment_abbreviation == "prod" ? 5 : 1) : aws_lb_listener.lb-listener[i].arn]
}

output "certificate" {
  # value = aws_lb_listener.lb-listener.certificate_arn
  value = [for i in range(var.environment_abbreviation == "prod" ? 5 : 1) : aws_lb_listener.lb-listener[i].certificate_arn]
}

################################################################################################################

# Output the private key so you can use it to SSH into the instances
output "private_key_pem" {
  value     = tls_private_key.generated_key.private_key_pem
  sensitive = true
}

# Output the public key
output "public_key" {
  value = tls_private_key.generated_key.public_key_openssh
}