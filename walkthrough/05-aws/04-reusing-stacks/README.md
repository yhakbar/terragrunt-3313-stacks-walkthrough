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

Also note that this mechanism scales for without any ambiguity as to where `inputs` are being defined. They are always defined for a Unit on the `terragrunt.hcl` file itself. No matter how deeply nested a Stack definition is (a Stack defining a Stack defining a Stack, for example), the `inputs` on a `terragrunt.hcl` file always determines the inputs for the Unit.

## Cleanup

To clean up the resources that were provisioned in this chapter, run the following:

```bash
$ terragrunt run-all destroy --terragrunt-non-interactive
```

## Next Steps

> TBD
>
> Please submit feedback if you would like to see more content here.

