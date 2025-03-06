# 02 - _envcommon

What most teams use today to define infrastructure is the `_envcommon` pattern, where a common `_envcommon` directory is placed at the root of a Terragrunt project to store shared configurations. This pattern allows teams to define common configurations that can be shared across multiple Terragrunt configurations, making it so that there's a single source of truth for common configurations.

## File Structure

```bash
$ eza -T -I 'src|dist|modules|README.md' --group-directories-last
.
├── root.hcl
├── _envcommon
│   ├── api.hcl
│   └── db.hcl
├── live
│   ├── dev
│   │   ├── environment.hcl
│   │   ├── api
│   │   │   └── terragrunt.hcl
│   │   └── db
│   │       └── terragrunt.hcl
│   └── prod
│       ├── environment.hcl
│       ├── api
│       │   └── terragrunt.hcl
│       └── db
│           └── terragrunt.hcl
└── scripts
    └── package.sh
```

The adjustments here include introducing the `_envcommon` directory, and adding the `environment.hcl` file to each environment. The `environment.hcl` file is used to define environment-specific configurations, such as the `environment` variable, which is used to define the environment name. The `terragrunt.hcl` files have been updated to reference those added configurations.

```hcl
# _envcommon/api.hcl
locals {
	root_hcl_file = find_in_parent_folders("root.hcl")

	project_name = read_terragrunt_config(local.root_hcl_file).locals.project_name

	parent_dir   = dirname(local.root_hcl_file)

	dist_dir       = "${local.parent_dir}/dist"
	source_dir     = "${local.parent_dir}/src"
	
	package_script = "${local.parent_dir}/scripts/package.sh"

	cur_dir_name = basename(get_terragrunt_dir())

	environment_hcl_path = find_in_parent_folders("environment.hcl")
	environment = read_terragrunt_config(local.environment_hcl_path).locals.environment

}

terraform {
	source = "${local.parent_dir}/modules/api"

	before_hook "package" {
		commands = ["plan", "apply"]
		execute  = [local.package_script, local.source_dir, local.dist_dir]
	}
}

dependency "db" {
	config_path = "${get_terragrunt_dir()}/../db"

	# Mock outputs allow us to continue to plan on the apply of the api module
	# even though the db module has not yet been applied.
	mock_outputs_allowed_terraform_commands = ["plan", "destroy"] 
	mock_outputs = {
		name = "mock-table"
		arn  = "arn:aws:dynamodb:us-west-2:123456789012:table/mock-table"
	}
}

inputs = {
	name = "${local.project_name}-${local.cur_dir_name}-${local.environment}"

	filename = "${local.dist_dir}/package.zip"

	dynamodb_table = dependency.db.outputs.name
	dynamodb_arn   = dependency.db.outputs.arn
}
```

```hcl
# live/dev/environment.hcl

locals {
	environment = "dev"
}
```

```hcl
# live/dev/api/terragrunt.hcl

include "root" {
	path = find_in_parent_folders("root.hcl")
}

include "api" {
	path = find_in_parent_folders("_envcommon/api.hcl")
}
```

With those adjustments in place, unit configurations now fairly minimal, with the majority of logic being done in shared `_envcommon` configurations. We can add new units to the project by creating a new directory under the `live` directory, and adding a `terragrunt.hcl` file that includes the `_envcommon` configurations, in addition to `root.hcl`.

While this is more DRY, it is also less flexible. Unit configurations in this pattern cannot take advantage of exposed includes (`expose = true`), as the different includes composing a unit don't have access to each other's configurations. They also require assumptions about the filesystem to work correctly, which can be brittle: The `environment.hcl` file must be present in every environment, and the `_envcommon/api.hcl` file must be present for the unit to work correctly. It's also difficult to reason about what exactly is going to be provisioned in each unit, as they each require evaluating a three way merge between the `terragrunt.hcl`, `root.hcl`, and `_envcommon/api.hcl` files. What if `prod` required more memory allocated to the `api` unit than `dev`? With this pattern, that configuration has to be declared as an HCL expression in the `_envcommon/api.hcl` file (e.g. `memory_size = local.environment == "prod" ? 256 : 128`), which can further confuse the reader. If you make that adjustment to the `_envcommon/api.hcl` file, how do you roll out that change? What if you want to roll it out incrementally?

All of these are addressable downsides, and with enough developer education, and documentation, teams can (and have) successfully use this pattern to manage infrastructure at very large scale. However, the biggest downside (and the downside that prompted the introduction of the `terragrunt.stack.hcl` file) is that this pattern requires a high file count of `terragrunt.hcl` files. In this pattern, the `terragrunt.hcl` files are largely placeholders for infrastructure state, with the actual configuration being stored in the `_envcommon` directory, which ends up resulting in a lot of files committed to repositories that don't do much.

## Conclusion

I do want to emphasize, though, that this pattern is not _wrong_. If it works for your team, and you're OK with the downsides, then by all means, use it. However, if you're looking for a more flexible way to manage infrastructure configurations at scale, the [`terragrunt.stack.hcl` file is likely a better fit](../03-stacks).

