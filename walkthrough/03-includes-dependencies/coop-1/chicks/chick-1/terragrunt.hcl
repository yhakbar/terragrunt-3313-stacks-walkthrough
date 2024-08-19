include "root" {
	path = find_in_parent_folders("terragrunt.hcl")
}

include "chicken" {
	path = "${dirname(find_in_parent_folders("terragrunt.hcl"))}/_shared/chicken.hcl"
}

include "chick" {
	path = "${dirname(find_in_parent_folders("terragrunt.hcl"))}/_shared/chick.hcl"
}

inputs = {
	first_name = "Junior"
}

