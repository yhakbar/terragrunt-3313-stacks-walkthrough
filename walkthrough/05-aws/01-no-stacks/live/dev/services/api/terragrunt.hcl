include "root" {
	path   = find_in_parent_folders("terragrunt.hcl")
	expose = true
}

include "api" {
	path = "${dirname(find_in_parent_folders("terragrunt.hcl"))}/_shared/api.hcl"
}

locals {
	project_name = include.root.locals.project_name
	random_id    = include.root.locals.random_id

	environment = read_terragrunt_config(find_in_parent_folders("environment.hcl")).locals.environment

	parent_dir = get_parent_terragrunt_dir("root")
	dist_dir   = "${local.parent_dir}/dist"
}

dependency "db" {
	config_path = "../../storage/db"

	# Mock outputs allow us to continue to plan on the apply of the api module
	# even though the db module has not yet been applied.
	mock_outputs_allowed_terraform_commands = ["plan", "destroy"] 
	mock_outputs = {
		name = "mock-table"
		arn  = "arn:aws:dynamodb:us-west-2:123456789012:table/mock-table"
	}
}

inputs = {
	name = "${local.project_name}-api-${local.random_id}-${local.environment}"

	filename = "${local.dist_dir}/package.zip"

	dynamodb_table = dependency.db.outputs.name
	dynamodb_arn   = dependency.db.outputs.arn
}

