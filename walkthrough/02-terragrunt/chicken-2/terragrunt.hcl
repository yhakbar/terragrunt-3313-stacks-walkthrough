terraform {
	source = "${get_repo_root()}/walkthrough/01-tofu/modules/chicken"
}

inputs = {
	first_name = "Lady"
	last_name  = "Kluck"
}

