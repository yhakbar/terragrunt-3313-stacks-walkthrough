unit "api" {
	source = "${dirname(find_in_parent_folders("root.hcl"))}/units/api"
	path   = "api"
}

unit "rng_api" {
	source = "${dirname(find_in_parent_folders("root.hcl"))}/units/rng-api"
	path   = "rng-api"
}

unit "db" {
	source = "${dirname(find_in_parent_folders("root.hcl"))}/units/db"
	path   = "db"
}
