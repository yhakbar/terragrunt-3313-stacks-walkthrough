# 03 - Recursive Stacks

So far, the walkthroughs have only delved into how to use Stacks to manage Units. This chapter will demonstrate how to use Stacks to manage other Stacks.

Take a look at the Stack defined in the [farm](./farm) directory. It's a Stack that manages two Stacks: `coop_1` and `coop-2`.

```hcl
stack "coop_1" {
	source = "../../stacks/coop"
	path   = "coop-1"
}

stack "coop_2" {
	source = "../../stacks/coop"
	path   = "coop-2"
}
```

This is very similar to what was done in the [previous chapter](../02-dynamicity/), but instead of managing Units, it's managing other Stacks, which in turn manage Units.

## Walkthrough

To use this part of the walkthrough, run the following in this directory:

```bash
./mock-stack-generate.sh
terragrunt run-all apply --terragrunt-non-interactive
```

What you should see after running this is the following:

```bash
$ tree -a -L 4 farm/.terragrunt-stack/
farm/.terragrunt-stack/
├── coop-1
│   ├── .terragrunt-stack
│   │   ├── chicks
│   │   │   ├── chick-1
│   │   │   └── chick-2
│   │   ├── father
│   │   │   ├── .terraform.lock.hcl
│   │   │   ├── .terragrunt-cache
│   │   │   └── terragrunt.hcl
│   │   └── mother
│   │       ├── .terraform.lock.hcl
│   │       ├── .terragrunt-cache
│   │       └── terragrunt.hcl
│   ├── father.inputs.hcl
│   ├── mother.inputs.hcl
│   └── terragrunt.stack.hcl
└── coop-2
    ├── .terragrunt-stack
    │   ├── chicks
    │   │   ├── chick-1
    │   │   └── chick-2
    │   ├── father
    │   │   ├── .terraform.lock.hcl
    │   │   ├── .terragrunt-cache
    │   │   └── terragrunt.hcl
    │   └── mother
    │       ├── .terraform.lock.hcl
    │       ├── .terragrunt-cache
    │       └── terragrunt.hcl
    ├── father.inputs.hcl
    ├── mother.inputs.hcl
    └── terragrunt.stack.hcl
```

Each Stack is initially generated into the `.terragrunt-stack` directory as a child directory with a `terragrunt.stack.hcl` file, and those Stacks are recursively generated until all Stacks are generated.

This provides a mechanism for encapsulation, as you can see that the `coop-1` and `coop-2` Stacks are generated independently with their own states, but reuse the definition in the [coop](../stacks/coop) Stack.

It also provides a mechanism for atomic updates to Stacks. Given that the entirety of the definition for a stack is stored elsewhere, it's possible to update the entire Stack by changing the value of the `source` attribute in the `terragrunt.stack.hcl` file, rather than editing individual `terragrunt.hcl` files.

As an excercise, let's adjust the `source` attribute in the `coop_1` and `coop_2` configuration blocks so that they point to the `../../stacks/dynamic-coop` directory, and then re-run the `./mock-stack-generate.sh` command.

Next, take a look at the error that occurs when running the `terragrunt run-all apply --terragrunt-non-interactive` command.

You should see an error that includes the following:

```
Call to function "find_in_parent_folders" failed: ParentFileNotFoundError: Could not find a coops.locals.hcl in any of the parent folders
```

This is one of the downsides to the design discussed in [the last chapter](../02-dynamicity/README.md). Re-usable configurations may have certain expectations regarding how they will be instantiated, and there is no obvious interface for what they expect. One has to read the `terragrunt.hcl` file and reason about what is required to instantiate it.

It's not clear that there's a way to handle this without some kind of interface that can be defined for `terragrunt.hcl` files, which can be inspected to determine the requirements to instantiate them. This may also result in configurations that are unique to `terragrunt.hcl` files that are used in Stacks, which sacrifices some of the advantages of the current design.

To resolve this error, you can copy the file [coops.locals.hcl.todo](./farm/coops.locals.hcl.todo) to `./farm/coops.locals.hcl`:

```bash
mv farm/coops.locals.hcl.todo farm/coops.locals.hcl
```

Once that's done, you can re-run the apply, which should work now:

```bash
terragrunt run-all apply --terragrunt-non-interactive
```

You should now see names for the chickens that align with the values defined in the `coops.locals.hcl` file.

## Feedback Requested

How do you feel about this trade-off? Is there another approach to defining the interface more cleanly that you would like to see?

Do you see the current design as something that you would be able to work with in your own infrastructure, or do you see it as something that would block adoption of Stacks?

How can this walkthrough be extended after this to answer more questions about how Stacks should work in Terragrunt? If you feel like there are interactions that are missing, please let me know. I'm happy to add more to this walkthrough to make it more useful.

