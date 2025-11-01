variable "github_token" {
  description = "GitHub Personal Access Token with repo permissions"
  type        = string
  sensitive   = true
}

variable "github_owner" {
  description = "GitHub organization or user name"
  type        = string
}

variable "default_branch" {
  description = "Default branch name for repositories"
  type        = string
  default     = "main"
}

variable "repository_visibility" {
  description = "Default visibility for repositories (public, private, internal)"
  type        = string
  default     = "private"
}
