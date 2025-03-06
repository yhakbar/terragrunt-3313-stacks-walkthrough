include "root" {
	path = find_in_parent_folders("root.hcl")
}

include "api" {
	path = find_in_parent_folders("_envcommon/api.hcl")
}
