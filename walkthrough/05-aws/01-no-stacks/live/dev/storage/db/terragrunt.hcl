include "root" {
	path   = find_in_parent_folders("terragrunt.hcl")
	expose = true
}

include "db" {
	path = "${dirname(find_in_parent_folders("terragrunt.hcl"))}/_shared/db.hcl"
}

locals {
	project_name = include.root.locals.project_name
	random_id    = include.root.locals.random_id

	environment = read_terragrunt_config(find_in_parent_folders("environment.hcl")).locals.environment
}

inputs = {
	name = "${local.project_name}-db-${local.random_id}-${local.environment}"
}

