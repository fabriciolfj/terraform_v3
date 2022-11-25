resource "aws_iam_user" "example" {
  name = var.user_name
}

resource "aws_iam_user_policy_attachment" "neo_cloudwatch_full_access" {
  count = var.give_neo_cloudwatch_full_access ? 1 : 0

  user       = aws_iam_user.example.name
  policy_arn = var.arn_cloudwatch_full
}

resource "aws_iam_user_policy_attachment" "neo_cloudwatch_read_only" {
  count = var.give_neo_cloudwatch_full_access ? 0 : 1

  user       = aws_iam_user.example.name
  policy_arn = var.arn_cloudwatch_read
}