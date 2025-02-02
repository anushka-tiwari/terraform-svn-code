# Data source for Route 53 Zone
data "aws_route53_zone" "zone" {
  name         = "${local.account-mapping[var.environment]}.awscloud.private"
  private_zone = true
}
# DynamoDB Table
resource "aws_dynamodb_table" "instance_metadata" {
  name         = "${local.project}-Instance-Metadata"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "InstanceId"

  attribute {
    name = "InstanceId"
    type = "S"
  }
  server_side_encryption {
    enabled     = true
    kms_key_arn = var.kms_key_id
  }

}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_exec" {
  name = "${local.project}-lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com",
        }
      }
    ]
  })
}

# IAM Policy for Lambda
resource "aws_iam_policy" "lambda_policy" {
  name        = "${local.project}-lambda-dns-policy"
  description = "Policy to allow Lambda to manage Route 53 records and DynamoDB"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:ListHostedZones",
          "route53:ListResourceRecordSets",
          "ec2:DescribeInstances",
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:DescribeTable",
          "dynamodb:Scan",
          "dynamodb:DeleteItem",
          "autoscaling:CompleteLifecycleAction",
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ],
        Resource = "*",
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ],
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Attach IAM Policy to IAM Role
resource "aws_iam_role_policy_attachment" "lambda_role_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# Create Lambda function deployment package
data "archive_file" "lambda_function" {
  type        = "zip"
  source_file = "${path.module}/lambda-function.py"
  output_path = "${path.module}/zipped-file/lambda-function.zip"
}

# Lambda Function
resource "aws_lambda_function" "dns_update" {
  function_name    = var.function_name
  handler          = "lambda-function.lambda_handler"
  runtime          = "python3.11"
  timeout          = 300
  role             = aws_iam_role.lambda_exec.arn
  filename         = data.archive_file.lambda_function.output_path
  source_code_hash = filebase64sha256(data.archive_file.lambda_function.output_path)
  environment {
    variables = {
      HOSTED_ZONE_ID      = data.aws_route53_zone.zone.zone_id
      DOMAIN_NAME         = var.domain_name
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.instance_metadata.name
    }
  }
}

# CloudWatch Event Rule for ASG events
resource "aws_cloudwatch_event_rule" "asg_event" {
  name        = "${local.project}-asg-event-rule"
  description = "Triggered when an instance is launched or terminated in the ASG"
  event_pattern = jsonencode({
    "source" : [
      "aws.autoscaling"
    ],
    "detail-type" : [
      "EC2 Instance Launch Successful",
      "EC2 Instance Terminate Successful"
    ]
  })
}

# CloudWatch Event Target
resource "aws_cloudwatch_event_target" "asg_event_target" {
  rule      = aws_cloudwatch_event_rule.asg_event.name
  target_id = "lambda_dns_update"
  arn       = aws_lambda_function.dns_update.arn
}

# Lambda permission to be invoked by CloudWatch Events
resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dns_update.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.asg_event.arn
}

