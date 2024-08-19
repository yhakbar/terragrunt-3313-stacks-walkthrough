# 01 - Basic

This chapter demonstrates the simplest usage of a Stack: To replace the configuration shown in the [previous chapter](../../03-includes-dependencies) with [a single file](./coop-1/terragrunt.stack.hcl) that defines the configuration for the entire Stack:

```hcl
unit "mother" {
	source = "../../units/chicken"
	path   = "mother"
}

unit "father" {
	source = "../../units/chicken"
	path   = "father"
}

unit "chick_1" {
	source = "../../units/chick"
	path   = "chicks/chick-1"
}

unit "chick_2" {
	source = "../../units/chick"
	path   = "chicks/chick-2"
}
```

To simulate what Terragrunt will do when Stacks are available, a script has been comitted that will generate the appropriate `.terragrunt-stack` directory using a bash script.

## Walkthrough

Navigate to the [coop-1](./coop-1) directory, and execute the [mock-stack-render.sh](./coop-1/mock-stack-render.sh) script to see it simulate the `terragrunt stack render` command.

```bash
$ cd coop-1
$ ./mock-stack-render.sh
$ tree .terragrunt-stack/
.terragrunt-stack/
├── chicks
│   ├── chick-1
│   │   └── terragrunt.hcl
│   └── chick-2
│       └── terragrunt.hcl
├── father
│   └── terragrunt.hcl
└── mother
    └── terragrunt.hcl
```

As you can see, the directory structure is very similar to that demonstrated in the [previous chapter](../../03-includes-dependencies), without the need to have a `_shared` directory for code re-use. Because the entire Unit can be re-used with stacks, there is less benefit to relying on an external store of shared configurations.

You can also try out what it would be like to execute `terragrunt stack apply` on the stack. Running the following will apply those Units:

```bash
$ terragrunt run-all apply --terragrunt-non-interactive
```

> Note that if you don't run the [mock-stack-render.sh](./coop-1/mock-stack-render.sh) script, you won't have the `.terragrunt-stack` directory, and the `terragrunt run-all apply` command will ignore the `terragrunt.stack.hcl` file.
> This is an intentional part of the design here. Users of Terragrunt versions older than the one that supports Stacks will not have tooling to render the `.terragrunt-stack` directory, and will not be able to use the `terragrunt.stack.hcl` file.
> Designing the functionality this way should prevent users from being surprised by the behavior of their Terragrunt configurations when they upgrade to a version that supports Stacks.
> In the future, it's likely that `run-all` will automatically render the `.terragrunt-stack` directory if it doesn't exist, but for now, it's a manual, opt-in process.

Similar to the previous chapter, you can also see that they leverage their position within the filesystem to drive metadata that can be used to determine where to store state:

```bash
$ cd .terragrunt-stack/chicks/chick-1
$ terragrunt show
# data.external.chicken:
data "external" "chicken" {
    id      = "-"
    program = [
        "cat",
        "-",
    ]
    query   = {
        "father"     = "A Chicken"
        "first_name" = "chick-1"
        "last_name"  = "Chicken"
        "lineage"    = "coop-1/.terragrunt-stack/chicks/chick-1"
        "mother"     = "A Chicken"
    }
    result  = {
        "father"     = "A Chicken"
        "first_name" = "chick-1"
        "last_name"  = "Chicken"
        "lineage"    = "coop-1/.terragrunt-stack/chicks/chick-1"
        "mother"     = "A Chicken"
    }
}


Outputs:

first_name = "chick-1"
last_name = "Chicken"
```

## Configuration Syntax

These Units that have been generated through the mock stack render command don't use any syntax that's different than the average Terragrunt Unit. All techniques, functions and patterns used to author `terragrunt.hcl` files will directly transfer over to authoring Units as part of stacks.

Note that the `unit` configuration blocks within the Stack definition specify a local `source`, and a `path`. The `source` will tell Terragrunt where to fetch content for use when rendering a stack, and the `path` will be used to determine where the Unit should be rendered in to the `.terragrunt-stack` directory.

In this walkthrough, the reusable Unit definitions have been placed in a [units](../units) folder. For users of monorepos, this might be how they define Unit sources. For users leveraging remote Unit definitions, this is more likely to be something like the following:

```
github/yhakbar/terragrunt-3313-stacks-walkthrough//walkthrough/04-stacks/units/mother?ref=main
```

Where the string is a valid `go-getter` string that references the Unit in a different git repository at a particular git reference. This is how Stacks will provide a mechanism for versioned Unit definitions.

Users can maintain the same well tested version of an OpenTofu module that serves many generic use-cases, then use different versions of Unit by adjusting the ref.

e.g. 

```
github/yhakbar/terragrunt-3313-stacks-walkthrough//walkthrough/04-stacks/units/mother?ref=v0.0.1
```

to:

```
github/yhakbar/terragrunt-3313-stacks-walkthrough//walkthrough/04-stacks/units/mother?ref=v0.0.2
```

This is useful if the change you are propagating is not how resources are provisioned in the cloud, but how inputs, integrations and outputs are leveraged by a Terragrunt Unit.

Let's explore some aspects of how the [chick](../units/chick/terragrunt.hcl) Unit is defined:

```hcl
include "root" {
	path = find_in_parent_folders("terragrunt.hcl")
}

terraform {
	source = "${get_repo_root()}/walkthrough/01-tofu/modules/chicken"
}

dependency "mother" {
	config_path = "../../mother"
}

dependency "father" {
	config_path = "../../father"
}

locals {
	first_name = "${basename(get_terragrunt_dir())}"
}

inputs = {
	mother = "${dependency.mother.outputs.first_name} ${dependency.mother.outputs.last_name}"
	father = "${dependency.father.outputs.first_name} ${dependency.father.outputs.last_name}"

	// From what I've gathered chickens live in a Matriarchy.
	last_name = dependency.mother.outputs.last_name

	first_name = local.first_name
}

```

### `include "root"`

There is still an `include "root"` at the top of the file. Terragrunt users are very familar with this configuration block being present in every `terragrunt.hcl` file, and it serves the same purpose it does outside of the context of a Stack:

1. It accesses common configurations that all Units need to leverage (like what state backend to use and provider to configure).
2. It can leverage the path to a parent `terragrunt.hcl` file to determine the path for state storage. In the command executed above, you can see how this results in `lineage` including the `.terragrunt-stack` directory.

### `terraform`

The `terraform` block is defined directly in this file, not shared from a central `_shared` directory. Given the fact that the whole Unit definition can be re-used, it's less beneficial in this context to do a secondary lookup for the `terraform` block. It can be defined directly in the `terragrunt.hcl` file once, and be re-used without splitting up configurations.

### `dependency`

The `dependency` blocks referenced here use relative paths to `mother` and `father`. Because users can specify a `path` attribute for the `unit` block, they can decide that any number of `chick` Units will be provisioned, and as long as the `mother` and `father` Units are rendered into the correct location, they will be able to fetch those dependencies as they would outside of the context of a Stack.

This proposal does not use any special syntax for configuring the integration between Units. As the Stack author, you know the patterns you expect for how a Stack will be rendered, and are expected to configure integrations in Unit definitions accordingly.

### `first_name`

The `first_name` input for the `chick` Unit uses a simple convention of leveraging the name of the directory it is rendered into (`basename(get_terragrunt_dir())`) to determine an input for the Unit. This is not always a desireable way to configure inputs for a Stack, but it is simple, and works for a large number of use-cases.

What a user might expect to be able to do is to define an input for this Unit at the Stack level. The design considerations for that pattern will be explored in the [next chapter](../02-dynamicity).

