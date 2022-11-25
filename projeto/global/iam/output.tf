output "user_arns" {
  value = values(module.users)[*].user_arn
}

output "upper_names" {
  value = [for name in var.user_names : upper(name) if length(name) < 5]
}

output "for_directive" {
  value = <<EOF
        "%{ for i, name in var.user_names }
          ${i} ${name} %{if i < length(var.user_names) - 1}, %{else}. %{endif}
          %{~endfor~}"
        EOF
}

output "arn_cloudwatch_full" {
  value = aws_iam_policy.cloudwatch_full_access.arn
}

output "arn_cloudwathc_read_only" {
  value = ""
}