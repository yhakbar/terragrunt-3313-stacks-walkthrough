terraform {
	source = "${get_repo_root()}/walkthrough/01-tofu/modules/chicken"
}

inputs = {
	first_name = "Ginger"
	last_name  = "Chicken"
}

