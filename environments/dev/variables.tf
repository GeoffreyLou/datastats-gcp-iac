# -----------------------------------------------------------------------------
# 🟢 Required parameters
# -----------------------------------------------------------------------------

variable "env" {
  description = "The environment to deploy resources"
  type        = string 
}

variable "project_id" {
  description = "The unique identifier of the project to deploy resources"
  type        = string
}

variable "region" {
  description = "The default region used for resources"
  type        = string
}

variable "project_name" {
  description = "The name of the project for resource naming purpose"
  type        = string
}

variable "cloud_sql_version" {
  description = "The type and version of the Cloud SQL"
  type        = string
}

# -----------------------------------------------------------------------------
# 🟢 Optional parameters
# -----------------------------------------------------------------------------

variable "apis_to_enable" {
  description = "The complete APIs list to enable in the project"
  type        = list(string)
  default     = [
    "iam.googleapis.com",
    "artifactregistry.googleapis.com",
    "run.googleapis.com",
    "compute.googleapis.com",
    "secretmanager.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com",
    "vpcaccess.googleapis.com"
  ]
}