include "root" {
	path = find_in_parent_folders("terragrunt.hcl")
}

terraform {
	source = "${get_repo_root()}/walkthrough/01-tofu/modules/chicken"
}

dependency "mother" {
	config_path = "../../mother"
}

dependency "father" {
	config_path = "../../father"
}

locals {
	first_name = "${basename(get_terragrunt_dir())}"
}

inputs = {
	mother = "${dependency.mother.outputs.first_name} ${dependency.mother.outputs.last_name}"
	father = "${dependency.father.outputs.first_name} ${dependency.father.outputs.last_name}"

	// From what I've gathered chickens live in a Matriarchy.
	last_name = dependency.mother.outputs.last_name

	first_name = local.first_name
}

