provider "github" {
  token = var.github_token
}

resource "github_repository" "baseline" {
  name        = "${var.name}-account-baseline"
  description = "account baseline"

  template {
    owner      = var.github_org
    repository = "terraform-aws-account-baseline"
  }
}

resource "github_repository" "application" {
  name        = "${var.name}-resources"
  description = "My awesome codebase"

  template {
    owner      = var.github_org
    repository = "blank-terraform-repo"
  }
}

provider "tfe" {
  token   = var.tfc_token
  version = "~> 0.15.0"
}

resource "tfe_workspace" "baseline" {
  name         = github_repository.baseline.name
  organization = var.tfc_org
  auto_apply   = true

  vcs_repo {
    identifier     = github_repository.baseline.full_name
    oauth_token_id = var.oauth_token_id
  }
}

resource "tfe_workspace" "application" {
  name         = github_repository.application.name
  organization = var.tfc_org

  vcs_repo {
    identifier     = github_repository.application.full_name
    oauth_token_id = var.oauth_token_id
  }
}

# set both workspaces to agent (tfe provider needs update https://github.com/hashicorp/terraform-provider-tfe/pull/242)
resource "null_resource" "agent" {
  provisioner "local-exec" {
    command = "./files/change_ws_exec_mode.sh ${var.tfc_org} aws-se_demos_dev ${tfe_workspace.baseline.name} ${tfe_workspace.application.name}"

    environment = {
      TOKEN = var.tfc_token
    }
  }

  depends_on = [
    tfe_workspace.baseline,
    tfe_workspace.application,
  ]
}

# required variables for account baseline
resource "tfe_variable" "account_name" {
  key          = "account_name"
  value        = var.name
  category     = "terraform"
  workspace_id = tfe_workspace.baseline.id
  description  = "The name for the account"
}

resource "tfe_variable" "environment" {
  key          = "environment"
  value        = var.environment
  category     = "terraform"
  workspace_id = tfe_workspace.baseline.id
  description  = "Account sub-type stg vs qa vs test..etc"
}

resource "tfe_variable" "int_environment" {
  key          = "int_environment"
  value        = var.int_environment
  category     = "terraform"
  workspace_id = tfe_workspace.baseline.id
  description  = "Application account type prod vs non-prod"
}

# required variables for application workspace
resource "tfe_variable" "role_arn" {
  key          = "role_arn"
  value        = data.terraform_remote_state.baseline.outputs.developer_role
  category     = "terraform"
  workspace_id = tfe_workspace.application.id
  description  = "The AWS IAM role to assume"
}

data "terraform_remote_state" "baseline" {
  backend = "remote"

  config = {
    organization = var.tfc_org
    workspaces = {
      name = tfe_workspace.baseline.name
    }
  }

  depends_on = [
    tfe_workspace.baseline,
  ]
}

