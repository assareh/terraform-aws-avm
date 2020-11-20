provider "github" {
  token = var.github_token
}

resource "github_repository" "baseline" {
  name        = "${var.name}-account-baseline"
  description = "Account baseline"

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
  version = "~> 0.23.0"
}

data "tfe_agent_pool" "aws" {
  name         = var.tfc_agent_pool
  organization = var.tfc_org
}

resource "tfe_workspace" "baseline" {
  name           = github_repository.baseline.name
  organization   = var.tfc_org
  execution_mode = "agent"
  agent_pool_id  = data.tfe_agent_pool.aws.id
  auto_apply     = true

  vcs_repo {
    identifier     = github_repository.baseline.full_name
    oauth_token_id = var.oauth_token_id
  }
}

resource "tfe_workspace" "application" {
  name           = github_repository.application.name
  organization   = var.tfc_org
  execution_mode = "agent"
  agent_pool_id  = data.tfe_agent_pool.aws.id

  vcs_repo {
    identifier     = github_repository.application.full_name
    oauth_token_id = var.oauth_token_id
  }
}

# required variables for account baseline
resource "tfe_variable" "account_name" {
  key          = "account_name"
  value        = var.name
  category     = "terraform"
  workspace_id = tfe_workspace.baseline.id
  description  = "The name for the account"
}

resource "tfe_variable" "tfc_org" {
  key          = "tfc_org"
  value        = var.tfc_org
  category     = "terraform"
  workspace_id = tfe_workspace.baseline.id
  description  = "The terraform organization name"
}

resource "tfe_variable" "tfc_token" {
  key          = "TFE_TOKEN"
  value        = var.tfc_token
  category     = "env"
  workspace_id = tfe_workspace.baseline.id
  description  = "The terraform organization name"
  sensitive    = true
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

# manually trigger a run in cases where the first run is before variables are set
resource "null_resource" "run" {
  provisioner "local-exec" {
    command = "${path.module}/files/manual_run.sh ${var.tfc_org} ${tfe_workspace.baseline.name}"

    environment = {
      TOKEN = var.tfc_token
    }
  }

  depends_on = [
    tfe_variable.account_name,
    tfe_variable.tfc_org,
    tfe_variable.tfc_token,
    tfe_variable.environment,
    tfe_variable.int_environment,
  ]
}

# add notifications to workspaces for tfc-agent scaling
