# 01 - Not DRY

As a base-case, let's take a look at some configurations that are intentionally _not_ DRY.

## File Structure

```bash
$ eza -T -I 'src|dist|modules|README.md' --group-directories-last
.
├── root.hcl
├── live
│   ├── dev
│   │   ├── api
│   │   │   └── terragrunt.hcl
│   │   └── db
│   │       └── terragrunt.hcl
│   └── prod
│       ├── api
│       │   ├── package.sh
│       │   └── terragrunt.hcl
│       └── db
│           └── terragrunt.hcl
└── scripts
    └── package.sh
```

Ignoring some uninteresting files here, we have one `root.hcl` file at the root of our configurations, and two environments, `dev` and `prod`, each with two units, `api` and `db`.

Each of those units has a `terragrunt.hcl` file that looks like this:

```hcl
# live/dev/api/terragrunt.hcl

include "root" {
	path   = find_in_parent_folders("root.hcl")
	expose = true
}

locals {
	project_name = include.root.locals.project_name

	parent_dir   = get_parent_terragrunt_dir("root")

	dist_dir       = "${local.parent_dir}/dist"
	source_dir     = "${local.parent_dir}/src"
	
	package_script = "${local.parent_dir}/scripts/package.sh"

	cur_dir_name = basename(get_terragrunt_dir())
}

terraform {
	source = "${local.parent_dir}/modules/api"

	before_hook "package" {
		commands = ["plan", "apply"]
		execute  = [local.package_script, local.source_dir, local.dist_dir]
	}
}

dependency "db" {
	config_path = "../db"

	# Mock outputs allow us to continue to plan on the apply of the api module
	# even though the db module has not yet been applied.
	mock_outputs_allowed_terraform_commands = ["plan", "destroy"] 
	mock_outputs = {
		name = "mock-table"
		arn  = "arn:aws:dynamodb:us-west-2:123456789012:table/mock-table"
	}
}

inputs = {
	name = "${local.project_name}-${local.cur_dir_name}-dev"

	filename = "${local.dist_dir}/package.zip"

	dynamodb_table = dependency.db.outputs.name
	dynamodb_arn   = dependency.db.outputs.arn
}
```

While there is some code re-use here, there isn't much. The `include "root` block at the top of the repository is used to ensure that there's common state configurations for all units, and the `dist`, `src`, `scripts` and `modules` directories referenced relative to the `root.hcl` file are shared as well.

What isn't shared is the actual configuration of the units themselves. The `terraform` block, `dependency` block, and `inputs` block are all duplicated across each unit. This includes the `-dev` suffix applied to the `name` attribute, which has to be set in each unit to reflect the appropriate environment.

While flexible (each unit could be configured completely differently if needed), this approach does result in a lot of brittle duplication that would be difficult to maintain as the number of units grows. What if you wanted to add a `staging` environment? You'd have to copy and paste the configuration from `dev` to `staging`, then update all the references to `dev` to `staging`. What if you wanted multiple APIs per environment? You'd have to copy and paste the configuration from `api` to `api2` in every environment, then make sure there weren't any naming collisions.

## Conclusion

To be clear, this approach to defining infrastructure isn't _wrong_, it just isn't the best fit for most teams. Most teams want to be able to conveniently replicate patterns used to provision infrastructure with dynamic configurations that can be easily adjusted. Until the introduction of the `terragrunt.stack.hcl` file, the most convenient way to achieve this was use of the "envcommon" pattern, as discussed in [envcommon](../02-envcommon).
