variable "name" {
  type = string
}

variable "handler" {
  type    = string
  default = "index.handler"
}

variable "runtime" {
  type    = string
  default = "nodejs20.x"
}

variable "filename" {
  type    = string
  default = "lambda.zip"
}

variable "dynamodb_table" {
  type = string
}

variable "dynamodb_arn" {
  type = string
}

