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

module "chicken" {
  source = "./modules/chicken"

  first_name = var.first_name
  last_name  = var.last_name

  mother = var.mother
  father = var.father

  lineage = var.lineage
}

output "first_name" {
  value = module.chicken.first_name
}

output "last_name" {
  value = module.chicken.last_name
}

