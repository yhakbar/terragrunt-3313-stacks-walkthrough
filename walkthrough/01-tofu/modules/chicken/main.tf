variable "first_name" {
  type    = string
}

variable "last_name" {
  type    = string
}

variable "mother" {
  type    = string
  default = null
}

variable "father" {
  type    = string
  default = null
}

variable "lineage" {
  type    = string
  default = null
}

data "external" "chicken" {
  program = ["cat", "-"]

  query = {
    first_name = var.first_name
    last_name  = var.last_name

    mother = var.mother
    father = var.father

    lineage = var.lineage
  }
}

output "first_name" {
  value = data.external.chicken.result.first_name
}

output "last_name" {
  value = data.external.chicken.result.last_name
}

