unit "api" {
	source = "${dirname(find_in_parent_folders("root.hcl"))}/units/api"
	path   = "api"

	values = {
		environment = values.environment
	}
}

unit "db" {
	source = "${dirname(find_in_parent_folders("root.hcl"))}/units/db"
	path   = "db"

	values = {
		environment = values.environment
	}
}
