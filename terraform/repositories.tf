# Example repository configurations
# Uncomment and customize as needed

# resource "github_repository" "example_app" {
#   name        = "example-app"
#   description = "Example application repository"
#   visibility  = var.repository_visibility
#
#   has_issues      = true
#   has_projects    = false
#   has_wiki        = false
#   has_discussions = false
#   has_downloads   = false
#
#   auto_init          = true
#   gitignore_template = "Node"
#   license_template   = "mit"
#
#   allow_merge_commit     = true
#   allow_squash_merge     = true
#   allow_rebase_merge     = true
#   delete_branch_on_merge = true
#
#   vulnerability_alerts = true
#
#   topics = ["automation", "terraform"]
# }

# resource "github_branch_default" "example_app_default" {
#   repository = github_repository.example_app.name
#   branch     = var.default_branch
# }

# resource "github_branch_protection" "example_app_main" {
#   repository_id = github_repository.example_app.node_id
#   pattern       = var.default_branch
#
#   required_pull_request_reviews {
#     required_approving_review_count = 1
#     dismiss_stale_reviews           = true
#   }
#
#   enforce_admins = false
# }

# Example: Repository with secrets
# resource "github_actions_secret" "example_secret" {
#   repository      = github_repository.example_app.name
#   secret_name     = "EXAMPLE_SECRET"
#   plaintext_value = var.example_secret_value
# }
