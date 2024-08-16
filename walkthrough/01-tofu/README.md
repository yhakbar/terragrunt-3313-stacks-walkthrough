# 01 - OpenTofu

If you're reading this, you probably already know what OpenTofu is and why it's useful.

In a nutshell, it lets you represent the infrastructure you want in files that end with `.tf` (and [`.tofu`](https://github.com/opentofu/opentofu/releases/tag/v1.8.0-rc1)). You can use the `tofu` CLI to make changes to your infrastructure driven by these files so that you go from one infrastructure state to another.

## Walkthrough

To use this part of the walkthrough, run the following in this directory:

```bash
tofu apply
```

You'll see a plan of what will be done, and then you can confirm that you want to apply the changes.

Implicitly, what you're seeing is that there's an initial null state where no infrastructure is provisioned, then some work done by `tofu` to drive infrastructure to a desired state, and then the final state where the infrastructure is provisioned.

This is the basic idea behind Infrastructure as Code (IaC).

## Limitations

This is a very basic example, and it's not very useful in practice. It's just to show the basic idea of how OpenTofu works.

The core issues that folks run into when trying to scale up infrastructure only using OpenTofu are:

1. Operations are generally all or nothing.

   The ability to do partial updates is limited, and you generally have to make a change that impacts all of state to make a change to infrastructure.

   This results in a large blast radius for changes, and can make it difficult to safely make changes to infrastructure without downtime.

2. The ability to execute side-effects is limited.

   OpenTofu is great for managing updates to infrastructure state, but it's not great for managing the side-effects of infrastructure changes.

   For example, if you want to build 

