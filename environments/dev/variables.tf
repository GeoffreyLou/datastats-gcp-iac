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

variable "scheduler_region" {
  description = "The region used for the Cloud Scheduler"
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

variable "run_job_urls_scrapper_name" {
  description = "The name of the Cloud Run Job Urls Scrapper"
  type        = string
}

variable "url_to_scrap" {
  description = "The url that will be used for Urls Scrapper Cloud Run Job"
  type        = string  
}

variable "utils_bucket_name" {
  description = "The name of the Bucket used for utils files"
  type        = string
}

variable "urls_bucket_name" {
  description = "The name of the Bucket used to store urls files"
  type        = string
}

variable "serverless_connector_name" {
  description = "The name of the VPC Access Connector for Serverless"
  type        = string
}

variable "urls_scrapper_workflow_name" {
  description = "The name of the Cloud Workflows for Urls Scrapper"
  type        = string
  
}

variable "router_name" {
  description = "The name of the Cloud Router"
  type        = string
  
}

variable "nat_name" {
  description = "The name of the Cloud NAT"
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

variable "workload_identity_provider_sa_roles" {
  description = "The roles to assign to the Service Account"
  type        = list(string)
}

# -----------------------------------------------------------------------------
# 🟢 Optional parameters
# -----------------------------------------------------------------------------

variable "apis_to_enable" {
  description = "The complete APIs list to enable in the project"
  type        = list(string)
  default     = [
    "compute.googleapis.com",
    "secretmanager.googleapis.com",
    "servicenetworking.googleapis.com",
    "sqladmin.googleapis.com",
    "vpcaccess.googleapis.com",
    "workflows.googleapis.com",
    "cloudbuild.googleapis.com",
    "iam.googleapis.com"
  ]
}

variable "urls_scrapper_workflow_schedules" {
  description = "The list of schedules for the Urls Scrapper Workflow Cloud Scheduler"
  type        = map(string)
  default     = {
    "urls_scrapper_workflow_scheduler_1" = "0 10 * * *",
    "urls_scrapper_workflow_scheduler_2" = "0 14 * * *" , 
    "urls_scrapper_workflow_scheduler_3" = "0 18 * * *" ,
    "urls_scrapper_workflow_scheduler_4" = "0 22 * * *"
  }
}