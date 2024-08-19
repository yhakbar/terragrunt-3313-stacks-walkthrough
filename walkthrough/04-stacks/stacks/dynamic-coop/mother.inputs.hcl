locals {
	coops = read_terraform_config("coops.inputs.hcl").locals
	current_directory = "${basename(get_terragrunt_dir())}"

	first_name = local.coops[current_directory].first_name
	last_name = local.coops[current_directory].last_name
}

inputs = {
	first_name = local.first_name
	last_name  = local.last_name
}
