include "root" {
	path   = find_in_parent_folders("root.hcl")
	expose = true
}

locals {
	project_name = include.root.locals.project_name

	parent_dir = get_parent_terragrunt_dir("root")

	cur_dir_name = basename(get_terragrunt_dir())
}

terraform {
	source = "${local.parent_dir}/modules/db"
}

inputs = {
	name = "${local.project_name}-${local.cur_dir_name}-prod"

	hash_key      = "Id"
	hash_key_type = "S"
}
