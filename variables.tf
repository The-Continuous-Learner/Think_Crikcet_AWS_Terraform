variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "ap-south-1"
}

variable "project_name" {
  description = "Used to prefix/tag all resources"
  type        = string
  default     = "think-cricket"
}

variable "environment" {
  description = "Deployment environment (prod, staging)"
  type        = string
  default     = "prod"
}

# ── Networking ────────────────────────────────────────────────────────────────

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "AZ for the public subnet (must be in aws_region)"
  type        = string
  default     = "ap-south-1a"
}

# ── EC2 ───────────────────────────────────────────────────────────────────────

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "app_port" {
  description = "Port the Spring Boot app listens on"
  type        = number
  default     = 8080
}

# ── Artifact (Spring Boot jar) ────────────────────────────────────────────────

variable "jar_s3_bucket" {
  description = "S3 bucket that holds the built Spring Boot jar"
  type        = string
  # Set in terraform.tfvars — not committed to git
}

variable "jar_s3_key" {
  description = "S3 object key for the Spring Boot jar (e.g. think-cricket/app.jar)"
  type        = string
  default     = "think-cricket/app.jar"
}

# ── Secrets ───────────────────────────────────────────────────────────────────

variable "ssm_prefix" {
  description = "SSM Parameter Store path prefix for app secrets (no trailing slash)"
  type        = string
  default     = "/think-cricket"
}
