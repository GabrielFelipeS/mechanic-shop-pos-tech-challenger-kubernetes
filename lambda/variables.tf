variable "region" {
  type = string
}

variable "project_name" {
  type    = string
  default = "mechanic-shop"
}

variable "function_name" {
  type = string
}

variable "artifact_bucket" {
  description = "Existing bucket containing the immutable Lambda deployment JAR."
  type        = string
}

variable "artifact_key" {
  description = "Key of the immutable Lambda deployment JAR."
  type        = string
}

variable "artifact_version" {
  description = "Optional version ID of the immutable Lambda deployment JAR."
  type        = string
  default     = null
}

variable "internal_api_base_url" {
  type      = string
  sensitive = true
}

variable "internal_api_secret" {
  type      = string
  sensitive = true
}

variable "jwt_secret" {
  type      = string
  sensitive = true
}

variable "tags" {
  type = map(string)
  default = {
    Project     = "mechanic-shop"
    School      = "FIAP"
    Turma       = "15SOAT"
    Environment = "Production"
  }
}
