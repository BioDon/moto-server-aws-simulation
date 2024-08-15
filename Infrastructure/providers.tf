terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region                      = "eu-central-1"
  access_key                  = "fakeaccesskey"  # Moto requires dummy credentials
  secret_key                  = "fakesecretkey"  # Moto requires dummy credentials
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    dynamodb           = "http://localhost:30500"
  }
}