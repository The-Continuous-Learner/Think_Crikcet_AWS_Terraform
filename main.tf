provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

module "networking" {
  source = "./modules/networking"

  project_name      = var.project_name
  vpc_cidr          = var.vpc_cidr
  subnet_cidr       = var.subnet_cidr
  availability_zone = var.availability_zone
}

module "ec2" {
  source = "./modules/ec2"

  project_name  = var.project_name
  aws_region    = var.aws_region
  vpc_id        = module.networking.vpc_id
  subnet_id     = module.networking.subnet_id
  instance_type = var.instance_type
  app_port      = var.app_port
  jar_s3_bucket = var.jar_s3_bucket
  jar_s3_key    = var.jar_s3_key
  ssm_prefix    = var.ssm_prefix
}
