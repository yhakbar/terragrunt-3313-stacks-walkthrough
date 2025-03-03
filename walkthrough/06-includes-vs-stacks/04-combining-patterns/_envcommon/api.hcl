locals {
	root_hcl_file = find_in_parent_folders("root.hcl")

	parent_dir   = dirname(local.root_hcl_file)
	project_name = read_terragrunt_config(local.root_hcl_file).locals.project_name

	dist_dir   = "./dist"
	source_dir = "./src"
	
	package_script = "./package.sh"

	cur_dir_name = basename(get_terragrunt_dir())

	environment_yml_path = find_in_parent_folders("environment.yml")

	environment = yamldecode(file(local.environment_yml_path)).name
}

terraform {
	before_hook "package" {
		commands = ["plan", "apply"]
		execute  = [local.package_script, local.source_dir, local.dist_dir]
	}
}

inputs = {
	name = "${local.project_name}-${local.cur_dir_name}-${local.environment}"

	filename = "${local.dist_dir}/package.zip"
}
