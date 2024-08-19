# 03 - Includes & Dependencies

To provide tooling to increase the reusability and integration of Terragrunt configurations, Terragrunt has a configuration blocks called `include` and `dependency`.

These allows users to share configurations across multiple Units and pass data from one Unit to another.

## Common Patterns

At this time, it's also useful to discuss common patterns that have organically arrisen in how users write their Terragrunt configurations. Users aren't required to write their configurations this way, but it's usually a good idea to. It serves to address the majority of use-cases involved with managing infrastructure at scale.

Most Terragrunt users follow a pattern like the following:

```bash
tree
.
├── README.md
├── _shared
│   ├── chick.hcl
│   └── chicken.hcl
├── coop-1
│   ├── children
│   │   ├── chick-1
│   │   │   └── terragrunt.hcl
│   │   └── chick-2
│   │       └── terragrunt.hcl
│   ├── father
│   │   └── terragrunt.hcl
│   └── mother
│       └── terragrunt.hcl
└── terragrunt.hcl
```

Where the `terragrunt.hcl` file at the root of a directory has the configurations common to _all_ Units, a directory to the side (named `_shared` here) containing configurations relevant to some subset of Units, and then trees of Units that have some relationship to each other.

This organizational pattern is especially useful in the context of IaC, as this provides a convenient mechanism for resolving common problems like determining where to store state. What most users do is use the path from the root `terragrunt.hcl` as the path for where remote state is stored in a state backend like S3. As a consequence, if you want to provision new infrastructure, or work on a piece of infrastructure in a particular piece of segmented state, all you have to do is navigate to the relevant directory in the filesystem and use the `terragrunt` CLI there.

Similarly, if Units need to acquire data from other Units, they can use `dependency` blocks to have Terragrunt handle message passing between Units. Each `terragrunt.hcl` file explicitly indicates where it expects to pull data from, and what data it expects to pull. They can also use `include` blocks to explicitly indicate that they are going to merge in configurations defiend elsewhere.

## Walkthrough

To take a look at this in action, run the following:

```bash
terragrunt run-all apply --terragrunt-non-interactive
```

Note that the Units in the `children` directory are applied after the Units they depend on (`mother` and `father`), and that they are all able to use the shared reference to configurations in `_shared` to reduce repetition.

These two qualities come about through usage of `dependency` and `include`, repectively.

Also note that the position of the Unit within the filesystem imparts special meaning to the Unit. Navigating to the `mother` Unit, and running the following:

```bash
$ cd coop-1/mother
$ terragrunt show
# data.external.chicken:
data "external" "chicken" {
    id      = "-"
    program = [
        "cat",
        "-",
    ]
    query   = {
        "father"     = null
        "first_name" = "Mrs."
        "last_name"  = "Chicken"
        "lineage"    = "coop-1/mother"
        "mother"     = null
    }
    result  = {
        "first_name" = "Mrs."
        "last_name"  = "Chicken"
        "lineage"    = "coop-1/mother"
    }
}


Outputs:

first_name = "Mrs."
last_name = "Chicken"
```

Shows how the `lineage` attribute is set to the path of the Unit in the filesystem. This is a common pattern that users use to determine where to store state for the Unit.

```bash
$ cd ../chicks/chick-1
$ terragrunt show
# data.external.chicken:
data "external" "chicken" {
    id      = "-"
    program = [
        "cat",
        "-",
    ]
    query   = {
        "father"     = "Mr. Chicken"
        "first_name" = "Junior"
        "last_name"  = "Chicken"
        "lineage"    = "coop-1/chicks/chick-1"
        "mother"     = "Mrs. Chicken"
    }
    result  = {
        "father"     = "Mr. Chicken"
        "first_name" = "Junior"
        "last_name"  = "Chicken"
        "lineage"    = "coop-1/chicks/chick-1"
        "mother"     = "Mrs. Chicken"
    }
}


Outputs:

first_name = "Junior"
last_name = "Chicken"
```

Shows a different `lineage`, which when used for state storage, means that the state for `chick-1` is stored in a different location than the state for `mother`.

One of the advantages of organizing code this way is that users are able to simply reproduce sets of infrastructure by duplicating the directory of Units.

e.g.

Copying the `coop-1` directory to a new `coop-2` results in all the infrastructure in `coop-1` being replicated in `coop-2` while ensuring that the Units in `coop-2` have their own state.

```bash
cp -R coop-1 coop-2
```

This is replicating a "Stack" of infrastructure in Terragrunt.

## Limitations

Although most of the configuration for these units is stored in the `_shared` directory, this approach does result in some duplication of content.

Taking a look at the [chick-1 Unit](./coop-1/chicks/chick-1/terragrunt.hcl), we see content that necessarily has to be replicated among all Units sharing that configuration:

```hcl
include "root" {
	path = find_in_parent_folders("terragrunt.hcl")
}

include "chicken" {
	path = "${dirname(find_in_parent_folders("terragrunt.hcl"))}/_shared/chicken.hcl"
}

include "chick" {
	path = "${dirname(find_in_parent_folders("terragrunt.hcl"))}/_shared/chick.hcl"
}

inputs = {
	first_name = "Junior"
}
```

This can be problematic at scale, as it can be difficult to manage updates in this situation.

e.g. Say you had to update the [chick.hcl](./_shared/chick.hcl) file. You would also have to trigger an update in every Unit that references that configuration. You would also have to decide _how_ you wanted to trigger that update without anything changing in IaC. As soon as the `chick.hcl` file is updated, the next update to every Unit referencing it would result in a corresponding change.

In addition, any change to the structure of the Stack can be difficult to manage. If you wanted to add, remove or rename a Unit within the Stack, you would have to find every instance of the Stack and manually update it. This includes changes to how Units depend on each other if their inputs or outputs change.

As users have reached the point where these limitations have become apparent, they've asked for tooling to help mitigate these limitations.

This is where [Stacks](../04-stacks) come in.

