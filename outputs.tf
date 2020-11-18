output "application_repo" {
  value = github_repository.application.full_name
}

output "application_workspace" {
  value = tfe_workspace.application.name
}

output "baseline_repo" {
  value = github_repository.baseline.full_name
}

output "baseline_workspace" {
  value = tfe_workspace.baseline.name
}
