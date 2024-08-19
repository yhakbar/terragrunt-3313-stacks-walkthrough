# 04 - Stacks

Currently, Stacks are a piece of Terragrunt tooling that is in the proposal phase ([#3313](https://github.com/gruntwork-io/terragrunt/issues/3313)).

The exact details of how they will be implemented is still being discussed. As such, this chapter will be updated as the proposal is finalized. The availability of the `stack` subcommand has been mocked out for demonstration purposes.

The goal of Stacks is to provide a way to mitigate the limitations dicsussed in the [previous chapter](../03-includes-dependencies), while retaining the advantages gained by Terragrunt users scaling their IaC.

A lot more detail is discussed in the RFC, so this chapter will serve to give some examples of what Stacks look like in practice, and how they are used.

## Walkthrough

This part of the walkthrough is broken down into multiple parts, as it is introducing a lot more than previous chapters.

The contents of the [units](./units) and [stacks](./stacks) directories are used throughout the chapters in this walkthrough.

To get started, navigate to [01-basic](./01-basic).

