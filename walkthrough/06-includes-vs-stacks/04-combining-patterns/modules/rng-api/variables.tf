variable "name" {
  type = string
}

variable "handler" {
  type    = string
  default = "bootstrap"
}

variable "runtime" {
  type    = string
  default = "provided.al2023"
}

variable "filename" {
  type    = string
  default = "package.zip"
}

variable "architectures" {
  type    = list(string)
  default = ["arm64"]
}
