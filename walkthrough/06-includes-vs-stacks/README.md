# 06 - Includes vs Stacks

Before the introduction of the `terragrunt.stack.hcl` file, the best way to achieve Don't Repeat Yourself (DRY) configuration in Terragrunt was to use the `include` block. This block allowed you to include the contents of another Terragrunt configuration file into the current one. This was useful for sharing common configurations across multiple Terragrunt configurations.

However, the `include` block has some limitations. Mainly, you can only include configurations stored on your local filesystem, and including configurations can tightly couple your Terragrunt configurations. This can make it difficult to incrementally adjust Terragrunt configurations.

This walkthrough goes through some sample Terragrunt configuration, explores how users would use the `include` block to DRY up the configuration, then introduces the `terragrunt.stack.hcl` file and how it can be used to achieve the same goal, but with more flexibility.
