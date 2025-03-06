include "root" {
	path   = find_in_parent_folders("root.hcl")
	expose = true
}

include "api" {
	path = find_in_parent_folders("_envcommon/api.hcl")
	merge_strategy = "deep"
}

locals {
	parent_dir = dirname(find_in_parent_folders("root.hcl"))
}

terraform {
	source = "${local.parent_dir}/modules/api"
}

dependency "db" {
	config_path = "../db"

	# Mock outputs allow us to continue to plan on the apply of the api module
	# even though the db module has not yet been applied.
	mock_outputs_allowed_terraform_commands = ["plan", "destroy"] 
	mock_outputs = {
		name = "mock-table"
		arn  = "arn:aws:dynamodb:us-west-2:123456789012:table/mock-table"
	}
}

inputs = {
	dynamodb_table = dependency.db.outputs.name
	dynamodb_arn   = dependency.db.outputs.arn
}
