variable "name" { type = string }
variable "role_arn" { type = string }
variable "runtime" { type = string default = "python3.12" }
variable "handler" { type = string default = "lambda_function.lambda_handler" }
variable "zip_path" { type = string description = "Path to packaged Lambda zip" }
variable "tags" { type = map(string) default = {} }
