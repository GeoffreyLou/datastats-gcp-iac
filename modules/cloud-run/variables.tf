# -----------------------------------------------------------------------------
# 🟢 Required parameters
# -----------------------------------------------------------------------------

variable "project_id" {
  description = "The project ID to deploy the Cloud Run Job"
  type        = string
}

variable "region" {
  description = "The region to deploy the Cloud Run Job"
  type        = string
}

variable "job_name" {
  description = "The name of the Cloud Run Job"
  type        = string
}

variable "env" {
  description = "The environment to deploy the Cloud Run Job"
  type        = string
}

variable "deletion_protection" {
  description = "The deletion protection on terraform destroy, must be true on prod"
  type        = string
}

# -----------------------------------------------------------------------------
# 🟢 Optional parameters
# -----------------------------------------------------------------------------

variable "timeout" {
  description = "The timeout for the Cloud Run Job"
  type        = string
  default     = "600s"
}

variable "max_retries" {
  description = "The number of retries if the Cloud Run Job fails"
  type        = string
  default     = "0"
}

variable "command" {
  description = "The command to run the Cloud Run Job"
  type        = list(string)
  default     = null
}

variable "args" {
  description = "The arguments to run the Cloud Run Job"
  type        = list(string)
  default     = null
}

variable "cpu" {
  description = "The CPU limit for the Cloud Run Job"
  type        = string
  default     = "2"
}

variable "memory" {
  description = "The memory limit for the Cloud Run Job"
  type        = string
  default     = "2Gi"
}

variable "env_vars" {
  description = "The environment variables for the Cloud Run Job"
  type        = list(object({
    name  = string
    value = string
  }))
  default     = []
}

variable "secret_env_vars" {
  description = "The secret environment variables for the Cloud Run Job"
  type        = list(object({
    name        = string
    secret_name = string
  }))
  default     = []
}

variable "connector_id" {
  description = "The serverless connector identifier used on the Cloud Run Job"
  type        = string 
  default     = null
}

variable "cloud_sql_instance_connection_name" {
  description = "The connection name of the Cloud SQL linked to the Cloud Run Job"
  type        = list(string)
  default     = []
}

variable "sa_roles" {
  description = "The roles to assign to the Cloud Run service account"
  type        = list(string)
  default     = [
    "roles/cloudsql.client",
    "roles/secretmanager.secretAccessor",
  ]
}

variable "network_name" {
  description = "value of the network name attached to the Cloud Run Job"
  type        = string
  default     = null
}

variable "subnetwork_name" {
  description = "value of the subnetwork name attached to the Cloud Run Job"
  type        = string
  default     = null
}

variable "egress" {
  description = "The egress setting for the VPC access connector"
  type        = string
  default     = null

  validation {
    condition     = var.egress == null || var.egress == "ALL_TRAFFIC" || var.egress == "PRIVATE_RANGES_ONLY"
    error_message = "egress must be one of 'ALL_TRAFFIC', 'PRIVATE_RANGES_ONLY' or null"
  }
}

variable "vpc_access_tags" {
  description = "Optional network tags for resources connected to the VPC"
  type        = list(string)
  default     = null
}