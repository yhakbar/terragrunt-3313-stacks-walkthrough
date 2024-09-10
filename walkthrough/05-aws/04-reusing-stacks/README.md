# 03 - Reusing Stacks

This chapter will detail how Stacks themselves can be re-used by Stacks to reproduce a set of infrastructure instead of just reproducing individual Units.

## Architecture

```bash
$ tree -a
.
├── .gitignore
├── README.md
├── live
│   ├── dev
│   │   ├── environment.hcl
│   │   └── terragrunt.stack.hcl
│   ├── mock-stack-generate.sh -> ../../../../scripts/mock-stack-generate.sh
│   └── prod
│       ├── environment.hcl
│       └── terragrunt.stack.hcl
├── modules
│   ├── api
│   │   ├── logs.tf
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   ├── role.tf
│   │   ├── variables.tf
│   │   └── versions.tf
│   └── db
│       ├── main.tf
│       ├── outputs.tf
│       ├── variables.tf
│       └── versions.tf
├── scripts
│   ├── id.sh
│   └── package.sh
├── src
│   └── index.mjs
├── stacks
│   └── stateful-service
│       └── terragrunt.stack.hcl
├── terragrunt.hcl
└── units
    ├── api
    │   ├── .terraform.lock.hcl
    │   └── terragrunt.hcl
    └── db
        ├── .terraform.lock.hcl
        └── terragrunt.hcl
```

## Walkthrough

Just like before, you can engage in this walkthrough by performing the following:

```bash
$ cd live
$ ./mock-stack-generate.sh
$ terragrunt run-all apply --terragrunt-non-interactive
```

Note that the logs display a different path for the Units being run:

```bash
$ terragrunt run-all destroy --terragrunt-non-interactive
16:28:49.121 INFO   The stack at /Users/yousif/repos/src/github.com/yhakbar/terragrunt-3313-stacks-walkthrough/walkthrough/05-aws/04-reusing-stacks/live will be processed in the following order for command destroy:
Group 1
- Module dev/.terragrunt-stack/stateful-service/.terragrunt-stack/services/api
- Module prod/.terragrunt-stack/stateful-service/.terragrunt-stack/services/api

Group 2
- Module dev/.terragrunt-stack/stateful-service/.terragrunt-stack/storage/db
- Module prod/.terragrunt-stack/stateful-service/.terragrunt-stack/storage/db
```

At first glance, this is _less DRY_ than the previous walkthrough, as there is a new `stacks/stateful-service/terragrunt.stack.hcl` file that has to be tracked. However, the advantage of this approach is that the `stacks/stateful-service/terragrunt.stack.hcl` file can be re-used across multiple environments, and can be edited in one place to alter the behavior of all environments.

Say, for example, you wanted to add another API to the `stateful-service` Stack. You could add it to the `stacks/stateful-service/terragrunt.stack.hcl` file, and any Stack that references it would automatically have the new API added to it.

Edit the [terragrunt.stack.hcl](./stacks/stateful-service/terragrunt.stack.hcl) file to look like the following:

```hcl
unit "api" {
	source = "../../../../units/api"
	path   = "services/api"
}

unit "canary_api" {
	source = "../../../../units/api"
	path   = "services/canary-api"
}

unit "db" {
	source = "../../../../units/db"
	path   = "storage/db"
}
```

Now, if we were to simply regenerate the Stacks, and apply them, we would actually get some errors from AWS. The reason for this is that the logic for the `api` Unit doesn't account for the fact that it might not be the only API in the Stack.

You can see the relevant logic for the `name` input here:

```hcl
...
	name = "${local.project_name}-api-${local.random_id}-${local.environment}"
...
```

Multiple API units would try to create resources using names like `stacks-walkthrough-05-04-api-zgggh-dev`.

This is a limitation of the design of RFC [#3313](https://github.com/gruntwork-io/terragrunt/issues/3313), and is something that additional tooling might be added in the future to make this more convenient to handle.

The design philosophy of the proposal is that the authors Unit `terragrunt.hcl` files should decide how they want to handle these sorts of conflicts, as they are authoring the configurations that will be passed directly as inputs to OpenTofu/Terraform modules.

In this case, the `path` gives us a useful way of disambiguating the resources that are created by the `api` Unit. We can update the `name` input to reference the name of the directory it is placed in.

```hcl
...
	name = "${local.project_name}-${basename(get_terragrunt_dir())}-${local.random_id}-${local.environment}"
...
```

Now, if you were to re-run the `mock-stack-generate.sh` script, and apply the Stacks, you would see that the resources are created without any issues.

```bash
$ ./mock-stack-generate.sh
$ terragrunt run-all apply --terragrunt-non-interactive
```

We'll now have resources provisioned like `stacks-walkthrough-05-04-api-zgggh-dev` and `stacks-walkthrough-05-04-canary-api-zgggh-dev`.

To drive the point home, let's add one more, and see that the logic works as expected:

```hcl
unit "api" {
	source = "../../../../units/api"
	path   = "services/api"
}

unit "canary_api" {
	source = "../../../../units/api"
	path   = "services/canary-api"
}

unit "backup_api" {
	source = "../../../../units/api"
	path   = "services/backup-api"
}

unit "db" {
	source = "../../../../units/db"
	path   = "storage/db"
}
```

```bash
$ ./mock-stack-generate.sh
$ terragrunt run-all apply --terragrunt-non-interactive
```

Note that both the `dev` and `prod` environments continuously received these updates simultaneously. This doesn't have to be the case.

The references here could have been updated to reference versioned directories (e.g. `services/api/v1`), and the `terragrunt.stack.hcl` file in each environment could be updated in a rolling fashion to adopt the new version of the Stack. The reference could also be a tagged reference to a different repository (e.g. `github.com/yhakbar/terragrunt-3313-stacks-walkthrough//walkthrough/05-aws/04-reusing-stacks?ref=v1.0.0`).

## Stack Dynamicity

Also note that this mechanism scales without any ambiguity as to where `inputs` are being defined. They are always defined for a Unit on the `terragrunt.hcl` file itself. No matter how deeply nested a Stack definition is (a Stack defining a Stack defining a Stack, for example), the `inputs` on a `terragrunt.hcl` file always determines the inputs for the Unit.

This is the design for how the same set of Units can be re-used multiple times, across different environments with dynamic configurations. It is ultimately not a feature of Stacks (as currently designed for [#3313](https://github.com/gruntwork-io/terragrunt/issues/3313)) to define inputs for Units, but for Units to define their own inputs, and pull in the necessary configurations from the context in which they are instantiated.

In the example above, the only difference in the inputs being provisioned was their names. All the resources in the `dev` environment ended with a `-dev` suffix, and all the resources in the `prod` environment ended with a `-prod` suffix.

For many use cases, this is sufficient. The development environment exactly mimics the production environment, with different names for resources. However, in other use-cases there may be more significant differences between environments. For example, the `dev` environment might have a smaller instance size for a database, or a different set of secrets it needs to fetch.

The design decision here is that all of that should be defined in the `terragrunt.hcl` file that is going to provision the OpenTofu/Terraform module using those inputs.

If the `prod` environment should have a larger value for `memory_size` of the Lambda function it provisions, that should be defined in the `terragrunt.hcl` file that is going to provision the Lambda function, not in the `terragrunt.stack.hcl` file that is going to provision the `prod` environment.

Users should be able to expect to see something like the following in the `api` Unit's `terragrunt.hcl` file:

```hcl
locals {
  ...
  environment_configs = read_terragrunt_config(find_in_parent_folders("environment.hcl"))
  memory_size         = local.environment_configs.locals.memory_size
  ...
}

inputs = {
  ...
  memory_size = local.memory_size
  ...
}
```

If they want to have `memory_size` be a dynamically configurable property of the `api` Unit provisioned by the `stateful-service` Stack.

This is what users are already authoring in their `terragrunt.hcl` files, and the design of Stacks is meant to allow users to avoid engaging in rewrites to achieve this level of dynamism.

In-fact, users might want to encode that the `environment` of prod necessarily means that the `memory_size` of the Lambda function should be larger, and that the `environment` of dev necessarily means that the `memory_size` of the Lambda function should be smaller.

To achieve this, they might do something like the following:

```hcl
locals {
  ...
  environment_configs = read_terragrunt_config(find_in_parent_folders("environment.hcl"))
  memory_size         = local.environment_configs.locals.environment == "prod" ? 1024 : 512
  ...
}

inputs = {
  ...
  memory_size = local.memory_size
  ...
}
```

Now the `memory_size` of the Lambda function is dynamically determined by the `environment` of the Stack that is provisioning it. As you've already seen in the example above, users can also leverage the `path` input to dynamically determine the name of the resources that are being provisioned as well.

All of these configurations are being set in the `terragrunt.hcl` file that is going to provision the OpenTofu/Terraform module, and the `terragrunt.stack.hcl` file is simply a way to define the set of Units that are going to be provisioned this way.

Even when re-used, as part of other Stacks, Units themselves determine how they are going to be configured, and the Stacks that reference them simply determine which Units are going to be provisioned. In this example, the `stateful-service` Stack is provisioning the `api` and `db` Units, and the `api` and `db` Units are determining how they are going to be configured. It doesn't matter if the `api` and `db` Units are being provisioned by the `stateful-service` Stack, or by another Stack that wraps them (like the `dev` and `prod` Stacks in this example). The dynamicity of Unit configuration is always determined by the Units themselves.

## Cleanup

To clean up the resources that were provisioned in this chapter, run the following:

```bash
$ terragrunt run-all destroy --terragrunt-non-interactive
```

## Next Steps

> TBD
>
> Please submit feedback if you would like to see more content here.

