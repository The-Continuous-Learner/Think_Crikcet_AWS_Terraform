terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # S3 remote state — created by bootstrap/cloudformation-bootstrap.yml
  # Note: backend block does not support variables. If you changed the default
  # bucket/table names in the CloudFormation parameters, update them here.
  # The region must match wherever you deployed the bootstrap CFT.
  backend "s3" {
    bucket         = "think-cricket-tfstate"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "think-cricket-tflock"
    encrypt        = true
  }
}
