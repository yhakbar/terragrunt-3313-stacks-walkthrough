include "root" {
	path = find_in_parent_folders("root.hcl")
}

include "db" {
	path = find_in_parent_folders("_envcommon/db.hcl")
}
