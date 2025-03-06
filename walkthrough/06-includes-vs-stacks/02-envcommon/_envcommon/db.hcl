locals {
	root_hcl_file = find_in_parent_folders("root.hcl")

	project_name = read_terragrunt_config(local.root_hcl_file).locals.project_name

	parent_dir = dirname(local.root_hcl_file)

	cur_dir_name = basename(get_terragrunt_dir())

	environment_hcl_path = find_in_parent_folders("environment.hcl")
	environment = read_terragrunt_config(local.environment_hcl_path).locals.environment
}

terraform {
	source = "${local.parent_dir}/modules/db"
}

inputs = {
	name = "${local.project_name}-${local.cur_dir_name}-${local.environment}"

	hash_key      = "Id"
	hash_key_type = "S"
}

