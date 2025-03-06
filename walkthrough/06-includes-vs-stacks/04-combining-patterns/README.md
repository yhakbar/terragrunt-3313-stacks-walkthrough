# 04 - Combined

To round out the examples in this chapter, consider a combination of the `_envcommon` and Stacks patterns.

## File Structure

```bash
$ eza -T -I 'src|dist|modules|README.md' --group-directories-last
.
├── root.hcl
├── _envcommon
│   └── api.hcl
├── live
│   ├── dev
│   │   ├── environment.yml
│   │   └── terragrunt.stack.hcl
│   └── prod
│       ├── environment.yml
│       └── terragrunt.stack.hcl
└── units
    ├── api
    │   ├── package.sh
    │   └── terragrunt.hcl
    ├── db
    │   └── terragrunt.hcl
    └── rng-api
        ├── package.sh
        └── terragrunt.hcl
```

To demonstrate the continued value of the `_envcommon` pattern, I've added a new unit, `rng-api` that behaves slightly different than the other `api` units. Rather than depending on the `db` unit to store and increment a counter, this version just returns a random number. Most of the configuration needed between the `api` unit and the `rng-api` unit are exactly the same, one just requires a `db` dependency and the other doesn't. This is an example of where the `_envcommon` pattern can continue to be useful, as the `_envcommon/api.hcl` file can be used to define the common configuration between the two units, and the `terragrunt.hcl` files can be used to adjust those common configurations as needed.

```hcl
# _envcommon/api.hcl
locals {
	root_hcl_file = find_in_parent_folders("root.hcl")

	parent_dir   = dirname(local.root_hcl_file)
	project_name = read_terragrunt_config(local.root_hcl_file).locals.project_name

	dist_dir   = "./dist"
	source_dir = "./src"

	package_script = "./package.sh"

	cur_dir_name = basename(get_terragrunt_dir())

	environment_yml_path = find_in_parent_folders("environment.yml")

	environment = yamldecode(file(local.environment_yml_path)).name
}

terraform {
	before_hook "package" {
		commands = ["plan", "apply"]
		execute  = [local.package_script, local.source_dir, local.dist_dir]
	}
}

inputs = {
	name = "${local.project_name}-${local.cur_dir_name}-${local.environment}"

	filename = "${local.dist_dir}/package.zip"
}
```

```hcl
# units/api/terragrunt.hcl
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
	source = "${local.parent_dir}/modules/api"
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
	dynamodb_table = dependency.db.outputs.name
	dynamodb_arn   = dependency.db.outputs.arn
}
```

```hcl
# units/rng-api/terragrunt.hcl
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
```

```hcl
# live/dev/terragrunt.stack.hcl
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
```

Here, you can see that both the `api` and `rng-api` units include the same `_envcommon/api.hcl` file, but the `api` unit also defines a `db` dependency. This allows the `api` unit to have the same base configuration as the `rng-api` unit, but also merge in configuration to use the `db` dependency. For teams that want a tight coupling between their unit configurations, this can be a good way to achieve that.

Some might prefer less-DRY configurations, and have `api` defined independently from `rng-api` with no `_envcommon`, but different teams have different needs. You have to decide where the correct trade-offs are for the infrastructure that you are managing, between highly DRY and highly flexible configurations.

Also note that the "Stack" abstraction has changed here. Instead of defining _all_ the infrastructure that lives in `live` using one `terragrunt.stack.hcl` file, multiple `terragrunt.stack.hcl` files have been used in each environment (`live/dev/terragrunt.stack.hcl` and `live/prod/terragrunt.stack.hcl`). Teams with a large IaC footprint probably already have many `terragrunt.hcl` files committed to their repositories, and tooling that interacts with the directories where those configurations are defined (e.g. in CI, you might navigate to `live/prod` and apply everything there when you merge to `main`). Rather than retool your CI/CD to leverage the new `terragrunt.stack.hcl` file, you can simply keep your existing tooling, and define your stacks the way that makes sense for your team.

Additionally, note the introduction of the `environment.yml` file in the environment stacks. Many teams today today use non-HCL configurations in conjunction with HCL configurations to define configurations for their environments. The `values` attribute of the `terragrunt.stack.hcl` file is useful, and many teams might prefer it to an `environment.hcl` file found in a parent folder. However, if you are a team that is already using configuration files like `environment.yml`, and have additional tooling like `yq` that interacts with those files, you might prefer to continue using those files. This is a good example of how the Stacks pattern really aims to be additive to your existing workflows and patterns, rather than a complete replacement. You don't have to rewrite all of your configurations if it doesn't benefit you.

## Conclusion

Hopefully, these examples give you a good idea of how you can use the different patterns enabled by Terragrunt to shape configurations in a way that works for your team, and the trade-offs they present.

The "Not DRY" pattern is a good way to get started with Terragrunt, and is a good way to get a feel for how Terragrunt works. It's also a good way to get started with Terragrunt if you're not sure how you want to structure your configurations yet. However, as your infrastructure grows, you'll likely find that you want to share more configuration between units, and the "Not DRY" pattern can become unwieldy.

The "_envcommon" pattern is a good way to quickly share configuration between units without larger refactoring, and is a valid way to get started with reusing configurations. However, as the number of units you manage grows, you'll likely find that you want to share more configuration between environments, and the "_envcommon" pattern can become unwieldy. It doesn't provide convenient mechanisms for making different instances of shared configuration unique. You might need to adopt advanced configurations using ternaries and discovery of configuration in parent folders to make different units including the same `_envcommon` configurations unique. It also requires that shared configuration exists on the local filesystem. This can be especially problematic when trying to gradually roll out changes across environments.

The "Stacks" pattern is a good way to manage configurations at scale, and is a good way to manage configurations across environments. However, it requires a different way of thinking about how you structure your configurations, and might not be a good fit for all teams, especially ones that have already invested heavily in the "_envcommon" pattern. Instead of primarily relying on shared partial configuration in the `_envcommon` directory to promote code reuse, the "Stacks" pattern relies on entire re-usable unit configurations that can be sourced in a `terragrunt.stack.hcl` file. You also don't need to structure your configurations with hierarchically discovered configurations in parent folders. Instead, you can use the `values` attribute to customize the unit configurations for different environments, and explicitly pass them down to the unit that's using them.

To be clear, I'm also not saying that the `_envcommon` pattern is a definite stepping stone to the "Stacks" pattern. Many teams have successfully managed infrastructure at large scale using the "_envcommon" pattern, and if it works for your team, then by all means, use it. Similarly, if you want to start from a scalable foundation, and you know that you will encounter the problems that the "_envcommon" pattern presents, then the "Stacks" pattern might be a good place to start after getting started with Terragrunt.

You should also know that there are trade-offs to combining patterns. It can make it so that your configurations won't look familiar to people with experience using Terragrunt, and you'll likely encounter more novel issues that the Terragrunt community at large doesn't have to worry about.

Terragrunt maintainers are introducing the "Stacks" pattern instead of expanding the tooling for the "_envcommon" pattern because of the belief that the "Stacks" pattern is a more scalable and flexible way to manage configurations at scale. For the vast majority of Terragrunt users, primarily relying on the "Stacks" pattern for code reuse will be the best path forward. You will also be able to expect more tooling and documentation geared towards making the "Stacks" pattern better in the future, so it's a good idea to start adopting it now, where possible.
