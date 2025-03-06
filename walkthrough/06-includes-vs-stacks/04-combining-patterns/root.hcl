locals {
  project_name = "stacks-walkthrough-combined"
  region       = "us-east-1"
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }
  config = {
    // Make sure you update this to a globally unique bucket name!
    bucket         = "${local.project_name}-2025-03-03-tfstate"
    key            = "${path_relative_to_include()}/tofu.tfstate"
    region         = local.region
    encrypt        = true
    dynamodb_table = "tfstate-lock"
  }
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
