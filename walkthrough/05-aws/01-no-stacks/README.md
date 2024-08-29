# 01 - No Stacks

To set a baseline, this walkthrough will set up a Stack without the use of any `terragrunt.stack.hcl` files.

This will motivate the need for `terragrunt.stack.hcl` files in the next walkthrough.

## Architecture

```bash
$ tree
.
├── README.md
├── _shared
│   ├── api.hcl
│   └── db.hcl
├── live
│   ├── dev
│   │   ├── environment.hcl
│   │   ├── services
│   │   │   └── api
│   │   │       └── terragrunt.hcl
│   │   └── storage
│   │       └── db
│   │           └── terragrunt.hcl
│   └── prod
│       ├── environment.hcl
│       ├── services
│       │   └── api
│       │       └── terragrunt.hcl
│       └── storage
│           └── db
│               └── terragrunt.hcl
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
└── terragrunt.hcl
```

The resources that are going to be provisioned as part of this walkthrough are fairly simple:

1. A DynamoDB table that will store a count.
2. A Lambda function that will accept `GET` and `POST` requests to read and increment a count in the DynamoDB table.

The two will be provisioned with their own OpenTofu state, and will integrate with each other via a `dependency` block on the `api` Unit.

Furthermore, the "Stack" of resources will be replicated across two environments: `dev` and `prod`.

To reduce repetition, the OpenTofu modules the Units will use have been abstracted into the `modules` directory, and the shared configuration for the Units has been abstracted into the `_shared` directory.

In addition, some helper scripts have been added in a `scripts` directory to package the source code in `src` for the Lambda function, and a `id.sh` script to generate a unique ID for the project.

The `id.sh` script is useful for this example, as it will generate a unique ID that can be used to ensure that the resources created in the walkthrough are globally unique.

This was added so that anyone following along with this walkthrough can run the code without having to worry about naming conflicts from S3 buckets provisioned by others.

### Note on Configuration Lifecycles

Many IaC authors starting out writing IaC see fully formed configurations like this and can get intimidated by the amount of configuration they are looking at.

It's important to remember that most IaC configurations are authored incrementally, and that the configuration lifecycle is iterative.

When writing up this walkthrough, I did so in the following order:

1. I created the `live/dev/services/api/terragrunt.hcl` file and created a `live/dev/services/api/main.tf` file with the minimal configuration to create a Lambda function.

   I also added the `src/index.mjs` file to the root of the project to serve as the source code for the Lambda function, and the `scripts/package.sh` script to package the source code.
   
   This allowed me to rapidly iterate on the Lambda function configuration and test it in isolation with plans and applies.

2. I then refactored out the OpenTofu configuration into the `modules/api` directory, and updated the `live/dev/services/api/terragrunt.hcl` file to reference it.

   Now, there's a clear separation between the pattern of infrastructure that's going to be instantiated multiple times, and the actual instantiation of that pattern as a Unit.

3. I repeated the process for the DynamoDB table, resulting in the `live/dev/storage/db/terragrunt.hcl` file and the `modules/db` directory.

   At this stage, I also wired up the `api` Unit to depend on the `db` Unit, and tested the configuration to ensure that the dependency was working as expected.

4. Next, I copied the `live/dev` directory to `live/prod`, and updated the `live/prod/environment.hcl` file to reflect the fact that this is a production environment.

5. Looking at the two environments, I refactored out the shared configurations into the `_shared` directory, and updated the relevant `terragrunt.hcl` files to reference them.

6. Finally, I setup the `terragrunt.hcl` file at the root of this walkthrough so that the contents in the `live` directory could be stored in a central state backend, using an S3 bucket.

This is a common pattern when writing IaC configurations. Start with adding a small piece of the infrastructure, and iterate on it until it's correct. Then, refactor out the common patterns into modules and shared configurations, then repeat the process.

The next walkthrough extends this pattern one step further by introducing a `terragrunt.stack.hcl` file to further abstract the configuration.

## Walkthrough

> :warning:
>
> This walkthrough applies real resources in AWS, including IAM roles and policies. Never blindly run code from the internet.
>
> Make sure you understand what the code does before running it.

Assuming your shell is currently authenticated with an AWS account, and you have the necessary permissions to create the resources in this walkthrough, you can follow along with the steps below.

```bash
$ cd live
$ terragrunt run-all apply --terragrunt-non-interactive
```

You can play with the provisioned infrastructure by sending `GET` and `POST` requests to the API URL:

```bash
$ cd live/dev/services/api
$ url="$(terragrunt output -raw url)"
$ curl -s "$url" | jq
{
  "Count": 0
}
$ curl -s -X POST "$url" | jq
{
  "Count": 1
}
```

As you can see, the API is working as expected, and the count is being incremented with each `POST` request.

You can also check that the prod environment is provisioned separately, and that the state is isolated between the two environments:

```bash
$ cd live/prod/services/api
$ url="$(terragrunt output -raw url)"
$ curl -s "$url" | jq
{
  "Count": 0
}
$ curl -s -X POST "$url" | jq
{
  "Count": 1
}
```

In addition to each of the environments being isolated from each other in terms of the DBs they use, the actual backend state for the resources are also isolated from each other.

Note that the resources were also provisioned following an order dictated by the Directed Acyclic Graph (DAG) of the dependencies between the Units:

```bash
$ terragrunt run-all apply --terragrunt-non-interactive
Group 1
- Module live/dev/storage/db
- Module live/prod/storage/db

Group 2
- Module live/dev/services/api
- Module live/prod/services/api
```

Terragrunt is able to determine the order in which Units should be applied based on the dependencies between them, and will apply them in the correct order.

## Cleanup

Clean up the resources created in this walkthrough by running the following command:

```bash
terragrunt run-all destroy --terragrunt-non-interactive
```

Note that reverse order of the DAG. The `api` Unit depends on the `db` Unit, so the `api` Unit is destroyed first.

## Next Steps

In the [next chapter](../02-stacks), we'll introduce `terragrunt.stack.hcl` files to further abstract the configuration of the Units in the `live` directory.

