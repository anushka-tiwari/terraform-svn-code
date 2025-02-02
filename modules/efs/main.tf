############################################ Security group for EFS #####################################
#########################################################################################################

resource "aws_security_group" "efs-sg" {
  name        = var.sg-name
  description = "EFS security Group"
  vpc_id      = data.aws_vpc.vpc.id

  ################################################ Ingress rule ################################################

  ingress {
    description = "Allow all traffic from Security group "
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
    Name = "${local.resource_name_prefix}-efs-sg-${var.track}"
  }
}

resource "aws_vpc_security_group_ingress_rule" "inbound-rule1" {
  security_group_id = aws_security_group.efs-sg.id

  description = "Allow all traffic from VPC"
  from_port   = 2049
  to_port     = 2049
  cidr_ipv4   = data.aws_vpc.vpc.cidr_block
  ip_protocol = "tcp"
}

################################################ Egress rule ################################################

resource "aws_vpc_security_group_egress_rule" "outbound-rule" {
  security_group_id = aws_security_group.efs-sg.id

  description = "allow all outbound traffic"
  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}



############################################ EFS ############################################ 

#create efs system
resource "aws_efs_file_system" "efs" {
  count = length(local.server_names)

  creation_token   = "${var.creation_token}-${count.index}"
  performance_mode = var.performance_mode
  throughput_mode  = var.throughput_mode
  encrypted        = var.encrypted
  kms_key_id       = var.kms_key_id


  lifecycle_policy {
    transition_to_ia = "AFTER_7_DAYS"
  }
  tags = {
    Name = "${local.server_names[count.index]}-${local.region-alias}-efs-${var.track}"
  }
}

resource "aws_efs_backup_policy" "policy" {
  count          = length(local.server_names)
  file_system_id = aws_efs_file_system.efs[count.index].id

  backup_policy {
    status = "ENABLED"
  }
}

############################################ EFS Mount Target ############################################ 

#create mount target for efs

resource "aws_efs_mount_target" "efs-mt" {
  count           = length(data.aws_subnets.subnet.ids) * length(local.server_names)
  file_system_id  = aws_efs_file_system.efs[count.index % length(local.server_names)].id
  subnet_id       = data.aws_subnets.subnet.ids[floor(count.index / length(local.server_names))]
  security_groups = [aws_security_group.efs-sg.id]
}



########################################### EFS File Policy ##############################################################

data "aws_iam_policy_document" "efs-policy" {
  statement {
    effect = "Allow"

    actions = [
      "elasticfilesystem:ClientRootAccess",
      "elasticfilesystem:ClientWrite",
      "elasticfilesystem:ClientMount",
    ]

    condition {
      test     = "Bool"
      variable = "elasticfilesystem:AccessedViaMountTarget"
      values   = ["true"]
    }

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }

  statement {
    effect = "Allow"

    actions = [
      "elasticfilesystem:ClientRootAccess",
      "elasticfilesystem:ClientWrite",
      "elasticfilesystem:ClientMount",
    ]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.project}-iam-role"]
    }
  }
}

resource "aws_efs_file_system_policy" "policy" {
  count          = var.environment_abbreviation == "prod" ? length(local.prod_server_names) : min(length(local.this_servername_prefix), 1)
  file_system_id = aws_efs_file_system.efs[count.index].id
  policy         = data.aws_iam_policy_document.efs-policy.json

  # Lifecycle block to prevent constant updates
  lifecycle {
    ignore_changes = [policy]
  }

}
