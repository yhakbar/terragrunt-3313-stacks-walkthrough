# 02 - Dynamicity

In the previous chapter, a fairly simple approach to rendering a Stack was taken: All the Units were rendered with no configurability aside from the name of the directory they were rendered into.

When introducing an abstraction like this, users may find it desireable to be able to have a set of inputs to the Stack that can be used to set different values for Units within that Stack.

The proposal in [#3313](https://github.com/gruntwork-io/terragrunt/issues/3313) takes a fairly conservative (and pretty controversial so far) approach to avoid introducing functionality like this.

Instead, it expects users to write Terragrunt configurations using functions and patterns that are in common usage today to derive that same functionality.

In this walkthrough, a hypothetical user wants to be able to render a `coop-1` stack, but wants to be able to do so using a configurable name for the `chicken` Units that serve as `mother` and `father`.

This simulates a more useful piece of functionality like naming a service, defining a VPC CIDR block, etc.


