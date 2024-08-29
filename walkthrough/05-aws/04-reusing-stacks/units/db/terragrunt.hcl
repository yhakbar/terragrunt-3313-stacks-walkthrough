include "root" {
	path   = find_in_parent_folders("terragrunt.hcl")
	expose = true
}

locals {
	project_name = include.root.locals.project_name
	random_id    = include.root.locals.random_id

	environment = read_terragrunt_config(find_in_parent_folders("environment.hcl")).locals.environment

	parent_dir = dirname(find_in_parent_folders("terragrunt.hcl"))
}

terraform {
	source = "${local.parent_dir}/modules/db"
}

inputs = {
	name = "${local.project_name}-db-${local.random_id}-${local.environment}"

	hash_key      = "Id"
	hash_key_type = "S"

}

