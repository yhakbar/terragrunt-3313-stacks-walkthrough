# 02 - Dynamicity

In the previous chapter, a fairly simple approach to generating a Stack was taken: All the Units were generated with no configurability aside from the name of the directory they were generated into.

A straightforward approach to handling this would be to allow users to define inputs for each Unit in a Stack, and then to have the generated Units use those inputs to configure themselves.

The proposal in [#3313](https://github.com/gruntwork-io/terragrunt/issues/3313) takes a fairly conservative (and pretty controversial so far) approach to avoid introducing functionality like this.

Instead, it expects users to write Terragrunt configurations using functions and patterns that are in common usage today to derive that same functionality without introducing any inputs to the `unit` configuration block.

In this walkthrough, a hypothetical user wants to be able to generate a similar stack to the one generated in [the previous chapter](../01-basic/coop-1/terragrunt.stack.hcl), but wants to be able to do so using configurable inputs `first_name` and `last_name` for the `chicken` Units that serve as `mother` and `father`.

This simulates a more practically useful piece of functionality like naming a service, defining a VPC CIDR block, etc. for a cloud resource.

## Walkthrough

To use this part of the walkthrough, run the following in this directory:

```bash
./mock-stack-generate.sh
terragrunt run-all apply --terragrunt-non-interactive
```

Note that the `mock-stack-generate.sh` script is no longer located in the `coop-1` directory, as it was in the last chapter. This is how users are expected to interact with the Stacks using the CLI.

Terragrunt should recursively traverse the filesystem and generate all Stacks discovered.

## Configuration Syntax

The only difference between the `terragrunt.stack.hcl` file used here and that used in [the previous chapter](../01-basic/coop-1/terragrunt.stack.hcl) is that the `source` for the `mother` and `father` Units is now set to the `../../units/mother` and `../../units/father` directories, respectively.

```hcl
unit "mother" {
	source = "../../units/mother"
	path   = "mother"
}

unit "father" {
	source = "../../units/father"
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

Due to the limitation of Terragrunt not currently supporting `unit` configuration blocks, an example has been presented here that deviates slightly from the proposal in `#3313`, but it takes the same approach to providing dynamicity in Stacks without changing how `terragrunt.hcl` files work today.

If you take a look at the [`mother` Unit](../units/mother/terragrunt.hcl), you'll see that it's using an `include` to merge in configurations defined in a parent directory:

```hcl
include "root" {
	path = find_in_parent_folders("terragrunt.hcl")
}

terraform {
	source = "${get_repo_root()}/walkthrough/01-tofu/modules/chicken"
}

include "inputs" {
	path = find_in_parent_folders("mother.inputs.hcl")
}
```

When inspecting the `coop-1` directory, you'll find that there's a `mother.inputs.hcl` file there that defines the inputs for the `mother` Unit:

```bash
$ tree coop-1/
coop-1/
├── father.inputs.hcl
├── mother.inputs.hcl
└── terragrunt.stack.hcl
```

```hcl
# coop-1/mother.inputs.hcl
inputs = {
	first_name = "Lady"
	last_name  = "Hen"
}
```

This can be described as providing a "pull" based approach to defining shared configurations instead of a "push" based approach.

The `mother` Unit is able to define inputs it wants to _pull_ from a parent directory, and decide how it wants to merge in those shared configurations.

An alternate approach might be something like the following:

```hcl
unit "mother" {
	source = "../../units/mother"
	path   = "mother"

	inputs = {
		first_name = "Lady"
		last_name  = "Hen"
    }
}

unit "father" {
	source = "../../units/father"
	path   = "father"

	inputs = {
		first_name = "Sir"
		last_name  = "Rooster"
	}
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

Where the `terragrunt.stack.hcl` file can _push_ inputs to the `unit` configuration blocks.

Some feedback on the RFC has suggested that this approach might be more intuitive. To explain why the RFC has taken the approach it has, it's worth considering the following:

1. This is a pattern that users are already familiar with, and are currently using in their `terragrunt.hcl` files.

   Currently, Terragrunt doesn't have a way to have external files define configurations that are applied onto a Unit without some code in the `terragrunt.hcl` file to explicitly pull them in. As a consequence, users are always able to look at a `terragrunt.hcl` file and work out all the configurations that apply to a Unit. Introducing the ability to define configurations in external files would break this pattern, and could result in "spooky action at a distance", where configurations changing in one place have unexpected effects in another.

   With this approach, users can always look at a `terragrunt.hcl` file and know that they're looking at the complete configuration for a Unit (even if the file itself indicates that configurations need to be read elsewhere and merged in).

2. This requires no changes to how `terragrunt.hcl` files work.

   A nice advantage to this approach is also that the internals for how Terragrunt works doesn't need to change from the perspective of `terragrunt.hcl` files. The only thing that needs to change is the introduction of tooling to generate `.terragrunt-stack` directories. This means that users familiar with the syntax used for `terragrunt.hcl` files will be able to use Stacks without needing to learn a new syntax when looking at `terragrunt.hcl` files generated for a Stack.

   This also means that all the techniques and tooling users have developed for managing `terragrunt.hcl` files will continue to work as expected. This should minimize the amount of work required to adopt Stacks.

   In addition, this also means that the `terragrunt.hcl` files are agnostic to whether they're being used in a Stack or not. This allows users to navigate to a directory containing a `terragrunt.hcl` file within a `.terragrunt-stack` directory and simply run `terragrunt` commands as they would if they were not part of a Stack at all.

   This applies both to human users and CI/CD pipelines that have been built by Terragrunt users. Users can adopt Stacks incrementally without any changes to their CI/CD pipelines. All they have to do is manually run `terragrunt stack generate`, then commit the `.terragrunt-stack` directory updates to their repository. From the pespective of the CI/CD pipeline, nothing has changed in how Terragrunt works.

## Feedback Requested

This decision is not final, and feedback is still being collected on the RFC. If you have thoughts on this approach, please share them in the RFC.

## Next Step

The [next walkthrough](../03-recursive-stacks) explores how Stacks can be used to generate Stacks, and how this can be used to manage infrastructure at scale.

