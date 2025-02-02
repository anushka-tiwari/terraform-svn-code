data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "ec2-assume-role" {
  statement {
    sid    = 1
    effect = "Allow"

    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "iam-role" {
  name               = "${local.project}-iam-role"
  assume_role_policy = data.aws_iam_policy_document.ec2-assume-role.json
}

resource "aws_iam_role_policy_attachment" "ec2_policies_attachment" {
  role       = aws_iam_role.iam-role.name
  policy_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/prov-EC2-Linux-Policy"
}


resource "aws_iam_role_policy_attachment" "ssm_policies_attachment" {
  role       = aws_iam_role.iam-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

data "aws_iam_policy_document" "efs-access-policy" {
  statement {
    sid       = 1
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "ec2:CreateTags",
      "elasticfilesystem:DescribeFileSystems",
      "elasticfilesystem:DescribeMountTargets",
      "elasticfilesystem:CreateMountTarget",
      "elasticfilesystem:ClientMount",
    ]
  }
}

data "aws_iam_policy_document" "kms-access-policy" {
  statement {
    sid    = 1
    effect = "Allow"

    actions = [
      "kms:DescribeKey",
      "kms:ReEncryptTo",
      "kms:ReEncryptFrom",
      "kms:CreateGrant",
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:ReEncrypt",
      "kms:GenerateDataKey"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "kms-policy" {
  name        = "${local.project}-iam-policy-kms"
  description = "Policy defining the necessary access to dependent KMS service."
  policy      = data.aws_iam_policy_document.kms-access-policy.json
}

resource "aws_iam_policy" "efs-policy" {
  name        = "${local.project}-iam-policy-efs"
  description = "Policy defining the necessary access to efs service."
  policy      = data.aws_iam_policy_document.efs-access-policy.json
}

resource "aws_iam_role_policy_attachment" "kms-policies_attachment" {
  role       = aws_iam_role.iam-role.name
  policy_arn = aws_iam_policy.kms-policy.arn
}

resource "aws_iam_role_policy_attachment" "efs-policies_attachment" {
  role       = aws_iam_role.iam-role.name
  policy_arn = aws_iam_policy.efs-policy.arn
}

resource "aws_iam_instance_profile" "ec2-iam-role" {
  name = "${local.resource_name_prefix}-ec2-iam-role"
  role = aws_iam_role.iam-role.id
}