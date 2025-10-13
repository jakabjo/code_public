remote_state {
  backend = "s3"
  config = {
    bucket         = "replace-me-tf-state"
    key            = "global/terragrunt.hcl.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "replace-me-tf-locks"
  }
}
