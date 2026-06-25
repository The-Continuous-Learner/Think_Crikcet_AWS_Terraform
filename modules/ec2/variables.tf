variable "project_name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "app_port" {
  type = number
}

variable "jar_s3_bucket" {
  type = string
}

variable "jar_s3_key" {
  type = string
}

variable "ssm_prefix" {
  type = string
}
