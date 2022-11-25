variable "user_name" {
  type = string
}

variable "give_neo_cloudwatch_full_access" {
  description = ""
  type = bool
  default = true
}

variable "arn_cloudwatch_full" {
  type = string
}

variable "arn_cloudwatch_read" {
  type = string
}