provider "aws" {
  region = "us-east-2"
}

module "users" {
  source = "../../modules/landing-zone/iam-user"
  for_each = toset(var.user_names)
  user_name = each.value
  arn_cloudwatch_full = aws_iam_policy.cloudwatch_full_access.arn
  arn_cloudwatch_read = aws_iam_policy.cloudwatch_read_only.arn
}

resource "aws_iam_policy" "cloudwatch_read_only" {
  name   = "cloudwatch-read-only3"
  policy = data.aws_iam_policy_document.cloudwatch_read_only.json
}

data "aws_iam_policy_document" "cloudwatch_read_only" {
  statement {
    effect    = "Allow"
    actions   = [
      "cloudwatch:Describe*",
      "cloudwatch:Get*",
      "cloudwatch:List*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "cloudwatch_full_access" {
  name   = "cloudwatch-full-access"
  policy = data.aws_iam_policy_document.cloudwatch_full_access.json
}

data "aws_iam_policy_document" "cloudwatch_full_access" {
  statement {
    effect    = "Allow"
    actions   = ["cloudwatch:*"]
    resources = ["*"]
  }
}