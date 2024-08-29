# 03 - No `_shared`

The only real adjustment from the previous chapter is the removal of the `_shared` directory. 

This is to demonstrate that the `terragrunt.hcl` files no longer need to `include` those shared configurations, as the entire `terragrunt.hcl` file can be re-used across Stacks.

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

I wouldn't bother going through a walkthrough in this chapter. It's the same as the previous one, but with the `_shared` directory removed.

If you'd like, compare these files to see what was removed in the `_shared` directory:

- [units/api/terragrunt.hcl](./units/api/terragrunt.hcl)
- [../02-stacks/units/api/terragrunt.hcl](../02-stacks/units/api/terragrunt.hcl)
- [../02-stacks/_shared/api.hcl](../02-stacks/_shared/api.hcl)

## Next Steps

The [next chapter](../04-reusing-stacks) will demonstrate how Stacks are not just used for reusing Unit configurations, but can also be used to define reused _Stack_ configurations.

