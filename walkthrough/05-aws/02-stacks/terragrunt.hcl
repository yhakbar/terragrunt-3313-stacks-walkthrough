locals {
  parent_dir = get_parent_terragrunt_dir()
  id_file    = "${local.parent_dir}/id.txt"
  id_script  = "${local.parent_dir}/scripts/id.sh"

  // This value is being generated here to ensure a random
  // value is generated for each user going through this walkthrough.
  // 
  // S3 bucket names must be globally unique, so we need to ensure
  // that the bucket name we generate is unique to the user.
  //
  // It's also a useful way to ensure a lack of collisions for
  // any resources already provisioned by users of this walkthrough.
  //
  //
  // In a real-world scenario, you would likely want to use a more
  // descriptive name for your bucket that is based on the environment
  // and region you are deploying to.
  // Something like "my-org-prod-us-west-2" would be a good example.
  random_id = run_cmd("--terragrunt-quiet", local.id_script, local.id_file)

  project_name = "stacks-walkthrough-05-02"
  region       = "us-east-1"
}

generate "provider" {
	path = "provider.tf"
	if_exists = "overwrite_terragrunt"
	contents = <<EOF
provider "aws" {
  region = "${local.region}"
}
EOF
}

remote_state {
  backend = "s3"
  config = {
    bucket                    = "${local.project_name}-${local.random_id}"
    key                       = "${path_relative_to_include()}/tofu.tfstate"
    region                    = local.region
    encrypt                   = true
    dynamodb_table            = "tf-locks-${local.random_id}"
    accesslogging_bucket_name = "${local.project_name}-${local.random_id}-logs"
  }
  generate = {
    path = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

terraform {
  extra_arguments "retry_lock" {
    commands = get_terraform_commands_that_need_locking()
    arguments = ["-lock-timeout=5m"]
  }
}

