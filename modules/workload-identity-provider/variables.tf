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

variable "pool_name" {
  description = "The name of Workload Identity Pool"
  type        = string
}

variable "pool_description" {
  description = "The description of Workload Identity Pool"
  type        = string
}

variable "provider_name" {
  description = "The name of Workload Identity Pool Provider"
  type        = string
}

variable "provider_description" {
  description = "The description of Workload Identity Pool Provider"
  type        = string
}

variable "assertion_condition" {
  description = "The assertion condition in Workload Identity Provider"
  type        = string
}

variable "assertion_value" {
  description = "The assertion value in Workload Identity Provider"
  type        = string
}

variable "attribute_condition" {
  description = "The attribute condition in Workload Identity Provider"
  type        = string
}

variable "workload_identity_provider_issuer" {
  description = "The issuer URI of the Workload Identity Provider"
  type        = string
}

variable "service_account_roles" {
  description = "The roles to assign to the Service Account"
  type        = list(string)
}