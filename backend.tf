# This file defines the S3 backend configuration for Terraform state management.
# Note: The S3 bucket must be created manually before using this backend.
# See the README.md for setup instructions.

terraform {
  backend "s3" {
    bucket       = "voxpop-terraform-state"
    key          = "infra/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}
