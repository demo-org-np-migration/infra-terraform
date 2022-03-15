# Backend literal: un bloque `backend` no acepta variables ni expresiones, así
# que estos valores están hardcodeados a propósito. Si algún día esto corre
# contra EKS real, se pisan con -backend-config en el init, no editando esto.
terraform {
  backend "s3" {
    bucket         = "cauri-terraform-state"
    key            = "platform/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"

    use_path_style              = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    skip_region_validation      = true

    endpoints = {
      s3       = "http://localhost:4566"
      dynamodb = "http://localhost:4566"
    }
  }
}
