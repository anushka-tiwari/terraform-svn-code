resource "aws_kms_key" "ebs-efs" {
  description             = "KMS Key for EFS"
  deletion_window_in_days = 10
  enable_key_rotation     = true

  # Lifecycle block to avoid changes to key attributes
  lifecycle {
    ignore_changes = [
      description # Ignore description changes
    ]
  }

}

resource "aws_kms_alias" "ebs-efs" {
  name          = "alias/${local.project}-kms-key-${var.track}"
  target_key_id = aws_kms_key.ebs-efs.key_id
}

resource "aws_kms_key_policy" "kms-policy-efs" {
  key_id = aws_kms_key.ebs-efs.arn

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Id": "AllowEBSVolumesEncryption",
    "Statement": [
        {
            "Sid": "Allow access through EBS for all principals in the account that are authorized to use EBS",
            "Effect": "Allow",
            "Principal": {
                "AWS": "*"
            },
            "Action": [
                "kms:DescribeKey",
                "kms:ReEncryptTo",
                "kms:ReEncryptFrom",
                "kms:CreateGrant",
                "kms:Decrypt",
                "kms:Encrypt",
                "kms:ReEncrypt",
                "kms:GenerateDataKey*"

            ],
            "Resource": "*"
        },
        {
            "Sid": "Allow administration of the key",
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
            },
            "Action": "kms:*",
            "Resource": "*"
        }
    ]
}
EOF

  # Lifecycle block to avoid policy updates
  lifecycle {
    ignore_changes = [policy]
  }

}