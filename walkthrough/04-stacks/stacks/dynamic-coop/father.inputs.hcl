locals {
	coops = read_terragrunt_config(find_in_parent_folders("coops.locals.hcl")).locals
	stack_name = "${basename(dirname(find_in_parent_folders("terragrunt.stack.hcl")))}"

	first_name = local.coops[local.stack_name].father.first_name
	last_name = local.coops[local.stack_name].father.last_name
}

inputs = {
	first_name = local.first_name
	last_name  = local.last_name
}
