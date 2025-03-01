# -----------------------------------------------------------------------------
# 🟢 Required parameters
# -----------------------------------------------------------------------------

variable "project_id" {
  description = "The project ID to deploy the Cloud Run job"
  type        = string
}

variable "region" {
  description = "The region to deploy the Cloud Run job"
  type        = string
}

variable "job_name" {
  description = "The name of the Cloud Run job"
  type        = string
}

variable "env" {
  description = "The environment to deploy the Cloud Run job"
  type        = string
}


variable "sa_roles" {
  description = "The roles to assign to the Cloud Run service account"
  type        = list(string)
  default     = [
    "roles/cloudsql.client",
    "roles/secretmanager.secretAccessor",
  ]
}

variable "deletion_protection" {
  description = "The deletion protection on terraform destroy, must be true on prod"
  type        = string
}

# -----------------------------------------------------------------------------
# 🟢 Optional parameters
# -----------------------------------------------------------------------------

variable "timeout" {
  description = "The timeout for the Cloud Run job"
  type        = string
  default     = "600s"
}

variable "command" {
  description = "The command to run the Cloud Run job"
  type        = list(string)
  default     = null
}

variable "args" {
  description = "The arguments to run the Cloud Run job"
  type        = list(string)
  default     = null
}

variable "cpu" {
  description = "The CPU limit for the Cloud Run job"
  type        = string
  default     = "2"
}

variable "memory" {
  description = "The memory limit for the Cloud Run job"
  type        = string
  default     = "2Gi"
}

variable "env_vars" {
  description = "The environment variables for the Cloud Run job"
  type        = list(object({
    name  = string
    value = string
  }))
  default     = []
}

variable "secret_env_vars" {
  description = "The secret environment variables for the Cloud Run job"
  type        = list(object({
    name        = string
    secret_name = string
  }))
  default     = []
}