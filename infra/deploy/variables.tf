variable "prefix" {
  description = "Prefix for resources in AWS"
  default     = "test"
}

variable "tf_state_bucket" {
  description = "Name of S3 bucket in AWS for storing TF state"
  default     = "devops-learn-dev"
}

variable "tf_state_lock_table" {
  description = "Name of DynamoDB table in AWS for TF state locking"
  default     = "devops-learn-dev"
}

variable "project" {
  description = "Project name for tagging resources"
  default     = "recipe-app-api"
}

variable "contact" {
  description = "Contact name for taggin resources"
  default     = "nishantdobariya@outlook.com"
}

variable "db_username" {
  description = "Usename for the database"
  sensitive   = true
}

variable "db_password" {
  description = "Password for the database"
  sensitive   = true
}