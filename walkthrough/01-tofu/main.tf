variable "first_name" {
  type    = string
  default = "Foghorn"
}

variable "last_name" {
  type    = string
  default = "Leghorn"
}

data "external" "chicken" {
  program = ["cat", "-"]

  query = {
    first_name = var.first_name
    last_name  = var.last_name
  }
}

output "first_name" {
  value = data.external.chicken.result.first_name
}

output "last_name" {
  value = data.external.chicken.result.last_name
}
