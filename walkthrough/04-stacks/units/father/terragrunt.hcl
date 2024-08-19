include "root" {
	path = find_in_parent_folders("terragrunt.hcl")
}

terraform {
	source = "${get_repo_root()}/walkthrough/01-tofu/modules/chicken"
}

include "inputs" {
	path = find_in_parent_folders("father.inputs.hcl")
}

