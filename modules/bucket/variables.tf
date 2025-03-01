# -----------------------------------------------------------------------------
# 🟢 Required parameters
# -----------------------------------------------------------------------------

variable "name" {
  description = "The name of the Bucket"
  type        = string
}

variable "project_id" {
  description = "The project ID to create the Bucket"
  type        = string
}

variable "location" {
  description = "The region to store the Bucket files"
  type        = string
}

variable "force_destroy" {
  description = "The deletion protection on terraform destroy, must be true on prod"
  type        = bool
}

variable "versioning" {
  description = "The versioning enabled or not for the Bucket"
  type        = bool
}

variable "autoclass" {
  description = "Storage Autoclass enabled or not for the Bucket"
  type        = bool
}

variable "env" {
  description = "The environment to deploy the Cloud Run job"
  type        = string
}


# -----------------------------------------------------------------------------
# 🟢 Optional parameters
# -----------------------------------------------------------------------------

variable "storage_class" {
  description = "The default storage class of the Bucket"
  type        = string
  default     = "STANDARD"
}

variable "uniform_bucket_level_access" {
  description = "Is ACS activated for the bucket"
  type        = bool 
  default     = true
}