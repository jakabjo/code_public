locals {
  name = "hello"
  tags = { Project = "aws-tf-snippets", Env = "dev" }
}

module "role" {
  source = "../../modules/iam-role-for-lambda"
  name   = "${local.name}-lambda-role"
  tags   = local.tags
}

# Create a tiny hello-world zip
resource "local_file" "lambda_py" {
  filename = "${path.module}/lambda_function.py"
  content  = <<-PY
def lambda_function(event, context):
    return {"statusCode": 200, "body": "hello from lambda"}
PY
}

resource "archive_file" "zip" {
  type        = "zip"
  source_file = local_file.lambda_py.filename
  output_path = "${path.module}/lambda.zip"
}

module "api" {
  source   = "../../modules/lambda-api"
  name     = "${local.name}-fn"
  role_arn = module.role.role_arn
  zip_path = archive_file.zip.output_path
  tags     = local.tags
}

output "invoke_url" { value = module.api.invoke_url }
