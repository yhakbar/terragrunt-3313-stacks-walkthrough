locals {
	parent_dir = dirname(find_in_parent_folders("terragrunt.hcl"))

	package_script = "${local.parent_dir}/scripts/package.sh"
	source_dir     = "${local.parent_dir}/src"
	dist_dir       = "${local.parent_dir}/dist"
}

terraform {
	source = "${local.parent_dir}/modules/api"

	before_hook "package" {
		commands = ["plan", "apply"]
		execute  = [local.package_script, local.source_dir, local.dist_dir]
	}
}

