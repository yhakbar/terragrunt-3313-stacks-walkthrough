include "root" {
	path   = find_in_parent_folders("root.hcl")
	expose = true
}

include "api" {
	path = find_in_parent_folders("_envcommon/api.hcl")
	merge_strategy = "deep"
}

locals {
	parent_dir = dirname(find_in_parent_folders("root.hcl"))
}

terraform {
	source = "${local.parent_dir}/modules/rng-api"
}
