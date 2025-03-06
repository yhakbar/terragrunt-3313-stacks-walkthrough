locals {
	root_hcl_file = find_in_parent_folders("root.hcl")

	project_name = read_terragrunt_config(local.root_hcl_file).locals.project_name

	parent_dir   = dirname(local.root_hcl_file)

	dist_dir       = "${local.parent_dir}/dist"
	source_dir     = "${local.parent_dir}/src"
	
	package_script = "${local.parent_dir}/scripts/package.sh"

	cur_dir_name = basename(get_terragrunt_dir())

	environment_hcl_path = find_in_parent_folders("environment.hcl")
	environment = read_terragrunt_config(local.environment_hcl_path).locals.environment

}

terraform {
	source = "${local.parent_dir}/modules/api"

	before_hook "package" {
		commands = ["plan", "apply"]
		execute  = [local.package_script, local.source_dir, local.dist_dir]
	}
}

dependency "db" {
	config_path = "${get_terragrunt_dir()}/../db"

	# Mock outputs allow us to continue to plan on the apply of the api module
	# even though the db module has not yet been applied.
	mock_outputs_allowed_terraform_commands = ["plan", "destroy"] 
	mock_outputs = {
		name = "mock-table"
		arn  = "arn:aws:dynamodb:us-west-2:123456789012:table/mock-table"
	}
}

inputs = {
	name = "${local.project_name}-${local.cur_dir_name}-${local.environment}"

	filename = "${local.dist_dir}/package.zip"

	dynamodb_table = dependency.db.outputs.name
	dynamodb_arn   = dependency.db.outputs.arn
}
