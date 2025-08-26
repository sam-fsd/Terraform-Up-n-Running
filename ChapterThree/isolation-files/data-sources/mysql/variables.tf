# variables that will hold our secrets. Marked with `sensitive = true`
# to prevent accidental exposure via Terraform logs
# To be passed via env variables using TF_VAR_ prefix

variable "db_username" {
  description = "The username for the database"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "The password for the database"
  type        = string
  sensitive   = true
}