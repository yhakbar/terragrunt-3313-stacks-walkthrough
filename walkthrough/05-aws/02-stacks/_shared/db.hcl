locals {
	parent_dir = dirname(find_in_parent_folders("terragrunt.hcl"))
}

terraform {
	source = "${local.parent_dir}/modules/db"
}

inputs = {
	hash_key = "Id"
	hash_key_type = "S"
}

