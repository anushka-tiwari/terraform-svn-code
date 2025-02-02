
###############################################################################################################
############################################### Security group for instances #################################################
###############################################################################################################

resource "aws_security_group" "ec2-sg" {
  name        = var.name-prefix
  vpc_id      = data.aws_vpc.vpc.id
  description = "Security group for launch template & asg"

  ingress {
    description = "Allow all traffic from security group "
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true

  }
  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      tags,        # Ignore tag changes
      description, # Ignore description changes
      ingress,     # Ignore ingress rule changes
      egress       # Ignore egress rule changes
    ]
  }

  tags = {
    Name = "${local.resource_name_prefix}-ec2-sg"
  }
}

############################################### Ingress rule #################################################


resource "aws_vpc_security_group_ingress_rule" "inbound-rule1" {
  security_group_id = aws_security_group.ec2-sg.id

  description = "Allow all traffic from VDI"
  cidr_ipv4   = "172.16.0.0/12"
  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22
}

resource "aws_vpc_security_group_ingress_rule" "inbound-rule2" {
  security_group_id = aws_security_group.ec2-sg.id

  description = "Allow all traffic from VPC"
  cidr_ipv4   = data.aws_vpc.vpc.cidr_block
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

}

resource "aws_vpc_security_group_ingress_rule" "inbound-rule3" {
  security_group_id = aws_security_group.ec2-sg.id

  description = "Allow all traffic from VPC"
  cidr_ipv4   = data.aws_vpc.vpc.cidr_block
  from_port   = 4434
  to_port     = 4434
  ip_protocol = "tcp"

}
################################################ Egress rule ###########################################

resource "aws_vpc_security_group_egress_rule" "outbound-rule" {
  security_group_id = aws_security_group.ec2-sg.id

  description = "allow all outbound traffic"
  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

############################################### Generating key pair ########################################

# Generate SSH Key Pair
resource "tls_private_key" "generated_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "generated_key" {
  key_name   = var.key-name
  public_key = tls_private_key.generated_key.public_key_openssh
}


resource "aws_secretsmanager_secret" "my_secret" {
  name = var.ssm-secret-key
}

resource "aws_secretsmanager_secret_version" "my_secret_version" {
  secret_id     = aws_secretsmanager_secret.my_secret.id
  secret_string = tls_private_key.generated_key.private_key_pem
}



########################################### Launch Template ############################################

# Create a launch template
resource "aws_launch_template" "launch-template" {
  count = length(local.server_names)


  name          = local.server_names[count.index]
  image_id      = var.image_id
  instance_type = var.instance-type
  vpc_security_group_ids = [
    aws_security_group.ec2-sg.id,         # Custom-created security group
    data.aws_security_group.default_sg.id # Security group fetched using data source
  ]
  key_name               = aws_key_pair.generated_key.key_name
  update_default_version = true

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size           = var.ebs-volume-size
      delete_on_termination = true
      volume_type           = "gp3"
      encrypted             = true
      kms_key_id            = var.kms_key_id

    }
  }

  # Swap volume
  block_device_mappings {
    device_name = "/dev/sdf"
    ebs {
      volume_size           = 4
      delete_on_termination = true
      volume_type           = "gp3"
      encrypted             = true
      kms_key_id            = var.kms_key_id
    }
  }

  iam_instance_profile {
    name = var.ec2-role
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name                     = local.server_names[count.index]
      business-owner           = "devsecops"
      operational-owner        = "infra"
      cost-center              = "17501"
      component                = local.project
      "managed-by.environment" = var.environment
      "managed-by.track"       = var.track
    }
  }

  private_dns_name_options {
    hostname_type                        = var.hostname_type
    enable_resource_name_dns_aaaa_record = var.enable_resource_name_dns_aaaa_record
    enable_resource_name_dns_a_record    = var.enable_resource_name_dns_a_record
  }


  user_data = base64encode(templatefile("${path.module}/user_data.sh.tpl", {

    base_hostname                   = var.environment_abbreviation == "prod" ? local.server_configs[count.index].hostname : local.this_servername_prefix[0]
    domain                          = "${local.account-mapping[var.environment]}.awscloud.private"
    console_name                    = "${local.console_name_prefix}"
    wildcard_certificate_pfx_secret = "keystore/wildcard.${var.environment_abbreviation}.awscloud.private"
    track                           = "${var.track}"
    region                          = "${local.region-alias}"
    efs_host                        = "${local.server_names[count.index]}"
    prod_server_names               = "${local.server_names[count.index]}"
    environment_abbreviation        = var.environment_abbreviation

  }))
}

########################################### Auto Scaling Group ############################################

# Defining the Auto Scaling group
resource "aws_autoscaling_group" "asg-group" {

  count = length(local.server_names)
  name  = var.environment_abbreviation == "prod" ? var.asg_prod_name[tostring(count.index)] : var.asg-name

  launch_template {
    id = aws_launch_template.launch-template[count.index].id
  }

  min_size                  = 1
  max_size                  = 1
  desired_capacity          = 1
  health_check_type         = "ELB"
  vpc_zone_identifier       = [for s in data.aws_subnets.subnets.ids : s]
  wait_for_capacity_timeout = "5m"
  health_check_grace_period = 300
  termination_policies      = ["Default"]


  lifecycle {
    create_before_destroy = true
  }
}


###########################################################################################################
############################################# Security Group for alb ######################################
###########################################################################################################

#Security group for load balancer
resource "aws_security_group" "alb-sg" {
  name        = var.sg-name
  vpc_id      = data.aws_vpc.vpc.id
  description = "Security group for load balancer"

  tags = {
    Name = "${local.resource_name_prefix}-alb-sg-${var.track}"
  }
}
############################################### Ingress rule for Security Group #################################################

resource "aws_vpc_security_group_ingress_rule" "inbound-rule" {
  security_group_id = aws_security_group.alb-sg.id

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  ip_protocol = "tcp"
  to_port     = 443
}

############################################### Egress rule for Security group ###########################################

resource "aws_vpc_security_group_egress_rule" "outbound-alb-rule" {
  security_group_id = aws_security_group.alb-sg.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

########################################### Load Balancer ############################################

# Create an application load balancer
resource "aws_lb" "alb" {
  count = length(local.server_names)

  name = var.environment_abbreviation == "prod" ? var.lb_name[tostring(count.index)] : var.lb-name


  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb-sg.id]

  subnets = [for s in data.aws_subnets.subnets.ids : s]
  tags = {
    Name = "${local.resource_name_prefix}-alb-${count.index}"
  }

}

########################################### SVN listener ############################################

# Create a listener for SVN
resource "aws_lb_listener" "lb-listener" {
  count             = length(local.server_names)
  load_balancer_arn = aws_lb.alb[count.index].arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.ssl_certificate.arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-tg[count.index].arn
  }
  tags = {
    Name = "${local.resource_name_prefix}-listener-${count.index}"
  }
}

################################ ALB Listner rule ##################################################
# Create a listener for SVNCheckout

resource "aws_lb_listener_rule" "svn_checkout_rule" {
  count = length(local.server_names)

  listener_arn = aws_lb_listener.lb-listener[count.index].arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb-svnchkout-tg[count.index].arn
  }

  condition {
    path_pattern {
      values = ["/svn/*", "/viewvc/*", "/repos/*"]
    }
  }

  tags = {
    Name = "${local.resource_name_prefix}-checkout-listener-${count.index}"
  }
}
######################################### SVN Target Group ###########################################

# Target group for SVN
resource "aws_lb_target_group" "alb-tg" {
  count       = length(local.server_names)
  name        = "${local.project}-${var.environment_abbreviation}-tg-${count.index}"
  port        = 4434
  protocol    = "HTTPS"
  vpc_id      = data.aws_vpc.vpc.id
  target_type = "instance"

  health_check {
    path                = "/csvn/login/auth"
    protocol            = "HTTPS"
    timeout             = 80
    interval            = 150
    healthy_threshold   = 2
    unhealthy_threshold = 10
    matcher             = 200
  }
  # Add more configurations as needed
  tags = {
    Name = "${local.resource_name_prefix}-lb-tg-${count.index}"
  }
}


resource "aws_lb_target_group" "alb-svnchkout-tg" {
  count       = length(local.server_names)
  name        = "${local.project}-${var.environment_abbreviation}-svnchkout-tg-${count.index}"
  port        = 443
  protocol    = "HTTPS"
  vpc_id      = data.aws_vpc.vpc.id
  target_type = "instance"

  health_check {
    path                = "/"
    protocol            = "HTTPS"
    timeout             = 120
    interval            = 180
    healthy_threshold   = 2
    unhealthy_threshold = 10
    matcher             = 200
  }
  # Add more configurations as needed
  tags = {
    Name = "${local.resource_name_prefix}-svnchkout-lb-tg-${count.index}"
  }
}

##################################### Attaching autoscaling group to the target group ###########################################

# Attach the autoscaling group to the target group
resource "aws_autoscaling_attachment" "asg-attachment-alb" {
  count                  = length(local.server_names)
  autoscaling_group_name = aws_autoscaling_group.asg-group[count.index].name
  lb_target_group_arn    = aws_lb_target_group.alb-tg[count.index].arn
}

resource "aws_autoscaling_attachment" "asg-attachment-svn" {
  count                  = length(local.server_names)
  autoscaling_group_name = aws_autoscaling_group.asg-group[count.index].name
  lb_target_group_arn    = aws_lb_target_group.alb-svnchkout-tg[count.index].arn
}

################################################ ALB DNS Record ###################################################


data "aws_route53_zone" "zone" {
  name         = "${local.account-mapping[var.environment]}.awscloud.private"
  private_zone = true
}

# Create a DNS record in Route 53 pointing to the ALB's DNS name
resource "aws_route53_record" "alb_dns_record" {

  count = length(local.server_names)

  # The Route 53 hosted zone ID
  zone_id = data.aws_route53_zone.zone.zone_id


  # The DNS name you want to associate with the ALB
  name = var.environment_abbreviation == "prod" ? var.prod_urls[tostring(count.index)] : var.dns_name
  type = "A"

  alias {
    name                   = aws_lb.alb[count.index].dns_name
    zone_id                = aws_lb.alb[count.index].zone_id
    evaluate_target_health = true
  }
}

