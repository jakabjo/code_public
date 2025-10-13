provider "aws" {
  region = var.region
}
variable "region" {
  type        = string
  description = "AWS region"
  default     = "us-west-2"
}
