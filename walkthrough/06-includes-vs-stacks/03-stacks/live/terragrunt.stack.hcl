stack "dev" {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/stacks/environment"
  path   = "dev"

  // values = {
  //   environment = "dev"
  // }
}

stack "prod" {
  source = "${dirname(find_in_parent_folders("root.hcl"))}/stacks/environment"
  path   = "prod"

  // values = {
  //   environment = "prod"
  // }
}
