# 02 - Terragrunt

Terragrunt provides a level of abstraction over OpenTofu/Terraform that takes advantages of their strengths, while providing capabilities that scales what you can accomplish with them.

At it's core, Terragrunt is an orchestrator. It leverages tools like OpenTofu to handle the underlying execution of infrastructure updates via Infrastructure as Code, but provides additional tooling so that organizations can feasibly define _all_ their infrastructure as code in a safe and efficient manner.

To handle this, the core construct of Terragrunt introduces is the Unit. This is an entity defined using a `terragrunt.hcl` file, and controls one atomic piece of infrastructure using an OpenTofu/Terraform module.

While it can be used with `*.tf` files directly placed next to the `terragrunt.hcl` file on the filesystem, it is typically used in conjunction with modules that are reusable, and stored elsewhere (either in a different directory in the case of a monorepo, or in different repository(ies) in a polyrepo context). This allows multiple Units to take advantage of the same pattern defined using an OpenTofu module to efficiently reproduce the same infrastructure.

## Walkthrough

In this example, the two Units defined here are:

1. `chicken-1`
2. `chicken-2`

Both of these Units use the same underlying module discussed in the [first walkthrough](../01-tofu), but they instantiate it separately.

This allows state to be segmented between the two Units so that they can be updated independently, and procedural logic can be executed around their updates.

In addition to allowing the two Units to be updated independently, updates to multiple Units can be coordinated simultaneously using the Terragrunt `run-all` command:

```bash
terragrunt run-all apply --terragrunt-non-interactive
```

Terragrunt provides the buffer that allows these patterns to be developed in isolation from how they are instantiated.

This concept is critical, as each Unit, defined entirely within a single `terragrunt.hcl` file defines everything required for one atomic piece of infrastructure with its own state.

## Limitations

It can be frustrating to define all that's required for a given Unit in a single file. There are often patterns that arise in how the same infrastructure is provisioned across environments that require more reuse.

Terragrunt has some tooling that assists with this, but this can come with its own problems. This is discussed in the [next chapter](../03-includes-dependencies).

