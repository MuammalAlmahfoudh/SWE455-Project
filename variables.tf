variable "aws_region" {
  description = "AWS region where resources will be created."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix for AWS resources."
  type        = string
  default     = "volleyball-api"
}

variable "allowed_app_cidr_blocks" {
  description = "CIDR blocks allowed to access the API on port 3000."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ec2_instance_type" {
  description = "EC2 instance type for the Node.js Docker host."
  type        = string
  default     = "t3.micro"
}

variable "ec2_key_name" {
  description = "Name of an existing AWS EC2 key pair in the selected region."
  type        = string
}

variable "container_image" {
  description = "Public Docker Hub image for the volleyball API."
  type        = string
  default     = "docker.io/your-dockerhub-username/volleyball-api:latest"
}

variable "db_instance_class" {
  description = "RDS PostgreSQL instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "PostgreSQL database name."
  type        = string
  default     = "volleyball_analytics"
}

variable "db_username" {
  description = "PostgreSQL username."
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "PostgreSQL password. Pass with TF_VAR_db_password or a secret; do not commit it."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.db_password) >= 12 && var.db_password != "password"
    error_message = "db_password must be at least 12 characters and cannot be the default placeholder."
  }
}
