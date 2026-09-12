variable "region" { default = "sa-east-1" }
variable "project_name" { default = "mechanic-shop" }
variable "namespace" { default = "mechanic-shop" }
variable "newrelic_app_name" { default = "mechanic-shop" }
variable "cluster_version" { default = "1.34" }
variable "lab_role_name" { default = "LabRole" }
variable "vpc_cidr" { default = "10.0.0.0/16" }
variable "subnet_count" { default = 3 }
variable "instance_type" { default = "t3.medium" }
variable "capacity_type" { default = "ON_DEMAND" }
variable "node_desired_size" { default = 2 }
variable "node_min_size" { default = 2 }
variable "node_max_size" { default = 3 }
variable "node_disk_size" { default = 50 }
variable "imds_hop_limit" { default = 2 }
variable "api_server_allowed_cidr" { default = "0.0.0.0/0" }
variable "nodeport_allowed_cidr" { default = "0.0.0.0/0" }
variable "mailpit_ui_node_port" { default = 30025 }
variable "use_exec_auth" { default = true }
variable "newrelic_license_key" {
  type      = string
  sensitive = true
  default   = ""
}
variable "newrelic_bundle_version" { default = "" }
variable "newrelic_low_data_mode" { default = true }
variable "app_deployer_role_arn" {
  description = "IAM role assumed by the Java application GitHub Actions workflow."
  type        = string
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
