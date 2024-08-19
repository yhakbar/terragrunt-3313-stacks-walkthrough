# 03 - Recursive Stacks

So far, the walkthroughs have only delved into how to use Stacks to manage Units. This chapter will demonstrate how to use Stacks to manage other Stacks.

Take a look at the Stack defined in the [farm](./farm) directory. It's a Stack that manages the `coop-1` Stack, and the `coop-2` Stack:

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
./mock-stack-render.sh
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

Each Stack is initially rendered into the `.terragrunt-stack` directory as a child directory with a `terragrunt.stack.hcl` file, then those Stacks are recursively rendered until all Stacks are rendered.

This provides a mechanism for encapsulation, as you can see that the `coop-1` and `coop-2` Stacks are rendered independently with their own states, but reuse the definition in the [coop](../stacks/coop) Stack.

It also provides a mechanism for atomic updates to Stacks. Given that the entirety of the definition for a stack is stored elsewhere, it's possible to update the entire Stack by changing the value of the `source` attribute in the `terragrunt.stack.hcl` file, rather than editing individual `terragrunt.hcl` files.

